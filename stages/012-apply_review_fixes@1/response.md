Implemented the only concrete gate issue selected by synthesis.

## 1. Gate issue addressed

### `repair-missing-gemini-review`
**Title:** Repair workflow so Gemini review Markdown is visible to synthesis.

**Fix:** Updated the iteration-review workflow so synthesis only runs after all three independent review stages succeed. If Claude, Codex/GPT, or Gemini fails, the workflow now routes to the existing infrastructure-style unavailable path instead of letting synthesis run with missing reviewer Markdown.

I did **not** apply the Claude/Codex product-code polish suggestions because the synthesis gate did not select them as repair items.

## 2. Code/config/test changes made

### Workflow hardening
Updated:

- `.fabro/workflows/iteration-review/workflow.fabro`

Changes:

- Added `retry_policy="patient"` to:
  - `claude_review`
  - `codex_review`
  - `gemini_review`
- Changed reviewer-stage edges so:
  - `claude_review -> codex_review` only happens on `outcome=succeeded`
  - `codex_review -> gemini_review` only happens on `outcome=succeeded`
  - `gemini_review -> synthesize_review` only happens on `outcome=succeeded`
- Added fallback routes from each reviewer stage to `synthesis_unavailable`.
- Updated the unavailable message to cover both “could not collect” and “could not synthesize” all independent review reports.

### Regression coverage
Added:

- `.fabro/workflows/iteration-review/scripts/test_review_report_routing.sh`

This static workflow regression test verifies:

- Reviewer stages have patient retry policy.
- Synthesis is reachable only after successful reviewer stages.
- Failed reviewer stages route to `synthesis_unavailable`.
- The old unconditional reviewer-to-synthesis routing is absent.

## 3. Issue-to-fix mapping

| Review issue | Files/modules/tests addressing it |
|---|---|
| `repair-missing-gemini-review` | `.fabro/workflows/iteration-review/workflow.fabro` |
| `repair-missing-gemini-review` regression proof | `.fabro/workflows/iteration-review/scripts/test_review_report_routing.sh` |

## 4. Tests and validation run

Passed:

- `bash .fabro/workflows/iteration-review/scripts/test_review_report_routing.sh`
  - Result: passed
- `PATH="$PWD/bin:$PATH" dev check`
  - Result: passed
  - ExUnit: `754 tests, 0 failures`
  - Acceptance: `73 scenarios, 489 steps`, all passed

Attempted but unavailable:

- `fabro validate .fabro/workflows/iteration-review/workflow.toml --no-upgrade-check`
  - Could not run because `fabro` is not installed in this sandbox/devenv.

## 5. Remaining gaps / human questions

- No product-code gaps remain from the synthesized gate issue.
- No acceptance feature files were changed.
- The new test script is runnable via `bash .../test_review_report_routing.sh`. I attempted to make it executable, but this sandbox reported `Operation not permitted` on `chmod` because repository files are owned by `root` while the session user is `user`.