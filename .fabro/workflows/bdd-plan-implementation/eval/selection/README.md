# Commit-only next-scenario decision

This tests one read-only prompt, not a parent/child implementation workflow.
The only task input is a Git commit. The agent must discover the one active
implementation plan using repository status conventions, its pending domain
scenarios, and enough existing code/guidance to choose the next scenario.
It returns a plan path, feature path, exact scenario name and short reason.
It must not edit files, run application tests or delegate. These are prompt
instructions; audit actual tool use and Git changes, not just the final answer.

## Fixed cases

`case.json` is host-side grading data, never sent to the agent or included in its
fixture checkout. The completed first case, source `3f30c0ad` / fixture `a481d142`,
tested choosing a useful foundation from the approved 068 plan before implementation.
It selected the cross-club/history rename in 20/20 independent sessions. Its original
case and evidence remain in `eval/results/commit-selection-20261020/`; this case
replaces the host-only `case.json` for the next batch without changing `prompt.md`.

The next case deliberately uses a **synthetic partial fixture**, not a historical
checkpoint. Starting from the clean first fixture, it imports the historical rename
path from `444ee7d72`, adapts stale historical step APIs to current query/dispatch
modules, and leaves *rename-only* blank/length and stale-baseline enforcement out.
Existing Person creation validation is unchanged. The cross-club/history domain
example is executable and passes. Both remaining 068 domain examples retain their
original wording, assertions and `@todo`, and have been run separately in normal
managed Docker with tags included: they fail at their behavioural assertions after
all setup/action steps pass. Photo (069), browser journey and unrelated iterations
remain untouched. The 068 plan/index occupy the one documented active WIP slot;
an inherited old 070 header still says `implementation`, outside the index's active
status vocabulary. This fixture does not prove clean arbitrary plan headers.

Both pending constraints are acceptable choices. This case measures exclusion of
done/out-of-scope work, **not** preference between those constraints. The reason
must be present but is not model-judged. Only this unique-active-plan, partial-
implementation commit is exercised; no/multiple active plans remain untested.
The case is not production implementation or evidence that the synthetic omissions
are safe to deploy.

The third fixed case continues from that synthetic fixture. Only the historical
rename-name normalization, blank rejection and 100-grapheme limit are restored;
the Person creation invariant is unchanged. Cross-club/history and whitespace
validation are now executable, while the stale-edit domain example remains
`@todo` and fails its original conflict assertion when separately exercised.
Both already-completed examples are unacceptable choices, as are photo (069),
the browser journey and other iterations. The sole acceptable next scenario
is the stale-edit example. The source plan's historical background still says
there is no rename command, and 070 retains its legacy `implementation` header;
actual code and the documented active-index convention govern this fixed case.
This does not test an all-done/no-pending response or generic plan ambiguity.

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
