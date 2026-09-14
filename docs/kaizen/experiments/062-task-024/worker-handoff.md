# Sample worker handoff: Board web-composition rule, domain layer

Status: historical preparation exercise only. Not a live task assignment or an approved todo change.

## Source and outcome

Source commit: `3ec928f3e` (the clean checkpoint immediately before failed task 024). All paths and line ranges below refer to that commit. Regenerate this packet against the actual source before using it for delivery.

Make one existing shared scenario executable at the domain layer:

`acceptance-tests/features/custom_group_conversations.feature` → rule “Web composition belongs to the selected group” → “Bob starts a Board discussion without addressing Everyone”.

Prove that Bob's message belongs to Board, is readable by Alice/Bob/Carol, produces their initial emails, gives Dan/Eve neither read access nor email, and is absent from Everyone's conversations. Bob receives the initial sender copy; do not apply reply-author exclusion to root messages.

This is acceptance plumbing for already implemented behavior, not new messaging functionality. “On the website” is exercised through the application command at this layer; actual browser interaction remains separate required work.

## Boundary

Include the scenario's five background steps, its six behavior/assertion steps, domain runner selection and focused regression coverage. No inbound-email posting, replies, follows, departure/rejoin, browser JavaScript, UI work or full-suite task is included.

Do not alter scenario wording or assertions. The approved plan permits narrowing runner-debt tags in this exact feature. Keep `@todo-ui` at feature level. Remove feature-level `@todo-domain` and put it on each of the other three rules, leaving this rule domain-enabled. Assert that exactly this one scenario becomes domain-selected and no browser scenario becomes enabled. Preserve `@iteration-062`.

If existing product behavior contradicts the scenario, report the failing public-API example and return it for preparation; do not absorb a new application repair into this task. Existing workflow acceptance/check-off and final-gate rules still apply.

## Fixture facts and reusable code

KMC has slug `kmc`; Alice/Dan are admins; Bob/Carol/Eve are ordinary active club members. Only Alice/Bob/Carol belong to custom group Board, with stored slug `board` and address `board@kmc.clubs.memba.io`. Dan's admin role must not grant conversation access.

Use the existing domain setup, not browser fixtures or direct projection writes:

- `web/test/features/step_definitions/custom_group_creation_steps.exs:24–39`: the club-slug and admin background wording already exists; the ordinary-member step currently names Bob/Eve, so the Carol-inclusive wording needs an adapter.
- Same file, `308–445`: fixture creation through Membership commands, role assignment, separate custom-group slug, and group-member addition. Crucially, `ensure_custom_group` creates with `group_key: nil`. Do not copy the older generic group helper's derived non-null key for this custom fixture.
- Same file, `199–226`: group address and conversation-membership assertion patterns. Existing wording says “should be” and “an … conversation”; this feature says “is” and “a Board conversation”. Add non-overlapping aliases/adapters rather than duplicate existing step patterns.

These helpers are private. Reuse within their owning module or make a small tested extraction if necessary; do not assume they can be called from a new module, and do not copy an entire fixture framework.

Existing fixture context:

- `clubs[club_name]` → club ID; `groups[{club_name, group_name}]` → group ID.
- `people[person_name]` → map containing `person_id` and `email`.
- `memberships[{club_name, person_name}]` → membership ID.

Use the full club name as the map key, not `KMC` or the slug.

## Action and observations

`web/test/features/step_definitions/group_conversation_steps.exs:416–459` shows the public action and context update. Send with `Messaging.send_club_message/2`, including `message_id`, `club_id`, `sender_id`, `audience_group_id: board_id`, `subject` and `body`, with `consistency: :strong`. Retain `sent_message`, `last_message_id` and `messages[subject]` so pronoun-based assertions refer to the same message.

Reuse these observation patterns:

- `group_conversation_steps.exs:128–158`: `Messaging.member_has_conversation_access?(message_id, club_id, person_id, :read)` for positive and negative access.
- `custom_group_creation_steps.exs:217–226`: `Messaging.list_conversations_for_group/1` for Board membership. Check Everyone separately using `SystemGroups.everyone_group_id(club_id)` and the target message identity.
- `web/test/features/step_definitions/messaging_steps.exs:1230–1280`: inspect `Messaging.list_recipient_deliveries/1`, dispatch through `EmailDeliveryDispatcher.dispatch_pending_email_deliveries/0`, then inspect `EmailDeliveryProviders.Fake.deliveries/0`, filtered by the target `message_id`. Assert exactly the three intended recipients and matching content. Compare the sorted recipient-ID list with the expected list; count plus membership checks alone can let duplicates conceal an omitted recipient. Absence of Dan/Eve must be proved after dispatch, not inferred solely from a pre-dispatch list.

The shared feature remains the behavioral specification for both runners (ADR 0010). Keep Membership setup and Messaging actions at their public boundaries (ADR 0007). Use strong-consistency/completion evidence, not sleeps or projection writes. You do not need to investigate inbound MIME parsing, reply correlation, follow cleanup or browser lifecycle for this slice.

## Completion evidence

Follow `web/test/features/custom_group_creation_steps_test.exs` for an `Memba.EventSourcedCase, async: false` runner. Create a focused conversation counterpart. `web/test/support/domain_cucumber_runner.ex` already discovers steps, expands rules/outlines and honors inherited rule debt tags; do not rebuild it.

Prove:

1. The selected scenario executes through the real domain step registry, rather than remaining skipped or undefined.
2. The selected conversation-scenario count is exactly one; the remaining twelve domain instances and all thirteen browser instances stay pending.
3. Existing creation and generic group scenarios still execute without ambiguous steps or context-shape regressions.

Focused validation: run the new conversation runner together with `test/features/custom_group_creation_steps_test.exs` and `test/features/domain_cucumber_runner_test.exs` through `dev test`; then run `test/features/domain_cucumber_acceptance_test.exs` for combined domain-registry coverage. Format touched Elixir files and run `git diff --check`. Capture commands, exit statuses, selected counts and any failure's actionable excerpt. Do not paste full passing logs into the handoff.

Return changed paths, the scenario-selection proof, focused results and unresolved facts. This completes only this proposed slice—not original task 024 or the iteration. Independent review and the eventual full delivery gate are still required.
