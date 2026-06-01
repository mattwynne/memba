Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `011 Remove @wip from the new failure scenario once implemented and passing.`

2. **Changes made**
   - Removed `@wip` from `acceptance-tests/features/member_message_deliverability.feature`.
   - Updated `web/test/features/cucumber_configuration_test.exs` so the newly untagged failure scenario is included in shared Elixir Cucumber runtime coverage and required step-pattern checks.

3. **Validation run**
   - `cd acceptance-tests && npm test -- features/member_message_deliverability.feature`
     - Passed: `21 scenarios`, `154 steps`.
   - `devenv shell -- bash -lc 'cd web && mix format --check-formatted test/features/cucumber_configuration_test.exs'`
     - Passed.
   - `devenv shell -- bash -lc 'MEMBA_DEVENV_SHELL=1 bin/dev postgres && cd web && MIX_ENV=test mix test test/features/cucumber_configuration_test.exs'`
     - Passed: `5 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `242 tests, 0 failures`.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 011 Remove @wip from the new failure scenario once implemented and passing.`
   - To:
     - `- [x] 011 Remove @wip from the new failure scenario once implemented and passing.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0003 / ADR 0010: preserved the shared, business-readable feature file and made sure the now-untagged scenario is covered by both browser Cucumber and Elixir Cucumber support.
   - ADR 0013 / ADR 0015: no member UI implementation was changed; test coverage remains aligned with user-facing feature-style validation.