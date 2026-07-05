Implemented the bounded review-repair changes for iteration 045.

## Issue-to-fix mapping

| Review issue | Status | Fix / proof |
|---|---:|---|
| `idempotent-tab-state-js` — make tab active-state JS idempotent | Addressed | Current implementation already used `JS.remove_class("is-active", ...)` rather than `JS.toggle_class(...)`. I strengthened regression coverage so this invariant is now asserted structurally from rendered `phx-click` JS commands. |
| `complete-tab-aria-relationships` — add explicit ARIA tab-panel relationships | Fixed | Added `role="tabpanel"` and matching `aria-labelledby` attributes to both section panels. Existing tabs already had stable IDs and `aria-controls`. |
| `tab-js-regression-coverage` — targeted regression coverage for tab JS wiring | Fixed | Updated the dashboard LiveView test to decode and assert the rendered `Phoenix.LiveView.JS` operation list, including `remove_class`, `add_class`, `aria-selected`, panel/action show-hide wiring, and explicit absence of `toggle_class` / `push`. |

## Files changed

### `idempotent-tab-state-js` / `tab-js-regression-coverage`

- `web/test/memba_web/live/member_dashboard_live_test.exs`
  - Replaced broad substring assertions on `phx-click` with decoded `Jason` assertions against the LiveView JS command list.
  - Verifies each tab:
    - removes `is-active` from all section tabs first
    - adds `is-active` only to the selected tab
    - resets and sets `aria-selected`
    - hides/shows the right panel
    - hides/shows the right per-tab action
    - does not use `toggle_class`
    - does not push a server event

### `complete-tab-aria-relationships`

- `web/lib/memba_web/controllers/page_html/club.html.heex`
  - Added:
    - `role="tabpanel"`
    - `aria-labelledby="member-section-tab-conversations"`
    - `aria-labelledby="member-section-tab-members"`

- `web/test/memba_web/live/member_dashboard_live_test.exs`
  - Strengthened default tab spine assertions to require those panel ARIA relationships.

## Validation run

Passed:

- `cd web && mix format lib/memba_web/controllers/page_html/club.html.heex test/memba_web/live/member_dashboard_live_test.exs`
- `cd web && MIX_ENV=test mix compile`

Blocked by sandbox/runtime issue:

- Attempted targeted test:

  ```sh
  PATH="$PWD/bin:$PATH" sh -c 'cd web && mix test test/memba_web/live/member_dashboard_live_test.exs'
  ```

  It failed before running tests because Postgres was started on:

  ```text
  /tmp/devenv-1d7df38/postgres/.s.PGSQL.15432
  ```

  while the readiness check expected:

  ```text
  /tmp/devenv/postgres
  ```

  Error:

  ```text
  Postgres did not become ready at PGHOST=/tmp/devenv/postgres PGPORT=15432
  ```

Per the sandbox/runtime boundary rule, I stopped there and did not patch product code, `bin/dev`, scripts, dependencies, or tests to compensate for the stale/incoherent runtime path.

## Dev check

Not run after the repair because the targeted test command exposed a sandbox Postgres socket/path blocker. I am **not** reporting `dev check` as passing for this repaired diff.

## Remaining gaps / human questions

- The code compiles and the bounded repair is applied, but the repaired diff still needs a clean runtime to run:
  - targeted `member_dashboard_live_test.exs`
  - required `dev check`
- No acceptance feature files were edited.