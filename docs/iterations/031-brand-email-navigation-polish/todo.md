# Implementation TODO

- [x] 001 Inspect the current homepage template/component and identify the smallest copy/template change that restores the volunteering-first hero.
- [x] 002 Update homepage tests or browser acceptance support so the volunteering promise is asserted without depending on fragile layout details.
- [x] 003 Inspect the transactional email layout/helpers from iteration 024 and identify the canonical footer component or helper.
- [x] 004 Replace the sign-in email icon with the Memba sprig asset/component used elsewhere in Memba branding.
- [x] 005 Ensure the sign-in email uses the standard transactional email footer.
- [x] 006 Inspect inbound club-message rejection email construction and the email request/provider shape for display-name support.
- [x] 007 Change the club-message rejection email sender/display name to `<club name> via Memba` while preserving sender address, reply-to/support guidance, and rejection content.
- [x] 008 Ensure the club-message rejection email uses the standard transactional email footer.
- [x] 009 If the footer is already centralized, migrate any remaining current transactional templates to it with focused tests. Do not redesign templates.
- [x] 010 Inspect public club-page template/layout and add a clear link to the main Memba homepage.
- [x] 011 Ensure the homepage link resolves to the root Memba host when rendered from a club subdomain.
- [x] 012 Add or update template/unit/LiveView/browser tests for the homepage copy, public club-page Memba link, sign-in email icon/footer, rejection sender name, and rejection footer.
- [x] 013 Remove or narrow `@todo-*` tags from the planned acceptance scenarios once their runners can execute them meaningfully.
- [x] 014 Run focused tests for changed web templates/components and email rendering.
- [ ] 015 Run the affected acceptance tests if executable.
- [ ] 016 Run `dev check`.
