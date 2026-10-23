# Product concepts and tool boundaries

## Objects an agent works with

| Object | Purpose | Relationship |
| --- | --- | --- |
| Organization | Tenant/access context selected through authentication | Scopes applications and accessible provider connections |
| SCM connection | Repository access through connected GitHub credentials | Used by build profiles and credential sync |
| Build provider | Executes the build job, such as Jenkins or GitHub Actions | Distinct from the repository and Docker registry |
| Docker registry connection | Image push/pull destination and authentication | BUILD and DEPLOYMENT should resolve consistent image access |
| Application | Logical service identity | Can have multiple BUILD and DEPLOYMENT profiles |
| BUILD profile | Source branch, build command, image/toolchain and packaging settings | Produces the image used by deployment |
| DEPLOYMENT profile | Runtime ports and deployment configuration | Can reference a BUILD profile |
| Preview Space | Expiring environment containing selected application/profile pairs | Called ephemeral environment in MCP names |
| Pipeline execution | Record of stages, steps and status | Multiple executions can belong to one Preview Space |
| Release candidate | Built artifact/version selected for deployment | May be reused when explicitly supported |
| AI workspace | Interactive coding runtime | Separate from ordinary build-and-deploy preview delivery |

ProdHub supplies organization defaults and orchestrates delivery; a coding agent
supplies user intent and verified source-derived settings. MCP runs through
Gateway, while build/deployment work is performed by backend services/providers.
Connecting MCP does not upload source, synchronize every provider credential,
or make a build succeed automatically.

## Choose the right path

- Existing app and correct profile pair: discover, plan, provision, monitor.
- New app: inspect source, propose onboarding, create app/profiles, plan, provision.
- Multiple profile pairs: select explicit IDs with provision_ephemeral_environment.
- Existing preview requiring another delivery: inspect it and use
  build_and_deploy_ephemeral_environment.
- Empty environment requested: create_ephemeral_environment is appropriate.
- Failed delivery: inspect execution, diagnose, correct the cause, retry deliberately.

## Current limits

Read live tools/list for the deployed feature set. In the source version reviewed
for this kit, there is no inspect_repository_for_delivery, apply_application_preview_plan,
general profile-update tool, or dedicated Preview Space deletion tool.
The planner only resolves existing application/profile selections. It is not a
source analyzer, capacity check, cost quote, or server-enforced approval mechanism.

Use explicit user intent to determine authorized scope. Do not repeatedly request
approval for an unchanged plan the user has already authorized. Request a new
decision when scope changes materially, such as a different organization, public
sharing, new dependent services, or deletion.

