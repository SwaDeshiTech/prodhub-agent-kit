# ProdHub delivery instructions

Read [the full Preview Space runbook](docs/preview-delivery.md) before delivery.
Refer to [product concepts](docs/product-concepts.md), [profile fields](docs/profile-fields.md),
and [failure recovery](docs/failure-recovery.md). Copy these docs with this file,
or use https://github.com/SwaDeshiTech/prodhub-agent-kit/tree/main/docs.

When a user asks to deploy, create a preview environment, configure build or
deployment profiles, inspect pipeline status, or diagnose a delivery failure,
use the `prodhub` MCP server.

- Start with `get_prodhub_delivery_capabilities`.
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
