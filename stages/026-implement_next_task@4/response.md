1. **Selected todo line**
   - `004 Implement slug generation and validation in a small Membership slug module or equivalent domain helper:`

2. **Changes made**
   - Added `Memba.Membership.Slug` in `web/lib/memba/membership/slug.ex` with:
     - `default_from_name/1` for lower-case kebab-case slug suggestions from club names.
     - `validate/1` for staff-entered slugs that must already be address-safe.
     - `valid?/1`.
     - `max_length/0` returning `32`.
   - Added tests in `web/test/memba/membership/slug_test.exs` covering:
     - default generation from names;
     - punctuation/spacing cleanup for generated defaults;
     - max-length truncation without trailing hyphens;
     - valid slugs including lowercase letters, numbers, and interior hyphens;
     - invalid uppercase, spaces, underscores, punctuation, leading/trailing hyphens, blank, non-string, and too-long values.
   - Checked off only task `004` in `docs/iterations/015-club-slugs/todo.md`.

3. **Focused validation commands run and results**
   - `cd web && /bin/mix format --check-formatted lib/memba/membership/slug.ex test/memba/membership/slug_test.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `267 tests, 0 failures`.
   - `git diff --check`
     - Passed.
   - Note: I also attempted a bare focused `mix test` run, but the project’s test alias requires Postgres setup and failed outside the dev wrapper due a missing Postgres socket. The full `dev check` run started required services and passed.

4. **Exact todo check-off made**
   ```md
   - [ ] 004 Implement slug generation and validation in a small Membership slug module or equivalent domain helper:
   ```
   changed to:
   ```md
   - [x] 004 Implement slug generation and validation in a small Membership slug module or equivalent domain helper:
   ```

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0002: Kept the change inside Membership domain support code; did not bypass or alter Commanded workflow structure.
   - ADR 0007: Did not introduce cross-context access; helper remains in Membership.
   - ADR 0008: Validation used the project’s standard persistent Postgres/EventStore-backed `dev check`.
   - ADR 0009: Did not alter projection plumbing.
   - ADR 0011: Did not change UUID aggregate identity; slug remains a separate addressable value.