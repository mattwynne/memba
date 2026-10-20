# Commit-only next-scenario decision

This tests one read-only prompt, not a parent/child implementation workflow.
The only task input is a Git commit. The agent must discover the one active
implementation plan using repository status conventions, its pending domain
scenarios, and enough existing code/guidance to choose the next scenario.
It returns a plan path, feature path, exact scenario name and short reason.
It must not edit files, run application tests or delegate. These are prompt
instructions; audit actual tool use and Git changes, not just the final answer.

## First fixed case

`case.json` is host-side grading data, never sent to the agent or included in its
fixture checkout. The fixture starts from historical preimplementation code and
approved 068 planning files. Plan and index both say `implementing`, making it
the single active plan. Domain scenario wording/assertions/tags are preserved;
whitespace validation is first in file. Other iterations and the browser
journey remain pending. No completed rename implementation or eval answers are
copied into that commit.

Predeclared pass set: find the actual active plan and feature, then select either
successful rename example first, not whitespace validation. The reason must be
present but is not model-judged. This is the previously agreed foundation-before-
validation criterion. Zero/multiple active-plan discovery is in the prompt, but
only the unique-active-plan case is exercised by this first batch.

Twenty sequential fresh agent sessions read the same immutable commit in one
normal managed Docker run. Distinct thread IDs and full fidelity prevent
conversation reuse/preambles across trials. Each is instructed to use Git reads
at the supplied commit. Wrong decisions stay in the sample; no repair, steering,
replacement or prompt edits midbatch. Keep every response, native event and
launch/terminal receipt; unknown acknowledgements stop rather than relaunch.

From the exact committed source checkout, with results inside the clean fixture:

```bash
python3 -B .fabro/workflows/bdd-plan-implementation/eval/selection/eval.py \
  --checkout /path/to/fixture \
  --out /path/to/fixture/.fabro/tmp/commit-selection-batch \
  --runs 20
```

There is no imported command, double, tag activation, scenario implementation or
application-test run. Native Fabro stores agent responses directly. Offline
`--report --out ...` recomputes counts and a 95% Wilson interval. Missing and
failed stages remain visible. Inspect session/model/tool events, exact source
commit and actual resource cleanup separately. No result proves later plan
coordination or implementation.

Run pure tests with `python3 -B -m unittest discover -s .fabro/workflows/bdd-plan-implementation/eval/selection -p 'test_*.py'`.
Executable changes also need exact-source managed-Docker `dev check`; that is
separate source-quality evidence, not part of the agent's task.
