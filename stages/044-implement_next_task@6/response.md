Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `006 Sweep the four member pages for any remaining hardcoded hex; replace with tokens/daisyUI classes.`

2. **Changes made**
   - Replaced remaining non-token member UI colour utilities in scoped member pages:
     - `message.html.heex`: `bg-slate-100` → `bg-base-200` for the member receipt summary bar.
     - `member_message_live/new.ex`: replaced `emerald`, `rose`, and `sky` Tailwind colour-family utilities with Memba/daisyUI tokens:
       - success state: `bg-success-soft text-success ring-success/20`
       - error state: `border-error/20 bg-error-soft text-error ring-error/20`
       - recipient summary: `border-info/20 bg-info-soft text-base-content`, etc.
   - Added `web/test/memba_web/member_page_design_system_alignment_test.exs` to guard the four scoped member pages plus `Layouts.club_site` against:
     - hardcoded hex colours,
     - legacy `--club-site-*` variables,
     - legacy member palette utilities (`blue`, `emerald`, `rose`, `sky`, `slate` numeric colour classes).

3. **Validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba_web/controllers/page_html/message.html.heex lib/memba_web/live/member_message_live/new.ex test/memba_web/member_page_design_system_alignment_test.exs` — passed.
   - Scoped source searches for hardcoded hex / old `--club-site-*` / legacy palette classes — passed for member sources and `Layouts.club_site`.
   - Focused tests:
     - `devenv shell -- bash -lc 'cd web && mix test test/memba_web/member_page_design_system_alignment_test.exs test/memba_web/live/member_message_live/new_test.exs test/memba_web/live/member_message_live/show_test.exs'`
     - Result: `18 tests, 0 failures`.
   - `git diff --check` — passed.
   - Final full gate on exact final worktree diff:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: `802 tests, 0 failures`; `82 scenarios (82 passed), 493 steps (493 passed)`.
   - `PATH="$PWD/bin:$PATH" dev down` — completed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 006 Sweep the four member pages for any remaining hardcoded hex; replace with tokens/daisyUI classes.`
   - to:
     - `- [x] 006 Sweep the four member pages for any remaining hardcoded hex; replace with tokens/daisyUI classes.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No ADR was explicitly referenced by the plan.
   - Checked relevant accepted ADRs:
     - ADR 0015: retained existing LiveView/member-page structure; this was a presentational token/class sweep only.
     - ADR 0006: did not change delivery-status vocabulary or staff delivery views.
     - ADR 0018: used `dev check`/`dev down` service workflow without changing service orchestration.