# Member compose LiveView flow

Date: 2026-06-01
Status: ready

## Goal

Replace the inline club-home message form with a focused member compose LiveView flow.

After this iteration, a signed-in active member starts from a club-home “Send club message” call to action, composes at `GET /messages/new?club_id=<club_id>`, sends as their own logged-in member identity, and sees a confirmation state with actions to see receipts, send another message, or return home. If sending fails, the member sees a clear incident-style failure state that says the message was not sent and directs them to support.

## Background / Context

Iteration 011 delivered the member-facing message journey with an inline compose form on club home. The wireframes show composition as a calmer, focused screen with explicit sent and error states.

Use these design references first:

- `docs/iterations/011-member-facing-message-behaviour/designs/Member Messaging Wireframes.html`
- `docs/iterations/011-member-facing-message-behaviour/designs/wireframes/compose.jsx`
- `docs/iterations/011-member-facing-message-behaviour/designs/wireframes/dashboard.jsx`
- `docs/iterations/011-member-facing-message-behaviour/designs/wireframes/wireframes.css`

Relevant current implementation:

- Club home is rendered by `MembaWeb.PageController.home/2` and `web/lib/memba_web/controllers/page_html/club.html.heex`.
- Message sending is currently handled by `MembaWeb.PageController.send_message/2` via `POST /?club_id=<club_id>`.
- The current form has a sender dropdown. That is no longer the desired product behaviour: members send as the logged-in active member, not on behalf of another member.
- Product direction: member application pages should generally be LiveViews; static marketing/legal pages such as `/about`, `/terms`, and `/privacy` can remain controller/static pages.

## Scope

### In scope

- Add a member compose LiveView at `GET /messages/new?club_id=<club_id>`.
- Add a LiveView-backed send flow for the compose page using Phoenix form conventions.
- Replace the inline compose form on club home with a “Send club message” CTA link to `/messages/new?club_id=<club_id>`.
- Keep the club-home CTA visually aligned with `dashboard.jsx` where practical, but do not otherwise redesign the dashboard in this slice.
- Remove the sender dropdown from the member compose experience.
- Derive the sender from the authenticated logged-in member for the selected club:
  - the sender is the current identity's active membership/person in that club;
  - the member cannot choose another sender;
  - if no active member can be derived, preserve the existing forbidden/not-authorized behaviour rather than sending.
- Preserve existing send semantics:
  - any active member can send;
  - message goes to all active members of that club;
  - sender is included as a recipient for now;
  - other clubs' members are not addressed.
- Compose screen fields:
  - show a non-editable “From” summary for the logged-in member, such as “Alice (you)” / “Sending as yourself”;
  - subject;
  - message body;
  - explanatory note that the message goes to all active members.
- On successful send, show a dedicated success state matching the intent of `ComposeSuccess`:
  - message sent confirmation;
  - “See who got it” link to the newly-created member message detail page;
  - “Send another message” link back to a fresh compose screen for the same club;
  - “Back to home” link to club home.
- On send failure, show a small incident-style error state matching the intent of `ComposeError`, adjusted for product policy:
  - say the message was not sent;
  - tell the member to contact support;
  - offer “Try again” and “Back to club home”;
  - no need to promise draft preservation in business copy;
  - log/capture enough detail for operators/developers to investigate.
- Update acceptance feature language with a small `@wip` scenario for failed send incident handling, keeping it navigation-agnostic.
- Add LiveView tests for compose route/auth, logged-in sender derivation, form submit success, success actions, send failure state, and removal of the sender dropdown.
- Keep existing member-message browser scenarios green.
- Keep `dev check` green.

### Out of scope

- Dashboard visual polish beyond replacing inline compose with the CTA link needed for this flow.
- Receipt detail polish from iteration 012.
- Draft saving or guaranteed preservation of failed message content.
- Rich editor, attachments, templates, replies, scheduling, recipient selection, or role-restricted sending.
- Sending on behalf of another member.
- Custom club domains or host-based club resolution.
- Changing delivery projections, Postmark/webhook behaviour, or receipt status vocabulary.
- Full incident-management workflow; only member-facing failure copy and useful logging are in scope.

## Iteration Type

Behaviour-facing.

User-observable rules changed:

- Members compose club messages in a focused member LiveView flow rather than an inline club-home form.
- A sent message gets a dedicated confirmation state with receipt, send-another, and home actions.
- Members send as their logged-in member identity; they cannot choose another sender.
- If a message is not sent, the member is told it was not sent and to contact support.

## Acceptance Scenarios / Feature Files

BDD decision: Required for the send-failure rule; existing scenarios remain suitable for the normal send flow.

`acceptance-tests/features/member_message_deliverability.feature` gains one `@wip` scenario under a new rule:

- `Alice is told a failed message was not sent`: when sending is unavailable and Alice tries to send a club message, she is told the message was not sent and to contact support.

The scenario is intentionally navigation-agnostic: it does not mention the compose route, buttons, pages, or LiveView implementation. The `@wip` tag must be removed during implementation once the scenario passes or if the implementation chooses to cover the same rule through an existing executable scenario.

Normal compose navigation, success actions, and the removal of the sender dropdown should be covered by LiveView tests because they are UI workflow/presentation details around the already-documented “Alice sends a club message” rule.

## Allowed acceptance feature changes

- `acceptance-tests/features/member_message_deliverability.feature`: add the send-failure incident-handling scenario described above.
- Implementation may make small wording adjustments to keep the scenario business-readable and executable, but must preserve the rule that a member is told a failed send did not send and to contact support.
- Do not add navigation- or route-specific Gherkin for the compose LiveView.

