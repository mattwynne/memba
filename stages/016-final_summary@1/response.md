# Iteration 066 implementation summary

- **Result:** `IMPLEMENTED_AND_PUBLISHED`
- **Plan path:** `docs/iterations/066-request-group-access/plan.md`
- **Published commit on `main`:** `3037eae8e4ea202ba48517d8948ce1b90a7dbb8d`

## Delivered capability

Implemented the custom-group access-request workflow:

- A club member who cannot access a custom group can send a fixed, server-composed request to the club’s Admin Group.
- The request uses the existing messaging aggregate and delivery flow rather than introducing a request entity or pending lifecycle.
- Request emails retain the ordinary URL in plain text and render a validated, escaped primary-action link in HTML.
- The private-group placeholder now offers a single-submit **Request access** action with concise sent feedback.
- Signed-in, authorised administrators can open the targeted add-member URL and review the person and group before taking action.
- GET remains read-only and scanner-safe; membership changes only after explicit confirmation.
- Confirmation uses the existing admission and welcome flow and rechecks current actor authority and target membership.
- Forged IDs, cross-club targets, built-in groups, inactive memberships, lost authority, stale target membership, and duplicate additions are covered.
- Existing privacy barriers and general Admin Group contact behaviour remain intact.

## Plan conformance

The plan-conformance gate returned:

- `plan_conformant: true`
- `plan_rework_available: false`

All nine entries in `docs/iterations/066-request-group-access/todo.md` were completed. The final artifact gate explicitly confirmed implementation evidence, permitted acceptance-feature changes, absence of generated Python bytecode, and reported:

> `Final artifact evidence confirmed.`  
> `Final artifact gate passed.`

The evidence reported a base-to-head implementation diff of **37 files**, with **3,926 insertions and 57 deletions**.

## Key files changed

The following paths are explicitly present in the final artifact gate evidence.

### Iteration records

- `docs/iterations/066-request-group-access/todo.md`

### Membership and messaging application layers

- `web/lib/memba/membership.ex`
- `web/lib/memba/messaging.ex`
- `web/lib/memba/messaging/commands/request_group_access.ex`
- `web/lib/memba/messaging/member_message_email.ex`

### Web UI, presentation, and routing

- `web/lib/memba_web/components/member_components.ex`
- `web/lib/memba_web/controllers/page_html.ex`
- `web/lib/memba_web/controllers/page_html/club.html.heex`
- `web/lib/memba_web/live/member_dashboard_live.ex`
- `web/lib/memba_web/member_dashboard_presentation.ex`
- `web/lib/memba_web/router.ex`

### Acceptance specifications explicitly identified by the artifact gate

- `acceptance-tests/features/custom_group_access_requests.feature`
- `acceptance-tests/features/group_conversations.feature`
- `acceptance-tests/features/journeys/custom_group_access_request.feature`
- `acceptance-tests/features/journeys/custom_group_admission.feature`
- `acceptance-tests/test/cucumber_config.test.js`

### Focused tests

- `web/test/memba/membership/no_crud_spike_test.exs`
- `web/test/memba/messaging/member_message_email_test.exs`
- `web/test/memba/messaging/no_crud_spike_test.exs`
- `web/test/memba/messaging/request_group_access_test.exs`
- `web/test/memba_web/components/member_components_test.exs`
- `web/test/memba_web/live/member_dashboard_live_test.exs`
- `web/test/memba_web/live/member_dashboard_targeted_add_live_test.exs`
- `web/test/memba_web/router_test.exs`

## Publication

The publish-to-main stage reran validation for the publication candidate, recorded a successful full dev-check attestation, pushed that attestation, and then pushed the candidate to `main`:

> `Recorded successful full dev-check attestation for 3037eae8e4ea202ba48517d8948ce1b90a7dbb8d`

> `3037eae8e4ea202ba48517d8948ce1b90a7dbb8d -> main`

> `Published implementation to main: 3037eae8e4ea202ba48517d8948ce1b90a7dbb8d`

## Commit trailer metadata

The supplied output does not enumerate the commit’s trailer lines, so their exact keys and values cannot be independently quoted here. Publication metadata and the successful dev-check attestation are present for the published SHA in `refs/notes/fabro-dev-check`.

## Tests and validation

- Full `dev ci` / dev-check completed successfully before publication.
- The publish stage reran validation on the exact candidate subsequently pushed to `main`.
- A successful dev-check attestation was recorded for commit `3037eae8e4ea202ba48517d8948ce1b90a7dbb8d`.
- The displayed browser acceptance result was:
  - **6 scenarios passed**
  - **106 steps passed**
  - **0 failures**
- The completed implementation checklist records successful execution of both acceptance layers.
- Focused coverage includes:
  - Membership target resolution and same-club validation
  - Request command composition and Admin recipient resolution
  - Safe HTML and plain-text email rendering
  - Placeholder request and sent states
  - Sign-in return and protected-detail denial
  - Scanner-safe GET behavior
  - Already-added idempotency
  - Revoked/departed actor checks at Add
  - Stale target membership checks at Add
  - Welcome-flow behavior and duplicate-welcome prevention
- Final artifact gate passed.
- Plan conformance gate passed.

## Manual demo/checks still recommended

No manual check is required for acceptance. As an optional release smoke test:

1. Open a private custom group as a non-member.
2. Submit **Request access** and verify the concise sent state.
3. Open the delivered Admin email and verify the styled action link.
4. Confirm that opening the link does not add the requester.
5. Explicitly confirm the addition and verify that the requester receives and can follow the normal welcome link.

## Non-blocking follow-ups

The iteration intentionally does not add:

- A tracked access-request entity or pending status
- A requester-facing reply conversation
- General arbitrary message composition for non-admin members
- Immediate aggregate-backed denial of a read-only GET during projection lag
- Authority embedded in old email links

Those remain separate future product decisions. Current write-time authority and membership checks are the enforcement boundary.