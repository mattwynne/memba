Result: REVIEW_ACCEPTED

Plan path: `docs/iterations/017-remove-open-tracking/plan.md`

Base sha: `9bf6d3c8c1134c4cda5bc94c2d9d4f4033b7948e`

Reviewed commit range: `9bf6d3c8c1134c4cda5bc94c2d9d4f4033b7948e..HEAD` as confirmed by the final artifact gate.

## ADR conformance summary

Independent review and synthesis accepted the implementation.

ADR conformance was assessed as passing:

- Commanded/CQRS-ES behaviour remains aligned with the existing architecture.
- Open-tracking command routing was removed from current behaviour while compatibility for historical data was preserved where needed.
- Email delivery status vocabulary now uses the intended current states only: sending, delivered, and delivery problem.
- Postmark outbound delivery no longer requests open tracking.
- Postmark open webhook events are rejected as unsupported rather than mutating delivery state.
- UI, projections, tests, and active documentation were updated to remove “opened” as a current product concept.
- The new/remove-open-tracking ADR direction was followed by the implementation.

No ADR violations were reported by the selected independent review or review synthesis.

## Independent review outcome

Independent review outcome: accepted.

The selected review concluded:

- Blocking issues: none.
- ADR conformance: pass.
- Confidence: high.
- Optional polish identified: clarify the deprecated opened command moduledoc.

Review synthesis reported:

```json
{"implementation_accepted":true,"review_fixes_available":false}
```

## Repairs applied during review

A review repair was applied for the deprecated opened-command moduledoc.

Repair file, matching final artifact gate evidence:

- `web/lib/memba/messaging/commands/report_email_delivery_opened.ex`

The repair clarified that open tracking has been removed, the command is no longer routed by `Memba.Messaging.Router`, and dispatching it will raise `Commanded.Router.UnregisteredCommandError`.

A separate test-isolation fix was also included in the reviewed final artifact evidence after a reproducible dev-check issue was addressed:

- `web/test/support/event_sourced_case.ex`
- `web/test/event_sourced_setup_test.exs`

## Code-health note status

`docs/code-health.md` was not updated.

Reason recorded by the workflow: after the review repair, no remaining review fixes were available. The remaining observations were low-priority judgement calls rather than issues requiring code-health tracking now.

## Key files reviewed or repaired

The final artifact gate confirmed the reviewed implementation evidence and listed the final changed-file set. Key files from that evidence include:

### Iteration and documentation

- `docs/iterations/017-remove-open-tracking/plan.md`
- `docs/iterations/017-remove-open-tracking/todo.md`
- `docs/postmark-email.md`
- `docs/problem-domain-audit-2026-06-01.md`

### Messaging domain and delivery behaviour

- `web/lib/memba/messaging.ex`
- `web/lib/memba/messaging/commands/report_email_delivery_opened.ex`
- `web/lib/memba/messaging/email_delivery_providers/postmark.ex`
- `web/lib/memba/messaging/message.ex`
- `web/lib/memba/messaging/projectors/memba_staff_email_delivery.ex`
- `web/lib/memba/messaging/projectors/member_email_delivery.ex`
- `web/lib/memba/messaging/router.ex`

### Webhook/controller/UI behaviour

- `web/lib/memba_web/controllers/page_html.ex`
- `web/lib/memba_web/controllers/page_html/message.html.heex`
- `web/lib/memba_web/controllers/postmark_webhook_controller.ex`
- `web/lib/memba_web/controllers/resend_webhook_controller.ex`
- `web/lib/memba_web/live/admin/deliveries_live/index.ex`
- `web/lib/memba_web/member_dashboard_presentation.ex`
- `web/lib/memba_web/member_email_delivery_presentation.ex`

### Tests and support

- `web/test/event_sourced_setup_test.exs`
- `web/test/features/cucumber_configuration_test.exs`
- `web/test/memba/messaging/app_test.exs`
- `web/test/memba/messaging/email_delivery_providers/postmark_test.exs`
- `web/test/memba/messaging/memba_staff_email_delivery_projection_test.exs`
- `web/test/memba/messaging/member_email_delivery_projection_test.exs`
- `web/test/memba/messaging/message_test.exs`
- `web/test/memba/messaging/send_message_dispatch_test.exs`
- `web/test/memba/messaging/status_report_api_test.exs`
- `web/test/memba_web/controllers/member_message_detail_test.exs`
- `web/test/memba_web/controllers/postmark_webhook_controller_test.exs`
- `web/test/memba_web/controllers/resend_webhook_controller_test.exs`
- `web/test/memba_web/live/browser_acceptance_harness_test.exs`
- `web/test/memba_web/live/deliveries_live_test.exs`
- `web/test/memba_web/live/member_dashboard_live_test.exs`
- `web/test/memba_web/live/member_message_live/show_test.exs`
- `web/test/memba_web/member_dashboard_presentation_test.exs`
- `web/test/memba_web/member_email_delivery_presentation_test.exs`
- `web/test/memba_web/member_message_detail_loader_test.exs`
- `web/test/support/event_sourced_case.ex`

The final artifact gate reported:

- `42 files changed`
- `715 insertions(+)`
- `357 deletions(-)`
- `No acceptance .feature changes detected`
- `Final artifact evidence confirmed`
- `Final artifact gate passed`

## Publish outcome

Review polish was pushed to `main`.

Publish output confirmed:

- Commit: `86c375f2d3d8f1af816138c2a12704eb0b82e5b8`
- Message: `review polish: iteration 017`
- Pushed to `main`: `951ca8d..86c375f`

The iteration was then marked merged and pushed to `main`:

- Commit: `3f93fc4`
- Message: `iteration 017: mark merged`
- Pushed to `main`: `86c375f..3f93fc4`

## Tests and validation run

Validation completed successfully.

`dev ci` / dev check output:

- ExUnit ran successfully.
- `380 tests, 0 failures`
- Final reported runtime: `18.2 seconds`
- Seed shown in the captured successful run: `498807`

Additional repair validation reported by the workflow:

- Reduced reproduction for the consistency-timeout issue passed:
  - `23 tests, 0 failures`
- Full ExUnit with failing seed `734908` passed:
  - `380 tests, 0 failures`
- Required full gate passed again:
  - `380 tests, 0 failures`

Final artifact gate also passed and confirmed no acceptance `.feature` files were changed in the final reviewed artifact.

## Manual demo/checks still recommended

No manual demo is required by the review outcome.

Optional manual checks, if desired before/after release:

- Send a test member email through Postmark and confirm outbound payloads do not request open tracking.
- Submit a representative Postmark open webhook payload in a non-production environment and confirm it is rejected as unsupported.
- Spot-check member and staff delivery screens to confirm only sending, delivered, and delivery-problem vocabulary is visible.

## Non-blocking follow-ups

No blocking follow-ups remain.

Judgement-worthy but non-blocking ideas from review:

- Consider a future project-wide policy for retained deprecated command/event modules, especially where event replay compatibility requires keeping historical modules.
- Consider whether shared delivery-status formatting helpers would be worthwhile if member and staff status presentation continues to duplicate identical formatting semantics.