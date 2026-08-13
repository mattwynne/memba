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
| 024 | 2026-06-06 | merged | Transactional email template redesign | [plan](024-email-template-designs/plan.md) |
| 025 | 2026-06-06 | merged | Messaging and onboarding quick wins | [plan](025-messaging-and-onboarding-quick-wins/plan.md) |
| 026 | 2026-06-07 | merged | Domain Cucumber convergence | [plan](026-domain-cucumber-convergence/plan.md) |
| 027 | 2026-06-06 | merged | Membership Administrator role foundation | [plan](027-membership-administrator-role/plan.md) |
| 028 | 2026-06-08 | merged | Staff member invitations with profile completion | [plan](028-staff-member-invitations/plan.md) |
| 029 | 2026-06-08 | merged | Membership Admin invitations | [plan](029-membership-admin-invitations/plan.md) |
| 030 | 2026-06-08 | merged | Verified public onboarding requests | [plan](030-verified-onboarding-requests/plan.md) |
| 031 | 2026-06-08 | merged | Brand, email, and navigation polish | [plan](031-brand-email-navigation-polish/plan.md) |
| 032 | 2026-06-13 | merged | Auth email delivery progress | [plan](032-auth-email-delivery-progress/plan.md) |
| 033 | 2026-06-13 | merged | Homepage staff bar | [plan](033-homepage-staff-bar/plan.md) |
| 034 | 2026-06-17 | merged | Member page design-system alignment | [plan](034-member-page-design-system-alignment/plan.md) |
| 035 | 2026-06-17 | merged | Obliterate the deprecated "opened" delivery status | [plan](035-obliterate-opened-delivery-status/plan.md) |
| 036 | 2026-06-17 | merged | Design-system catch-up: member management & auth check-email | [plan](036-ds-catchup-member-management-and-auth/plan.md) |
| 037 | 2026-06-17 | merged | Design-system catch-up: onboarding requests + empty states & member refresh | [plan](037-ds-catchup-onboarding-requests-and-refresh/plan.md) |
| 038 | 2026-06-19 | merged | Async email delivery dispatch | [plan](038-email-delivery-handoff-boundary/plan.md) |
| 039 | 2026-06-19 | merged | Club message conversations and replies | [plan](039-club-message-threads-and-in-app-replies/plan.md) |
| 040 | 2026-06-19 | merged | Follow a conversation, send replies to followers | [plan](040-thread-follow-and-reply-notification-emails/plan.md) |
| 041 | 2026-06-19 | merged | Reply by email | [plan](041-reply-by-email-threading/plan.md) |
| 042 | 2026-06-21 | merged | Club email subdomains | [plan](042-club-email-subdomains/plan.md) |
| 043 | 2026-06-22 | merged | Conversations overview: group replies with a reply count | [plan](043-conversations-overview-grouping/plan.md) |
| 044 | 2026-07-04 | merged | Shared member app-shell: app-bar + app-card frame (plan replaced 2026-07-04 against refreshed design) | [plan](044-shared-app-shell/plan.md) |
| 045 | 2026-07-04 | merged | Club home: Conversations / Members section tabs (slot repurposed 2026-07-04; prior stop-following plan in git history) | [plan](045-club-home-section-tabs/plan.md) |
| 046 | 2026-07-04 | merged | Conversation page: follow toggle, replies-first, message timestamps (slot repurposed 2026-07-04) | [plan](046-conversation-page-alignment/plan.md) |
| 047 | 2026-07-04 | merged | Delivery details page + relocate delivery off the conversation | [plan](047-conversation-delivery-details/plan.md) |
| 048 | 2026-07-04 | merged | Club home Members: named member rows (role badges deferred to 049) | [plan](048-named-member-rows/plan.md) |
| 049 | 2026-07-07 | merged | Club home Members: role badges | [plan](049-member-role-badges/plan.md) |
| 050 | 2026-07-09 | merged | Club home conversation & member-list fidelity fixes | [plan](050-club-home-conversation-and-member-row-fidelity/plan.md) |
| 051 | 2026-07-09 | merged | Club home: conversation participant avatar-stack | [plan](051-conversation-participant-avatar-stack/plan.md) |
| 052 | 2026-07-09 | merged | Desktop member app design-system alignment | [plan](052-desktop-member-app-design-alignment/plan.md) |
| 053 | 2026-07-11 | merged | My settings email-address management | [plan](053-my-settings-email-addresses/plan.md) |
| 054 | 2026-08-13 | validated | Members change their own name | [plan](054-member-name-editing/plan.md) |
| 055 | 2026-08-13 | draft | Members set their own profile photo | [plan](055-member-profile-photo/plan.md) |

Status notes:

- `draft` means a captured plan still needs human review before validation or implementation.
- `ready` means a human-approved plan is waiting for validation or implementation.
- `validated` means plan validation has passed; it may wait while another iteration is active.
- `implementing`, `ready-for-review`, `in-review`, `reviewing`, and `finalizing` occupy the single implementation WIP slot.

