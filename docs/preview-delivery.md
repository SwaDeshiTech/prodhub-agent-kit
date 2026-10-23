# Preview Space delivery: end to end

This is the operating guide for an agent delivering an application through ProdHub.
Read [product concepts](product-concepts.md), [profile fields](profile-fields.md),
and [failure recovery](failure-recovery.md) as needed. Examples use MCP tool
arguments, not REST bodies. Replace every angle-bracket placeholder with a value
returned by discovery or verified in source; never send placeholders literally.

## 1. Understand the request and establish scope

Record the application/repository, branch, desired services, preview lifetime,
and whether the user wants an existing environment updated or a new one.
If the user asked for one day, pass `expiry_duration_days: 1`; omission currently
defaults to seven days. Ask about choices that materially change the requested
deployment, rather than asking the user to find database IDs.

A build checks out remote source. Local edits are not automatically uploaded.
Check the local Git branch, remote, and uncommitted changes when a checkout is
available. Explain if the requested changes are not present on the remote branch.
Do not claim that a remote build includes uncommitted changes. Publishing source
requires authorization under the user's repository workflow.

## 2. Connect and discover

Use the configured ProdHub MCP connection and its OAuth flow. Read the live
`tools/list`: documentation describes the source implementation, which may be
ahead of the deployed server.

Call `get_prodhub_delivery_capabilities` and `get_application_profile_contract`.
For Jenkins, also read `get_prodhub_build_pipeline_contract`.
Use `list_organizations` if organization context is missing or unclear.
Organization selection belongs to the authenticated product/OAuth session;
listing organizations does not switch the current session.

If a bootstrap tool is unavailable, report that version mismatch and use the
available documented tools. Do not invent a replacement tool or bypass ACLs.

## 3. Discover provider connections

Call `list_connections` once for each type:

```json
{"type":"scm"}
{"type":"repositoryProvider"}
{"type":"buildProvider"}
```

Select an accessible active GitHub connection and intended build provider.
For registry selection, MCP profile creation preserves an explicit registry ID;
otherwise it prefers a private user connection, then organization-visible,
then globally shared connections. If multiple acceptable connections exist,
make the selection explicit when it affects the image destination.

Verify repository and branch:

```json
{"credential_id":"<scm-id>"}
```

Pass that to `list_github_repositories`, then call
`list_github_branches`:

```json
{"credential_id":"<scm-id>","repository":"<owner/repository>"}
```

If GitHub is missing, use `start_github_connection` and let the user complete
the returned OAuth link. Re-list connections afterwards. Use the product's
connection flow for registry secrets when possible; do not put secrets in
project files or repeat them in output.

Synchronize selected SCM and registry credentials to the actual build provider
using `sync_credential_to_build_providers`, one credential per call:

```json
{"credential_id":"<scm-or-registry-id>","build_provider_ids":["<build-provider-id>"]}
```

Read each provider's result, not just the top-level message. The selected
provider must match the profile's effective provider, including organization
defaults. A successful registry sync does not imply that SCM credentials are
synced. Do not guess a GitHub Actions environment name; the generic sync tool
can omit `github_actions_environment_name` to use the provider default.

## 4. Reuse or onboard the application

Call `list_applications`. Reuse the intended application if it exists.
Names that look similar are not proof of identity. Disambiguate using the
repository and user context.

For an existing application, call `list_application_profiles` for both types:

```json
{"application_id":"<application-id>","profile_type":"BUILD"}
{"application_id":"<application-id>","profile_type":"DEPLOYMENT"}
```

Reuse a pair only when it matches the requested source and runtime. A profile
dropdown may provide identifiers and labels without all settings; if you cannot
verify its data, do not claim it has been checked.

For a new application, prepare an onboarding proposal describing the repository,
branch, inferred fields, provider/registry, and resource creation. Proceed under
the user's authorization; ask for missing authorization before executing writes.

`create_application` accepts:

```json
{"name":"catalog-web"}
```

Application names are lowercase DNS labels, maximum 63 characters. Persist its
returned ID in task context before the next operation.

## 5. Derive BUILD and DEPLOYMENT settings

Inspect the target source revision: build manifest, lockfile, runtime versions,
Dockerfile, .dockerignore, startup script, application root, port and dependencies.
Read [profile fields](profile-fields.md) for the meanings and packaging rules.
Keep a compact evidence record such as:

| Field | Proposed value | Evidence |
| --- | --- | --- |
| buildPath | . | package.json at repository root |
| artifactPath | .prodhub-artifact | selected Jenkins job supports managed Node mode |
| buildCommand | omitted | managed Node packaging selected |
| httpPort | 3001 | committed startup script sets PORT=3001 |

This is an example, not a universal default. Verify every row for the target.

If source is unavailable, `start_profile_generation` is an optional fallback:

```json
{"github_url":"https://github.com/<owner>/<repository>","credential_id":"<scm-id>","branch":"<branch>","application_id":"<application-id>"}
```

Poll `get_profile_generation` with `{"job_id":"<returned-job-id>"}`.
Treat drafts and assumptions as proposals. If evidence remains insufficient,
request the missing information. The current tool surface does not include a
general-purpose repository-file reader named `inspect_repository_for_delivery`.

## 6. Save profiles when required

Create a BUILD profile with `create_application_profile`. This example assumes
a root Node app, no Dockerfile, a compatible selected Node image, and a deployed
Jenkins job supporting managed Node packaging:

