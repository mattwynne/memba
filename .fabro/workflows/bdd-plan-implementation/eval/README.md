# Test the plan navigator without reimplementing scenarios

The real navigator chooses work and calls a native Fabro child workflow. The
child is a test double: it supplies prepared code, records the selected
scenario and removes its WIP tag. It never calls a model or runs application
tests. No real scenario implementation is repeated to test the parent.

## First case: iteration 068

- Starting product code: `5645fb62d50892b763f419f4b08e5d22b9a0e4bd`.
- Approved plan, links and scenarios: `c5402f0bd8fc99587c8b220b51643ecd650377eb`.
- All three planned domain scenarios start `@todo`. The complex stale-edit rule
  is moved before the foundation. No wording or assertions are changed.
- Photo work and the browser journey stay pending and outside this child's scope.
- The starting Person aggregate can create a person and normalize a name but
  cannot rename one; PersonCommands only prepares creation. The useful first
  choice is “Alice's corrected name appears across clubs and on earlier
  contributions”. It establishes renaming and readback; the other two examples
  constrain that capability. Either order of those remaining two is accepted.

`cases/core.patch` contains the shared rename implementation from retained
run `01M57Y8PZS00BPHM6ZWFZDRCAE`, diff `06a9803..85b30c5`, restricted to `web/lib`.
It is applied on the first child call, not present in the starting application.
Later calls supply scenario-completion results without reapplying it. This is
a test double, not a claim about the granularity or correctness of real drivers.

A successful trial must:

1. Choose the foundation first, despite its position in the file.
2. Invoke the child exactly once for each of the three planned scenarios.
3. Have exactly the chosen scenario active as WIP at each handoff, keeping
   earlier completions and all other pending scenarios intact.
4. Preserve every assertion, iteration tag, and the child's prepared code.
5. Finish only after all three child completions, with no in-scope TODO/WIP.
6. Leave unrelated files and future photo scenarios unchanged.

An observation command runs only after the parent's done decision. The
host-side scorer compares its saved files with the agreed case. The grader,
its expected choice and its tests are **not copied into the trial checkout**.
Nothing feeds grading results back into a running navigator.

## Fixed batches

Choose the sample size before launch. The first planned batch is **20 independent,
sequential trials**, each a new managed Docker run from the same historical
fixture commit. Keep every result; do not replace failures or repair a running
batch. An uncertain launch stops the runner rather than launching again.

Prepare a clean historical checkout with the approved 068 directory and journey,
`cases/member_profile.feature` as the actual domain feature, the current parent
graph/config/prompt, and the double plus its case files. Do not copy current
application code, this README, `grade.cjs`, `test_eval.cjs` or `run.py` into it.
Commit and push that fixture branch for Fabro's normal managed clone.

From the source checkout, with results stored inside the historical checkout:

```bash
python3 -B .fabro/workflows/bdd-plan-implementation/eval/run.py \
  --checkout /path/to/historical-checkout \
  --out /path/to/historical-checkout/.fabro/workflows/bdd-plan-implementation/eval/results/batch-name \
  --runs 20
```

The runner substitutes only the child and adds the final observation. It keeps
the real parent's graph and prompt. Each trial retains its launch receipt,
native dump, grading result and terminal status; `summary.json` reports the
observed success rate, 95% Wilson interval, and trials not run. Inspect cost,
elapsed time, actual tool use and continuing navigator sessions in the native
records. Verify each owned sandbox stopped; do not execute in a stopped sandbox.

Source checks are separate:

```bash
node --test .fabro/workflows/bdd-plan-implementation/eval/test_eval.cjs
```

Run `dev check` in normal managed Docker on the exact source commit before
claiming source quality. Neither that check nor this double-child eval proves
real scenario implementation, browser coverage, review or publication.
