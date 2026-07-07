Implemented the review-gate repair items for iteration 048.

## Issue-to-fix mapping

| Review issue | Fix applied | Files |
|---|---|---|
| `test-member-row-helper` — Refactor member-row test assertions into bounded helpers | Replaced repeated long member-row selectors with focused helpers: `assert_rendered_member_row/3`, `assert_live_member_row/3`, and current-member state helpers. Helpers still verify row identity, design-system classes, visible name, initials, and “You” marker behavior. | `web/test/memba_web/live/member_dashboard_live_test.exs` |
| `audit-data-member-name` — Audit/remove test-only `data-member-name` duplication if unused | Audited usages and removed `data-member-name` from the club Members-tab markup where visible text and `data-member-id` already prove the intended behavior. Updated tests to assert visible names and explicitly refute `data-member-name` on active member rows/list. | `web/lib/memba_web/controllers/page_html/club.html.heex`, `web/test/memba_web/live/member_dashboard_live_test.exs` |

## Concrete changes

### `web/lib/memba_web/controllers/page_html/club.html.heex`
- Removed duplicate `data-member-name={member.name}` from:
  - the first-member empty-state avatar
  - each named member row
- Kept stable row identifiers:
  - `id="club-member-..."`
  - `data-testid="club-member-row"`
  - `data-member-id`
  - `data-current-member`

### `web/test/memba_web/live/member_dashboard_live_test.exs`
- Added member-row assertion helpers to reduce brittle repetition.
- Updated member-row assertions to use visible `.member-row__name` text instead of `data-member-name`.
- Added negative assertions proving `data-member-name` is no longer emitted in the active members list/rows.
- Preserved coverage for:
  - named rows
  - initials avatars
  - current member “You” marker
  - non-current member not marked “You”
  - member-list state/count attributes
  - invite action preservation
  - empty state preservation

## Tests run

- `cd web && mix format lib/memba_web/controllers/page_html/club.html.heex test/memba_web/live/member_dashboard_live_test.exs` — passed.
- `cd web && mix test test/memba_web/live/member_dashboard_live_test.exs` — failed because Postgres was not running at `/tmp/devenv/postgres/.s.PGSQL.15432`; no code changes were made for that runtime issue.
- `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs` — passed: `27 tests, 0 failures`.
- `PATH="$PWD/bin:$PATH" dev check` — passed: `85 scenarios, 523 steps`.

## Remaining gaps / human questions

- No remaining repair gaps for the selected review issues.
- `dev check` output included existing dependency advisory notices, but the quality gate exited successfully.
- Working tree has the intended source/test modifications plus pre-existing untracked `.fabro/tmp/`; no commits were made.