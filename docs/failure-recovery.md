# Failure diagnosis and recovery

Record the environment ID as soon as creation succeeds and execution IDs as soon
as they are available. Inspect existing state before retrying a write after a
timeout; provisioning is not an atomic transaction or guaranteed idempotent.

| Symptom | Evidence to inspect | Recovery |
| --- | --- | --- |
| OAuth/session error | Client connection status, current organization | Reconnect/refresh through the client's auth flow |
| 403 access rule not configured | Failed tool/path and role scope | Report missing Gateway ACL; do not bypass via another endpoint |
| Repository unavailable | Selected SCM ID and repository visibility | Correct connection/permissions; re-list repos and branches |
| No client found for provider ID | Effective BUILD provider and defaults | Correct stale provider selection before retry |
| Missing workflow source token | SCM sync result for actual provider/environment | Sync SCM credential; registry sync alone is insufficient |
| Registry push/pull failure | Both profile registry IDs, image reference, sync result | Correct registry mapping/access without disclosing passwords |
| COPY .next: not found | Build output, .dockerignore, selected job | Use verified managed Node packaging or repair a deliberate custom artifact |
| Build output exists but runtime crashes | Startup script, packaged file layout, runtime deps, port | Align entrypoint and runtime with artifact content |
| HTTP URL exists but app is unavailable | Current execution status, DNS/TLS/routing, application response | Report allocated URL separately from verified readiness |
| Summary tool returns 404 | Deployed tool and backend endpoint availability | Use available execution metadata and report missing summary support |
| Profile selection ambiguous | Active profiles and referenced_profile_id | Select the intended pair explicitly |
| Timeout after environment creation | Environment ID in error, list/get environments, executions | Reuse existing environment; do not provision a duplicate |

## Retry in the same environment

After the cause is fixed and the retry is authorized, retrieve
get_ephemeral_environment and identify the profiles actually attached to it.
They may be environment-specific copies; do not assume the original application's
profile IDs are the attached IDs.

Call build_and_deploy_ephemeral_environment with verified IDs:

```json
{
  "environment_id": "<existing-environment-id>",
  "profiles": [{
    "build_profile_id": "<attached-build-profile-id>",
    "deployment_profile_id": "<attached-deployment-profile-id>"
  }]
}
```

Do not set force_restart simply because a previous build failed. Do not provide
release_candidate_id unless deliberately reusing a verified existing artifact.
A new build/deploy call creates another execution: record it and follow that one.

If attached profiles cannot be corrected through exposed tools, explain the
missing edit capability and use an authorized product operation. Repeatedly
creating new applications or profiles is not a substitute for understanding
which environment settings are in use.

## Completion and cleanup

Report the observed revision if available, image/build reference if useful,
environment URL, expiry and verification result. Never label an allocated URL
as a successfully deployed app without supporting evidence.

Use the product lifecycle flow for early cleanup where supported. The kit does
not instruct agents to delete database records, flush caches, delete shared
applications, or bypass role checks to remove an environment.

