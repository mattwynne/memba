Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `005 Change /auth/check-email to use an opaque request ID, with backward-compatible handling for any old route if needed.`

2. **Changes made**
   - Added dynamic LiveView route:
     - `/auth/check-email/:request_id`
   - Kept backward-compatible route:
     - `/auth/check-email`
   - Updated `AuthLive.SignIn` so sign-in form submissions patch to:
     - `/auth/check-email/<opaque-auth-email-request-id>`
   - Preserved fallback to `/auth/check-email` if creating the progress request fails.
   - Added request-id parsing/validation in the LiveView without surfacing account-existence data.
   - Updated Get Started email-verification flow so its current auth email redirect also uses an opaque request-id URL when a progress request can be created.
   - Added tests for:
     - Rendering the check-email page with an opaque request ID.
     - Known and unknown auth submissions using the same opaque route shape.
     - Get Started verification redirecting to an opaque check-email URL.

3. **Validation run**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted ...`
     - Passed.
   - `PATH="$PWD/bin:$PATH" bin/mix test ...`
     - Direct wrapper hit the known Fabro PGHOST/Postgres socket mismatch.
   - `devenv shell -- bash -lc 'cd web && PATH="$PWD/../bin:$PATH" mix test test/memba_web/controllers/auth_controller_test.exs'`
     - Passed: `26 tests, 0 failures`.
   - Targeted get-started/admin redirect tests:
     - Passed: `77 tests, 0 failures, 74 excluded`.
   - Broader focused controller/admin test command surfaced unrelated existing `PageControllerTest` message-routing failures.
   - `git diff --check`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check`
     - First attempt timed out waiting/doing the quality gate.
     - Re-run completed with exit code `0`; acceptance scenarios reported `77 scenarios (77 passed)`.
     - Output still includes unrelated baseline ExUnit failures, consistent with prior run context.

4. **Todo check-off made**
   - Changed exactly:
     - From `- [ ] 005 Change /auth/check-email to use an opaque request ID, with backward-compatible handling for any old route if needed.`
     - To `- [x] 005 Change /auth/check-email to use an opaque request ID, with backward-compatible handling for any old route if needed.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Read ADR 0021 and ADR 0022.
   - No PubSub publishing, projection barrier, or Commanded projection work was added in this task.
   - URL uses only the opaque auth-email request ID.
   - Existing no-ID `/auth/check-email` remains neutral/backward-compatible and does not invent progress.
   - No sensitive email address or account-existence signal is exposed in route shape or UI copy.