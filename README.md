# ProdHub Agent Kit

Give any MCP-compatible coding harness a safe, repeatable path from source code
to a ProdHub Preview Space.

This kit does not contain credentials. ProdHub uses browser-based OAuth, scopes
each session to the approved organization, and applies the same role controls as
the product UI.

## Install

The canonical remote MCP endpoint is:

```text
https://app.prodhub.in/mcp
```

ProdHub is described for machine discovery in [server.json](./server.json) and
published under `io.github.SwaDeshiTech/prodhub` in the official MCP Registry.
MCP clients and registry-backed catalogs can use that entry to discover the
hosted Streamable HTTP endpoint without relying on a general web search.

### Codex

```bash
codex mcp add prodhub --url https://app.prodhub.in/mcp
```

Merge the delivery instructions in `AGENTS.md` into the repository where Codex
should use ProdHub; preserve existing project instructions. Copy the supporting
docs too, or retain links to this kit.

### Gemini CLI

```bash
gemini mcp add prodhub https://app.prodhub.in/mcp --transport http --scope user
```

Copy `GEMINI.md` into that repository or merge its instructions with an existing
project file.

### Claude Code and other MCP clients

Use the remote-server entry in [mcp.json](./mcp.json), then copy or merge
[CLAUDE.md](./CLAUDE.md) into the project guidance file used by your client.

## First connection

1. Add the MCP endpoint in the client.
2. Start the OAuth connection. Sign in to ProdHub and choose an organization.
3. Approve the consent screen.
4. Ask the coding harness to deploy a branch or create a Preview Space.

The agent should begin with `get_prodhub_delivery_capabilities`, call
`list_available_product_areas`, inspect the repository
and the `prodhub_build` contract, show a plan, obtain approval, and then create
resources. The product-area response is filtered by the same role-based tab
configuration used by the ProdHub UI and does not require organization selection.

Read the full workflow in [docs/preview-delivery.md](./docs/preview-delivery.md).

## Understand the product before deploying

Start with [product concepts](docs/product-concepts.md) to distinguish applications,
profiles, provider connections, Preview Spaces, and pipeline executions.
Then follow the [end-to-end Preview Space runbook](docs/preview-delivery.md).
It covers new applications, existing profiles, credential sync, branch/revision
verification, planning, explicit profile selection, provisioning, monitoring,
retrying in the same environment, and lifecycle handoff.

Use [profile field definitions](docs/profile-fields.md) while inspecting source,
and [failure recovery](docs/failure-recovery.md) when delivery fails.
These guides describe the current implementation; the connected server's
`tools/list` is authoritative for tool availability.

## Example requests

- “Deploy this repository's feature/login branch to a new Preview Space for one day.”
- “Reuse the existing catalog application's profiles and give me a verified preview URL.”
- “Check why this Preview Space failed, fix the configuration, and retry in the same environment.”

The agent should retain the application, profile, environment, and execution IDs
returned by tools. Users should not have to discover these IDs manually.
Local uncommitted changes are not included in a remote build.

## Important boundaries

`plan_application_preview` plans delivery for an existing application with saved
profiles. New application onboarding needs its own proposal before those records
are created. The planner does not validate the source code or reserve resources.

A `url_available` response means a URL exists, not necessarily that the application
has finished deploying. Inspect the current execution and verify the application
response before reporting success. Early environment deletion and generic profile
updates currently need a supported product flow; do not invent MCP tools for them.

`mcp.json` is a configuration example. Clients have different file names and
schemas; cloning this repository alone does not register the MCP server.

## Files

- [server.json](./server.json): official MCP Registry metadata for the hosted server.
- [mcp.json](./mcp.json): portable remote-MCP configuration.
- [AGENTS.md](./AGENTS.md): Codex-oriented project instructions.
- [CLAUDE.md](./CLAUDE.md): Claude Code project instructions.
- [GEMINI.md](./GEMINI.md): Gemini CLI project instructions.
- [docs/preview-delivery.md](./docs/preview-delivery.md): safe delivery workflow.

For the browser setup page, see [prodhub.in/setup](https://prodhub.in/setup).

## Publishing discovery metadata

The `Publish MCP Registry metadata` GitHub workflow validates and publishes
`server.json` using GitHub OIDC. No registry token or long-lived secret is
required. Increment the manifest version whenever the public MCP identity or
tool contract changes; merging that update to `main` republishes the entry.
