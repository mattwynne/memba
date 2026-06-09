Result: **REVIEW_ACCEPTED**

## Plan path

`docs/iterations/030-verified-onboarding-requests/plan.md`

## Base SHA and reviewed commit range

- Base SHA: `4bbaa97b6cdd8bd810bcf1ffefff58f6f42c4bc1`
- Reviewed / published range: `4bbaa97b6cdd8bd810bcf1ffefff58f6f42c4bc1..f8dc9335a51468eb9e94b0e2a8637d22ea75be8e`

## Final artifact gate confirmation

The final artifact gate confirmed the reviewed implementation evidence against base SHA `4bbaa97b6cdd8bd810bcf1ffefff58f6f42c4bc1`.

It reported:

> `Final artifact evidence confirmed.`  
> `Final artifact gate passed.`

It also confirmed the changed files since the base SHA, including the implementation, tests, acceptance updates, iteration docs, and workflow polish.

Acceptance `.feature` changes were explicitly allowed by the plan:

> `acceptance-tests/features/request_account.feature: ... add the planned @iteration-030 scenarios ... update existing public request scenarios to the new language, and remove or narrow @todo-domain/@todo-ui when the scenarios pass...`

## ADR conformance summary

Independent reviews from Claude, Codex, and Gemini all concluded:

- **ADR conformance: PASS**
- No ADR violations identified.
- The implementation reuses existing architectural boundaries:
  - existing magic-link / sign-in token authentication flow;
  - existing `Onboarding` context;
  - existing Staff request inbox and notification behaviour;
  - existing Membership-domain conversion semantics;
  - no new persistence model, auth mechanism, notification infrastructure, or competing service boundary.

The review synthesis accepted the implementation.

## Independent review outcome

Independent review outcome: **ACCEPT**

Confidence reported by reviewers: **High**

Blocking issues: **None identified**

The implementation was considered plan-conforming and mergeable.

## Finding disposition

### Fixed

1. **Make Get Started request params nil-safe**
   - Disposition: **Fixed during review repair**
   - Evidence: final artifact gate includes:
     - `web/lib/memba_web/controllers/page_controller.ex`
     - `web/test/memba_web/controllers/page_controller_test.exs`
   - The repair reported adding guarded request parameter handling so malformed or missing request params flow into validation instead of raising.

2. **Clarify trusted requester name / existing Person precedence**
   - Disposition: **Fixed during review repair**
   - Evidence: final artifact gate includes:
     - `web/lib/memba_web/controllers/page_controller.ex`
   - The repair reported extracting trusted requester detail selection so existing Person name/email precedence is explicit.

3. **Add malformed-param regression coverage**
   - Disposition: **Fixed during review repair**
   - Evidence: final artifact gate includes:
     - `web/test/memba_web/controllers/page_controller_test.exs`
   - The repair reported adding a controller regression test for a signed-in malformed request that returns validation errors, creates no onboarding request, and sends no Staff email.

### Dismissed with reason

4. **Reviewer concern that automated repair targeted the wrong controller**
   - Disposition: **Dismissed / superseded by final artifact evidence**
   - Reason: independent reviewers repeatedly referred to `get_started_controller.ex`, but the final artifact gate’s reviewed implementation evidence shows the actual changed Get Started implementation files are:
     - `web/lib/memba_web/controllers/page_controller.ex`
     - `web/lib/memba_web/controllers/page_html/get_started.html.heex`
     - `web/test/memba_web/controllers/page_controller_test.exs`
   - Therefore, the repair files are consistent with the final reviewed artifact evidence. The reviewer path mismatch should be treated as a review/tooling evidence confusion, not a remaining product-code blocker.

### Still unhandled / not recorded

5. **Verified-email invariant is enforced by the web caller rather than structurally encoded in the domain API**
   - Disposition: **Unhandled**
   - Reason: reviewers consistently noted that the public flow correctly uses the signed-in identity email, but the domain API still accepts raw request attrs. This was not fixed in this review repair and was not successfully recorded in `docs/code-health.md`.

6. **`/get-started` multiplexes signed-out verification and signed-in request submission**
   - Disposition: **Unhandled**
   - Reason: reviewers considered this acceptable for the iteration but worth tracking if the flow grows. It was not fixed and was not successfully recorded in `docs/code-health.md`.

7. **Email normalization may be duplicated**
   - Disposition: **Unhandled**
   - Reason: reviewers suggested possible future consolidation if repeated normalization patterns exist. This was not fixed and was not successfully recorded in `docs/code-health.md`.

