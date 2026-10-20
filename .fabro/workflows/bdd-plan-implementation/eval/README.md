# Plan-parent eval

Use the real plan navigator and an imported workflow double—not another round of
scenario implementation. There are three pieces:

- `double.cjs`: require one active WIP, supply prepared code, remove WIP and
  append the selection and current tags to one child-call log.
- `grade.cjs`: check that log, native imported-workflow completions, the final feature and
  final Git diff. No per-child feature copies, code hashes or file inventories.
- `run.py`: launch fresh runs, collect native events and the final artifacts,
  then report every attempted run with a 95% Wilson interval. Receipts are the
  record; attempted directories, acknowledged run IDs and known terminal results are
reported separately. A failed export cannot erase a known terminal result. `--report`
  recomputes the summary without launching anything. No `fabro dump` dependency.

## Historical case and approved criteria

Product base: `5645fb62d50892b763f419f4b08e5d22b9a0e4bd`. Approved iteration 068
plan, links and scenarios: `c5402f0bd8fc99587c8b220b51643ecd650377eb`.
`cases/member_profile.feature` moves the whitespace-validation rule first, changing no
assertions. All three name-change scenarios begin TODO; photo work and the
browser journey stay pending.

The first choice must establish a successful rename: either “Alice's corrected name
appears across clubs and on earlier contributions” or “Alice's older edit requires
confirmation of the newer name”. Whitespace-first fails; either remaining order is accepted.
Require exactly three successful imported-workflow completions, only one selected WIP at each
handoff, preserved earlier completions, unchanged assertions/future work, and
all prepared code retained at completion with no unrelated edits.

This is a new historical fixture and fixed 20-trial batch, not a regrade or resume of
the original failed trial `01M58Z7AFPYM8A5JS4R0HT2EPN` (19 others unrun).
The native runtime defects are not fixed here. This version uses stock Fabro
imports instead of a separate child engine, and prompts agents to use shell
writes instead of native uploads. Source checks alone do not prove that agents
will follow that instruction.

## Preparing and running

Use one fresh checkout from the historical base, with the approved 068 directory,
journey, reordered domain feature and current parent/scenario runtime files.
Copy only `eval/.gitignore`, not eval code, cases or results. Start from the base,
not the old fixture's history. Commit and push the fixture for normal managed Git.
The runner refuses a starting tree containing eval files other than `.gitignore`.

The host bundles the double and prepared patch into the imported command. They are
not copied into the managed checkout; the patch is supplied only when that child
executes. The shared patch is `06a9803..85b30c5`, restricted to `web/lib`, applied
once. It represents a prepared result, not real driver granularity or test proof.

Freeze the source, fixture, case and batch manifest before launching. Run exactly
20 independent sequential trials from the same model, prompt and image. From the
source checkout:

```bash
python3 -B .fabro/workflows/bdd-plan-implementation/eval/run.py \
  --checkout /path/to/historical-checkout \
  --out /path/to/historical-checkout/.fabro/workflows/bdd-plan-implementation/eval/results/new-batch \
  --runs 20
```

Trials are sequential, each in fresh managed Docker. Wrong graded choices remain
in the sample; grader parsing/I/O errors and infrastructure/collection failures stop for inspection, without
repair or replacement. Unknown launch acknowledgements never trigger a relaunch.
Keep native events, artifacts and failures. Audit actual tool use/cost and verify
owned sandboxes stopped. Real-scenario import wiring is inspected, not separately tested.

Local pure tests: `node --test .fabro/workflows/bdd-plan-implementation/eval/test_eval.cjs`
and `python3 -B -m unittest discover -s .fabro/workflows/bdd-plan-implementation/eval -p 'test_*.py'`.
Run full `dev check` separately in managed Docker on the exact source commit.
`cases/stock-fabro/workflow.fabro` is a tiny model-free capability check: shell
writes before/inside/after an import must retain ownership and contents, and
native output export must resolve the imported command output. It uses no real
scenario or application tests and no patched binary. All failures route to a
failing terminal command, not the success exit.

The original failed trial and its unmodified evidence remain in ignored
`results/2026-10-19-v1/` and the retained historical source refs.
