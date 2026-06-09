### Decision
**VALID**

### Evidence
- Completed todo/check-off evidence found:
  - Live working tree is clean.
  - Recent checkpoint `804cecb fabro(...): implement_next_task (succeeded)` changed exactly one ordinary todo line:
    - `002 Update homepage tests or browser acceptance support so the volunteering promise is asserted without depending on fragile layout details.`
    - from `- [ ]` to `- [x]`.
  - Current `todo.md` shows tasks 001 and 002 checked, with 003 as the first remaining unchecked task.
- Implementation artifacts found:
  - `acceptance-tests/features/support/homepage.js` now asserts the homepage promise via accessible heading role using `HOMEPAGE_VOLUNTEERING_PROMISE`, avoiding layout/CSS coupling.
  - `acceptance-tests/features/step_definitions/homepage_steps.js` adds the planned step: `Then I should see that volunteering should not feel like work`.
  - `acceptance-tests/test/homepage_steps.test.js` adds/updates coverage for the new support assertion.
  - `web/lib/memba_web/controllers/page_html/home.html.heex` updates the signed-out hero heading to `Volunteering shouldn’t feel like work.`
  - `web/test/memba_web/controllers/page_controller_test.exs` updates controller assertions for the new homepage copy and signed-in exclusion.
- Tests run/results found:
  - Live validation reran `cd acceptance-tests && node --test test/homepage_steps.test.js` — passed, 5/5 tests.
  - Implementor reported:
    - Cucumber dry-run for the planned homepage scenario passed with no undefined steps.
    - `dev check --quick` passed.
    - Full `dev check` passed with 757 ExUnit tests and 73 browser acceptance scenarios.
    - `git diff --check` passed.
- ADR/plan conformance notes:
  - Task 002 was the first unchecked task at implementation start.
  - Work stays within the approved homepage-copy/test-support slice and does not check off or silently defer later email/navigation tasks.
  - No `.feature` files were edited; only support and step-definition plumbing was added for an existing planned scenario.
  - ADR 0001 is respected by keeping behaviour in the Phoenix app.
  - ADR 0003/0013 constraints are respected: acceptance language remains in the shared feature file, while browser support asserts user-visible behaviour through accessible Playwright roles rather than fragile selectors.

{"context_updates":{"task_valid":true,"task_retry_available":false}}