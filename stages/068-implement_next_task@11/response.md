Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 011 Ensure the homepage link resolves to the root Memba host when rendered from a club subdomain.`

2. **Changes made**
   - Added `MembaWeb.ClubSite.root_url/1` to build the root Memba host URL from the configured club-site base domain:
     - test/local: `http://lvh.me:4002/`
     - production-like `clubs.memba.io`: `https://memba.io/`
   - Updated public club-page Memba-home links to use `ClubSite.root_url()` instead of `~p"/"`:
     - `web/lib/memba_web/live/public_club_page_live.ex`
     - `web/lib/memba_web/components/layouts.ex`
   - Updated/added focused tests:
     - `web/test/memba_web/club_site_test.exs`
     - `web/test/memba_web/controllers/page_controller_test.exs`
     - `web/test/memba_web/components/layouts_test.exs`
   - Tests now assert that rendering from `kmc.lvh.me` points Memba-home links to `http://lvh.me:4002/`, not `/`.

3. **Validation commands/results**
   - Initial preferred wrapper command hit a local Postgres readiness/socket mismatch twice:
     - `PATH="$PWD/bin:$PATH" bin/mix test ...`
     - Result: failed before tests ran due Postgres readiness mismatch.
   - Started Postgres explicitly, then ran focused tests:
     - `devenv shell -- bash -lc 'real_mix=$(which -a mix | grep -v "$(pwd)/bin/mix" | head -1); cd web; "$real_mix" test test/memba_web/club_site_test.exs test/memba_web/controllers/page_controller_test.exs test/memba_web/components/layouts_test.exs'`
     - Result: `49 tests, 0 failures`
   - Format check:
     - `devenv shell -- bash -lc 'real_mix=$(which -a mix | grep -v "$(pwd)/bin/mix" | head -1); cd web; "$real_mix" format --check-formatted lib/memba_web/club_site.ex lib/memba_web/live/public_club_page_live.ex lib/memba_web/components/layouts.ex test/memba_web/club_site_test.exs test/memba_web/controllers/page_controller_test.exs test/memba_web/components/layouts_test.exs'`
     - Result: passed
   - Full required browser-facing validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: `758 tests, 0 failures`; `73 scenarios (73 passed)`
   - Whitespace:
     - `git diff --check`
     - Result: passed

4. **Todo check-off made**
   - Changed exactly:
     - from `- [ ] 011 Ensure the homepage link resolves to the root Memba host when rendered from a club subdomain.`
     - to `- [x] 011 Ensure the homepage link resolves to the root Memba host when rendered from a club subdomain.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0019 respected: URL generation remains based on the configurable club-site base domain; local/test keeps `lvh.me`, production-like `clubs.memba.io` maps root navigation to `memba.io`.
   - ADR 0015 respected: public/member club surfaces remain LiveView-based; no routing architecture change or controller rewrite was introduced.