Implemented task 011.

1. **Selected todo line**
   - `- [ ] 011 Implement live validity/availability feedback for staff slug editing, either in LiveView or via a small admin-only validation endpoint.`

2. **Changes made**
   - Updated `web/lib/memba_web/live/admin/clubs_live/show.ex`:
     - Added `phx-change="validate_club_slug"` to the admin edit-club form.
     - Added live slug feedback with `#edit-club-slug-feedback`.
     - Shows statuses via `data-status="invalid" | "taken" | "available"`.
     - Checks slug validity with `Memba.Membership.Slug.validate/1`.
     - Checks availability with `Membership.get_club_by_slug/1`, allowing the current club’s own slug.
     - Disables `#update-club-button` when the slug is invalid or already taken.
     - Preserves feedback after stale/bypassed invalid submissions.
   - Updated `web/test/memba_web/live/admin/clubs_live/show_test.exs`:
     - Added tests for live invalid slug feedback and disabled save button.
     - Added tests for live duplicate slug feedback and disabled save button.
     - Added tests that a valid/available slug re-enables save.
   - Updated `docs/iterations/015-club-slugs/todo.md`:
     - Checked off only task 011.

3. **Validation commands run**
   - `cd web && mix format --check-formatted` — passed.
   - `git diff --check` — passed.
   - `PATH="$PWD/bin:$PATH" dev check` — passed after final check-off:
     - `289 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 011 Implement live validity/availability feedback for staff slug editing, either in LiveView or via a small admin-only validation endpoint.`
   - To:
     - `- [x] 011 Implement live validity/availability feedback for staff slug editing, either in LiveView or via a small admin-only validation endpoint.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No accepted ADR files were present under `docs/adr/` beyond the template.
   - Kept slug validation and lookup behavior inside the Membership bounded context.
   - Did not change aggregate identity or Commanded/event-sourcing flow.
   - Followed local LiveView/HEEx guidance: explicit DOM IDs, `to_form/2`, `phx-change`, and selector-based LiveView tests.
   - Did not edit locked acceptance feature files.