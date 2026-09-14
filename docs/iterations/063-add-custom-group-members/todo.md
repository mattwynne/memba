# Implementation TODO

- [x] 001 Add a public authenticated custom-group admission use case and actor-bearing command handled by `Membership.Club`.
- [x] 002 Evaluate actor active club membership, actor group membership or existing admin permission, target active membership and custom-group identity against current aggregate state.
- [x] 003 Preserve trusted system-group commands rather than exposing them directly to web callers.
- [x] 004 Reuse `GroupMemberAdded` and the existing projection.
- [x] 005 Make duplicate addition an idempotent no-op and carry sufficient actor/new-transition information for the welcome use case.
- [x] 006 Respect the departure/rejoin cleanup introduced in 062; no projection-only mutation or restoration shortcut.
- [x] 007 Extend `MemberDashboardPresentation`, shared member components and the group Members surface with the picker and admin self-add.
- [x] 008 Use explicit component attributes/slots, not a copied full-page template.
- [x] 009 Query candidates through Membership's public API, reauthorize on submit and render fresh membership after a successful transition.
- [ ] 010 Add a small provider-neutral group-welcome composer using `Memba.EmailTemplates` and the existing `Memba.Mailer` handoff conventions.
- [ ] 011 Send only after a confirmed new membership transition, not on projection replay, duplicate requests or ordinary group reads.
- [ ] 012 Keep provider side effects out of aggregates/projectors; committed membership must not be represented as rolled back if delivery fails.
- [ ] 013 Reuse default operational/error handling; do not build a notification framework, bespoke retry UI or delivery-status feature.
- [ ] 014 Implement the tagged admission/history scenarios, including outside-admin self-add, duplicate additions, inactive/cross-club targets and system-group bypass attempts.
- [ ] 015 Test replay does not resend welcomes, already-open views update, and existing invitation/role behaviour is unchanged.
- [ ] 016 Run `dev check` on the exact delivery state.
