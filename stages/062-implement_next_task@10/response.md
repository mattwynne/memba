1. **Selected todo line**
   - `010 Preserve Staff conversion/rejection semantics for verified submitted requests, including creating/reusing the Person during conversion.`

2. **Changes made**
   - Updated `web/test/memba_web/live/admin/requests_live/index_test.exs`.
   - Added a `verified_request_fixture/3` helper that submits `/get-started` as a signed-in verified identity and consumes the Staff new-request notification.
   - Updated Staff rejection coverage to reject a verified submitted request and assert:
     - request leaves the active inbox;
     - rejection audit fields are stored;
     - no club/person/membership/sign-in token records are created;
     - no requester email is sent.
   - Updated Staff conversion coverage to convert a verified submitted request with no existing Person and assert:
     - Person is created from the verified request details;
     - club, active membership, and sign-in token/welcome email are created as before.
   - Updated existing-Person conversion coverage to submit the request via verified identity, assert the stored request uses the existing Person details, and assert conversion reuses that Person and sends the welcome email.
   - Checked off only the selected todo line in `docs/iterations/030-verified-onboarding-requests/todo.md`.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba_web/live/admin/requests_live/index_test.exs`
     - Passed.
   - Initial direct focused test hit the known sandbox `PGHOST` readiness mismatch.
   - Reran focused test successfully:
     - `devenv shell -- bash -lc 'cd web && mix test test/memba_web/live/admin/requests_live/index_test.exs --seed 0'`
     - Passed: `10 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `747 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 010 Preserve Staff conversion/rejection semantics for verified submitted requests, including creating/reusing the Person during conversion.`
   - To:
     - `- [x] 010 Preserve Staff conversion/rejection semantics for verified submitted requests, including creating/reusing the Person during conversion.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No `docs/adr/*.md` files are present.
   - The change preserves the iteration plan’s Staff rejection/conversion semantics for verified requests without changing routing, UI, feature files, or unrelated behaviour.