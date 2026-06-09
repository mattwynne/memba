Implemented the automatic repair for the selected review issue. No commits made.

## Issue-to-fix mapping

| Review issue | Fix | Files/tests |
|---|---|---|
| `harden-review-repair-diff-comparison`: `verify_review_repair` used `cmp -s`, which was unavailable in the sandbox and could fail open inside an `if` conditional | Replaced `cmp -s` with `git diff --no-index --quiet`; identical patches still fail the repair, different patches pass, and unexpected comparison statuses now fail closed | `.fabro/workflows/iteration-review/workflow.fabro` |
| Same issue | Added guard assertions to prevent reintroducing `cmp` and require the checked comparison failure path | `.fabro/workflows/iteration-review/scripts/test_review_report_routing.sh` |
| Same issue | Recorded the second review repair in the kaizen note | `docs/kaizen/2026-06-09-iteration-review-code-health-recording-failure.md` |

## Files changed

### Review repair diff comparison hardening

- `.fabro/workflows/iteration-review/workflow.fabro`
- `.fabro/workflows/iteration-review/scripts/test_review_report_routing.sh`
- `docs/kaizen/2026-06-09-iteration-review-code-health-recording-failure.md`

No acceptance feature files were edited.

## Tests / validation run

Passed:

- `bash .fabro/workflows/iteration-review/scripts/test_review_report_routing.sh`
- `bash .fabro/workflows/iteration-review/scripts/test_collect_implementation_evidence.sh`
- `bash -n .fabro/workflows/iteration-review/scripts/collect_implementation_evidence.sh .fabro/workflows/iteration-review/scripts/test_collect_implementation_evidence.sh .fabro/workflows/iteration-review/scripts/test_review_report_routing.sh`
- `git diff --check`
- Focused `git diff --no-index --quiet` behavior check for equal vs different files
- `PATH="$PWD/bin:$PATH" dev check`
  - ExUnit: 758 tests, 0 failures
  - Acceptance: 77 scenarios, 502 steps, all passed

Attempted but unavailable in this sandbox:

- `fabro validate .fabro/workflows/iteration-review/workflow.toml --no-upgrade-check`
  - `fabro` not available on `PATH`
- `PATH="$PWD/bin:$PATH" dev fabro validate ...`
  - wrapper does not expose a `validate` command

## Remaining gaps / human questions

- `.fabro/tmp/` remains untracked run-state from the Fabro workflow environment.
- Full `fabro validate` could not be run because the validation CLI path is unavailable here; I did not patch tooling or product code to compensate.
- No product behavior was changed.