Result: **REVIEW_ACCEPTED**

Plan path: `docs/iterations/035-obliterate-opened-delivery-status/plan.md`

Base SHA: `c4be16303bbb07a1dd1f82981e259de54887ed66`

Reviewed commit range: changes since `c4be16303bbb07a1dd1f82981e259de54887ed66`, as confirmed by the final artifact gate.

## ADR conformance summary

Independent reviews from Claude, Codex, and Gemini all reported:

- **ADR conformance: PASS**
- No ADR violations found.
- The implementation was judged consistent with the project’s Commanded/CQRS/event-sourcing architecture.
- The retained `EmailDeliveryOpened` event tombstone plus documented aggregate/projector no-op handling was considered the correct replay-safe approach for a deprecated persisted event.

## Independent review outcome

Independent review consensus:

- **Decision: ACCEPT**
- **Confidence: High**
- **Blocking issues: None**
- **Bounded-safe fixes: None required**

The implementation was accepted as plan-conforming. Reviewers agreed that active `"opened"` delivery-status behavior was removed while retaining only the replay-safety shim required for historic event deserialization and projection rebuilds.

## Final artifact evidence

The final artifact gate confirmed the reviewed implementation evidence and passed:

> `Final artifact evidence confirmed.`  
> `Final artifact gate passed.`

It reported the implementation change summary as:

- 32 files changed
- 407 insertions
- 506 deletions

Key changed files from the final artifact gate included:

- `docs/iterations/035-obliterate-opened-delivery-status/plan.md`
- `docs/iterations/035-obliterate-opened-delivery-status/todo.md`
- `docs/iterations/035-obliterate-opened-delivery-status/inventory.md`
- `docs/iterations/README.md`
- `web/lib/memba/messaging.ex`
- `web/lib/memba/messaging/commands/report_email_delivery_opened.ex`
- `web/lib/memba/messaging/events/email_delivery_opened.ex`
- `web/lib/memba/messaging/message.ex`
- `web/lib/memba/messaging/projectors/memba_staff_email_delivery.ex`
- `web/lib/memba/messaging/projectors/member_email_delivery.ex`
- `web/lib/memba_web/controllers/postmark_webhook_controller.ex`
- `web/lib/memba_web/member_email_delivery_presentation.ex`
- `web/test/memba/messaging/email_delivery_opened_replay_test.exs`
- `web/test/support/event_sourced_case.ex`
- Multiple affected messaging, webhook, delivery projection, LiveView, controller, and acceptance-support tests listed by the artifact gate.

No acceptance `.feature` changes were detected by the final artifact gate.

## Finding disposition

### Fixed by implementation

The following plan/review findings were addressed by the implementation itself:

- Active `opened` delivery-status behavior was removed.
- `ReportEmailDeliveryOpened` was deleted.
- `"opened"` read-model normalization was removed.
- `"opened" -> "delivered"` presentation mapping was removed.
- Webhook handling no longer has the previous `"opened"` rejection branch.
- Member/staff delivery surfaces and tests no longer assert an opened status/count.
- `EmailDeliveryOpened` remains only as a documented replay tombstone.
- Aggregate and projector handling for `EmailDeliveryOpened` was reduced to documented no-op replay support.
- A replay-safety regression test was added: `web/test/memba/messaging/email_delivery_opened_replay_test.exs`.

### Recorded

None.

`docs/code-health.md` was **not** updated.

### Dismissed with reason

- **Potential metrics/logging references to `"opened"`**: dismissed for this review as speculative/out-of-scope. The final artifact evidence and independent review material did not identify a concrete changed file or surviving code reference requiring repair.

### Still unhandled / workflow gap

There is a workflow gap: independent reviewers identified judgement-worthy non-blocking code-health findings, but the `record_code_health` stage reported that no visible judgement-worthy findings were found and did not update `docs/code-health.md`.

Unhandled non-blocking findings:

1. **Event tombstone/deprecation pattern is implicit project knowledge**
   - Suggested future ADR/reference documentation for the tombstone + no-op replay-safety pattern.
   - Not fixed.
   - Not recorded in `docs/code-health.md`.

