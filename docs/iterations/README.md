# Iterations

See [roadmap.md](roadmap.md) for the current product sequencing after the routing and authentication foundations.

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
| 006 | 2026-05-30 | merged | Browser Cucumber automation for member-facing acceptance | [plan](006-browser-cucumber-automation/plan.md) |
| 007 | 2026-05-29 | merged | Deliveries overview for operator deliverability | [plan](007-deliveries-overview/plan.md) |
| 008 | 2026-05-30 | merged | Postmark email integration for outbound member messages | [plan](008-postmark-email-integration/plan.md) |
| 009 | 2026-05-31 | merged | Routing and LiveView surface split | [plan](009-routing-and-liveview-surface-split/plan.md) |
| 010 | 2026-05-31 | merged | Shared magic-link authentication | [plan](010-shared-magic-link-auth/plan.md) |
| 011 | 2026-06-01 | merged | Member-facing message behaviour | [plan](011-member-facing-message-behaviour/plan.md) |
| 012 | 2026-06-01 | merged | Member receipt detail LiveView polish | [plan](012-member-receipt-detail-liveview-polish/plan.md) |
| 013 | 2026-06-01 | implementing | Member compose LiveView flow | [plan](013-member-compose-liveview-flow/plan.md) |
| 014 | 2026-06-01 | validated | Member dashboard LiveView polish | [plan](014-member-dashboard-liveview-polish/plan.md) |

Status notes:

- `draft` means a captured plan still needs human review before validation or implementation.
- `ready` means a human-approved plan is waiting for validation or implementation.
- `validated` means plan validation has passed; it may wait while another iteration is active.
- `implementing`, `ready-for-review`, `in-review`, `reviewing`, and `finalizing` occupy the single implementation WIP slot.

Shared acceptance feature files used across these iterations:

- [`member_message_deliverability.feature`](../../acceptance-tests/features/member_message_deliverability.feature) (`@wip` for iteration 011 planning until the member-facing browser slice is implemented)
- [`operator_email_deliverability.feature`](../../acceptance-tests/features/operator_email_deliverability.feature) (iteration 007 remodels this as a deliveries overview across messages; browser Cucumber automation is iteration 006)
