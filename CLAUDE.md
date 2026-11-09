# ProdHub delivery instructions

Read [the full Preview Space runbook](docs/preview-delivery.md) before delivery.
Refer to [product concepts](docs/product-concepts.md),
[profile fields](docs/profile-fields.md),
[runtime templates](docs/runtime-templates.md), and
[failure recovery](docs/failure-recovery.md). For Kubernetes capacity management,
read [the Resource Manager runbook](docs/resource-manager.md). Copy these docs
with this file, or use
https://github.com/SwaDeshiTech/prodhub-agent-kit/tree/main/docs.

When a user asks to deploy, create a preview environment, configure build or
deployment profiles, inspect pipeline status, or diagnose a delivery failure,
use the `prodhub` MCP server.

- Start with `get_prodhub_delivery_capabilities`.
- Call `list_available_product_areas` and stay
  within the role-filtered product areas returned by the server.
- For Resource Manager work, call `get_resource_manager_contract`, then discover
  allowlisted operations for `/dashboard/resourceManager` with
  `list_product_operations`. Read current state first and require explicit user
  approval for writes. Never attempt to access Cloud Resources through MCP.
- Inspect the current repository and call `get_prodhub_build_pipeline_contract`
  before preparing BUILD profile values.
- Use only source-backed configuration. In particular, validate `.dockerignore`,
  runtime profile scripts, artifact paths, and listening ports.
- For new apps, propose onboarding first: the planner requires saved profiles.
  Call `plan_application_preview` for an existing pair and show the result.
  Use existing user authorization for the agreed scope; ask when it is missing
  or the plan materially changes.
- Call `provision_application_preview` only after approval; poll
  `get_preview_delivery_status`. Check current execution completion and app
  reachability before declaring success. Keep operation IDs for retries.
- Use `summarize_pipeline_failure` for a failed delivery when available.

Never expose credentials or bypass ProdHub with direct cluster/cloud operations.
