Implemented the selected automatic repair.

## 1. Review issue from the gate

### `include-fabro-files-in-review-evidence`
**Issue:** The iteration-review evidence collector excluded `.fabro/workflows/` and `docs/kaizen/`, so workflow-focused reviews could not inspect the actual changed workflow/config/kaizen files.

## 2. Concrete changes made

### Issue-to-fix mapping

| Review issue | Fix | Files/tests |
|---|---|---|
| Include Fabro workflow and kaizen files in implementation evidence excerpts | Extracted the embedded evidence collection script into a dedicated script so the excerpt policy is maintainable and directly testable | `.fabro/workflows/iteration-review/scripts/collect_implementation_evidence.sh`, `.fabro/workflows/iteration-review/workflow.fabro` |
| Include Fabro workflow and kaizen files in implementation evidence excerpts | Expanded excerpt filter to include `docs/kaizen/` and `.fabro/workflows/` while preserving existing product/bin/iteration/ADR paths | `.fabro/workflows/iteration-review/scripts/collect_implementation_evidence.sh` |
| Include Fabro workflow and kaizen files in implementation evidence excerpts | Added a regression test proving changed workflow and kaizen files are excerpted, while unrelated docs remain excluded | `.fabro/workflows/iteration-review/scripts/test_collect_implementation_evidence.sh` |
| Include Fabro workflow and kaizen files in implementation evidence excerpts | Strengthened routing guard test to ensure the workflow uses the script-backed collector | `.fabro/workflows/iteration-review/scripts/test_review_report_routing.sh` |
| Include Fabro workflow and kaizen files in implementation evidence excerpts | Recorded the review repair and validation in the kaizen note | `docs/kaizen/2026-06-09-iteration-review-code-health-recording-failure.md` |

## 3. Files changed

### Evidence collector repair
- `.fabro/workflows/iteration-review/workflow.fabro`
- `.fabro/workflows/iteration-review/scripts/collect_implementation_evidence.sh`

### Automated tests / guards
- `.fabro/workflows/iteration-review/scripts/test_collect_implementation_evidence.sh`
- `.fabro/workflows/iteration-review/scripts/test_review_report_routing.sh`

### Kaizen documentation
- `docs/kaizen/2026-06-09-iteration-review-code-health-recording-failure.md`

## 4. Tests run

Passed:

- `bash .fabro/workflows/iteration-review/scripts/test_review_report_routing.sh`
- `bash .fabro/workflows/iteration-review/scripts/test_collect_implementation_evidence.sh`
- `bash -n .fabro/workflows/iteration-review/scripts/collect_implementation_evidence.sh .fabro/workflows/iteration-review/scripts/test_collect_implementation_evidence.sh .fabro/workflows/iteration-review/scripts/test_review_report_routing.sh`
- `bash .fabro/workflows/iteration-review/scripts/collect_implementation_evidence.sh 745e53ab293802c5ced1a4c877e3c604a996469e | grep -E ...`
  - Confirmed excerpts are now selected for:
    - `.fabro/workflows/iteration-review/prompts/record_code_health.md`
    - `.fabro/workflows/iteration-review/scripts/test_review_report_routing.sh`
    - `.fabro/workflows/iteration-review/workflow.fabro`
    - `docs/kaizen/2026-06-09-iteration-review-code-health-recording-failure.md`
- `dev check --quick`
  - Passed: 758 tests, 0 failures
- `git diff --check`
  - Passed

Attempted but unavailable in this sandbox:

- `fabro validate .fabro/workflows/iteration-review/workflow.toml --no-upgrade-check`
  - `fabro` was not on PATH.
- `dev fabro validate ...`
  - The local `dev fabro` wrapper does not expose a `validate` command.

## 5. Remaining gaps / human questions

- No product behaviour was changed.
- No acceptance feature files were edited.
- `.fabro/tmp/` remains untracked from the existing Fabro run state.
- The new scripts are marked intent-to-add so they appear in `git diff`; no content is staged.
- Full Fabro workflow validation could not be rerun in this sandbox because the validation CLI was unavailable here. The focused workflow shell tests and `dev check --quick` passed.