## Acceptance Criteria

- Club home no longer renders the inline compose form.
- Club home shows a clear “Send club message” CTA linking to `/messages/new?club_id=<club_id>`.
- `GET /messages/new?club_id=<club_id>` is available only to authenticated active members of the selected club through the same member-auth rules as other member pages.
- The compose page uses `<Layouts.club_site>` and is implemented as a LiveView.
- The compose page shows a non-editable sender summary for the logged-in active member.
- The compose page does not include a sender dropdown or any way to send on behalf of another member.
- Submitting the compose form sends as the logged-in active member for the selected club.
- A successful send creates the same kind of club message and recipient deliveries as the current inline flow.
- A successful send shows a confirmation state rather than immediately redirecting home.
- The confirmation state includes:
  - “See who got it” linking to `/messages/:message_id?club_id=<club_id>` for the newly-created message;
  - “Send another message” linking to a fresh compose screen for the same club;
  - “Back to home” linking to `/?club_id=<club_id>`.
- On send failure, no message is reported as sent to the member.
- On send failure, the member is told the message was not sent and to contact support.
- On send failure, the state offers “Try again” and “Back to club home”.
- Send failures are logged or captured with enough context for operators/developers to investigate without exposing technical internals to the member.
- Existing normal-send browser scenarios continue to pass with business wording unchanged.
- The new send-failure scenario is untagged and passing by the end of implementation, or remains `@wip` only if Matt explicitly accepts deferring executable coverage.
- `dev check` passes.

## Open Business Decisions

None known.

Decisions made during planning:

- Compose URL is `/messages/new?club_id=<club_id>`.
- Confirmation includes “See who got it”, “Send another message”, and “Back to home”.
- Members send as the logged-in member; the sender dropdown should be removed.
- Send failure is treated as an incident and should tell the member to contact support.
- Gherkin should stay agnostic of navigation.

## Implementation Plan

1. Inspect the current club-home form, `PageController.send_message/2`, member auth plugs, route tests, and browser acceptance helpers for member message sending.
2. Introduce a compose LiveView, for example `MembaWeb.MemberMessageLive.New`, routed at `GET /messages/new` through the existing browser/member auth pipeline.
3. In the LiveView mount path:
   - read `club_id` from query params;
   - find the selected club from the authenticated identity's active clubs;
   - derive the current member/person for the identity and selected club;
   - load active member count for the explanatory note;
   - assign a `to_form/2` form for subject/body only.
4. Replace the club-home inline compose section with a CTA card/link to the new compose route. Preserve stable IDs or update tests/helpers deliberately.
5. Move sending behaviour into the LiveView submit event or a small shared service function:
   - generate a message ID before dispatch so the success state can link to details;
   - pass `sender_id` from the derived current member, not params;
   - call the existing `Messaging.send_club_message/2` path with strong consistency where needed.
6. Render compose form based on `compose.jsx`:
   - back link to club home;
   - “New message” eyebrow;
   - active-member recipient note;
   - non-editable sender summary;
   - subject/body inputs using Phoenix form components;
   - “Send to all members” primary action and cancel/back action.
7. Render success state based on `ComposeSuccess`, adding the required “Send another message” action.
8. Render failure state based on `ComposeError`, adjusted to say nothing was sent and contact support; include Try again and Back to club home actions.
9. Add or update LiveView/Phoenix tests for:
   - auth and selected-club requirements;
   - no sender dropdown;
   - sender derived from current member;
   - successful submit and success action links;
   - send failure state and support copy;
   - club home CTA replacing inline compose.
10. Update acceptance step support only as needed for the new send-failure scenario and for existing normal-send steps to use the new compose flow without changing scenario wording.
11. Remove `@wip` from the new failure scenario once implemented and passing.
12. Run the targeted browser Cucumber feature and `dev check`.

## Open Technical Decisions

- Exact LiveView module name and route helper naming.
- Best way to simulate message-send unavailability in acceptance tests without coupling Gherkin to infrastructure. Prefer a test-support seam or existing fake provider configuration rather than changing business wording.
- Whether the old `POST /?club_id=<club_id>` route should be removed immediately or kept temporarily for compatibility. The member UI should stop using it in this slice.

## New Capability

Members have a focused, calmer compose experience with clear post-send choices. Messages are sent as the logged-in member, and failure is treated as an incident with support guidance rather than a confusing form validation problem.

## Validation Plan

- Run `dev check`.
- Run targeted LiveView/Phoenix tests for the compose LiveView and club-home CTA.
- Run `acceptance-tests/features/member_message_deliverability.feature` through the browser runner.
- Manual demo:
  - sign in as Alice;
  - open Kootenay Mountaineering Club;
  - click “Send club message”;
  - confirm compose screen has no sender dropdown and shows Alice as sender;
  - send “Trip planning night”;
  - confirm success state shows “See who got it”, “Send another message”, and “Back to home”;
  - follow “See who got it” to the message detail page;
  - return and use “Send another message” to start a fresh compose;
  - simulate send failure and confirm the message was not sent, support guidance appears, and Try again/Home actions are available.

## Risks / Follow-ups

- Existing browser helpers may assume the inline form exists; update helpers while keeping feature language business-focused.
- Error simulation needs a clean test seam so the new Gherkin does not become infrastructure-specific.
- Removing the sender dropdown changes a product affordance that existed accidentally; tests should make the new rule explicit.
- Dashboard polish remains a future iteration.