2. **Replay-regression test uses low-level event-store/projection reset internals**
   - Suggested future extraction/documentation of shared replay-test support if more replay tests are added.
   - Not fixed.
   - Not recorded in `docs/code-health.md`.

3. **Long-term tombstone removal criteria remain undefined**
   - Suggested future operational process for proving whether historic event tombstones can be removed.
   - Not fixed.
   - Not recorded in `docs/code-health.md`.

Because these were not fixed or recorded, the run should be considered accepted for implementation correctness, but not fully handled from a code-health recording workflow perspective.

## Repairs applied during review

No review repairs were applied.

The publish step reported:

> `No staged review diff remains after squash reset; main remains unchanged.`

So there were no additional review-polish file changes to list.

## Code-health note status

`docs/code-health.md` was not updated.

The code-health recording stage stated:

> `No code-health entry is needed... docs/code-health.md was not edited; git diff -- docs/code-health.md is empty.`

However, this conflicts with the independent review outputs, which did contain judgement-worthy non-blocking findings. This is a workflow gap as noted above.

## Key files reviewed or changed

Matching the final artifact gate evidence, notable files reviewed/changed included:

- `web/lib/memba/messaging.ex`
- `web/lib/memba/messaging/commands/report_email_delivery_opened.ex`
- `web/lib/memba/messaging/events/email_delivery_opened.ex`
- `web/lib/memba/messaging/message.ex`
- `web/lib/memba/messaging/projectors/memba_staff_email_delivery.ex`
- `web/lib/memba/messaging/projectors/member_email_delivery.ex`
- `web/lib/memba_web/controllers/postmark_webhook_controller.ex`
- `web/lib/memba_web/member_email_delivery_presentation.ex`
- `web/test/memba/messaging/email_delivery_opened_replay_test.exs`
- `web/test/support/event_sourced_case.ex`
- `web/test/memba/messaging/message_test.exs`
- `web/test/memba/messaging/status_report_api_test.exs`
- `web/test/memba/messaging/send_message_dispatch_test.exs`
- `web/test/memba/messaging/memba_staff_email_delivery_projection_test.exs`
- `web/test/memba/messaging/member_email_delivery_projection_test.exs`
- `web/test/memba_web/controllers/postmark_webhook_controller_test.exs`
- `web/test/memba_web/controllers/resend_webhook_controller_test.exs`
- `web/test/memba_web/controllers/member_message_detail_test.exs`
- `web/test/memba_web/live/deliveries_live_test.exs`
- `web/test/memba_web/live/member_dashboard_live_test.exs`
- `web/test/memba_web/live/member_message_live/show_test.exs`
- `web/test/memba_web/member_dashboard_presentation_test.exs`
- `web/test/memba_web/member_email_delivery_presentation_test.exs`
- `acceptance-tests/features/step_definitions/member_message_steps.js`
- `acceptance-tests/features/support/member_message.js`
- `acceptance-tests/test/member_message_steps.test.js`

## Publish outcome

Review polish was **not pushed to main**.

Publish step outcome:

> `No staged review diff remains after squash reset; main remains unchanged.`

## Tests and validation run

Validation completed successfully.

`dev ci` passed.

Acceptance output included:

- 82 scenarios passed
- 493 steps passed

The final artifact gate also passed and confirmed reviewed implementation evidence.

The review evidence indicates the added regression coverage exercises historic `EmailDeliveryOpened` replay/projection rebuild safety, not merely forward dispatch.

## Manual demo/checks still recommended

No manual demo is required before merge based on the review outcome.

Optional manual checks, if desired:

- Spot-check member/staff delivery UI surfaces to confirm no “opened” status/count appears.
- Run the final grep described in the plan if a human wants extra confidence that only documented replay shims retain `opened`/`Opened`.

## Non-blocking follow-ups

Recommended follow-ups from independent review, currently unrecorded in `docs/code-health.md`:

1. Document the event tombstone/deprecation pattern in ADR or reference documentation if this pattern recurs.
2. Consider extracting shared replay/projection-rebuild test support if more replay-safety tests are added.
3. Define an operational process for determining whether historic event tombstones can ever be safely removed.
4. Optionally audit operational metrics/logging outside this iteration’s code scope for stale `"opened"` delivery-status references.