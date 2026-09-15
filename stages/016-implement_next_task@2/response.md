Task 015 is implemented and ready for independent review.

Selected todo line:

`- [ ] 015 Test replay does not resend welcomes, already-open views update, and existing invitation/role behaviour is unchanged.`

Changes made:

- Added projection-replay coverage in [member_dashboard_admission_live_test.exs](/workspace/memba/web/test/memba_web/live/member_dashboard_admission_live_test.exs:109). It confirms that:
  - A genuine admission sends one welcome.
  - Membership projections rebuild successfully from retained events.
  - Replaying the admission does not send another welcome.
- Added an already-open LiveView test in [member_dashboard_admission_live_test.exs](/workspace/memba/web/test/memba_web/live/member_dashboard_admission_live_test.exs:152). Carol’s open nonmember view receives the committed read-model change and immediately gains the participating UI, member row, and updated count without navigation or reload.
- Added invitation and role regression coverage in [add_custom_group_member_dispatch_test.exs](/workspace/memba/web/test/memba/membership/add_custom_group_member_dispatch_test.exs:345). It proves custom-group admission:
  - Leaves an existing pending club invitation unchanged.
  - Leaves club-member roles unchanged.
  - Does not grant the target club-management permission.

Focused validation passed:

- `PATH="$PWD/bin:$PATH" dev test test/memba/membership/add_custom_group_member_dispatch_test.exs test/memba_web/live/member_dashboard_admission_live_test.exs`
  - 15 tests, 0 failures.
- `PATH="$PWD/bin:$PATH" dev acceptance --tags '@iteration-063'`
  - 12 scenarios passed, 96 steps passed.
- `mix format --check-formatted test/memba/membership/add_custom_group_member_dispatch_test.exs test/memba_web/live/member_dashboard_admission_live_test.exs`
  - Passed.
- `git diff --check`
  - Passed.

The selected line remains unchecked as required:

```markdown
- [ ] 015 Test replay does not resend welcomes, already-open views update, and existing invitation/role behaviour is unchanged.
```

No todo lines were split, added, reordered, or checked. Full `dev check` was not run because it remains the separate explicit task 016.

ADR conformance:

- ADR 0002/0009: replay coverage rebuilds Ecto projections from retained event history and verifies public query state.
- ADR 0003: the existing shared iteration-063 scenarios remain intact and passed through the browser runner.
- ADR 0007: regression assertions use Membership’s public APIs rather than reaching across bounded-context internals.
- ADR 0013/0015: already-open member UI behavior is exercised through a connected LiveView.
- ADR 0021: the open-view test uses the real committed read-model PubSub notification path.
- ADR 0022: replay validation captures projector positions and waits on projection barriers rather than polling.
- ADR 0024: club roles and permissions remain governed by the Club consistency boundary and are unchanged by custom-group admission.