8. **Controller clause ordering carries implicit flow behaviour**
   - Disposition: **Unhandled**
   - Reason: reviewers considered this idiomatic and non-blocking, but potentially worth revisiting if controller states grow. This was not fixed and was not successfully recorded in `docs/code-health.md`.

## Repairs applied during review

A review polish commit was created and published.

The repair reported addressing:

- nil-safe Get Started request parameter handling;
- clearer trusted requester details selection;
- malformed request regression coverage.

Files shown in final artifact evidence that correspond to the review repair:

- `.fabro/workflows/iteration-review/scripts/test_review_report_routing.sh`
- `.fabro/workflows/iteration-review/workflow.fabro`
- `web/lib/memba_web/controllers/page_controller.ex`
- `web/test/memba_web/controllers/page_controller_test.exs`

No repaired file is claimed outside the final artifact gate evidence.

## Code-health note status

`docs/code-health.md` was **not updated**.

The `record_code_health` stage explicitly reported:

> `CODE_HEALTH_RECORDING_FAILED: I’m unable to edit docs/code-health.md in this environment because no file-editing tools are available in the current API session.`

Therefore, the judgement-worthy non-blocking findings were **not recorded**. This is a workflow gap. They remain unhandled follow-ups rather than fully dispositioned code-health notes.

Findings that should still be recorded or otherwise triaged:

- domain API does not structurally encode the verified-email invariant;
- `/get-started` multiplexes signed-out and signed-in workflow states;
- email normalization may be duplicated;
- controller clause ordering may become brittle if the controller grows.

## Key files reviewed or repaired

From final artifact gate evidence, key changed files included:

### Iteration and workflow artifacts

- `.fabro/workflows/iteration-review/scripts/test_review_report_routing.sh`
- `.fabro/workflows/iteration-review/workflow.fabro`
- `docs/iterations/030-verified-onboarding-requests/inspection-notes.md`
- `docs/iterations/030-verified-onboarding-requests/plan.md`
- `docs/iterations/030-verified-onboarding-requests/todo.md`
- `docs/iterations/README.md`

### Acceptance tests

- `acceptance-tests/features/request_account.feature`
- `acceptance-tests/features/support/request_account.js`
- `web/test/features/step_definitions/authentication_steps.exs`
- `web/test/features/step_definitions/request_account_steps.exs`

### Implementation

- `web/lib/memba/onboarding/request.ex`
- `web/lib/memba_web/controllers/page_controller.ex`
- `web/lib/memba_web/controllers/page_html/get_started.html.heex`

### Tests

- `web/test/memba/onboarding_conversion_test.exs`
- `web/test/memba/onboarding_test.exs`
- `web/test/memba_web/controllers/page_controller_test.exs`
- `web/test/memba_web/live/admin/requests_live/index_test.exs`

## Publish outcome

Review polish was pushed to `main`.

Publish step output:

- Created review polish commit:

  `review polish: iteration 030`

- Successfully rebased.
- Published to main:

  `f8dc9335a51468eb9e94b0e2a8637d22ea75be8e`

Final publish line:

> `Published review polish to main: f8dc9335a51468eb9e94b0e2a8637d22ea75be8e`

## Tests and validation run

Validation completed successfully.

### Sandbox / preflight

- `dev sandbox-check` passed.

### Dev check / CI

`dev ci` / dev check passed.

Reported acceptance result:

- `73 scenarios`
- `73 passed`
- `489 steps`
- `489 passed`

Independent reviews also cited the ExUnit result:

- `755 tests`
- `0 failures`

### Final artifact validation

- Final artifact gate passed.
- Acceptance feature changes were confirmed as allowed by the iteration plan.

## Manual demo/checks still recommended

No manual demo is required for merge based on the automated validation and independent review consensus.

Optional manual smoke check, if desired:

1. Visit `/get-started` signed out.
2. Submit an email.
3. Confirm magic-link email includes return to `/get-started`.
4. Follow link and confirm signed-in verified request form renders.
5. Submit request.
6. Confirm Staff inbox shows only the verified submitted request.

## Non-blocking follow-ups

The implementation is accepted, but these follow-ups remain because they were neither fixed nor successfully recorded in `docs/code-health.md`:

1. Consider encoding the verified-email invariant in the `Onboarding` context API.
2. Revisit `/get-started` route/template splitting if verification and request-submission flows grow more complex.
3. Search for repeated email normalization and consider a shared helper only if duplication is meaningful.
4. Revisit controller clause organization if additional Get Started states or param shapes are added.