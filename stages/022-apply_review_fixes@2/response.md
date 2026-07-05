Implemented/verified the synthesized repair brief for iteration 045.

No new working-tree changes were needed in this pass: the current checkout already contains the bounded review repairs for all three synthesized blockers, and I verified them directly.

## Issue-to-fix mapping

| Review issue | Status | Files/modules/tests addressing it |
|---|---:|---|
| `fix-club-home-tab-state-js` — Make tab active-state JS idempotent | Addressed | `web/lib/memba_web/controllers/page_html.ex` uses `JS.remove_class("is-active", ...)`, not `JS.toggle_class`, before activating the selected tab. |
| `fix-club-home-tab-aria-relationships` — Complete tab/panel ARIA relationships | Addressed | `web/lib/memba_web/controllers/page_html/club.html.heex` has tab IDs, `aria-controls`, panel `role="tabpanel"`, and panel `aria-labelledby`. |
| `fix-club-home-tab-js-coverage` — Add targeted regression coverage for tab JS wiring | Addressed | `web/test/memba_web/live/member_dashboard_live_test.exs` decodes rendered `phx-click` JS and asserts `remove_class`, expected panel/action show-hide wiring, `aria-selected` updates, and absence of `toggle_class` / `push`. |

## Files changed

None in this pass.

Verified existing repaired files:

- `web/lib/memba_web/controllers/page_html.ex`
- `web/lib/memba_web/controllers/page_html/club.html.heex`
- `web/test/memba_web/live/member_dashboard_live_test.exs`

No acceptance feature files were edited.

## Tests run

- `PATH="$PWD/bin:$PATH" dev check --quick`

Result:

- Passed
- `925 tests, 0 failures`

## Remaining gaps / human questions

None for the synthesized review blockers. Full browser acceptance was not rerun in this pass because no new diff was produced; the quick project quality gate passed on the current repaired state.