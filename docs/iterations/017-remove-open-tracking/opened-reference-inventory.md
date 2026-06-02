# Opened/open-tracking reference inventory

Task: `001 Inspect current opened references in web/lib, web/test, acceptance-tests/features, active docs, and Postmark delivery code`.

Date: 2026-06-02

## Scope inspected

- Current app code: `web/lib`
- Current app tests: `web/test`
- Shared acceptance area: `acceptance-tests/features`
- Active docs, excluding old `docs/iterations/**` artifacts and vendored tool docs
- Postmark delivery code and webhook handling

The plan does not explicitly reference any ADRs. Relevant accepted ADRs nearby are:

- `docs/adr/0004-model-message-deliverability-as-a-message-aggregate.md`
- `docs/adr/0006-simplify-member-facing-delivery-status.md`
- `docs/adr/0012-track-whether-message-delivery-was-opened.md`
- `docs/adr/0016-use-resend-as-switchable-email-provider.md`

ADR 0012 currently conflicts with this iteration's accepted plan because it requires `opened` as a delivery status. The plan is the current iteration source of truth for removing open tracking; later implementation should either supersede/update ADR 0012 or leave it as historical architecture context if that is the project's ADR convention.

## Search evidence

Bare `rg` was not available in this sandbox, so this inspection used `grep` and Python file scans.

Commands run:

```sh
grep -RIlEi "opened|track_opens|open tracking" web/lib web/test acceptance-tests/features docs --exclude-dir=iterations
grep -RInEi "opened|track_opens|open tracking" acceptance-tests/features --include='*.feature'
grep -RInEi "opened|track_opens|open tracking" acceptance-tests/features/member_message_deliverability.feature acceptance-tests/features/memba_staff_email_deliverability.feature web/test/features/cucumber_configuration_test.exs
python3 - <<'PY'
from pathlib import Path
import re
paths = [Path('web/lib'), Path('web/test'), Path('acceptance-tests/features')]
pat = re.compile(r'opened|track_opens|open tracking', re.I)
for root in paths:
    files=[]
    for p in sorted(root.rglob('*')):
        if p.is_file():
            text=p.read_text(errors='ignore')
            matches=sum(1 for _ in pat.finditer(text))
            if matches:
                files.append((str(p), matches))
    print(root, len(files), sum(m for _, m in files))
PY
```

Summary counts:

| Area | Files with matches | Match count |
| --- | ---: | ---: |
| `web/lib` | 15 | 54 |
| `web/test` | 17 | 122 |
| `acceptance-tests/features` | 2 | 9 |
| active docs excluding `docs/iterations/**` and `docs/tools/**` | 8 | 26 |

## Shared acceptance references

The plan-named `.feature` files are already free of opened/open-tracking matches:

- `acceptance-tests/features/member_message_deliverability.feature`
- `acceptance-tests/features/memba_staff_email_deliverability.feature`

`web/test/features/cucumber_configuration_test.exs` is also already free of opened/open-tracking matches.

Remaining acceptance-harness support references are in plumbing rather than shared feature prose:

- `acceptance-tests/features/step_definitions/member_message_steps.js`
  - reports `"opened"` for historical/opened step definitions.
- `acceptance-tests/features/support/member_message.js`
  - maps opened labels/statuses and enforces opened-after-delivered assumptions in browser-support helpers.

## Messaging domain/API references

Current opened command/API/event path:

- `web/lib/memba/messaging.ex`
  - aliases `ReportEmailDeliveryOpened`.
  - exposes `report_email_delivery_opened/2`.
  - builds opened-report commands.
  - documents simplified member vocabulary including opened.
- `web/lib/memba/messaging/router.ex`
  - routes `ReportEmailDeliveryOpened`.
- `web/lib/memba/messaging/commands/report_email_delivery_opened.ex`
  - command module for reporting opens.
- `web/lib/memba/messaging/events/email_delivery_opened.ex`
  - event module for opened deliveries.
- `web/lib/memba/messaging/message.ex`
  - handles `ReportEmailDeliveryOpened`.
  - emits/applies `EmailDeliveryOpened`.
  - permits `:delivered -> :opened` and `:sent -> :opened` transitions.

Domain tests with opened expectations:

- `web/test/features/step_definitions/messaging_steps.exs`
- `web/test/memba/messaging/app_test.exs`
- `web/test/memba/messaging/message_test.exs`
- `web/test/memba/messaging/send_message_dispatch_test.exs`
- `web/test/memba/messaging/status_report_api_test.exs`

## Projection/read-model references

Projection code that currently writes opened status:

- `web/lib/memba/messaging/projectors/member_email_delivery.ex`
  - projects `EmailDeliveryOpened` to member status `"opened"`.
- `web/lib/memba/messaging/projectors/memba_staff_email_delivery.ex`
  - projects `EmailDeliveryOpened` to staff status `"opened"`.

Projection/read-model tests with opened expectations:

- `web/test/memba/messaging/member_email_delivery_projection_test.exs`
- `web/test/memba/messaging/memba_staff_email_delivery_projection_test.exs`
- `web/test/memba_web/member_message_detail_loader_test.exs`

