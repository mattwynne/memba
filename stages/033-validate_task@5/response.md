### Decision
**VALID**

### Evidence
- Completed todo/check-off evidence found:
  - Live working tree is clean except untracked `.fabro/tmp/`.
  - Recent implementation checkpoint is `561c9bc fabro(...): implement_next_task (succeeded)`; current HEAD is the following pre-validation checkpoint `9361785`.
  - `git show 561c9bc -- docs/iterations/022-request-to-club-onboarding/todo.md` shows exactly one ordinary todo change:
    - `005 Implement signed-out /get-started form with required-field and email validation.`
    - from `- [ ]` to `- [x]`.
  - Parent todo state had `001`–`004` checked and `005` as the first unchecked task.

- Implementation artifacts found:
  - Added `Memba.Onboarding.change_request/2` for request form changesets.
  - Added `POST /get-started` route.
  - Updated `PageController` with hosted form rendering and submission handling:
    - successful signed-out submissions persist an active onboarding request and redirect to `/get-started?submitted=true`;
    - invalid submissions render `422` with changeset errors.
  - Replaced the mailto-only `/get-started` page with a Phoenix form for name, email, club name, and note.
  - Added/updated controller tests covering signed-out form rendering, required validation, invalid email rejection, durable request creation, acknowledgement, and no immediate club/membership creation.
  - No `*.feature` or `acceptance-tests/` files were changed in the implementation checkpoint.

- Tests run/results found:
  - `git diff --check 561c9bc^ 561c9bc` passed.
  - `PATH="$PWD/bin:$PATH" dev check --quick` passed: `544 tests, 0 failures`.
  - `PATH="$PWD/bin:$PATH" dev check` passed:
    - ExUnit: `544 tests, 0 failures`;
    - acceptance: `38 scenarios (38 passed), 252 steps (252 passed)`.

- ADR/plan conformance notes:
  - Work stays within task `005`; signed-in prepopulation, notification email, staff inbox, rejection, conversion, welcome email, and acceptance step support remain correctly deferred to later unchecked tasks.
  - Preserves the anti-abuse boundary: public request submission creates no club or membership.
  - ADR 0001 respected by using Phoenix/controller-rendered HTML with PostgreSQL-backed request persistence.
  - ADR 0002 respected by building on the explicit onboarding-request Ecto model from the prior persistence task rather than adding unrelated CRUD domain workflow.
  - ADR 0013 respected with user-facing web tests/selectors for controller-rendered behaviour.
  - ADR 0015 respected: `/get-started` is a public marketing/onboarding page, so controller-rendered HTML is appropriate.
  - Phoenix HTML guidance followed: uses `<.form>`, `to_form/2`, `<.input>`, and stable DOM IDs.

{"context_updates":{"task_valid":true,"task_retry_available":false}}