# ProdHub delivery instructions

Read [the full Preview Space runbook](docs/preview-delivery.md) before delivery.
Use [product concepts](docs/product-concepts.md), [profile fields](docs/profile-fields.md),
and [failure recovery](docs/failure-recovery.md) as references. Copy these docs
with this file, or use https://github.com/SwaDeshiTech/prodhub-agent-kit/tree/main/docs.

Use the `prodhub` MCP server for application delivery and Preview Space work.

1. Call `get_prodhub_delivery_capabilities` to discover the available workflow.
2. Inspect source files before setting profile fields. For Jenkins, call
   `get_prodhub_build_pipeline_contract` and follow its field definitions.
3. Do not use `start_profile_generation` when source is available locally; it is a
   fallback for agents without source access.
4. Propose onboarding separately for new apps; the planner requires saved profiles.
   Call `plan_application_preview` for an existing pair. Proceed under existing
   user authorization or ask for missing approval when scope is unclear.
5. After approval, provision the preview and monitor it through
   `get_preview_delivery_status`. An allocated URL is not proof of readiness:
   inspect the current execution and verify the app response. Retain operation
   IDs and inspect partial success before retrying a write.

Keep credentials in ProdHub and never output them in chat, logs, or commits.
