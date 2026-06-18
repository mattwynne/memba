# Obliterate the deprecated "opened" email delivery status

Date: 2026-06-17
Status: validated

## Goal

Remove the deprecated `"opened"` email-delivery status as a live concept everywhere except a deliberate, documented event-store tombstone. After this iteration there is one clear answer to "is opened a status Memba tracks?" — no — and the codebase stops carrying the half-removed husk that currently misleads contributors, the design system, and the dev seeds/gallery.

After this iteration:

- No `opened`/`Opened` references remain in `lib/` except a clearly documented ignore-on-replay shim (the event module plus no-op aggregate/projector clauses) retained only so historic events deserialize and projection rebuilds stay green.
- The deprecated `ReportEmailDeliveryOpened` command, the read-model normalization of `"opened"`, the presentation `"opened" -> "delivered"` mapping, the Postmark webhook `"opened"` rejection branch, and all active projector behaviour for the event are gone.
- Tests no longer assert behaviour for a status the product does not support; a regression test proves a historic `EmailDeliveryOpened` event replays safely.

## Background / Context

Surfaced while building realistic dev seeds for the gallery walk (problem note 2026-06-17): "opened" is already deprecated end-to-end at the edges — `ReportEmailDeliveryOpened` is a retained no-op, the Postmark webhook rejects the `"opened"` record type as unsupported, and `MemberEmailDeliveryPresentation` collapses `"opened" -> "delivered"`. So "opened" is no longer produced, yet the concept still threads through command, event, aggregate, both projectors, read-model normalization, presentation, webhook, and ~13 test suites. This half-removed state misleads: the design system and member dashboard still imply an "opened" count, the seeds/gallery can't represent it, and contributors can't tell whether "opened" is supported.

Iteration 017 ("Remove email open tracking") already removed open tracking from the user-facing surfaces and the `.feature` acceptance scenarios. This iteration finishes the job in the domain/read/presentation/webhook code and tests.

Event-sourcing caveat: historic `EmailDeliveryOpened` events may exist in the production event store from before iteration 017. A hard delete of the event type could break projection rebuilds/replays. The chosen strategy is an **ignore-on-replay shim**: keep a minimal event module and no-op handler clauses so historic events deserialize and replay without effect, and remove everything else.

## Related Problems

- [`docs/problems/2026-06-17-obliterate-opened-email-delivery-status.md`](../../problems/2026-06-17-obliterate-opened-email-delivery-status.md): **expected to resolve.** This iteration removes the live "opened" concept across command, read models, presentation, and webhook, removes the active projector/aggregate behaviour, and retains only a documented replay shim per the event-sourcing note in that problem.

## Scope

### In scope

- Delete the deprecated command `lib/memba/messaging/commands/report_email_delivery_opened.ex` and any dispatch routing/registration for it.
- Remove the `status: "opened"` normalization clauses in `lib/memba/messaging.ex` (member and staff read paths, ~lines 430 and 439).
- Remove the `"opened" -> "delivered"` mapping in `lib/memba_web/member_email_delivery_presentation.ex`.
- Remove the `"opened"` rejection branch in `lib/memba_web/controllers/postmark_webhook_controller.ex` (an `opened` record type now falls through the same unsupported/ignored path as any other unrecognised type).
- Remove the active projection behaviour for the event in `lib/memba/messaging/projectors/member_email_delivery.ex` and `lib/memba/messaging/projectors/memba_staff_email_delivery.ex`.
- **Retain as a documented ignore-on-replay shim:**
  - `lib/memba/messaging/events/email_delivery_opened.ex` (event struct kept so historic events deserialize).
  - A no-op `apply/2` clause for `EmailDeliveryOpened` in `lib/memba/messaging/message.ex` returning state unchanged.
  - No-op `project`/handler clauses for `EmailDeliveryOpened` in both projectors **only where** replay/rebuild would otherwise crash on the historic event.
  - Each shim element carries a clear comment: deprecated, retained only for replay safety, do not extend.
- Update/remove `"opened"` assertions and fixtures across the affected ExUnit suites and the acceptance JS step/support files (see Touchpoints).
- Add a regression test proving a persisted historic `EmailDeliveryOpened` event replays without affecting member/staff projections or read models.

### Out of scope

- The iteration 034 member-page design-system work (separate iteration, holds the WIP slot).
- Any change to the statuses Memba does track (delivered / sending / delivery problem) or their colours.
- Marketing site and email templates.
- A full upcaster/event-store rewrite to physically purge historic events (the chosen strategy is the shim, not history rewriting).

