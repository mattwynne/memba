1. **Selected todo line and task text**
   - Selected original first unchecked task:
     - `003 Update Layouts.admin to the redesigned staff operations shell with working nav links: Clubs, People, Messages, Deliveries.`
   - Split because `/admin/people` and `/admin/messages` do not exist until the next plan task, so the “working links” part cannot honestly be completed before routes are added.

2. **Changes made**
   - Updated `web/lib/memba_web/components/layouts.ex`:
     - Replaced the compact top admin bar with a staff operations shell.
     - Added a left/sidebar-style staff rail with warm mockup-inspired styling.
     - Added iteration-021 nav entries only:
       - Clubs
       - People
       - Messages
       - Deliveries
     - Did **not** add Incoming or Roles.
     - Preserved existing sign-out form/button IDs and behavior.
     - Preserved `#admin-layout[data-surface="admin"]`.
   - Updated `web/test/memba_web/components/layouts_test.exs`:
     - Covers sidebar/content shell selectors.
     - Verifies the four staff nav links and labels.
     - Verifies absence of Incoming/Roles.
     - Verifies sign-out form still renders.
   - Updated `docs/iterations/021-staff-area-redesign/todo.md`:
     - Split task 003 into an implemented layout-shell slice and a later route-verification slice.

3. **Focused validation commands run and results**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba_web/components/layouts.ex test/memba_web/components/layouts_test.exs`
     - Passed.
   - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/components/layouts_test.exs'`
     - Passed: `4 tests, 0 failures`.
     - Used `devenv shell` here because the bare-shell `bin/mix` wrapper needed `pg_isready`, which was only available inside the devenv shell.
   - `git diff --check`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed after installing missing acceptance npm dependencies with:
       - `cd acceptance-tests && npm_config_cache=/tmp/memba-npm-cache npm ci`
     - Final result:
       - ExUnit: `513 tests, 0 failures`
       - Acceptance: `34 scenarios (34 passed), 215 steps (215 passed)`

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 003a Update Layouts.admin to the redesigned staff operations shell with the iteration-021 nav entries: Clubs, People, Messages, Deliveries.`
   - To:
     - `- [x] 003a Update Layouts.admin to the redesigned staff operations shell with the iteration-021 nav entries: Clubs, People, Messages, Deliveries.`

5. **Todo splits/additions/reordering**
   - Replaced original task 003 with:
     - `003a` implemented now: layout shell and nav entries.
   - Added:
     - `004a Route-verify the People and Messages staff nav links after /admin/people and /admin/messages exist so the original task-003 working-link requirement is fully satisfied.`
   - Kept existing task `004` as the next unchecked task, because it creates the missing `/admin/people` and `/admin/messages` routes needed before route-verifying those links.

6. **ADR conformance evidence**
   - Read and followed relevant accepted ADRs:
     - ADR 0001: Phoenix remains the core app surface.
     - ADR 0013: Updated Phoenix feature/component-style test coverage for user-visible web chrome.
     - ADR 0015: Kept admin app surface in LiveView-compatible Phoenix layout patterns.
   - Followed project Phoenix/HEEx/Tailwind guidance:
     - Used HEEx component layout.
     - Used `<.link>` and `<.form>` components.
     - Preserved stable DOM IDs for tests.
     - Did not add JavaScript, new dependencies, unsupported nav pages, or acceptance feature edits.