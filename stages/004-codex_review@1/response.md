## Decision: READY

## Confidence: High

## Blocking gaps

None.

## Non-blocking improvements

1. The plan combines three separate quick wins rather than one tightly unified product outcome. This is acceptable because each item is small, independently testable, and bounded, but the author could acknowledge that the smallest slices are separable.
2. The `## Open Technical Decisions` section lists low-level implementation choices. They do not appear blocking, but the plan would read cleaner if these were reframed as “implementation details to confirm” rather than open decisions.
3. The absolute URL source for staff notification links is worth clarifying before coding if the app has multiple existing URL-generation conventions.
4. The acceptance criteria could explicitly state that existing staff authorization for `/admin/requests` applies to the new request-specific route, though this is strongly implied by placing it under the existing staff LiveView/session.

## Smallest viable iteration

The smallest useful slice would be **one of the three quick wins**, preferably:

- Add blank/whitespace-only member compose body validation that preserves the subject, shows a body-specific error, and prevents message creation/email delivery.

That said, the current three-part quick-wins iteration is still reasonably small and ready because each change is bounded, testable, and avoids larger adjacent product areas.

## Required plan edits

None required for readiness.

## Validation plan

Success should be proven by:

1. Adding the planned Gherkin scenarios in:
   - `acceptance-tests/features/member_message_deliverability.feature`
   - `acceptance-tests/features/request_account.feature`
2. Running focused provider/email tests proving member-message outbound subjects are prefixed as `[slug] Subject` while stored/in-app message subjects remain unchanged.
3. Running member compose LiveView tests proving blank and whitespace-only bodies show a body-specific validation error, preserve subject input, and do not call `Messaging.send_club_message/2` or the delivery provider.
4. Running onboarding requests LiveView tests proving:
   - `/admin/requests` still lists active requests.
   - Convert uses LiveView patch navigation.
   - `/admin/requests/:request_id` opens the existing conversion panel for active requests.
   - inactive, converted, rejected, missing, or invalid request IDs show the no-longer-active/not-found state.
   - cancel and successful conversion return to `/admin/requests`.
5. Running onboarding notification email tests proving the staff email includes an absolute request-specific conversion URL.
6. Running affected acceptance tests or feature parsing/tag checks while new scenarios remain `@wip`.
7. Running `dev check` before delivery is considered complete.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}