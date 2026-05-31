Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 002 Add persistence for authentication:`

2. **Changes made**
   - Generated migration with `mix ecto.gen.migration create_auth_magic_tokens`.
   - Added `auth_magic_tokens` table with:
     - `email`
     - `token_hash` as `bytea`
     - `expires_at`
     - `consumed_at`
     - timestamps
   - Added indexes:
     - unique index on `token_hash`
     - index on `email`
     - index on `expires_at`
   - Added `web/test/memba/auth_persistence_test.exs` covering:
     - no plaintext token column,
     - token hash storage shape,
     - lifecycle timestamp columns,
     - required lookup indexes,
     - inserting and consuming a token row.
   - Added `docs/iterations/010-shared-magic-link-auth/persistence.md` documenting the persistence shape and the decision not to add a separate identity/session table yet.

3. **Validation commands/results**
   - `cd web && mix format --check-formatted` — passed.
   - `bin/dev check` — passed after all changes:
     - `140 tests, 0 failures`

4. **Todo check-off made**
   - Changed:
     - `- [ ] 002 Add persistence for authentication:`
   - To:
     - `- [x] 002 Add persistence for authentication:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001: Uses Phoenix/Ecto/PostgreSQL persistence in the core app.
   - ADR 0007: Does not couple auth persistence to Membership or Messaging internals.
   - ADR 0008: Keeps this normal application table in the public app schema, not EventStore schema.
   - ADR 0009: Does not misuse projection machinery for auth token storage.