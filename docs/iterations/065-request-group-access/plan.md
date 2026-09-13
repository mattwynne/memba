# Request custom-group access through an Admin message

Date: 2026-09-13
Status: ready

Stakeholder review complete; Fabro plan validation pending.

## Goal

A club member outside a custom group can ask the club admins to add them with one action. The request is an ordinary Admin conversation, not an approval workflow or a new source of access rights.

## Background / Context

Depends on [061](../061-discover-club-groups/plan.md) and [063](../063-add-custom-group-members/plan.md); deliver after 064 in the agreed sequence. The interim access placeholder already supplies the Admin email address. This slice adds Request access without an editable composer.

Existing email policy lets any active club member start a conversation in a group by email without joining or gaining read/reply/follow rights. Reuse that distinction for this narrowly defined system-composed Admin message; do not generally widen non-member web composition.

## Related Problems

- [Simple, app-like interface](../../problems/2026-06-23-interface-too-fancy-for-simple-app-use.md): partially addresses the access-help journey with one action rather than a new composer or workflow; the wider problem remains open.
- [Club email lacks context links](../../problems/2026-06-01-club-email-lacks-context-links.md): partially addresses this new message's context by identifying the requester, group and management link; does not retrofit every existing email.
- [Renaming](../../problems/2026-09-12-custom-groups-cannot-be-renamed.md) and [archiving](../../problems/2026-09-12-retired-custom-groups-need-archiving.md): deliberately deferred.

## Scope

### In scope

- Request access button on the regular non-member custom-group placeholder, alongside the existing Admin email address.
- Server-composed standard message to the current club's Admin group, identifying the requester and target group and linking to its Members management.
- Ordinary Admin conversation/list/email behaviour; requester receives successful-send confirmation but no membership or conversation access.
- Repeated deliberate requests remain ordinary additional messages. Admins fulfil requests through existing membership management.

### Out of scope

Editable composer, request entity/status, duplicate suppression, pending/approved/denied records, request dashboards, request-specific notifications or replies to the requester, automatic membership, custom technical-failure screens or new generic error infrastructure. The Admin system group keeps its existing role-management surface; do not expose this as a new automatic admin-role request/grant workflow.

## Iteration Type

Behaviour-facing. Rule: requesting access sends an ordinary Admin message and grants no access.

## Acceptance Scenarios / Feature Files

BDD decision: Required.

Add `acceptance-tests/features/custom_group_access_requests.feature`, tagged `@iteration-065 @todo-domain @todo-ui`, for a standard request, no editable composer, no requester access to Admin replies, ordinary subsequent membership grant and repeated requests. Include invalid/cross-club actor/target authorization without bespoke technical-failure scenarios.

Add the Request access affordance example to `group_conversations.feature` with `@iteration-065 @todo-domain @todo-ui`. Preserve the earlier 061 email contact/privacy examples; they remain true after the button appears.

Matt reviewed the rules and HTML prototype during planning.

## Allowed acceptance feature changes

- `acceptance-tests/features/custom_group_access_requests.feature`: implement the defined request behaviour and remove/narrow runner-debt tags only when supported.
- `acceptance-tests/features/group_conversations.feature`: add/enable only this slice's custom-group request-affordance scenario; retain older iteration tags and all privacy/regression assertions.

## Designs

- `design-system/templates/club-group-non-member.html`: Request access and confirmation states.
- `design-system/templates/club-group-access-request.html`: standard request as an ordinary Admin conversation.
- `design-system/explorations/custom-groups-prototype.html`: Eve requests; Alice sees the Admin message; ordinary Members controls fulfil it.

Use reviewed copy or equivalent: subject `Access request: Board`; body names the requester and Board, links to Board's Members page, and explains that the requester cannot read Admin replies. No editable composer or request-specific Admin moderation UI. The confirmation says the request was sent, not that access was granted; repeat requests remain possible. Use existing shared message rendering, tab actions, footer and generic technical-error mechanism. Local HTML is sufficient; cloud sync remains pending.

## Acceptance Criteria

- An active club member outside a custom group can send the standard request from its placeholder without writing a message.
- Requester and club are derived from the authenticated identity/context. The target must be an existing custom group in that same club. Forged target/actor/destination/body parameters cannot redirect, impersonate or widen access.
- Admins receive the request using normal Admin-group root-message delivery; the conversation contains a useful management link.
- Sending does not join the requested group or Admin, grant a read/write access rule, or auto-follow the Admin conversation for the requester. Admin replies are not emailed to them.
- An admin can add the requester using the ordinary 063 action and welcome behaviour. No approval record is created.
- Repeated deliberate requests send again, with no pending-request or duplicate-suppression model.
- No new technical-failure handling is designed or implemented for this feature; normal app-level handling applies.

## Open Business Decisions

None known. The request is a message, not a tracked application. Admin-group email remains visible as the alternative contact method.

## Implementation Plan

1. Introduce a narrow authenticated request-access use case in the existing Membership/Messaging application boundary. Derive requester/club from session identity, resolve the custom target under the club, require current active club membership, and resolve the Admin destination through `SystemGroups`. Compose fixed text/link server-side. Do not accept arbitrary audience or message body from the browser.
2. Send through the existing group-aware Messaging root-message pipeline, preserving the active-club nonmember-start distinction without weakening the normal web compose/reply/follow authorization APIs. Explicitly prevent requester auto-follow/read grants. Keep root-message recipients as current Admin-group members and reuse existing email handoff, subject conventions and thread semantics.
3. Add the single Request access action and normal pending/sent feedback to the existing placeholder. Preserve group context, Admin mailto link, keyboard/focus behaviour and default app errors. Do not add a composer, request state schema, pending queue, denial action or special failure/retry page.
4. Render requests as ordinary Admin conversations with the management link, using existing `MemberComponents` rows and conversation presentation. The request is not an instruction to grant access automatically. Admin membership additions use the existing use case, not a new approval endpoint.
5. Implement both runners' tagged examples and focused action-security/Messaging tests for same-club resolution, current actor status, repeat requests and no auto-follow or reply disclosure. Verify member addition after the request follows the normal welcome path. Run `dev check` on the exact delivered state.

## Open Technical Decisions

No new entity, aggregate, inbox or event type is required for request tracking: the existing conversation is the record. A dedicated command/use-case boundary is needed so allowing this fixed message does not permit arbitrary non-member web posting. Use ordinary message creation IDs/idempotency already provided by Messaging; do not add deliberate-request deduplication.

## New Capability

Members can ask for group membership without switching applications, while admins handle the request using the conversation and membership tools they already have.

## Validation Plan

- Parse feature files and verify planning-time debt tags; requester/admin rules reviewed during planning.
- Domain tests: intended Admin recipients, requester identity, target/club matching, unchanged conversation access and no auto-follow.
- Browser: Eve requests Board, gets confirmation, stays outside; Alice reads the request, adds Eve through Members; Eve receives welcome/history but not the Admin discussion.
- Repeated request creates another message; existing generic error infrastructure and normal delivery tests remain unchanged.
- Run both acceptance runners and `dev check` on the final delivery state.

## Risks / Follow-ups

The dangerous shortcut is globally loosening web composition because the request sender is outside Admin. Keep the exception narrow and server-composed. A management link must retain the target club/group without granting rights. Request-specific status tracking, spam/rate policies beyond existing app controls, and replies visible to the requester are not in this slice.
