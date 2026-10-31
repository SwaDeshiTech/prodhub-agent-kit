# Submit ProdHub to the ChatGPT plugin directory

The generated package uses the portable Agent Plugins format and connects one
remote, OAuth-protected MCP server at `https://app.prodhub.in/mcp`.

## Remaining-issue checklist

### Code and package

- [x] Provide the portable `plugin.json` manifest and OpenAI interface metadata.
- [x] Provide exactly five positive and three negative review cases.
- [x] Describe the expected safe behavior for every negative case.
- [x] Declare the canonical OAuth resource in `mcp.json`.
- [x] Publish OAuth authorization-server and protected-resource metadata.
- [x] Support authorization code, PKCE S256, DCR, refresh-token rotation, and
  exact redirect-URI validation.
- [x] Bind the OAuth `resource` value through authorization, code exchange,
  refresh grants, access-token audience, and Gateway token validation.
- [x] Return explicit `readOnlyHint`, `destructiveHint`, and `openWorldHint`
  values for every live MCP tool.
- [x] Declare OAuth `securitySchemes` on every tool and mirror them under
  `_meta` for compatibility.
- [ ] Deploy the corresponding Gateway changes before running the OpenAI tool
  scan. Existing MCP access and refresh tokens must be authorized again because
  old tokens use the previous internal audience.
- [ ] Confirm the OpenAI upload validator accepts its documented
  `extensions.com.openai.auth` block despite the portable MCP 1.0 schema not
  yet recognizing that extension.

### Review material and portal actions

- [ ] Create a dedicated reviewer account and sample organization using the
  data described below. Store credentials only in OpenAI Review details.
- [ ] Run all five positive and three negative cases using the reviewer account
  in ChatGPT and Codex.
- [ ] Record a walkthrough of OAuth linking and the principal test cases; host
  it at a reviewer-accessible HTTPS URL.
- [ ] Add that real URL as
  `extensions.com.openai.review.demo_recording_url`, increment the package
  version, and rebuild the ZIP. Do not add a placeholder URL.
- [ ] Verify the SwaDeshiTech developer or business identity in OpenAI.
- [ ] Upload the ZIP as a draft and select the remote **With MCP** flow.
- [ ] Serve the exact portal-generated token at the requested
  `/.well-known/openai-apps-challenge` URL and complete domain verification.
- [ ] Connect the reviewer account, run a fresh production tool scan, and
  resolve every annotation, authentication, privacy, or safety finding.
- [ ] Complete the policy attestations and submit the validated draft.

## Prepare the review account

Create a dedicated ProdHub reviewer account containing only sample data. It
should have:

- an active organization;
- an accessible `prodhub-static` application with one active BUILD profile and
  one active DEPLOYMENT profile;
- at least one Preview Space template;
- at least one recent Preview Space with a pipeline execution; and
- enough quota and configured providers to create one short-lived Preview Space
  if the reviewer approves the write action.

Do not place its password, OAuth tokens, provider credentials, or reviewer login
instructions in this repository or in the plugin ZIP. Enter them in the secure
Review details form in the OpenAI portal.

## Build the upload

From this repository, run:

```bash
./scripts/package-chatgpt-plugin.sh
```

Upload the generated `dist/prodhub-chatgpt-plugin-<version>.zip` file. The ZIP
contains only `plugin.json`, `mcp.json`, `assets/`, and `skills/`.

## Create the submission

1. Open the ChatGPT Plugins directory and choose **Add**.
2. Choose the option to upload a new or existing plugin.
3. Select the verified SwaDeshiTech developer or business identity.
4. Upload the generated ZIP and choose the remote **With MCP** path.
5. Confirm the MCP URL is `https://app.prodhub.in/mcp` and authentication is
   OAuth with dynamic client registration.
6. Complete the domain challenge shown by the portal at the exact HTTPS
   `/.well-known/openai-apps-challenge` location it requests. The response must
   contain only the provided token as plain text.
7. Connect the review account and allow the portal to scan the live MCP tools.
8. Resolve all required metadata, authentication, and tool findings.

## Finish review material

Record a reviewer-accessible walkthrough demonstrating the five positive cases
from `plugin.json` and the OAuth consent flow. Add its HTTPS URL as
`extensions.com.openai.review.demo_recording_url`, increment the plugin version,
and rebuild the ZIP.

In the portal, securely enter the reviewer account credentials and sign-in
instructions. Verify that the imported review material contains exactly five
positive cases and three negative cases. Run all positive cases against the
review account before submission.

## Submit and publish

Submit the draft for review and complete the policy attestations. After approval,
open the approved package version and explicitly publish it. MCP tool changes are
scanned separately after initial publication; listing, asset, or skill changes
require a new plugin package version.