Shared acceptance feature files used across these iterations:

- [`authentication.feature`](../../acceptance-tests/features/authentication.feature) (iteration 032 adds `@iteration-032 @todo-domain @todo-ui` planning scenarios for privacy-preserving auth email delivery progress)
- [`member_message_deliverability.feature`](../../acceptance-tests/features/member_message_deliverability.feature) (iteration 017 removes opened receipt expectations; iteration 019 adds `@todo-domain`/`@todo-ui` inbound club-message email scenarios until delivery implements Resend inbound handling; iteration 020 reuses these scenarios for Postmark migration without feature changes; iteration 025 adds `@todo-domain`/`@todo-ui` scenarios for slugged email subjects and blank-body compose validation; iteration 042 changes the inbound address convention to `everyone@<club>.clubs.memba.io`)
- [`memba_staff_email_deliverability.feature`](../../acceptance-tests/features/memba_staff_email_deliverability.feature) (iteration 017 removes opened receipt expectations; iteration 007 remodels this as a deliveries overview across messages; browser Cucumber automation is iteration 006)
- [`staff_club_slugs.feature`](../../acceptance-tests/features/staff_club_slugs.feature) (`@todo-domain`/`@todo-ui` for iteration 015 planning until staff slug management and public club subdomain routing are implemented)
- [`person_email_addresses.feature`](../../acceptance-tests/features/person_email_addresses.feature) (`@todo-domain`/`@todo-ui` planning scenarios for iteration 016 until the person email-address model and staff/member behaviours are implemented; iteration 053 adds `@iteration-053 @todo-domain @todo-ui` member Account settings and email-address verification scenarios until self-service settings/verification behaviour is implemented)
- [`member_club_subdomains.feature`](../../acceptance-tests/features/member_club_subdomains.feature) (`@todo-domain`/`@todo-ui` planning scenarios for iteration 018 until member-facing club subdomain routing and navigation are implemented; iteration 031 adds an `@not-domain @todo-ui` public club-page link back to Memba scenario)
- [`memba_staff_operations.feature`](../../acceptance-tests/features/memba_staff_operations.feature) (`@todo-domain`/`@todo-ui` planning scenarios for iteration 021 until the redesigned staff operations pages, global People page, and global Messages page are implemented)
- [`request_account.feature`](../../acceptance-tests/features/request_account.feature) (`@todo-domain`/`@todo-ui` planning scenarios for iteration 022 until staff-approved request-to-club onboarding is implemented; iteration 025 adds an `@todo-domain`/`@todo-ui` scenario for opening request conversion from the staff notification email; iteration 030 adds `@iteration-030 @todo-domain @todo-ui` scenarios for verified public onboarding requests)
- [`club_membership_administration.feature`](../../acceptance-tests/features/club_membership_administration.feature) (`@todo-domain`/`@todo-ui` planning scenarios for iteration 027 until the Membership Administrator role and permission foundation is implemented)
- [`club_member_invitations.feature`](../../acceptance-tests/features/club_member_invitations.feature) (`@iteration-028` with `@todo-domain`/`@todo-ui` planning scenarios until Staff invitation and profile-completion behaviour is implemented; iteration 029 adds `@iteration-029` Membership Admin invitation scenarios under the same temporary runner-debt tags until member-admin invitation behaviour is implemented)
- [`homepage.feature`](../../acceptance-tests/features/homepage.feature) (iteration 031 adds an `@not-domain @todo-ui` homepage volunteering-vision scenario)
- [`email_branding.feature`](../../acceptance-tests/features/email_branding.feature) (iteration 031 adds `@todo-domain @todo-ui` planning scenarios for sign-in email branding and club rejection email sender/footer polish)
- [`club_message_replies.feature`](../../acceptance-tests/features/club_message_replies.feature) (iterations 039 and 040 implement conversation replies and follower-only reply notifications; iteration 041 plans header-routed reply-by-email scenarios using standard `Message-ID` / `In-Reply-To` / `References` matching while preserving bare club-address new-message behaviour; iteration 042 moves the visible reply destination to `everyone@<club>.clubs.memba.io`)
- [`list_members.feature`](../../acceptance-tests/features/list_members.feature) (`@iteration-049 @todo-domain @todo-ui` planning scenarios for member-list role badges and removed-member exclusion until implementation adds domain/browser step support and makes them executable)
- [`member_profile.feature`](../../acceptance-tests/features/member_profile.feature) (new in iteration 054; self-service profile editing from `/my/settings`. Iteration 054 adds `@iteration-054 @todo-domain @todo-ui` scenarios for changing your own name; iteration 055 adds `@iteration-055 @todo-domain @todo-ui` scenarios for adding, replacing, and removing a profile photo, including upload rejection, upload failure, and signed-in-only photo visibility. Both sets stay excluded from the domain and browser runners until their iteration implements the steps)
