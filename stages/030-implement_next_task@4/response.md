Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `004 Replace member initials avatars with <.avatar>, including the club-home stack and "+N".`

2. **Changes made**
   - Updated `web/lib/memba_web/controllers/page_html/club.html.heex`:
     - Replaced the message sender initials `<span>` with `<.avatar>`.
     - Replaced the first-member empty-state initials markup with `<.avatar>`.
     - Replaced the active-member avatar stack entries with `<.avatar>`.
     - Replaced the `+N` overflow marker with `<.avatar initials={"+N"} ...>`.
     - Preserved existing IDs, `data-testid`, member IDs/names, and titles for selectors and accessibility.
   - Updated `web/test/memba_web/live/member_dashboard_live_test.exs`:
     - Existing dashboard assertions now verify `avatar avatar-placeholder` classes.
     - Added coverage for the active-member stack overflow avatar rendering `+1` through the shared avatar component.

3. **Validation run**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba_web/controllers/page_html/club.html.heex test/memba_web/live/member_dashboard_live_test.exs` — passed.
   - `devenv shell -- bash -lc 'cd web && mix test test/memba_web/live/member_dashboard_live_test.exs'` — passed: `17 tests, 0 failures`.
   - `git diff --check` — passed.
   - `PATH="$PWD/bin:$PATH" dev check` — passed, including acceptance: `82 scenarios (82 passed), 493 steps (493 passed)`.
   - `PATH="$PWD/bin:$PATH" dev down` — completed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Replace member initials avatars with <.avatar>, including the club-home stack and "+N".`
   - to:
     - `- [x] 004 Replace member initials avatars with <.avatar>, including the club-home stack and "+N".`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan does not explicitly reference an ADR.
   - Inspected current ADRs; ADR 0015 (“Use LiveView for member application pages”) remains respected.
   - This task changed the existing member dashboard LiveView-rendered template/tests only; no new controller-rendered member app surface, route pattern, or acceptance feature changes were introduced.