# Iteration 061 Review

- **Decision:** ACCEPT
- **Confidence:** Medium
- **ADR conformance:** PASS

## ADR violations

None identified.

The implementation remains within the plan’s existing context/read-model architecture: discovery is treated separately from participation and conversation access, authorization remains server-authoritative, and there is no evidence of a replacement permission framework, new aggregate, or web-layer projection shortcut conflicting with an accepted ADR.

The surfaced transcript truncates much of the production diff, so confidence is not High; however, the prior plan-conformance gate, targeted regressions, review repair, and two successful full validation runs provide no evidence of an ADR violation.

## Blocking issues

None.

The review blocker concerning Cucumber inventory tag inheritance was repaired:

- `acceptance-tests/test/cucumber_config.test.js` now uses the official Gherkin AST parser.
- Inventory exclusions combine feature, rule, and scenario tags.
- Tests cover inheritance and ensure rule tags do not leak beyond their rule.
- `@cucumber/gherkin` is now an explicit development dependency.
- The repair did not alter product behaviour or acceptance feature files.

## Bounded-safe fixes

None remaining.

The concrete bounded-safe issue found during the first review pass has already been addressed and validated.

## Judgement-worthy non-blocking code-health findings

1. **File:** `acceptance-tests/test/cucumber_config.test.js`  
   **Smell:** Scenario Outline inventory still represents an outline once and does not account for tags attached to individual `Examples:` blocks.  
   **Why it may need human judgement:** There are currently no tagged `Examples:` blocks, so this does not affect present inventory or exclusions. If those tags are introduced later, maintainers should decide whether inventory is scenario-level or expanded-example-level and add matching regression coverage.

2. **File:** `.fabro/workflows/iteration-review/scripts/verify_review_repair.sh`  
   **Smell:** The verification stage attempted to invoke `cmp`, which was unavailable, but the stage still reported success.  
   **Why it may need human judgement:** This did not invalidate the subsequent full `dev ci` run, but it weakens the repair workflow’s independent before/after comparison. Workflow owners should decide whether `cmp` is a required sandbox dependency or whether the script should use a more portable Git-based comparison and fail explicitly when comparison cannot run.

3. **Files:** Membership discovery/access APIs and `MemberDashboardPresentation`  
   **Smell:** The distinction between discoverability and effective participation is security-sensitive and could be eroded by a future “simplifying” refactor.  
   **Why it may need human judgement:** The current implementation and tests conform to the plan, but the similarly related group-query responsibilities need to remain deliberately separate. Future work should not reuse discovery summaries as Messaging authorization or load private rows for presentation-layer filtering.

## Suggested fixes

No merge-required changes.

For future maintenance:

- Extend the Cucumber inventory tests before introducing tags on individual `Examples:` blocks.
- Make `verify_review_repair.sh` fail fast or avoid relying on an unavailable `cmp` executable.
- Preserve explicit naming and documentation around discovery versus effective membership/conversation access.

## Validation notes

- Sandbox runtime preflight passed.
- The original full `dev ci` run passed.
- After the review repair, the full `dev ci` run passed again on the repaired state:
  - 1,292 ExUnit tests passed.
  - 145 browser acceptance scenarios passed.
  - 1,052 acceptance steps passed.
- Targeted acceptance configuration validation passed: 68 tests.
- Package-lock dry-run reported the lockfile up to date.
- `git diff --check` passed.
- The repair changed only:
  - `acceptance-tests/package.json`
  - `acceptance-tests/package-lock.json`
  - `acceptance-tests/test/cucumber_config.test.js`
- No product behaviour or acceptance feature files were changed by the repair.
- The transcript does not independently evidence the plan’s desktop/mobile manual visual review; this limits confidence but does not reveal a behavioural or architectural blocker given the green browser coverage and prior plan-conformance result.