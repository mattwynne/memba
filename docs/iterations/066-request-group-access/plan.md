# Ask to join a group

Date: 2026-09-27
Status: implementing

## Goal

A club member outside Board can ask to be added in one click. The club admins receive an ordinary Admin Group message with a link that opens Board's Members page ready to add that member. Opening the link changes nothing; an authorised person explicitly confirms the addition.

## Background / Context

[061](../061-discover-club-groups/plan.md) lets members discover a group they cannot read. [063](../063-add-custom-group-members/plan.md) and [064](../064-leave-and-remove-group-members/plan.md) already supply group admission and removal. [065](../065-browser-journeys-and-domain-examples/plan.md) distinguishes focused domain examples from selected browser journeys. This plan **replaces** the earlier 066 plan and its stale `validated` label; it has not been Fabro-validated against these changes.

Current inbound policy allows club members to email the Admin Group without belonging to Admin, but does **not** allow non-members to post to Board by email. The proposed one-click request is a narrowly fixed Admin message; it does not widen general web composition or group email policy. Existing executable group-discovery examples still assert the Admin email address on Board's placeholder; they must be updated **during delivery**, when the page changes, without making planning-time checks red.

## Related Problems

- [Interface too fancy](../../problems/2026-06-23-interface-too-fancy-for-simple-app-use.md): partially addresses the request journey with one action and no composer; broader issue remains open.
- [Club email lacks context links](../../problems/2026-06-01-club-email-lacks-context-links.md): partially addresses the new request email with a direct management link; existing message emails are unchanged.
- [Group renaming](../../problems/2026-09-12-custom-groups-cannot-be-renamed.md) and [archiving](../../problems/2026-09-12-retired-custom-groups-need-archiving.md): intentionally leave unresolved.

## Scope

### In scope

- One-click Request access on the non-member Board placeholder, with sending and sent feedback. Remove the explanatory helper and alternative Admin email line from this placeholder and its sent state as agreed.
- A fixed Admin Group root message naming the member and group, delivered through normal Admin recipient email and conversations. HTML email styles its ordinary management URL as an **Add Eve to Board** link/button; plain text shows the URL.
- A signed-in GET page at `/groups/:group_id/members/add/:person_id` that shows the identified person ready to add. Explicit Add uses current membership and authorisation, existing addition and welcome behaviour. Already a member means no addition or duplicate welcome.

### Out of scope

Request entity/status, approve/deny workflow, editable message, automatic addition on link open, additional replies to outsiders, new access/follow rules, special error infrastructure, request deduplication, general rich text, provider recovery or new group membership policy. Repeated deliberate requests remain ordinary messages. Nothing in this slice allows requesting membership of built-in groups.

## Iteration Type

Behaviour-facing: a member can ask to join a group by sending a fixed ordinary message and an authorised person can act through existing member management.

## Acceptance Scenarios / Feature Files

BDD decision: **Required**. Focused domain examples in [`custom_group_access_requests.feature`](../../acceptance-tests/features/custom_group_access_requests.feature) describe one successful request and rejection when the actor is not an active member of that club. One deliberate [`@journey` browser example](../../acceptance-tests/features/journeys/custom_group_access_request.feature) follows Eve from Board's placeholder through Dan opening the email link, explicitly adding Eve, and Eve's welcome return. Both are future `@iteration-066 @todo` examples until implementation. Existing group access, addition, welcome, duplicate-add and removal examples remain the authority for those rules; do not repeat them in this feature.

## Allowed acceptance feature changes

