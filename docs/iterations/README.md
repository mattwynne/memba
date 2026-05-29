# Iterations

The user-facing capability "member message deliverability" is delivered
across iterations 001–004. Each iteration is independently shippable: it
leaves the codebase passing `dev check` and Cucumber, with strictly more
scenarios green than before.

| # | Date | Status | Title | Plan |
| --- | --- | --- | --- | --- |
| 001 | 2026-05-28 | merged | Event-sourced foundation | [plan](001-event-sourced-foundation/plan.md) |
| 002 | 2026-05-28 | ready | Membership model | [plan](002-membership-model/plan.md) |
| 003 | 2026-05-28 | ready | Messaging skeleton | [plan](003-messaging-skeleton/plan.md) |
| 004 | 2026-05-28 | ready | Delivery statuses and views | [plan](004-delivery-status-and-views/plan.md) |

Shared acceptance feature files used across these iterations:

- [`member_message_deliverability.feature`](../../acceptance-tests/features/member_message_deliverability.feature)
- [`operator_email_deliverability.feature`](../../acceptance-tests/features/operator_email_deliverability.feature)
