# Implementation TODO

- [x] 001 Inspect the current homepage template/component and identify the smallest copy/template change that restores the volunteering-first hero.
  - Finding: the signed-out homepage hero is in `web/lib/memba_web/controllers/page_html/home.html.heex`. The smallest copy/template change is to replace the public hero `h1` text `A simpler way to keep your group members informed.` with `Volunteering shouldn’t feel like work.` and update the matching signed-out `page_title` in `web/lib/memba_web/controllers/page_controller.ex`; the existing eyebrow already says `Private member websites for volunteer-run groups` and the existing body copy already keeps the promise grounded in today's product.
- [x] 002 Update homepage tests or browser acceptance support so the volunteering promise is asserted without depending on fragile layout details.
- [x] 003 Inspect the transactional email layout/helpers from iteration 024 and identify the canonical footer component or helper.
  - Finding: iteration 024 introduced `Memba.EmailTemplates` in `web/lib/memba/email_templates.ex` as the shared transactional email rendering layer. The canonical standard footer helper is `EmailTemplates.memba_footer/1`, rendered through `EmailTemplates.render_shell/1`'s `:footer` option; it provides the ambient Memba baseline (`Delivered for <group> by Memba`, recipient/why/reply-to support lines, consistent border/padding/mark). `EmailTemplates.trust_footer/1` is a separate sign-in/welcome trust panel (`Secured by Memba`) that may sit above the standard footer but is not the standard footer itself.
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