- `acceptance-tests/features/custom_group_access_requests.feature`: implement the focused examples; remove `@todo` only once executable and passing in the intended domain layer. Keep `@iteration-066` provenance.
- `acceptance-tests/features/journeys/custom_group_access_request.feature`: implement the one selected browser journey; remove `@todo` only once the browser runner executes it successfully.
- `acceptance-tests/features/group_conversations.feature`: the redundant future 066 affordance example was removed during planning. During delivery, update **only** the existing iteration-061 Board-discovery example's superseded custom-group Admin-email assertion to match the approved placeholder, retaining its name/privacy/non-joining assertions and original provenance; retain the Admin Group contact example. Add `@iteration-066` to the altered Board example. Do not tag it `@todo` to hide a broken regression.
- `acceptance-tests/features/journeys/custom_group_admission.feature`: when the UI changes, replace **only** its old Board-placeholder Admin-email assertion while retaining the rest of the existing journey and `@journey` tag. Add `@iteration-066` provenance; do not mark this already-running journey `@todo`.

If steps for the changed assertions are absent, implement them as part of delivery rather than weakening privacy assertions or changing test plumbing during planning.

## Designs

[Approved local HTML mock-up](mockup.html) covers Eve's private-group placeholder, sending/sent status, the ordinary Admin request email, the targeted Members page and already-added/success states. Matt approved the Admin email → targeted Add → result flow, then reviewed Eve's side and removed extra helper/contact copy. This is local design coverage based on [`club-group-non-member.html`](../../../design-system/templates/club-group-non-member.html), [`club-group-access-request.html`](../../../design-system/templates/club-group-access-request.html), [`club-group-members.html`](../../../design-system/templates/club-group-members.html) and [`group-welcome.html`](../../../design-system/emails/group-welcome.html); live DesignSync was unavailable and is not claimed. The approved local mock-up is the implementation handoff for this slice; [design notes](design-handoff.md) record its limits and pending cloud sync.

Reuse normal loading and generic error states. The link is safe to preview and to follow by scanners; sign-in returns to the target page. Show the already-added state without Add. On mobile, retain readable email/button and targeted person. Focus the target heading on arrival; Cancel/Escape returns focus to ordinary Add member, success announces status and focuses the member row. No separate approval page.

## Acceptance Criteria

- The current active club member outside a non-built-in group can send one fixed message with one click. Requester and club come from authentication, group resolves within that club, and client-supplied sender/destination/body cannot alter the request.
- Normal Admin Group recipients get the message at posting time. Its body identifies the requester and target group and holds the club-hosted Members add URL. HTML makes that URL a safe, styled link; the text email retains the URL. Accepted-for-send confirmation does not assert provider delivery or group admission.
- Opening `/groups/:group_id/members/add/:person_id` is read-only, signed-in and currently authorised; it discloses no protected details to an unauthorised visitor. The URL carries identity, not authority. The requester remains outside the group until explicit addition.
- Explicit Add rechecks current actor authority and target's active club membership, resolves the target's current club-membership identity, invokes the existing group-add command and normal welcome follow-up. Already-added targets produce no extra membership/welcome. A departure or loss of actor authority before confirmation denies the addition.
- Requesting does not create a request record, new conversation access, follow right or membership. Existing Admin rights, if the requester already holds them, remain unchanged. Repeating the request does not create special pending state or suppression.

## Open Business Decisions

None known. The request is ordinary correspondence, not a tracked application. Later admin replies do not become a new requester-facing conversation feature.

## Domain Vocabulary

Canonical terms reused or agreed in [`docs/problem-domain-terms.md`](../../problem-domain-terms.md): **Club member**, **Group**, **Built-in group**, **Admin Group**, **Club admin**, **Message**, **Sender** and **Email delivery**. Use **Group** normally; identify Board by name. “Request access” is the UI wording for asking to join, not a separate pending entity. Internal `custom_group`, `MessageSent`, command names, aggregate and URL parameter identifiers are solution-domain terminology. No unresolved naming questions.

## Domain Model

[Agreed model](domain-model.md): `RequestGroupAccess` is an application-layer **composite command** expressing Eve's intent. Messaging handles it by checking current Membership eligibility and group ownership, composing the fixed body/URL, and dispatching its constituent `SendMessage` to the existing Message aggregate. `MessageSent` and delivery events are existing facts; there is no request event, entity or lifecycle. Membership owns current membership, group authority and the existing add decision; the web surface dispatches the existing add command only after explicit confirmation. The existing application addition flow sends the welcome on an actual admission, not merely on `GroupMemberAdded`. Message recipient selection and async email delivery follow existing rules; no cross-context distributed transaction is added.

