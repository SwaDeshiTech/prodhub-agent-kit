# Resource Manager: template-driven cluster placement

Use Resource Manager when the user wants to group Kubernetes clusters or decide
which capacity should run Preview Spaces and AI Studio workspaces. Resource
Manager does not connect a new cluster; Kubernetes onboarding must already be
complete.

## Authorization boundary

Start with `get_prodhub_delivery_capabilities` and
`list_available_product_areas`. Continue only when the authenticated user's
role-visible response contains `/dashboard/resourceManager` and the required
child area:

- `/dashboard/resourceManager/k8sClusterGroups`

Tab visibility is discovery guidance, not authorization by itself. Every request
still passes through the Gateway ACL and ProdHub ownership/access checks. Do not
try another path, organization, or identifier after an authorization failure.

`/dashboard/resourceManager/cloudResources` is intentionally unavailable through
MCP. Do not approximate cloud inventory access with another tool or operation.

## Required MCP sequence

1. Call `get_resource_manager_contract` and follow its live field definitions.
2. Call `list_product_operations` for the Resource Manager parent:

```json
{"product_area_link":"/dashboard/resourceManager"}
```

3. Read existing cluster groups and pipeline templates through only the operation
   IDs returned by that call. Resolve template, organization, and cluster IDs from
   authorized ProdHub discovery; do not ask the user to type opaque IDs.
4. Prepare the smallest complete change. Show its name, scope, workload types,
   pipeline templates, clusters, scheduling behavior, priority, and active state.
5. Obtain explicit user approval immediately before create, update, or delete.
6. Call `execute_product_operation` with the exact returned operation ID. Set
   `confirmed` to `true` only after approval.
7. Re-read the affected object and report the observed saved state.

Reads use the same executor without confirmation:

```json
{
  "operation_id":"list_k8s_cluster_groups"
}
```

A confirmed write has this shape:

```json
{
  "operation_id":"create_k8s_cluster_group",
  "body":{
    "name":"Preview capacity",
    "description":"Run Preview Space pipelines on the approved cluster pool",
    "clusterIds":["<resolved-cluster-id>"],
    "pipelineTemplateIds":["<resolved-pipeline-template-id>"],
    "schedulingStrategy":"RESOURCE_BASED",
    "workloadTypes":["EPHEMERAL_ENVIRONMENT"],
    "priority":10,
    "isActive":true
  },
  "confirmed":true
}
```

The values above illustrate the payload shape. Never copy example IDs or assume
the priority and scope are appropriate for the connected organization.

## Kubernetes cluster groups

A cluster group is a scheduling pool. Read the live contract before writing;
the supported fields currently include:

| Field | Meaning |
| --- | --- |
| `name` | Required human-readable group name |
| `description` | Optional capacity and purpose explanation |
| `clusterIds` | Connected Kubernetes cluster IDs selected through ProdHub |
| `pipelineTemplateIds` | Required pipeline templates whose workloads use the group |
| `schedulingStrategy` | `RESOURCE_BASED` or `ROUND_ROBIN` |
| `priority` | Non-negative ordering value |
| `isActive` | Whether the group can receive workloads |
| `workloadTypes` | `EPHEMERAL_ENVIRONMENT`, `AI_WORKSPACE`, or both as supported by the live contract |

Before removing a cluster or disabling/deleting a group, explain that future
allocation may stop matching it. Do not claim that changing the group migrates
already-running workloads unless a returned tool explicitly provides that
behavior.

Allocation is template-driven: a workload is eligible for a group only when all
pipeline templates used by that workload are mapped to the group. When more than
one eligible group exists, priority and the selected scheduling strategy decide
which capacity is evaluated first. Always resolve template and cluster IDs from
authorized reads rather than accepting opaque IDs from the user.

For Preview Spaces and standard deployments, Resource Manager is an override of the Kubernetes cluster
already selected by the deployment profile. If no active mapping applies to the
pipeline template, workload type, and organization, ProdHub falls back to the
deployment-profile cluster. If an applicable mapping exists but its clusters
lack capacity or are unavailable, allocation fails instead of bypassing the
configured policy. AI workspaces have no deployment-profile fallback and
therefore require an applicable Resource Manager mapping.

## Safe failure handling

- If the contract tool is missing, the deployed Gateway is older than this kit.
  Report the mismatch and do not invent operations.
- If the requested child tab is not visible, explain that the connected role
  does not expose that workflow.
- If `list_product_operations` omits an expected operation, treat it as
  unavailable even if this document names it.
- If a write is rejected, preserve the current state and report the returned
  authorization or validation error. Do not retry with altered scope.
- If a save succeeds but the verification read differs, report the observed
  backend state rather than the intended payload.
