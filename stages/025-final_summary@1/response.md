Result: REVIEW_ACCEPTED

Plan path: `docs/iterations/038-email-delivery-handoff-boundary/plan.md`

Base SHA: `90134f8ebf5b313e76e43e912c50800ab2687545`

Reviewed / published commit range: `90134f8ebf5b313e76e43e912c50800ab2687545..3031fc1`

Final published main commit: `3031fc1`  
Review polish commit pushed to main: `f6a6e2955b24d9b6cad2a5edf4bac9b5e6f715ec`  
Iteration status commit pushed to main: `3031fc1`

## ADR conformance summary

Independent reviews and synthesis agreed on ADR conformance: PASS.

No cited ADR violation was found. Reviewers noted that the implementation remains broadly consistent with the project’s CQRS / event-sourced direction because:

- command acceptance is no longer coupled to synchronous provider delivery;
- email delivery provider handoff is modeled as an explicit asynchronous lifecycle;
- provider dispatch occurs behind a supervised dispatcher and read-model state;
- the implementation follows the iteration plan’s explicit choices:
  - use existing `EmailDelivery` records;
  - use `pending`, `dispatching`, `sent`, and `failed`;
  - use PubSub/read-model-change nudges;
  - provide manual retry only;
  - defer automatic retries, sweeps, and startup recovery.

Reviewers did identify event-sourcing and operational durability smells, but treated them as non-blocking because the plan explicitly accepted or deferred those trade-offs.

## Independent review outcome

Independent reviews from Claude, Codex, and Gemini all concluded:

- Decision: ACCEPT
- Confidence: Medium
- Blocking issues: None
- ADR violations: None identified

The review synthesis accepted the implementation:

```json
{
  "implementation_accepted": true,
  "review_fixes_available": false
}
```

The implementation was considered plan-conforming and suitable to merge, with non-blocking code-health concerns and bounded polish opportunities.

## Final artifact gate confirmation

The final artifact gate passed and confirmed the reviewed implementation evidence.

It reported:

- `35 files changed`
- `2173 insertions(+), 181 deletions(-)`
- `No acceptance .feature changes detected`
- `Final artifact evidence confirmed`
- `Final artifact gate passed`

This is the authoritative final artifact evidence for files changed/reviewed in this run.

## Finding disposition

### Fixed during review polish

The review-repair pass was ultimately published as `review polish: iteration 038` and included 9 changed files according to the publish step. These fixes are also represented in the final artifact gate file list.

1. **Dispatcher boundary observability**
   - Disposition: Fixed
   - Summary: Structured dispatcher logging was added around delivery dispatch lifecycle events.
   - Evidence files from final artifact gate:
     - `web/lib/memba/messaging/email_delivery_dispatcher.ex`
     - `web/lib/memba/messaging/email_delivery_provider.ex`

2. **Provider exception normalization**
   - Disposition: Fixed
   - Summary: Unexpected provider exceptions are normalized into failed delivery diagnostics instead of crashing through the dispatcher path.
   - Evidence files from final artifact gate:
     - `web/lib/memba/messaging/email_delivery_dispatcher.ex`
     - `web/test/memba/messaging/email_delivery_dispatcher_test.exs`
     - `web/test/support/messaging/email_delivery_providers/raising.ex`

3. **Centralized email delivery status vocabulary**
   - Disposition: Fixed
   - Summary: A shared status vocabulary module was added and used to harden status handling / tests.
   - Evidence files from final artifact gate:
     - `web/lib/memba/messaging/email_delivery_status.ex`
     - `web/lib/memba/messaging/email_delivery_dispatcher.ex`
     - `web/lib/memba/messaging/projectors/email_delivery.ex`
     - `web/lib/memba/messaging/projections/email_delivery.ex`
     - `web/test/memba/messaging/email_delivery_status_constraints_test.exs`

### Recorded in code health

1. **Projector replay can nudge the supervised email dispatcher**
   - Disposition: Recorded
   - Summary: `docs/code-health.md` was updated to record a judgement-worthy non-blocking issue: projector replay/rebuild can still publish read-model-change nudges to the supervised dispatcher if it is running, risking provider side effects during replay/rebuild.
   - Evidence file from final artifact gate:
     - `docs/code-health.md`

