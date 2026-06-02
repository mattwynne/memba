# Remove email open tracking

Date: 2026-06-01
Status: validated

## Goal

Memba no longer models, records, requests, or displays pixel-based email open tracking.

After this iteration, delivery status stops at sending, delivered, or delivery problem. Members and Memba staff can still see whether messages were handed off, delivered, delayed, bounced, or marked as spam, but Memba does not ask Postmark to track opens and does not expose an `opened` delivery state anywhere in the current app.

## Background / Context

Memba currently treats email opens as a first-class delivery status:

- outbound Postmark email delivery enables open tracking with `track_opens: true`;
- the Postmark webhook maps `Open`/`Opened` events onto `Messaging.report_email_delivery_opened/2`;
- Messaging has an opened-report command, opened event, opened aggregate status, and opened projector updates;
- member receipt views and dashboard summaries display opened counts, groups, labels, and progress segments;
- Memba staff delivery views display opened status;
- shared acceptance features describe opened receipts.

Matt has decided that pixel-based open tracking should be removed completely from the model and app. This is a policy and product-model simplification, not a replacement with another engagement metric.

## Scope

### In scope

- Remove `opened` as a current Messaging delivery state from the domain model and public APIs.
- Remove or stop exposing the opened-report command/API, opened event, opened transition, and opened projection updates from current behaviour.
- Stop enabling Postmark open tracking for outbound member-message email.
- Change Postmark open webhook events (`Open`/`Opened` or equivalent) so they are rejected as unsupported and do not change delivery state.
- Remove opened status from member-facing message receipt detail and member dashboard summaries, groups, counts, labels, progress bars, and copy.
- Remove opened status from Memba staff delivery visibility.
- Replace copy such as “arrived, not opened yet” with wording that does not imply open tracking.
- Update executable tests and current active documentation that describe the current app behaviour or Postmark operational settings.
- Update shared acceptance feature files so stakeholder-readable behaviour no longer includes opened receipts.
- Keep `dev check` green.

### Out of scope

- Data migration or backfill for existing development/test/historic rows or events that already say `opened`.
- Repository-wide cleanup of old iteration plans, design handoff artifacts, prototypes, or historical notes that mention opened receipts.
- A replacement engagement metric.
- New provider integrations beyond preserving existing Postmark delivery/problem handling.
- Changes to magic-link/auth email behaviour.

## Iteration Type

Behaviour-facing policy/model simplification.

The changed user-observable rule is: Memba does not track email opens. Members and staff see delivery handoff and delivery problem information, but not whether a recipient opened an email.

## Acceptance Scenarios / Feature Files

BDD decision: Required.

This iteration changes stakeholder-visible delivery-status vocabulary and privacy/tracking behaviour. Update the existing shared Cucumber feature files as living documentation:

- `acceptance-tests/features/member_message_deliverability.feature`
  - Update `Alice sees different statuses for different members` so the example shows Sending, Delivered, and Delivery problem only. Dana remains Sending instead of being reported as Opened.
- `acceptance-tests/features/memba_staff_email_deliverability.feature`
  - Remove the `Opens are visible after delivery` scenario because opens are no longer a supported staff-visible delivery state.

No new `@wip` scenarios are needed. These edits remove obsolete expected behaviour. The Cucumber configuration/runtime expectation test should be updated alongside the feature edits so planning-time validation reflects the revised shared feature files without changing step definitions.

## Allowed acceptance feature changes

- `acceptance-tests/features/member_message_deliverability.feature`: replace the opened example in the member status scenario with non-open statuses. Reason: member-facing living documentation must no longer describe opened receipts. Coverage is preserved for Sending, Delivered, and Delivery problem.
- `acceptance-tests/features/memba_staff_email_deliverability.feature`: remove the opened-after-delivery scenario. Reason: the rule is intentionally no longer supported. Coverage is preserved for delayed, bounced, and spam complaint staff delivery visibility.
- `web/test/features/cucumber_configuration_test.exs`: update the hard-coded shared-feature scenario/step expectations to match the revised feature files, without changing Cucumber step definitions. Reason: this validation test mirrors the shared acceptance feature files and must stay green after planning edits.

## Acceptance Criteria

