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
| 013 | 2026-06-01 | merged | Member compose LiveView flow | [plan](013-member-compose-liveview-flow/plan.md) |
| 014 | 2026-06-01 | merged | Member dashboard LiveView polish | [plan](014-member-dashboard-liveview-polish/plan.md) |
| 015 | 2026-06-01 | merged | Club slugs and public club subdomains | [plan](015-club-slugs/plan.md) |
| 016 | 2026-06-01 | merged | Multiple email addresses per person | [plan](016-person-email-addresses/plan.md) |
| 017 | 2026-06-01 | merged | Remove email open tracking | [plan](017-remove-open-tracking/plan.md) |
| 018 | 2026-06-01 | merged | Member-facing club subdomains | [plan](018-member-club-subdomains/plan.md) |
| 019 | 2026-06-02 | merged | Inbound club messages by email | [plan](019-inbound-club-messages-by-email/plan.md) |
| 020 | 2026-06-02 | merged | Migrate production email to Postmark | [plan](020-migrate-production-email-to-postmark/plan.md) |
| 021 | 2026-06-05 | merged | Staff area redesign and read-only operations indexes | [plan](021-staff-area-redesign/plan.md) |
| 022 | 2026-06-05 | merged | Staff-approved request-to-club onboarding | [plan](022-request-to-club-onboarding/plan.md) |
| 023 | 2026-06-06 | merged | Public copy pass for older community members | [plan](023-copy-review-for-older-club-members/plan.md) |
| 024 | 2026-06-06 | implementing | Transactional email template redesign | [plan](024-email-template-designs/plan.md) |

Status notes:

- `draft` means a captured plan still needs human review before validation or implementation.
- `ready` means a human-approved plan is waiting for validation or implementation.
- `validated` means plan validation has passed; it may wait while another iteration is active.
- `implementing`, `ready-for-review`, `in-review`, `reviewing`, and `finalizing` occupy the single implementation WIP slot.

Shared acceptance feature files used across these iterations:

- [`member_message_deliverability.feature`](../../acceptance-tests/features/member_message_deliverability.feature) (iteration 017 removes opened receipt expectations; iteration 019 adds `@wip` inbound club-message email scenarios until delivery implements Resend inbound handling; iteration 020 reuses these scenarios for Postmark migration without feature changes)
- [`memba_staff_email_deliverability.feature`](../../acceptance-tests/features/memba_staff_email_deliverability.feature) (iteration 017 removes opened receipt expectations; iteration 007 remodels this as a deliveries overview across messages; browser Cucumber automation is iteration 006)
- [`staff_club_slugs.feature`](../../acceptance-tests/features/staff_club_slugs.feature) (`@wip` for iteration 015 planning until staff slug management and public club subdomain routing are implemented)
- [`person_email_addresses.feature`](../../acceptance-tests/features/person_email_addresses.feature) (`@wip` planning scenarios for iteration 016 until the person email-address model and staff/member behaviours are implemented)
- [`member_club_subdomains.feature`](../../acceptance-tests/features/member_club_subdomains.feature) (`@wip` planning scenarios for iteration 018 until member-facing club subdomain routing and navigation are implemented)
- [`memba_staff_operations.feature`](../../acceptance-tests/features/memba_staff_operations.feature) (`@wip` planning scenarios for iteration 021 until the redesigned staff operations pages, global People page, and global Messages page are implemented)
- [`request_account.feature`](../../acceptance-tests/features/request_account.feature) (`@wip` planning scenarios for iteration 022 until staff-approved request-to-club onboarding is implemented)
