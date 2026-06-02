### Decision
**VALID**

### Evidence
- Completed todo/check-off evidence found:
  - Live working tree is clean.
  - Recent checkpoint history shows `64adee9 fabro(...): implement_next_task (succeeded)` followed by `fae3b58 ... pre_validate_snapshot`.
  - `git diff 64adee9^ 64adee9 -- docs/iterations/017-remove-open-tracking/todo.md` shows exactly one ordinary task line changed:
    - `004 Update projections/read models and loaders so current status lists, summaries, and grouping functions do not include opened.` from `- [ ]` to `- [x]`.
  - Parent todo state had tasks `001`-`003` checked and `004` as the first unchecked task.

- Implementation artifacts found:
  - `web/lib/memba/messaging/projectors/member_email_delivery.ex`
    - Historic `EmailDeliveryOpened` projection now maps to `"delivered"` instead of `"opened"`.
  - `web/lib/memba/messaging/projectors/memba_staff_email_delivery.ex`
    - Historic `EmailDeliveryOpened` projection now maps to `"delivered"` with `reason: nil`.
  - `web/lib/memba/messaging.ex`
    - Member and Memba-staff delivery query APIs normalize existing/historic `"opened"` projection rows to `"delivered"`.
    - Normalization covers single-delivery getters, message/recipient getters, operator email delivery lists, and operator delivery overview.
  - Tests added/updated for projection compatibility and read-model normalization:
    - `web/test/memba/messaging/member_email_delivery_projection_test.exs`
    - `web/test/memba/messaging/memba_staff_email_delivery_projection_test.exs`
    - `web/test/memba_web/controllers/member_message_detail_test.exs`
    - `web/test/memba_web/live/member_message_live/show_test.exs`

- Tests run/results found:
  - Validator ran `PATH="$PWD/bin:$PATH" dev check`.
  - Result: `377 tests, 0 failures`.
  - `git diff --check 64adee9^ 64adee9` passed.
  - A direct bare `mix test` attempt failed only because the database service was not available outside the dev environment; the required `dev check` subsequently passed.

- ADR/plan conformance notes:
  - Work matches plan task `004`: current projections/read-model query paths no longer expose `"opened"` as a delivery status, while preserving historic event/row compatibility by mapping to delivered.
  - ADR 0004 aggregate boundary is not changed.
  - ADR 0007 Messaging bounded-context/query boundary is preserved.
  - ADR 0009 Commanded Ecto projection architecture is preserved.
  - ADR 0012’s previous opened-tracking decision is intentionally superseded by this approved iteration plan for current behaviour.
  - No acceptance feature files were edited in this checkpoint.
  - Remaining opened/open-tracking references correspond to later unchecked tasks for Postmark, presentation/UI, staff views, and documentation.

{"context_updates":{"task_valid":true,"task_retry_available":false}}