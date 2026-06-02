Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 014 Add tests for:`

2. **Changes made**
   - Added focused coverage for duplicate slug server rejection on club creation:
     - `web/test/memba/membership/public_api_test.exs`
       - Verifies `Membership.create_club/2` returns `{:error, :slug_taken}` for duplicate slugs and does not create the duplicate club.
     - `web/test/memba_web/live/admin/clubs_live/index_test.exs`
       - Verifies staff duplicate slug create submissions show a server error, keep the form editable, and preserve the existing slug owner.
   - Made the minimal implementation fix required by that coverage:
     - `web/lib/memba/membership.ex`
       - `create_club/2` now checks projected slug uniqueness before dispatch, matching the existing update-side duplicate slug guard.
   - Checked off only task 014 in:
     - `docs/iterations/015-club-slugs/todo.md`

3. **Validation run**
   - `cd web && mix format --check-formatted` — passed.
   - `git diff --check` — passed.
   - `PATH="$PWD/bin:$PATH" dev check` — passed:
     - `293 tests, 0 failures`
   - Note: I first attempted a direct targeted `mix test ...` outside the devenv-managed DB service; it failed because PostgreSQL was not available on that bare shell. The supported `dev check` path started services correctly and passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 014 Add tests for:`
   - To:
     - `- [x] 014 Add tests for:`
   - Left task 015 unchecked.

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001: stays within Phoenix/Elixir/PostgreSQL.
   - ADR 0002/0009: keeps Commanded write flow and Ecto projection read-model boundaries intact.
   - ADR 0007: duplicate slug enforcement remains in the Membership context public service layer.
   - ADR 0011: preserves caller-generated UUID aggregate identities; slug remains an attribute.
   - ADR 0013/0015: web behaviour is tested through Phoenix LiveView test helpers with stable element selectors.