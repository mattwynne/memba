### Decision
**VALID**

### Evidence
- Completed todo/check-off evidence found:
  - Live working tree is clean.
  - Recent implementation checkpoint `4fa6a50 fabro(...): implement_next_task (succeeded)` is corroborated by `git log --oneline -5`; `5a82442` is the later pre-validation checkpoint.
  - `git diff 4fa6a50^ 4fa6a50 -- docs/iterations/017-remove-open-tracking/todo.md` shows exactly one ordinary task line changed:
    - `003 Remove or deprecate the Messaging opened-report command/API/event path from current behaviour:` from `- [ ]` to `- [x]`.
  - Parent todo state had `001` and `002` checked and `003` unchecked, so `003` was the first unchecked task.

- Implementation artifacts found:
  - `web/lib/memba/messaging.ex`
    - Removed public `report_email_delivery_opened/2`.
    - Removed the private opened-command builder.
    - Updated member delivery vocabulary docs to exclude opened.
  - `web/lib/memba/messaging/router.ex`
    - Removed `ReportEmailDeliveryOpened` from routed commands.
  - `web/lib/memba/messaging/message.ex`
    - Removed aggregate execution for `ReportEmailDeliveryOpened`.
    - Removed `sent/delivered -> opened` transitions.
    - Preserved historic `EmailDeliveryOpened` replay compatibility by applying it as delivered rather than current opened state.
  - `web/lib/memba/messaging/commands/report_email_delivery_opened.ex`
    - Kept as a compatibility struct with moduledoc stating it is no longer routed/current behaviour.
  - Tests were updated to cover delivered, delayed, bounced, spam complaint, and absence of public opened-report API.
  - Dependent Postmark/Resend webhook paths were updated so opened events no longer call the removed API and are rejected as unsupported.
  - No acceptance `.feature` files were edited in this checkpoint.

- Tests run/results found:
  - Live focused test run passed:
    - `46 tests, 0 failures`
    - Covered Messaging app/router, aggregate, status API, projections, dispatch, Postmark/Resend webhook controllers, and browser acceptance harness tests.
  - Live full repository check passed:
    - `PATH="$PWD/bin:$PATH" dev check`
    - `373 tests, 0 failures`
  - `git diff --check 4fa6a50^ 4fa6a50` passed.
  - Working tree remained clean after validation.

- ADR/plan conformance notes:
  - Work matches plan item `003`: current opened-report API/command routing/event emission path was removed or deprecated from current behaviour.
  - The Message aggregate boundary from ADR `0004` and Messaging Commanded context boundary from ADR `0007` were preserved.
  - Projection machinery from ADR `0009` was not replaced or bypassed.
  - ADR `0012`’s prior opened-tracking decision is intentionally superseded by the approved iteration plan for current behaviour; historic compatibility was preserved as the plan requested.
  - No todo split/reorder/addition occurred, and no plan-required work was deleted or weakened.
  - Remaining opened references in presentation/projection/docs areas correspond to later unchecked tasks `004`, `007`, `008`, and `009`, so they do not invalidate this independently useful checkpoint.

{"context_updates":{"task_valid":true,"task_retry_available":false}}