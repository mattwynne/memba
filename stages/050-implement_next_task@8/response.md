Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `008 Decommission direct Staff club-member creation from name/email by hiding/removing that action or redirecting it to the invite route. Keep person edit behaviour where still needed for existing people.`

2. **Changes made**
   - Removed the Staff club detail “Add member” form/select/button from `web/lib/memba_web/live/admin/clubs_live/show.ex`.
   - Kept the existing “Invite member” route/link and added a clear “Invitation required” notice.
   - Left a defensive `add_member` LiveView event handler that redirects stale/direct submissions to `/admin/clubs/:club_id/invitations/new` without creating membership.
   - Preserved existing people/person edit behaviour and links.
   - Updated `PeopleLive.New` copy so it no longer tells staff to add active memberships directly from the club page.
   - Updated tests:
     - `show_test.exs` now proves the direct add form is gone, invite link is present, stale `add_member` submission redirects, and no membership is created.
     - `admin_people_live_test.exs` now proves creating a person record does not make them an active club member.
     - `browser_acceptance_harness_test.exs` now expects the invitation notice and no direct add-member controls; harness setup uses the Membership API directly instead of removed Staff UI controls.

3. **Validation run**
   - Formatting:
     - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba_web/live/admin/clubs_live/show.ex lib/memba_web/live/admin/people_live/new.ex test/memba_web/live/admin/clubs_live/show_test.exs test/memba_web/live/admin_people_live_test.exs test/memba_web/live/browser_acceptance_harness_test.exs`
     - Passed.
   - Focused tests:
     - Initial preferred wrapper hit the known sandbox Postgres readiness/socket issue.
     - Reran with:
       - `devenv shell -- bin/mix test test/memba_web/live/admin/clubs_live/show_test.exs test/memba_web/live/admin_people_live_test.exs test/memba_web/live/browser_acceptance_harness_test.exs test/memba_web/live/admin/club_member_invitations_live/new_test.exs`
     - Passed: `23 tests, 0 failures`.
   - Full gate, required because this changed browser-facing LiveView/UI behaviour:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed; acceptance output ended with `62 scenarios (62 passed)`.
   - Whitespace:
     - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 008 Decommission direct Staff club-member creation from name/email by hiding/removing that action or redirecting it to the invite route. Keep person edit behaviour where still needed for existing people.`
   - To:
     - `- [x] 008 Decommission direct Staff club-member creation from name/email by hiding/removing that action or redirecting it to the invite route. Keep person edit behaviour where still needed for existing people.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001: Changes remain in the Phoenix core app.
   - ADR 0015: Staff app surface remains LiveView-based.
   - ADR 0013: User-facing behaviour is covered with PhoenixTest/LiveView tests.
   - ADR 0007: Product UI no longer directly creates memberships; Membership public API usage added only in test harness setup where active memberships are required as fixtures.