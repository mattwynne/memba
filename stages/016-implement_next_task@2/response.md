Implemented task 002.

1. **Selected todo line**
   - `002 Remove the --club-site-* layer: replace its variables/classes with sage tokens + daisyUI classes; simplify or retire the white-label parts of Layouts.club_site while keeping the member page chrome (header/footer) working in sage.`

2. **Changes made**
   - Removed the white-label theme plumbing from `Layouts.club_site`:
     - Deleted `:theme` attr.
     - Deleted `@club_site_theme_defaults`.
     - Deleted `club_site_theme_style/1`, `theme_value/3`, and `css_name/1`.
     - Removed inline `style={@theme_style}`.
   - Replaced all member/public club-site `--club-site-*` variable-based classes in source with canonical theme classes/tokens such as:
     - `bg-base-200`, `bg-base-100`
     - `text-base-content`, `text-ink-2`
     - `border-base-300`, `ring-base-300`
     - `bg-primary`, `text-primary`, `border-primary`
   - Updated all affected shared club-site/member surfaces that depended on the removed variables:
     - `Layouts.club_site`
     - club home template
     - member message detail template
     - member message compose LiveView
     - public club page LiveView
     - member invitation LiveView
     - member message fallback LiveView render
   - Updated `LayoutsTest` to assert:
     - the layout renders with canonical Memba/daisy theme classes;
     - no `--club-site-*` custom properties are emitted;
     - no `style` attribute is emitted on `#club-site-layout`.

3. **Focused validation run**
   - `bin/mix format ...` — passed after rerunning with web-relative paths.
   - Source greps:
     - `grep -R ... -- '--club-site' web/lib/memba_web` — no source matches.
     - `grep -R ... 'var(--club-site' web/lib/memba_web` — no source matches.
   - `git diff --check` — passed.
   - `devenv shell -- bash -lc 'cd web && mix test test/memba_web/components/layouts_test.exs'`
     - `4 tests, 0 failures`
   - `devenv shell -- bash -lc 'cd web && mix test ...member surface tests...'`
     - `50 tests, 0 failures`
   - Full browser-facing validation:
     - `PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 PATH="$PWD/bin:$PATH" dev check`
     - ExUnit: `798 tests, 0 failures`
     - Acceptance: `82 scenarios (82 passed), 493 steps (493 passed)`
   - Stopped managed dev processes afterward with `dev down`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 002 Remove the --club-site-* layer...`
   - to:
     - `- [x] 002 Remove the --club-site-* layer...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan does not explicitly reference any ADRs.
   - `docs/adr/**/*` has no ADR files in this checkout.
   - No acceptance feature files were changed.