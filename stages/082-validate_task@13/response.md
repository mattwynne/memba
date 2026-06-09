### Decision
**VALID**

### Evidence
- Completed todo/check-off evidence found.
  - `/tmp/fabro-pre-validate-snapshot.md` shows a clean snapshot at implementation checkpoint `7b1689e`.
  - Live `git status --short` is clean; live `git diff` is empty.
  - Recent commits show `a6469b5` pre-validation on top of `7b1689e` implementation.
  - `git show 7b1689e -- docs/iterations/031-brand-email-navigation-polish/todo.md` changes exactly one ordinary task line:
    - `013 Remove or narrow @todo-* tags from the planned acceptance scenarios once their runners can execute them meaningfully.`
    - from `- [ ]` to `- [x]`.
  - The parent todo state had tasks `001`–`012` checked and `013` as the first unchecked task.

- Implementation artifacts found.
  - Implementation checkpoint `7b1689e` changes:
    - Allowed acceptance feature files:
      - `acceptance-tests/features/homepage.feature`
      - `acceptance-tests/features/member_club_subdomains.feature`
      - `acceptance-tests/features/email_branding.feature`
    - Browser acceptance plumbing/support:
      - `acceptance-tests/features/step_definitions/email_branding_steps.js`
      - `acceptance-tests/features/step_definitions/member_club_subdomain_steps.js`
      - `acceptance-tests/features/support/authentication.js`
      - `acceptance-tests/features/support/member_message.js`
      - `acceptance-tests/test/cucumber_config.test.js`
    - `todo.md`
  - `@todo-ui` was removed from the homepage and public club-page scenarios.
  - `email_branding.feature` was narrowed from `@todo-domain @todo-ui` to `@todo-domain`, leaving domain-runner exclusion while enabling browser/email runner coverage.
  - Added executable assertions for:
    - sign-in email Memba sprig icon and standard footer,
    - rejection email sender name and standard footer,
    - public club-page link to the Memba homepage/root host.
  - Config test now asserts iteration 031 scenarios are no longer blocked from the browser runner.

- Tests run/results found.
  - Re-ran focused validation successfully:
    - `node --check` on changed JS support/step files: passed.
    - `node --test acceptance-tests/test/cucumber_config.test.js`: passed, `5/5`.
    - `PATH="$PWD/bin:$PATH" dev acceptance --tags "@iteration-031"`: passed, `4 scenarios, 13 steps`.
  - Working tree remained clean after validation.
  - Implementor also reported full `dev check` passing for this task checkpoint.

- ADR/plan conformance notes.
  - Plan explicitly allows edits to the three changed acceptance feature files under `## Allowed acceptance feature changes`; the edits stay within the permitted tag narrowing/implementation of planned scenarios.
  - `@todo-domain` remains on email branding scenarios because the domain runner does not yet provide meaningful email-rendering/provider coverage, matching the plan’s “remove or narrow” wording.
  - ADR 0003 and ADR 0010 are respected: shared feature files remain under `acceptance-tests/features/`, browser runner support was added without duplicating feature specs, and external email behaviour is asserted through test/captured-mail support rather than real providers.
  - The checkpoint is focused, plan-aligned, and independently useful.

{"context_updates":{"task_valid":true,"task_retry_available":false}}