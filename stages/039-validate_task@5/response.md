### Decision

**VALID**

### Evidence

- **Completed todo/check-off evidence found.**
  - Worktree is clean in `/tmp/fabro-pre-validate-snapshot.md` and live `git status --short`, which is acceptable under the Fabro checkpoint contract.
  - Recent implement checkpoint `f1edba3 fabro(...): implement_next_task (succeeded)` changed exactly one ordinary todo line:
    - `005 Adjust shared member app layout/footer rendering so authenticated member app pages use only the compact app footer and public/marketing/legal pages keep the full public footer.`
    - from `- [ ]` to `- [x]`.
  - Parent todo state had tasks `001`–`004` checked and `005` as the first unchecked task.
  - Current `todo.md` has `005` checked and `006` as the next unchecked task; no todo deletion, weakening, split, or reorder was found.

- **Implementation artifacts found.**
  - `web/lib/memba_web/router.ex`
    - Adds `plug :suppress_public_footer` to the authenticated `:club_member_required` pipeline.
    - The plug assigns `:hide_public_footer` for authenticated member app routes.
  - `web/lib/memba_web/components/layouts.ex`
    - Replaces prior message-detail path-specific footer suppression with conn-assign-based suppression.
    - Root layout now hides the full public footer when `conn.assigns.hide_public_footer == true`.
  - `web/test/memba_web/components/layouts_test.exs`
    - Adds coverage that member app chrome suppresses the public footer while preserving compact footer content.
    - Adds coverage that public pages keep the full public footer by default.
  - `web/test/memba_web/live/member_dashboard_live_test.exs`
    - Adds routed `/conversations` and `/members` assertions that authenticated member app pages render one compact footer and no public footer.
  - `git show --name-only f1edba3` shows no acceptance feature files were edited.

- **Tests run/results found.**
  - Implementation summary reported:
    - focused layout/dashboard tests passed;
    - `dev check` passed.
  - Validator reran focused tests live:
    - `PATH="$PWD/bin:$PATH" dev test test/memba_web/components/layouts_test.exs test/memba_web/live/member_dashboard_live_test.exs`
    - Result: `40 tests, 0 failures`.
  - Worktree remained clean after validation.

- **ADR/plan conformance notes.**
  - Matches plan task `005` and acceptance criterion: authenticated member app pages no longer render the full public footer below the compact `Powered by Memba` footer, while public pages retain it.
  - Scope remains presentation/layout-only; no new routing semantics, permissions, data model, migrations, commands/events/projections, notifications, or email behaviour were introduced.
  - ADR 0001 respected: implementation remains within Phoenix/Plug/layout conventions.
  - ADR 0013 respected: user-visible rendered/LiveView behaviour is covered by Phoenix tests.
  - ADR 0015 respected: member app surfaces remain LiveView-backed and share member app chrome.
  - ADR 0023 unaffected: no URL-addressable LiveView state or navigation semantics changed.

{"context_updates":{"task_valid":true,"task_retry_available":false}}