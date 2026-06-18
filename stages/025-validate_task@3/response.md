### Decision

**VALID**

### Evidence

- Completed todo/check-off evidence found:
  - Read `/tmp/fabro-pre-validate-snapshot.md`; it records a clean tree at validation snapshot time with implementation checkpoint `b8e61fb`.
  - Live `git status --short` is clean.
  - Recent log shows latest validation checkpoint `4011ac1` and implementation checkpoint `b8e61fb`.
  - `git show b8e61fb -- docs/iterations/035-obliterate-opened-delivery-status/todo.md` shows exactly one ordinary todo line changed:
    - task `003 Remove the "opened" read-model normalization clauses...`
    - from `- [ ]` to `- [x]`.
  - Parent todo state had tasks `001` and `002` checked and `003` as the first unchecked task.

- Implementation artifacts found:
  - `web/lib/memba/messaging.ex`: removed member and staff `"opened"` read-model normalization clauses.
  - `web/lib/memba_web/member_email_delivery_presentation.ex`: removed `"opened" -> "delivered"` presentation normalization.
  - `web/lib/memba_web/controllers/postmark_webhook_controller.ex`: removed the explicit `"opened"` Postmark rejection branch; `"Opened"` now falls through the generic unsupported-record path.
  - Related tests were updated in:
    - `web/test/memba_web/member_email_delivery_presentation_test.exs`
    - `web/test/memba/messaging/member_email_delivery_projection_test.exs`
    - `web/test/memba/messaging/memba_staff_email_delivery_projection_test.exs`
    - `web/test/memba_web/controllers/postmark_webhook_controller_test.exs`
  - Live grep confirms the task-003 target production files no longer reference `opened`/`Opened`.
  - No `.feature` files were changed in the implementation commit.

- Tests run/results found:
  - I reran the focused changed-behaviour tests live:
    - `MIX_ENV=test mix test test/memba_web/member_email_delivery_presentation_test.exs test/memba/messaging/member_email_delivery_projection_test.exs test/memba/messaging/memba_staff_email_delivery_projection_test.exs test/memba_web/controllers/postmark_webhook_controller_test.exs`
    - Result: `30 tests, 0 failures`.
  - `git show --check b8e61fb` passed.

- ADR/plan conformance notes:
  - Work matches implementation plan item 3 exactly.
  - Scope is limited to read-query normalization, member presentation normalization, webhook classification, and directly affected tests.
  - It does not prematurely alter the aggregate/event/projector replay shim work reserved for tasks 004/005/007.
  - Commanded/CQRS boundaries are preserved: no command routing, aggregate transition, event-store, or projector replay behaviour was changed in this slice.
  - The historical opened-tracking ADR is being retired by this validated iteration plan; this slice only removes the approved live compatibility behaviours while preserving replay-shim work for later tasks.

{"context_updates":{"task_valid":true,"task_retry_available":false}}