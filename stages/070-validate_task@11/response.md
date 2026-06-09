### Decision
**VALID**

### Evidence
- Completed todo/check-off evidence found.
  - `/tmp/fabro-pre-validate-snapshot.md` shows a clean working tree at the validation snapshot.
  - Live `git status --short` and `git diff` are clean.
  - Recent commits show `79294c8 ... pre_validate_snapshot` on top of `d6cca3b ... implement_next_task`.
  - `git show d6cca3b -- docs/iterations/031-brand-email-navigation-polish/todo.md` changes exactly one ordinary task line:
    - `011 Ensure the homepage link resolves to the root Memba host when rendered from a club subdomain.`
    - from `- [ ]` to `- [x]`.
  - Parent todo state confirms task `011` was the first unchecked task when implementation started.

- Implementation artifacts found.
  - `web/lib/memba_web/club_site.ex` adds `MembaWeb.ClubSite.root_url/1`, deriving the root Memba host from the configured club-site base domain.
  - `web/lib/memba_web/live/public_club_page_live.ex` uses `ClubSite.root_url()` for the visible `Visit Memba home` link.
  - `web/lib/memba_web/components/layouts.ex` uses `ClubSite.root_url()` for the club-site footer Memba link.
  - Tests were updated in:
    - `web/test/memba_web/club_site_test.exs`
    - `web/test/memba_web/controllers/page_controller_test.exs`
    - `web/test/memba_web/components/layouts_test.exs`
  - The tests assert local/test root URL behavior and production-like `clubs.memba.io` → `memba.io` behavior.

- Tests run/results found.
  - Implementation summary reports focused tests passing: `49 tests, 0 failures`.
  - Implementation summary reports full `dev check` passing: `758 tests, 0 failures`; `73 scenarios (73 passed)`.
  - Implementation summary reports format check and `git diff --check` passing.
  - Validator attempted to rerun the focused test set, but the local Postgres socket was unavailable before tests ran; working tree remained clean afterward.

- ADR/plan conformance notes.
  - Matches task `011`: Memba-home links on club subdomain pages now point to the root Memba host, not `/` on the club subdomain.
  - Preserves scope: no signed-in club switcher, custom-domain work, or broader navigation redesign.
  - ADR 0019 respected: URL generation remains based on configurable club-site base domains; local/test uses `lvh.me`, production uses `clubs.memba.io`.
  - ADR 0015 respected: the public/member club surface remains LiveView-based.
  - Acceptance feature files were not edited in this checkpoint or current working tree.
  - The checkpoint is small, concrete, and independently useful.

{"context_updates":{"task_valid":true,"task_retry_available":false}}