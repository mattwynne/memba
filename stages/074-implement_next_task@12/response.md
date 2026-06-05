Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `011 Restyle person new/edit pages enough that they feel part of the redesigned staff area; preserve existing behaviour.`

2. **Changes made**
   - Updated `web/lib/memba_web/live/admin/people_live/new.ex`
     - Restyled the new-person page to match the staff operations shell.
     - Added a page header, workflow summary cards, a form card, a club context card, and workflow guidance.
     - Preserved existing person creation form IDs/events/behaviour.
   - Updated `web/lib/memba_web/live/admin/people_live/edit.ex`
     - Restyled the edit-person page consistently with the staff area.
     - Clarified that the edit flow preserves existing email-address editing behaviour and keeps the person name read-only.
     - Preserved existing save/validate/add/remove email-address behaviours.
   - Updated `web/test/memba_web/live/admin_people_live_test.exs`
     - Added assertions for the new staff-area structure and stable selectors on new/edit pages.
   - Updated `docs/iterations/021-staff-area-redesign/todo.md`
     - Checked off only task `011`.

3. **Validation commands/results**
   - Formatting:
     - Initial `bin/mix format ...` and `devenv shell ... mix format ...` attempts could not rewrite root-owned workspace files.
     - Ran:
       - `PATH="$PWD/bin:$PATH" devenv shell -- bash -lc 'cd web && mix format --check-formatted lib/memba_web/live/admin/people_live/new.ex lib/memba_web/live/admin/people_live/edit.ex test/memba_web/live/admin_people_live_test.exs'`
       - Passed.
   - Focused tests:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bash -lc 'cd web && mix test test/memba_web/live/admin_people_live_test.exs'`
     - Passed: `5 tests, 0 failures`.
   - Full validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed:
       - ExUnit: `524 tests, 0 failures`
       - Acceptance: `34 scenarios (34 passed), 215 steps (215 passed)`
   - Whitespace:
     - `git diff --check`
     - Passed.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 011 Restyle person new/edit pages enough that they feel part of the redesigned staff area; preserve existing behaviour.`
   - To:
     - `- [x] 011 Restyle person new/edit pages enough that they feel part of the redesigned staff area; preserve existing behaviour.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001: Changes remain in Phoenix/LiveView.
   - ADR 0007: No Membership/Messaging boundary changes; this only restyles Membership staff person workflows.
   - ADR 0009: No projection or read-model plumbing changes.
   - ADR 0013: Browser-facing behaviour remains covered with feature-style web tests plus focused LiveView tests.