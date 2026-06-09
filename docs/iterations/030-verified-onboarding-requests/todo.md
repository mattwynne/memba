# Implementation TODO

- [x] 001 Inspect the current `/get-started` controller/templates or LiveView, auth sign-in token creation, return-to handling, Staff request inbox, and onboarding request creation/notification code.
- [x] 002 Split the public Get Started experience into two states:
- [x] 003 Reuse the existing magic-link sign-in flow for the signed-out email-only step, setting return-to back to the Get Started request form.
- [x] 004 Ensure following the magic link returns the requester to Get Started and assigns `current_identity` for the verified email.
- [x] 005 Update request form rendering:
- [ ] 006 Update request submission so it requires a signed-in identity email and never trusts a typed requester email for Staff-visible requests.
- [ ] 007 Ensure email-only verification requests do not create onboarding request records or Staff notifications.
- [ ] 008 Ensure verified request submission does not create Person, club, membership, or club access.
- [ ] 009 Preserve Staff request inbox and notification behaviour for verified submitted requests.
- [ ] 010 Preserve Staff conversion/rejection semantics for verified submitted requests, including creating/reusing the Person during conversion.
- [ ] 011 Add or update controller/LiveView tests for signed-out email-only step, magic-link return-to, verified identity with no Person, verified identity with existing Person, and no Staff visibility before verification.
- [ ] 012 Add or update domain/context tests proving request creation requires a verified identity email and does not create membership-domain records.
- [ ] 013 Update Cucumber step definitions only as needed during delivery to exercise the `@iteration-030` scenarios.
- [ ] 014 Remove or narrow `@todo-domain`/`@todo-ui` from the new/updated scenarios only when they pass in the relevant runner.
- [ ] 015 Run `dev check`.
