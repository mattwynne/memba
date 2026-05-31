Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 011 Update operational documentation for auth Postmark environment variables and the required message stream.`

2. **Changes made**
   - Updated `docs/postmark-email.md` to document:
     - shared magic-link auth email as a separate Postmark-backed email path,
     - required auth email environment variables:
       - `MEMBA_AUTH_EMAIL_PROVIDER=postmark`
       - `MEMBA_POSTMARK_SERVER_TOKEN`
       - `MEMBA_AUTH_EMAIL_FROM_ADDRESS`
       - `MEMBA_AUTH_EMAIL_MESSAGE_STREAM`
     - required dedicated auth message stream, suggested as `outbound-authentication`,
     - sender address guidance, e.g. `auth@mail.memba.io`,
     - that Swoosh sends the auth stream via Postmark’s `MessageStream` option,
     - that auth-stream webhooks should not be pointed at the existing member-message Postmark webhook route unless the handler is later extended,
     - controlled auth magic-link smoke-test steps.
   - Updated `docs/human-todo.md` with an operational checklist for creating/configuring the auth Postmark stream, sender address, deployment secrets, and smoke test.
   - Checked off only task 011 in `docs/iterations/010-shared-magic-link-auth/todo.md`.

3. **Focused validation commands run**
   - `git diff --check`
     - Passed.
   - `env -u MEMBA_DEVENV_SHELL PATH="$PWD/bin:$PATH" dev check`
     - Passed: `192 tests, 0 failures`.
     - The devenv manager printed its usual shutdown SIGKILL message after tests completed successfully.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 011 Update operational documentation for auth Postmark environment variables and the required message stream.`
   - To:
     - `- [x] 011 Update operational documentation for auth Postmark environment variables and the required message stream.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No ADR was explicitly referenced by the plan.
   - I inspected the current hosting/deployment ADR (`docs/adr/0014-use-fly-io-for-production-hosting.md`); the docs update aligns with its use of Fly secrets for Postmark settings.
   - No acceptance feature files were changed.
   - No code or HTTP-client behavior was changed.