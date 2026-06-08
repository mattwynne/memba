Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 008 Keep the Admin invitation form email-only.`

2. **Changes made**
   - Updated `web/test/memba_web/live/member_invitation_live/new_test.exs`.
   - Added a focused LiveView test proving the Membership Admin invitation form:
     - renders exactly one invitation field,
     - that field is `invitation[email]` with `type="email"`,
     - does not render name or role controls,
     - still remains email-only after a crafted validation payload includes extra `name` / `role` params.
   - No production code changes were needed; the existing LiveView already filters form params to email only.
   - Updated formatting in the same test file as required by `mix format`.

3. **Validation commands/results**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba_web/live/member_invitation_live/new_test.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/live/member_invitation_live/new_test.exs`
     - Blocked by sandbox Postgres readiness mismatch/lock when using the direct mix wrapper.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `734 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `734 tests, 0 failures`; acceptance suite `69 scenarios, 466 steps` passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 008 Keep the Admin invitation form email-only.`
   - To:
     - `- [x] 008 Keep the Admin invitation form email-only.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001: Stayed within the Phoenix core application stack.
   - ADR 0015: Kept the member-facing invitation surface as LiveView-based.
   - ADR 0013: Used LiveView/Phoenix web testing for form behaviour; no domain or Commanded architecture was changed.
   - No acceptance feature files, routes, projections, commands, or domain lifecycle code were altered for this task.