## Iteration Type

Technical/engineering cleanup. There is no new user-observable behaviour: iteration 017 already removed open tracking from every member/staff surface and from the acceptance scenarios. This removes dead/confusing internal surface area and hardens replay safety.

## Acceptance Scenarios / Feature Files

BDD decision: **Not useful for this slice.**

This is internal cleanup of an already-removed feature. The shared `.feature` files contain no `opened` scenarios (iteration 017 removed them), so there is no new or changed stakeholder-readable domain rule to express. The only `opened` references in `acceptance-tests/` are step-definition/support plumbing that must be cleaned up as part of removal, not domain scenarios. Correctness is verified by ExUnit (including the historic-event replay-safety regression test) and `dev check`.

## Acceptance Criteria

- No `opened`/`Opened` references remain in `lib/` **except** the documented ignore-on-replay shim (event module + no-op aggregate clause + minimal no-op projector clauses), each commented as retained-for-replay-only.
- `ReportEmailDeliveryOpened`, the read-model `"opened"` normalization, the `"opened" -> "delivered"` presentation mapping, and the webhook `"opened"` rejection branch are gone.
- No member or staff delivery surface (dashboard, message detail, staff diagnostics/deliveries) references an "opened" status or count.
- A regression test persists/replays a historic `EmailDeliveryOpened` event and asserts projections and read models are unaffected and the rebuild succeeds.
- All remaining tests no longer assert behaviour for the "opened" status; the acceptance JS step/support files no longer reference it.
- `dev check` passes.

## Open Business Decisions

None known. "Opened" is already not a tracked product status; this is cleanup.

## Implementation Plan

1. Inventory every `opened`/`Opened` reference in `lib/`, `test/`, and `acceptance-tests/` (baseline grep) and classify each as remove vs retain-as-shim.
2. Delete the `ReportEmailDeliveryOpened` command and any dispatch routing/registration for it.
3. Remove the `"opened"` read-model normalization clauses in `messaging.ex`, the presentation `"opened" -> "delivered"` mapping, and the webhook `"opened"` rejection branch.
4. Reduce the aggregate `apply/2` for `EmailDeliveryOpened` to a documented no-op; reduce the two projectors to documented no-op handling only where replay would otherwise fail, removing all active behaviour.
5. Keep `events/email_delivery_opened.ex` as the deserialization tombstone with a deprecation comment.
6. Update/remove `"opened"` assertions and fixtures across the affected ExUnit suites and acceptance JS step/support files.
7. Add the historic-event replay-safety regression test.
8. Re-run the baseline grep to confirm only the documented shim remains.
9. Run `dev check`.

## Open Technical Decisions

- Exact shape of replay safety in the Commanded projectors: whether each projector needs an explicit no-op `project` clause for `EmailDeliveryOpened` or whether the existing subscription/skip behaviour already tolerates an unhandled historic event. Decide per projector by exercising a rebuild in the regression test; keep the minimal clause that makes replay green.
- Whether the aggregate's `EmailDeliveryOpened` alias can be dropped or must remain for the no-op clause to reference the struct.

These are implementation details and should not need product decisions.

## New Capability

Contributors, the design system, and the dev seeds/gallery have a single, consistent source of truth: Memba does not track an "opened" delivery status. The codebase no longer carries a misleading half-removed status, and projection rebuilds remain safe against historic events.

## Validation Plan

- ExUnit suites updated to drop "opened" assertions, all green.
- New regression test: a persisted historic `EmailDeliveryOpened` event replays/rebuilds without affecting member/staff projections or read models.
- Baseline-vs-final grep showing no `opened`/`Opened` in `lib/` outside the documented shim, and none in `test/`/`acceptance-tests/` outside intentional shim coverage.
- Full `dev check` before delivery is complete.

## Risks / Follow-ups

- **Replay safety is the main risk.** If a projector cannot tolerate the historic event without an explicit clause, the no-op clause must stay; the regression test must actually exercise a rebuild, not just a forward dispatch, to prove it.
- The shim is a deliberate tombstone, not dead code to be "cleaned up" later by a well-meaning contributor — comments must make its purpose explicit so it is not removed and break replays.
- If, during inventory, the production event store can be confirmed to contain zero `EmailDeliveryOpened` events, a future iteration could drop the shim entirely; record that as a follow-up rather than widening this slice.
- This plan can be validated now but cannot deliver until iteration 034 vacates the single implementation WIP slot.
