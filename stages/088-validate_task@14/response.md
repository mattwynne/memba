### Decision
**VALID**

### Evidence
- Completed todo/check-off evidence found:
  - `/tmp/fabro-pre-validate-snapshot.md` shows clean working tree at implement checkpoint `5e8c592`.
  - Live `git status --short` is clean.
  - Recent log shows `2ce8f30` pre-validation checkpoint on top of `5e8c592` implement checkpoint.
  - `git diff 5e8c592^ 5e8c592 -- docs/iterations/030-verified-onboarding-requests/todo.md acceptance-tests/features/request_account.feature` shows exactly one ordinary todo changed from unchecked to checked:
    - `014 Remove or narrow @todo-domain/@todo-ui from the new/updated scenarios only when they pass in the relevant runner.`
  - Parent todo had `014` as the first unchecked task; current todo leaves only `015 Run dev check` unchecked.

- Implementation artifacts found:
  - Implement checkpoint `5e8c592` changed:
    - `acceptance-tests/features/request_account.feature`
    - `docs/iterations/030-verified-onboarding-requests/todo.md`
  - The four `@iteration-030` scenarios now have `@todo-domain` removed and retain `@todo-ui`, matching the implementor’s stated narrowing.
  - Current tag check confirms all four relevant scenarios are now `@iteration-030 @todo-ui`.

- Tests run/results found:
  - Validator reran focused domain Cucumber acceptance tests:
    - `devenv shell -- bash -lc 'cd web && mix test test/features/domain_cucumber_runner_test.exs test/features/domain_cucumber_acceptance_test.exs --seed 0'`
    - Result: `64 tests, 0 failures`.
  - The preceding implementation summary also reported:
    - focused domain Cucumber passed,
    - browser probe justified retaining `@todo-ui`,
    - `dev check` passed with `754 tests, 0 failures` and browser Cucumber `73 scenarios, 489 steps passed`.
  - Post-test `git status --short` remains clean.

- ADR/plan conformance notes:
  - Plan explicitly allows editing `acceptance-tests/features/request_account.feature` to remove or narrow `@todo-domain`/`@todo-ui` when scenarios pass in relevant runners.
  - The change preserves ADR 0003 and ADR 0010: shared feature files remain the single behavioural specification used by domain and browser runners.
  - Scope is plan-conforming: domain todo tag removed only after domain runner passes; browser todo tag retained because browser runner support is still incomplete.
  - No plan-required work was deleted, weakened, or silently deferred; task `015` remains for the final `dev check` checkpoint.

{"context_updates":{"task_valid":true,"task_retry_available":false}}