### Dismissed as non-blocking / plan-accepted

These findings were explicitly treated by reviewers as judgement-worthy but non-blocking because the iteration plan accepted the underlying trade-offs or deferred stronger mechanisms.

1. **Business dispatch depends on PubSub/read-model-change nudges**
   - Disposition: Dismissed as blocker; remains follow-up-worthy
   - Reason: The plan explicitly selected supervised dispatcher + PubSub nudges and explicitly deferred automatic sweeps/startup recovery.

2. **No automatic retry / startup sweep / periodic sweep**
   - Disposition: Dismissed as blocker
   - Reason: Explicitly out of scope in the plan.

3. **Provider-level idempotency remains deferred**
   - Disposition: Dismissed as blocker
   - Reason: The plan explicitly accepted best-effort duplicate prevention for this slice.

4. **Single dispatcher process serializes provider calls**
   - Disposition: Dismissed as blocker
   - Reason: Acceptable initial implementation; scalability can be addressed later if needed.

### Still unhandled / workflow gap

The following substantive independent-review findings were not fixed and, based on the recorded code-health response, were not all recorded in `docs/code-health.md`. They should be treated as workflow gaps / unhandled follow-up candidates rather than as fully handled items.

1. **Projection derives recipient data from current member state**
   - Disposition: Unhandled workflow gap
   - Concern: The `EmailDelivery` projector appears to query current member state to derive recipient email/address data. This can make projection replay non-deterministic if member data changes after the message event.

2. **Missing or blank member email may silently skip delivery creation**
   - Disposition: Unhandled workflow gap
   - Concern: A message can be accepted while no `EmailDelivery` row is created, leaving operators without an explicit failed/undeliverable diagnostic.

3. **Deliveries can remain indefinitely in `dispatching`**
   - Disposition: Unhandled workflow gap
   - Concern: If the dispatcher crashes after claiming a delivery but before persisting `sent` or `failed`, the delivery can remain stuck without recovery tooling.

4. **`Memba.Messaging` may still carry mixed responsibilities**
   - Disposition: Unhandled workflow gap
   - Concern: The context still mixes command orchestration, read-model access, retry APIs, and provider/request-building concerns.

5. **Member-facing and staff-facing delivery status language should remain separate**
   - Disposition: Unhandled workflow gap
   - Concern: Infrastructure statuses such as `pending`, `dispatching`, and `failed` could leak into member-facing presentation if helpers are reused too broadly.

## Repairs applied during review

Review polish was applied and pushed to main.

Publish step evidence:

```text
[ fabro/run/01KVMJ25ZA75KV5A0DPJ4A6X2D 369590f ] review polish: iteration 038
9 files changed, 255 insertions(+), 18 deletions(-)
create mode 100644 web/lib/memba/messaging/email_delivery_status.ex
create mode 100644 web/test/support/messaging/email_delivery_providers/raising.ex
...
Published review polish to main: f6a6e2955b24d9b6cad2a5edf4bac9b5e6f715ec
```

Repairs corresponded to:

- dispatcher observability;
- provider exception normalization;
- centralized email delivery status vocabulary;
- regression coverage for provider exceptions/status constraints.

Note: an earlier `verify_review_repair` stage reported no working-tree diff change since the repair baseline, but the later final artifact gate and publish step confirm that review polish did become part of the final artifact and was pushed to main.

## Code-health note status

`docs/code-health.md` was updated.

Recorded issue:

- projector replay can still nudge the supervised email dispatcher if it is running, risking provider side effects during replay/rebuild.

However, not all substantive non-blocking reviewer findings appear to have been recorded there. The unrecorded findings listed above should be treated as workflow gaps / follow-up candidates.

## Key files reviewed or repaired

From final artifact gate evidence, key implementation/review-polish files included:

- `docs/code-health.md`
- `docs/iterations/038-email-delivery-handoff-boundary/task-001-inspection.md`
- `docs/iterations/038-email-delivery-handoff-boundary/todo.md`
- `web/config/test.exs`
- `web/lib/memba/application.ex`
- `web/lib/memba/messaging.ex`
- `web/lib/memba/messaging/email_delivery_dispatcher.ex`
- `web/lib/memba/messaging/email_delivery_provider.ex`
- `web/lib/memba/messaging/email_delivery_status.ex`
- `web/lib/memba/messaging/projections/email_delivery.ex`
- `web/lib/memba/messaging/projections/memba_staff_email_delivery.ex`
- `web/lib/memba/messaging/projectors/email_delivery.ex`
- `web/lib/memba_web/live/admin/deliveries_live/index.ex`
- `web/lib/memba_web/live/admin/messages_live/show.ex`
- `web/lib/memba_web/member_email_delivery_presentation.ex`
- `web/priv/repo/migrations/*add_dispatch_diagnostics_to_messaging_email_deliveries.exs`
- `web/priv/repo/migrations/*add_status_constraints_to_messaging_email_deliveries.exs`
- `web/test/memba/messaging/app_test.exs`
- `web/test/memba/messaging/email_delivery_dispatcher_test.exs`
- `web/test/memba/messaging/email_delivery_status_constraints_test.exs`
- `web/test/memba/messaging/inbound_club_message_acceptance_test.exs`
- `web/test/memba/messaging/message_projection_test.exs`
- `web/test/memba/messaging/send_club_message_test.exs`
- `web/test/memba_web/controllers/postmark_inbound_webhook_controller_test.exs`
- `web/test/memba_web/controllers/resend_inbound_webhook_controller_test.exs`
- `web/test/memba_web/live/admin_diagnostics_live_test.exs`
- `web/test/memba_web/live/member_message_live/new_send_test.exs`
- `web/test/memba_web/member_email_delivery_presentation_test.exs`
- `web/test/support/messaging/email_delivery_providers/raising.ex`
- `web/test/support/messaging/email_delivery_providers/selective_failure.ex`

Final artifact gate also confirmed no acceptance `.feature` files were changed.

## Publish outcome

Review polish was pushed to `main`.

Publish evidence:

- Review polish pushed to main at `f6a6e2955b24d9b6cad2a5edf4bac9b5e6f715ec`
- Iteration marked merged and pushed to main at `3031fc1`

The publish step did not leave main unchanged; it rebased and pushed the review-polished implementation.

## Tests and validation run

Validation evidence:

- `dev ci` / dev check passed.
- Acceptance suite passed:
  - `82 scenarios`
  - `493 steps`
- Review-repair validation reported:
  - ExUnit: `824 tests, 0 failures`
  - Acceptance: `82 scenarios passed`, `493 steps passed`
- Final artifact gate passed.
- Sandbox preflight passed.
- No acceptance `.feature` changes detected.

## Manual demo/checks still recommended

Non-blocking manual checks still recommended:

1. Send a local/dev club message with the fake provider and observe:
   - `pending → dispatching → sent`
   - dispatcher logs around claim/success.

2. Force provider failure and confirm:
   - delivery becomes `failed`;
   - `attempt_count` increments;
   - `latest_error` / `latest_error_detail` are persisted.

3. Retry a failed delivery and confirm:
   - it re-enters dispatch;
   - it transitions to `sent` on success;
   - no duplicate local delivery records are created.

4. Send or accept an inbound club message and confirm:
   - it uses the same pending-delivery / dispatcher path.

5. Inspect member-facing and staff/operator delivery views:
   - member-facing screens should hide or soften infrastructure statuses;
   - staff/operator screens may show exact status and diagnostics.

## Non-blocking follow-ups

Recommended follow-ups:

1. Decide whether projection-time member lookups are acceptable or whether events should carry immutable delivery recipient data.

2. Decide how to represent missing/blank recipient email:
   - reject message command;
   - create explicit failed/undeliverable `EmailDelivery`;
   - enrich events with immutable delivery context.

3. Add durable recovery for missed PubSub nudges:
   - startup sweep;
   - periodic sweep;
   - manual dispatch tool;
   - durable job system.

4. Add stale `dispatching` recovery:
   - stale timeout;
   - operator requeue API;
   - sweep process.

5. Consider provider-level idempotency using `delivery_id` where Postmark/Resend support metadata or idempotency keys.

6. Continue extracting provider/request-building responsibilities out of `Memba.Messaging` if the context keeps growing.

7. Ensure replay/rebuild paths cannot trigger real provider side effects via dispatcher nudges, or document/guard the operational procedure clearly.