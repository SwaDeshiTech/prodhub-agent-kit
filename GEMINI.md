# ProdHub delivery instructions

Read [the full Preview Space runbook](docs/preview-delivery.md) before delivery.
Use [product concepts](docs/product-concepts.md), [profile fields](docs/profile-fields.md),
[runtime templates](docs/runtime-templates.md), and
[failure recovery](docs/failure-recovery.md) as references. For Kubernetes
capacity management, read [the Resource Manager runbook](docs/resource-manager.md).
Copy these docs with this file, or use
https://github.com/SwaDeshiTech/prodhub-agent-kit/tree/main/docs.

Use the `prodhub` MCP server for application delivery and Preview Space work.

1. Call `get_prodhub_delivery_capabilities` to discover the available workflow.
2. Call `list_available_product_areas` and only
   propose workflows from the returned role-filtered product areas.
3. For Resource Manager work, read `get_resource_manager_contract`, then call
   `list_product_operations` for `/dashboard/resourceManager`. Read existing
   cluster groups and allocation rules before proposing a change, and obtain
   explicit approval before a write. Cloud Resources is excluded from MCP.
4. Inspect source files before setting profile fields. For Jenkins, call
   `get_prodhub_build_pipeline_contract` and follow its field definitions.
5. Do not use `start_profile_generation` when source is available locally; it is a
   fallback for agents without source access.
6. Call `get_runtime_template_contract` before changing runtime templates. For a
   source-repository Helm chart, verify `Chart.yaml`, use relative paths, and
   inherit the application repository and exact pipeline commit by default.
7. Propose onboarding separately for new apps; the planner requires saved profiles.
   Call `plan_application_preview` for an existing pair. Proceed under existing
   user authorization or ask for missing approval when scope is unclear.
8. After approval, provision the preview and monitor it through
   `get_preview_delivery_status`. An allocated URL is not proof of readiness:
   inspect the current execution and verify the app response. Retain operation
   IDs and inspect partial success before retrying a write.

Keep credentials in ProdHub and never output them in chat, logs, or commits.
