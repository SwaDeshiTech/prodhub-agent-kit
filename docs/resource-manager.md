# Resource Manager: cluster placement and capacity rules

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
- `/dashboard/resourceManager/allocationRules`

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

3. Read existing cluster groups and allocation rules through only the operation
   IDs returned by that call. Resolve group, organization, and cluster IDs from
   authorized ProdHub discovery; do not ask the user to type opaque IDs.
4. Prepare the smallest complete change. Show its name, scope, workload type,
   cluster group, scheduling behavior, priority, and active state.
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
  "operation_id":"create_resource_allocation_rule",
  "body":{
    "name":"Preview capacity",
    "description":"Route Preview Spaces to the approved cluster pool",
    "clusterGroupId":"<resolved-cluster-group-id>",
    "organizationId":"<resolved-organization-id>",
    "workloadType":"EPHEMERAL_ENVIRONMENT",
    "priority":10,
    "active":true
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
| `schedulingStrategy` | `RESOURCE_BASED` or `ROUND_ROBIN` |
| `priority` | Non-negative ordering value |
| `isActive` | Whether the group can receive workloads |
| `workloadTypes` | `EPHEMERAL_ENVIRONMENT`, `AI_WORKSPACE`, or both as supported by the live contract |

Before removing a cluster or disabling/deleting a group, explain that future
allocation may stop matching it. Do not claim that changing the group migrates
already-running workloads unless a returned tool explicitly provides that
behavior.

## Resource allocation rules

An allocation rule maps a workload type to a cluster group. The supported fields
currently include:

| Field | Meaning |
| --- | --- |
| `name` | Required rule name |
| `description` | Optional explanation of when the rule applies |
| `clusterGroupId` | Required existing cluster-group ID |
| `organizationId` | Optional organization-specific scope |
| `workloadType` | `EPHEMERAL_ENVIRONMENT` or `AI_WORKSPACE` |
| `priority` | Non-negative evaluation priority |
| `active` | Whether the rule participates in allocation |

Always list groups first so the selected `clusterGroupId` is valid and visible.
When the user does not specify organization scope or priority, explain the
choice instead of silently broadening access or precedence.

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
