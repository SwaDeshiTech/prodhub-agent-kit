# Deriving profile values from source

Always read the live application-profile and selected build-pipeline contracts.
This guide explains semantics; it does not override the deployed tool schema.

## BUILD profile fields

| MCP field | Meaning and evidence |
| --- | --- |
| application_id | Existing logical application ID returned by discovery/creation |
| scm_credential_id | Connected SCM ID, never the raw access token; copied to data.scmId |
| name | Optional alphanumeric profile name; distinguish repository/branch purpose |
| data.repo | Verified owner/repository from SCM discovery |
| data.branchName | Verified remote branch containing the intended changes |
| data.buildPath | Working directory for the build, relative to repository root; defaults to . |
| data.dockerfileAvailable | Actual presence of Dockerfile at the selected build location |
| data.buildCommand | Shell command executed after changing to buildPath; required for custom builds |
| data.artifactPath | Output copied into the generated image, relative to repository root |
| data.profilePath | Runtime profile directory, relative to repository root; may supply conf, install.sh, bin/startup.sh |
| data.baseImage | In the shared Jenkins job, both builder and generated runtime base; must match toolchain and runtime |
| data.buildProviderId | Selected accessible provider ID or verified organization default |
| data.buildTemplate | Selected provider job/template; Jenkins shared template is prodhub_build |
| data.pipelineTemplateId | Organization pipeline default unless explicitly selected |
| data.dockerRegistryCredentialProviderId | Connected registry ID, preferably identical in intent to deployment registry |

For a nested custom build, buildPath=services/api and artifactPath=services/api/dist
refer to different execution contexts: the command runs inside services/api,
but Docker COPY uses repository-root context. Do not turn artifactPath into an
absolute local path. Avoid copying the entire repository simply to hide a missing
artifact: that can include credentials, caches and unrelated files.

## Managed Node packaging in the Jenkins shared job

Use this only when the selected deployed job supports it and package.json is
present at buildPath. Omit buildCommand and pass .prodhub-artifact as the MCP
artifact marker. The job installs dependencies using package-manager metadata,
runs the build script when present, and stages runnable output.

For root builds the output is .prodhub-artifact; for nested builds the job derives
<buildPath>/.prodhub-artifact. Verify nested/workspace dependency support before
assuming a monorepo package is self-contained.

Choose baseImage from engines, packageManager, lockfile and repository build
configuration. Do not blindly copy node:18-alpine from historical examples.
Check whether pnpm/yarn need Corepack or whether Bun is actually installed.

The packaged runtime may contain standalone Next.js output, Nuxt output, static
assets with a server, or generic Node source/dependencies. Inspect startup behavior:
an existing profile bin/startup.sh takes precedence over the generated Node
entrypoint in the shared job. A script executing node server.js requires that
server.js exists at the packaged runtime root. A correct artifact path alone does
not prove the startup script, runtime image, or port is correct.

The shared job creates a Docker ignore override for managed artifacts. Custom
builds still need their selected artifact included in the Docker context.
Raw .next alone is not a complete generic Next.js runtime; it may also be excluded
by .dockerignore. MCP currently rejects the node:* / .next combination.

## Custom builds and Dockerfiles

Verify dependency installation, wrapper permissions, output path and runtime
dependencies for Java, Go or custom Node commands. A JAR needs Java; a dynamically
linked binary needs compatible runtime libraries.

Do not assume dockerfileAvailable=true makes every shared Jenkins job use that
Dockerfile. Verify the selected template's behavior and the backend command
mapping before choosing this path. The documented managed Node recipe is not a
generic contract for GitHub Actions or arbitrary Jenkins jobs.

## DEPLOYMENT profile fields

| Field | Meaning and evidence |
| --- | --- |
| application_id | Same logical application as the BUILD profile |
| referenced_profile_id | BUILD profile ID linked by this deployment profile |
| data.httpPort / grpcPort / tcpPort | At least one actual listening port; source/startup configuration is evidence |
| data.dockerContainerRegistry | Registry connection capable of pulling the built image |
| runtime_environment | Optional top-level override; otherwise use organization runtime |
| data.startUpCommand | Override only when the image's entrypoint is inadequate |
| resource and probe fields | Use defaults unless measurements/application behavior justify overrides |

An EXPOSE instruction is a hint, not proof of the application's runtime port.
Check environment overrides and that the process binds to an externally reachable
interface. A health probe must use a real endpoint and the correct protocol.
Do not silently change ports just to fit a commonly used framework default.

## Evidence and defaults

Keep a field/value/evidence table in task context. For each unresolved value:
use a documented applicable default, inspect further, or ask the user.
Do not invent provider IDs, registry hosts, startup scripts or health endpoints.
If the live contract and implementation appear inconsistent, report the conflict
before starting a build likely to fail.