```json
{
  "application_id": "<application-id>",
  "scm_credential_id": "<scm-id>",
  "name": "CatalogPreviewBuild",
  "profile_type": "BUILD",
  "data": {
    "repo": "<owner/repository>",
    "branchName": "<verified-branch>",
    "buildPath": ".",
    "dockerfileAvailable": false,
    "artifactPath": ".prodhub-artifact",
    "profilePath": "<verified-profile-directory>",
    "baseImage": "<verified-node-image>",
    "buildProviderId": "<selected-build-provider-id>",
    "dockerRegistryCredentialProviderId": "<selected-registry-id>"
  }
}
```

Provider and registry overrides can be omitted when verified defaults are
appropriate. Do not hardcode IDs from examples or another organization.
Save the returned BUILD profile ID, then create a linked deployment profile:

```json
{
  "application_id": "<application-id>",
  "name": "CatalogPreviewDeployment",
  "profile_type": "DEPLOYMENT",
  "referenced_profile_id": "<build-profile-id>",
  "data": {
    "httpPort": "<verified-port>",
    "dockerContainerRegistry": "<same-selected-registry-id>"
  }
}
```

Profile names contain letters and digits only. `data` is an object in MCP
arguments; the server performs backend serialization. Keep runtime/cluster/
resource defaults unless the task requires an evidenced override. Check that
the registry chosen for BUILD and DEPLOYMENT is consistent.

Current MCP exposes creation, not a general profile-update tool. If an existing
profile is wrong, use an available authorized product edit flow, or create a
replacement pair and select it explicitly. Never pretend creation updates an ID.

## 7. Prepare the delivery plan

For an existing application with a resolvable active pair:

```json
{
  "application_id": "<application-id>",
  "name": "catalog-preview",
  "expiry_duration_days": 1
}
```

Call `plan_application_preview`. It resolves profiles and previews environment
creation; it does not inspect repository contents, validate credentials, estimate
cost, or guarantee that the build will run. It requires the application and
profiles to already exist, so it cannot plan initial onboarding before those
writes. Show an onboarding proposal separately in that case.

Review the returned profile IDs, environment name and lifetime with the user.
A plan is not an approval token or a reservation; profile state may change before
execution. Carry the exact planned name and lifetime into the provision request.

Multiple active pairs may be ambiguous. Use explicit IDs and show the equivalent
plan to the user before `provision_ephemeral_environment`:

```json
{
  "name": "catalog-preview",
  "expiry_duration_days": 1,
  "profiles": [{
    "application_id": "<application-id>",
    "build_profile_id": "<build-profile-id>",
    "deployment_profile_id": "<deployment-profile-id>"
  }]
}
```

Do not set `confirm_dependencies` unless dependencies have been reviewed and
authorized. Do not enable AI workspace mode for an ordinary preview.

## 8. Provision and retain operation IDs

For a unique approved pair, call `provision_application_preview` with the same
application ID, planned name and expiry. It creates the environment and starts
build/deploy. Do not call `create_ephemeral_environment` first and then provision:
that would create another environment.

Record environment ID, profile IDs and execution IDs immediately. Provisioning
spans several backend operations and can partially succeed. If it times out or
reports that the environment was created but delivery failed, inspect that
environment before retrying. See [failure recovery](failure-recovery.md).

Conceptually the delivery creates environment resources, checks out source,
builds/packages the application, pushes an image, deploys it, and exposes a URL.
Actual stage order, image reuse and provider behavior come from the selected
pipeline; read execution evidence rather than promising a fixed stage sequence.

## 9. Monitor until the outcome is known

Call `get_preview_delivery_status` with
`{"environment_id":"<environment-id>"}`. Poll with a modest delay (for example
10–15 seconds, backing off for long builds). Also use
`list_ephemeral_environment_pipeline_executions` and
`get_pipeline_execution` for precise stage evidence.

Interpret the normalized states carefully:

| State | Agent action |
| --- | --- |
| in_progress | Follow current executions; avoid starting a duplicate build. |
| failed | Identify the relevant failed execution and diagnose it. |
| url_available | A URL has been allocated; check execution completion and application health before claiming readiness. |

The current aggregator can see older failed executions, and URLs may exist while
a build is running. Correlate timestamps and execution IDs with this delivery.
A reachable URL is useful evidence, but verify expected application content or
a known health endpoint when network access permits. Never invent /health or
declare a site healthy only because DNS resolves.

If verification is unavailable, return the URL with its actual status and state
what remains unverified. A failed or timed-out status query is not proof that
the deployment itself failed.

## 10. Diagnose, recover, and hand off

Use `summarize_pipeline_failure` with the failed execution ID when available.
If unsupported or returning 404, report that limitation and use available
execution metadata; do not fabricate a log diagnosis. Apply only fixes within
the user's scope, then retry the existing environment using verified attached
profile IDs rather than creating another preview.

A completion report should include application, repository/branch, observed
revision if available, Preview Space name, URL, expiry, delivery status, and any
verification limitation. Keep IDs available for follow-up diagnostics.

Expiry is the configured lifecycle policy, not proof that cleanup has completed.
Early deletion currently has no dedicated Preview Space MCP tool in this source
version; use an authorized product deletion flow if available. Do not substitute
`decommission_application`: that removes the application and owned profiles,
not merely this preview. Never use Mongo/Redis deletion as routine lifecycle work.

