# Problems

## Email footers are inconsistent

Observed: 2026-06-06

Status: Resolved for current transactional templates by [iteration 024: Transactional email template redesign](../iterations/024-email-template-designs/plan.md) and [iteration 031: Brand, email, and navigation polish](../iterations/031-brand-email-navigation-polish/plan.md). Iteration 024 introduced shared `Memba.EmailTemplates` footer/trust-footer helpers for auth, onboarding welcome, member-message, and inbound-rejection email paths; iteration 031 standardised the sign-in and club-message rejection footer treatment touched by the brand-polish slice. Evidence: `web/test/memba/email_templates_test.exs`, `web/test/memba/accounts/auth_email_test.exs`, and `web/test/memba/messaging/inbound_club_rejection_email_test.exs`.

Emails sent by Memba do not all use the same footer style or content.

Expected:

- Memba emails use a consistent footer.
- People receiving emails get a predictable, recognisable experience across different Memba messages.
