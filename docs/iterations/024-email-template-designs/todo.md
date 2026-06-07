# Implementation TODO

- [x] 001 Inspect the v2 source artifacts in `docs/iterations/024-email-template-designs/source/` and current email-building modules/tests.
- [x] 002 Add shared helper module `web/lib/memba/email_templates.ex` (`Memba.EmailTemplates`) for the email HTML shell/components and text-safe helpers. Keep inline styles and avoid external CSS dependencies.
- [x] 003 Implement safe helpers in `Memba.EmailTemplates` for:
- [x] 004 Update `web/lib/memba/accounts/auth_email.ex` to render the new sign-in template while preserving provider options and error handling. Keep `deliver_sign_in_link/2`; add an optional context/options variant for group-led sign-in where callers can provide group name/context.
- [x] 005 Update sign-in call sites only where group context is already available or cheaply derivable, such as club-subdomain sign-in. When no group context is available, keep the Memba-led sign-in subject/heading.
- [x] 006 Update `web/lib/memba/onboarding/welcome_email.ex` to use the compatible group-led welcome/sign-in variant and pass the converted club as context.
- [x] 007 Update member-message delivery HTML in `web/lib/memba/messaging/email_delivery_providers/postmark.ex` and `web/lib/memba/messaging/email_delivery_providers/local.ex`, extracting shared rendering so both paths stay aligned. Keep plain-text member-message bodies exactly as the sender wrote them.
- [x] 008 Update `web/lib/memba/messaging/inbound_club_rejection_email.ex` to use the new delivery-notice template, subject rules, reason copy, next-step copy, threading headers, and metadata.
- [x] 009 Update tests, especially:
- [x] 010 Run targeted email-related tests while developing.
- [x] 011 Run any affected acceptance tests if mailbox text parsing changes.
- [x] 012 Run `dev check`.
- [ ] 013 Record implementation notes and any deliberate deviations from the supplied designs in this iteration folder.