The GET route is only a targeted view. It resolves person and group under the selected club and checks current actor authority before disclosing details. The stored plain-text body contains the ordinary URL; email presentation renders it as a styled link after validating the club-hosted route and escaping surrounding text, without arbitrary HTML or new action metadata. The model records relevant departure, duplicate-add, follow and delivery timing; no new ADR is needed.

## Architecture Decisions

No new ADR required. Reuse accepted [0005](../../adr/0005-message-send-commands-include-resolved-recipients.md), [0007](../../adr/0007-use-separate-membership-and-messaging-commanded-contexts.md), [0023](../../adr/0023-use-url-addressable-liveview-state.md), [0024](../../adr/0024-use-club-as-membership-admin-consistency-boundary.md) and [0025](../../adr/0025-use-current-group-participation-for-access-and-delivery.md). Matt agreed `RequestGroupAccess` dispatches `SendMessage` at the application boundary rather than adding a separately routed aggregate command/event.

## Implementation Plan

1. Handle the composite `RequestGroupAccess` command in the Messaging application layer. Authenticate identity and club context, resolve the target through Membership's public authoritative API at the established stable ordering point, reject built-in/cross-club/non-active targets, compose subject/body and club-hosted link server-side, resolve Admin Group recipients and dispatch existing `SendMessage`. Propagate send result; do not bypass normal web compose restrictions globally.
2. Present the stored body URL in text email and as a safe styled link in HTML using the existing primary-action helper. Recognise/validate the route and origin, escape all untrusted body text, and do not infer system authorship from a subject line or enable arbitrary HTML. Display the request as an ordinary Admin conversation.
3. Add Request access to the non-member placeholder with single-submit feedback and concise sent status; remove the explanatory line and alternative Admin email from this placeholder/sent state. Keep the existing access barrier and Admin Group contact behaviour elsewhere.
4. Add the signed-in read-only `/groups/:group_id/members/add/:person_id` route. Resolve current group/person/club membership; check current authority before display. Show a targeted existing Members-page Add confirmation and already-added state. The explicit Add invokes the existing membership command and application welcome flow; keep sign-in return and keyboard/focus states.
5. Enable the two focused domain examples and one browser journey; update the two existing placeholder assertions without dropping their privacy coverage. Test forged IDs, unauthorised GET, lost authority, stale membership, link scanner GET, already-added and safe HTML/text rendering with focused tests. Run both acceptance layers and `dev check` on the exact delivered state.

## Open Technical Decisions

None known. UUID/route encoding and module placement may follow existing code conventions; they must not alter the agreed command boundary or permission model.

## New Capability

A member can ask from a group's private placeholder and an authorised person can act from the resulting email without searching for the requester, while addition remains an explicit existing membership action.

## Validation Plan

- Domain acceptance: intended Admin message and non-club requester rejection. Existing group access/add/welcome examples remain passing.
- Browser journey: Eve requests, sees accepted-for-send feedback, Dan opens the email's target page without changing membership, confirms addition and Eve follows her welcome link. Existing discovery/admission journeys stay green with updated copy.
- Focused command and presentation tests: forged input, active membership ordering, Admin recipients and follow eligibility, plain-text URL/HTML button escape and origin validation; no provider-send guarantee implied by confirmation.
- Focused LiveView tests: sign-in return, cross-club and unauthorised GET privacy, scanner-safe GET, already-added no-op, current actor/target checks at Add and accessible status/focus. Run full `dev check` on the delivered state.

## Risks / Follow-ups

Do not weaken all web composition to let non-Admin requesters send arbitrary Admin messages. Do not add HTML or an action-record model for one styled URL. An old email link carries no authority and may become stale; current membership and permission checks decide any later addition. General replies to outside senders, request tracking and wider group administration remain separate potential work.
