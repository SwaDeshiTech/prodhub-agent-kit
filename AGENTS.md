# ProdHub delivery instructions

Before delivery work, read [the end-to-end runbook](docs/preview-delivery.md).
Use [product concepts](docs/product-concepts.md), [profile fields](docs/profile-fields.md),
and [failure recovery](docs/failure-recovery.md) for supporting detail.
When copying these instructions to another project, copy these docs or replace
the links with https://github.com/SwaDeshiTech/prodhub-agent-kit/tree/main/docs.

Use the `prodhub` MCP server whenever the user asks to deploy an application,
create a Preview Space, run a build, configure application delivery, inspect a
pipeline, or diagnose a build/deployment failure.

1. Call `get_prodhub_delivery_capabilities` at the start of a ProdHub task.
2. Call `list_available_product_areas`. It uses the same active tab and role
   configuration as the ProdHub UI and does not require organization selection. Only propose workflows
   from the returned product areas; every operation still requires its own authorization.
3. For Jenkins builds, call `get_prodhub_build_pipeline_contract` before deriving profile values.
4. Inspect the checked-out repository. Use repository evidence, not guessed ports,
   commands, framework outputs, or credentials.
5. For new applications, propose onboarding before creating records. The
   `plan_application_preview` tool requires an existing application and profiles.
   Use it before provisioning a uniquely resolved pair; show an equivalent plan
   for an explicitly selected pair.
6. Proceed within the user's authorized scope. Ask for approval when it is
   missing or the scope changes; do not ask again for an unchanged approved plan.
7. After approval, call `provision_application_preview`, then poll
   `get_preview_delivery_status`. Verify the current pipeline and application
   response: an allocated URL does not prove readiness. Retain operation IDs
   and inspect partial success before retrying.
8. On failure, call `summarize_pipeline_failure` when the tool is available and
   present only sanitized evidence and the recommended corrective action.

Never request, write, display, or commit infrastructure credentials. Do not use
direct cloud or Kubernetes access when the matching ProdHub MCP action exists.