- Outbound Postmark member-message emails do not request or enable open tracking.
- Postmark open webhook events are rejected as unsupported and do not change any delivery state.
- The current Messaging API no longer exposes or uses `report_email_delivery_opened/2` for current behaviour.
- The current Messaging aggregate/model no longer has an `opened` delivery status or delivered-to-opened transition.
- Current read models/projections no longer produce `opened` as a delivery status.
- Member message receipt detail views show only Sending, Delivered, and Delivery problem groupings/statuses.
- Member dashboard message summaries and receipt bars do not show opened counts or opened segments.
- Copy no longer says or implies “not opened yet”.
- Memba staff delivery views do not show opened as a possible current status.
- Existing delivery problem reason handling for delayed, bounced, and spam complaint reports is preserved.
- Existing delivered status behaviour is preserved.
- Shared acceptance features no longer describe opened receipts.
- Active Postmark/current-app documentation no longer instructs operators that Memba tracks opens or enables Postmark open tracking.
- `dev check` passes.

## Open Business Decisions

None known.

Decisions made during planning:

- Existing `opened` data does not need a migration/backfill for this iteration.
- Old iteration/design artifacts may continue to mention opened receipts as historical context.
- Provider open webhook events should be rejected as unsupported, not silently accepted.

## Implementation Plan

1. Inspect current opened references in `web/lib`, `web/test`, `acceptance-tests/features`, active docs, and Postmark delivery code. Exclude old `docs/iterations/**` design/prototype artifacts from cleanup unless they are active validation inputs.
2. Update shared acceptance feature expectations to remove opened receipts.
3. Remove or deprecate the Messaging opened-report command/API/event path from current behaviour:
   - delete or stop routing `ReportEmailDeliveryOpened` command handling;
   - delete or stop emitting `EmailDeliveryOpened` for current command execution;
   - remove the delivered-to-opened transition from the aggregate;
   - ensure current public APIs and tests use delivered/problem statuses only.
4. Update projections/read models and loaders so current status lists, summaries, and grouping functions do not include opened.
5. Update Postmark outbound delivery so it does not set `track_opens: true` or any equivalent open-tracking option.
6. Update Postmark webhook handling so open events are treated as unsupported and do not mutate delivery status.
7. Update member LiveViews/presentation modules/tests to remove opened receipt segments, groups, toggles, counts, data attributes, and copy.
8. Update Memba staff delivery views/tests to remove opened status expectations while preserving delivered/problem visibility.
9. Update active operational/current-app documentation, especially Postmark email docs, to remove open-tracking instructions or claims.
10. Run targeted tests while changing each layer, then run `dev check` and fix regressions.

## Open Technical Decisions

None known.

Implementation notes:

- If deleting old opened event modules would break event deserialization for local historic data, prefer keeping a compatibility shim that is not emitted by current code and is not exposed as current model behaviour. Do not add a data migration/backfill unless implementation discovers the app cannot boot or replay without one.
- Keep webhook rejection consistent with the existing unsupported-event response style.

## New Capability

Memba can send and monitor member email delivery without pixel-based open tracking. The product vocabulary is simpler and avoids implying that Memba observes whether a recipient read a message.

## Validation Plan

- Run or update the shared acceptance harness so:
  - member deliverability scenarios pass with Sending, Delivered, and Delivery problem only;
  - staff deliverability scenarios pass without any opened scenario.
- Run Messaging domain tests covering delivered, delayed, bounced, and spam complaint reports.
- Run Postmark provider tests proving open tracking is not enabled.
- Run Postmark webhook/controller tests proving open events are unsupported and do not alter delivery status.
- Run member dashboard and member message LiveView tests proving opened groups/counts/copy are absent.
- Run Memba staff delivery LiveView/tests proving opened status is absent while other statuses remain visible.
- Run documentation/search checks such as `rg "opened|track_opens|open tracking" web/lib web/test acceptance-tests/features docs/email-delivery.md` and confirm remaining matches are either removed or explicitly historical/irrelevant.
- Run `dev check`.

## Risks / Follow-ups

- Removing old event modules entirely may be awkward if local event stores contain historic opened events. Keep compatibility internal if needed, but do not expose opened as current behaviour.
- Third-party provider dashboards may still report opens independently if a stream was configured outside Memba. Document that Memba does not request or consume those signals.
- Future engagement metrics, if ever wanted, should be planned as a separate product/privacy decision rather than reusing tracking pixels by accident.