## Postmark and provider references

Outbound Postmark delivery:

- `web/lib/memba/messaging/email_delivery_providers/postmark.ex`
  - line 43 sets `put_provider_option(:track_opens, true)`.
- `web/test/memba/messaging/email_delivery_providers/postmark_test.exs`
  - expects open tracking in the provider options.

Postmark webhook handling:

- `web/lib/memba_web/controllers/postmark_webhook_controller.ex`
  - maps `"open"`/`"opened"` record types to `:opened`.
  - dispatches `Messaging.report_email_delivery_opened/1`.
- `web/test/memba_web/controllers/postmark_webhook_controller_test.exs`
  - expects Postmark open webhook events to change member status to `"opened"`.

Related non-Postmark provider references found during the same inspection:

- `web/lib/memba_web/controllers/resend_webhook_controller.ex`
  - maps Resend opened events to `Messaging.report_email_delivery_opened/1`.
- `web/test/memba_web/controllers/resend_webhook_controller_test.exs`
  - expects Resend opened events to mutate status to `"opened"`.

The implementation plan names Postmark specifically for outbound tracking and webhook rejection, but the broader goal says Memba no longer models/records/displays opens. Later slices should account for Resend opened webhook behaviour too if the shared Messaging opened API is removed.

## Member-facing presentation references

Current member-facing opened UI/copy/status references:

- `web/lib/memba_web/member_email_delivery_presentation.ex`
  - status order includes `"opened"`.
  - label/icon/description includes `"Opened"` and `"arrived, not opened yet"`.
- `web/lib/memba_web/member_dashboard_presentation.ex`
  - computes opened count and `"N of M opened"` glance copy.
- `web/lib/memba_web/controllers/page_html.ex`
  - static/status class helpers include `"opened"`.
- `web/lib/memba_web/controllers/page_html/message.html.heex`
  - copy says receipt groups are ordered by opened first.

Member-facing tests with opened expectations:

- `web/test/memba_web/controllers/member_message_detail_test.exs`
- `web/test/memba_web/live/browser_acceptance_harness_test.exs`
- `web/test/memba_web/live/member_dashboard_live_test.exs`
- `web/test/memba_web/live/member_message_live/show_test.exs`
- `web/test/memba_web/member_dashboard_presentation_test.exs`
- `web/test/memba_web/member_email_delivery_presentation_test.exs`

## Memba-staff delivery view references

Current staff delivery UI reference:

- `web/lib/memba_web/live/admin/deliveries_live/index.ex`
  - `status_class("opened")`.

Staff-visible opened expectations also appear in domain/projection tests:

- `web/test/memba/messaging/memba_staff_email_delivery_projection_test.exs`
- `web/test/memba/messaging/status_report_api_test.exs`

No opened matches were found under a separate `web/test/memba_web/live/admin` test path.

## Active documentation references

Current-app/operational docs requiring updates:

- `docs/postmark-email.md`
  - webhook events include `Open`.
  - outbound behaviour says Postmark open tracking is enabled per email.
  - manual smoke test asks to open the HTML email and confirm an open webhook reaches Memba.
- `docs/human-todo.md`
  - Postmark setup checklist still says to enable opened webhooks and open tracking.
  - auth-stream note says not to point delivery/open/bounce events at member-message routes.

Architecture/problem-domain docs with opened as model vocabulary:

- `docs/adr/0004-model-message-deliverability-as-a-message-aggregate.md`
- `docs/adr/0006-simplify-member-facing-delivery-status.md`
- `docs/adr/0012-track-whether-message-delivery-was-opened.md`
- `docs/adr/0016-use-resend-as-switchable-email-provider.md`
- `docs/problem-domain-audit-2026-06-01.md`

Likely historical/irrelevant active-doc matches:

- `docs/kaizen/2026-05-30-iteration-implementation-reset-cycle-limit.md`
  - mentions a past failed-run synchronization issue involving opened.
- `docs/strategy/research/extracted-text/Memba Market and Competitor Research.txt`
  - contains competitor research text, not current app behaviour.
- `docs/tools/**`
  - vendored or library documentation examples such as `BankAccountOpened` and browser-window text; excluded from cleanup.

`docs/email-delivery.md` does not exist; the current operational email document is `docs/postmark-email.md`.

## Suggested follow-on mapping

- Task 002: feature prose appears already updated; confirm whether only harness/support cleanup is needed or whether this task can be checked off by validation.
- Task 003: remove/deprecate the Messaging opened command/API/router/aggregate emission path while preserving any needed event compatibility module.
- Task 004: stop current projectors/loaders/read-model status lists from producing opened.
- Task 005: remove `track_opens` from the Postmark provider and update provider tests.
- Task 006: make Postmark open webhook events unsupported; also decide how to handle Resend opened events now that the shared opened API is being removed.
- Task 007: remove opened member-facing presentation groups/counts/copy/tests.
- Task 008: remove opened staff delivery presentation/tests.
- Task 009: update active operational/current-app docs, especially `docs/postmark-email.md` and `docs/human-todo.md`.
