# Iterations

The user-facing capability "member message deliverability" is delivered
across iterations 001–004. Iterations 005 and later bring that behaviour into
browser-facing surfaces. Each iteration is independently shippable: it leaves
the codebase passing `dev check` and Cucumber, with strictly more scenarios
green than before.

| # | Date | Status | Title | Plan |
| --- | --- | --- | --- | --- |
| 001 | 2026-05-28 | merged | Event-sourced foundation | [plan](001-event-sourced-foundation/plan.md) |
| 002 | 2026-05-28 | merged | Membership model | [plan](002-membership-model/plan.md) |
| 003 | 2026-05-28 | merged | Messaging skeleton | [plan](003-messaging-skeleton/plan.md) |
| 004 | 2026-05-28 | merged | Delivery statuses and views | [plan](004-delivery-status-and-views/plan.md) |
| 005 | 2026-05-29 | merged | App substrate for browser-facing member behaviour | [plan](005-browser-acceptance-harness/plan.md) |
| 006 | 2026-05-30 | ready-for-review | Browser Cucumber automation for member-facing acceptance | [plan](006-browser-cucumber-automation/plan.md) |
| 007 | 2026-05-29 | validated | Deliveries overview for operator deliverability | [plan](007-deliveries-overview/plan.md) |
| 008 | 2026-05-30 | ready | Postmark email integration for outbound member messages | [plan](008-postmark-email-integration/plan.md) |

Status notes:

- `draft` means a captured plan still needs human review before validation or implementation.
- `ready` means a human-approved plan is waiting for validation or implementation.
- `validated` means plan validation has passed; it may wait while another iteration is active.
- `implementing`, `ready-for-review`, `in-review`, `reviewing`, and `finalizing` occupy the single implementation WIP slot.

Shared acceptance feature files used across these iterations:

- [`member_message_deliverability.feature`](../../acceptance-tests/features/member_message_deliverability.feature)
- [`operator_email_deliverability.feature`](../../acceptance-tests/features/operator_email_deliverability.feature) (iteration 007 remodels this as a deliveries overview across messages; browser Cucumber automation is iteration 006)
