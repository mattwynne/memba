# Implementation TODO

- [x] 001 Inspect the current homepage template/component and identify the smallest copy/template change that restores the volunteering-first hero.
  - Inspection result: the logged-out homepage hero lives in `web/lib/memba_web/controllers/page_html/home.html.heex` lines 157-165, with a matching logged-out `page_title` in `web/lib/memba_web/controllers/page_controller.ex` line 55. The smallest behaviour change is to replace only the logged-out hero heading/page title copy with `Volunteering shouldn’t feel like work.` and keep nearby copy honest/current by retaining the existing volunteer-run eyebrow plus a concise subheadline about private member messages for volunteer-run clubs. The signed-in `Your clubs` branch should remain unchanged.
- [x] 002 Update homepage tests or browser acceptance support so the volunteering promise is asserted without depending on fragile layout details.
- [x] 003 Inspect the transactional email layout/helpers from iteration 024 and identify the canonical footer component or helper.
  - Inspection result: iteration 024 added the shared transactional email rendering layer in `web/lib/memba/email_templates.ex` (`Memba.EmailTemplates`). The canonical standard footer helper for non-auth transactional emails is `EmailTemplates.memba_footer/1`, passed as the `:footer` to `EmailTemplates.render_shell/1`; current uses include member-message HTML (`web/lib/memba/messaging/member_message_email.ex`), inbound rejection HTML (`web/lib/memba/messaging/inbound_club_rejection_email.ex`), and member invitation HTML (`web/lib/memba/membership/club_member_invitation_email.ex`). Sign-in/welcome auth-style emails currently use `EmailTemplates.trust_footer/1` plus local per-template footer rows (`auth_footer/1` / `welcome_footer/1`), so the later footer-standardisation tasks should use the shared `memba_footer/1` treatment where the plan asks for a standard footer while preserving the auth trust footer when needed.
- [ ] 004 Replace the sign-in email icon with the Memba sprig asset/component used elsewhere in Memba branding.
- [ ] 005 Ensure the sign-in email uses the standard transactional email footer.
- [ ] 006 Inspect inbound club-message rejection email construction and the email request/provider shape for display-name support.
- [ ] 007 Change the club-message rejection email sender/display name to `<club name> via Memba` while preserving sender address, reply-to/support guidance, and rejection content.
- [ ] 008 Ensure the club-message rejection email uses the standard transactional email footer.
- [ ] 009 If the footer is already centralized, migrate any remaining current transactional templates to it with focused tests. Do not redesign templates.
- [ ] 010 Inspect public club-page template/layout and add a clear link to the main Memba homepage.
- [ ] 011 Ensure the homepage link resolves to the root Memba host when rendered from a club subdomain.
- [ ] 012 Add or update template/unit/LiveView/browser tests for the homepage copy, public club-page Memba link, sign-in email icon/footer, rejection sender name, and rejection footer.
- [ ] 013 Remove or narrow `@todo-*` tags from the planned acceptance scenarios once their runners can execute them meaningfully.
- [ ] 014 Run focused tests for changed web templates/components and email rendering.
- [ ] 015 Run the affected acceptance tests if executable.
- [ ] 016 Run `dev check`.
