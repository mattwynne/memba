# Operating the BDD plan implementation workflow

> **One functional historical run has passed on stock 0.389.** Managed source
> checks and native editing ownership were verified. Strict HEAD-tree-only
> selection was not met: the first selector also read Git history. See the
> [result and limits](REHEARSAL.md).
> This is not general reliability proof or approval for a current product run.

This opt-in workflow implements the domain scenarios in one active plan. It does
not implement journeys, refactor or review the result, publish it, or mark the
iteration merged. Use `bin/dev fabro deliver <plan> --domain-only` for the guarded
real-plan route after approval. Ordinary delivery without that flag is unchanged.

## Prepare the committed plan and TODOs

For a real iteration, start with a published ready/validated plan and committed
acceptance features. The delivery helper owns validation and reserves the
implementing status; do not mark it active by hand to bypass those checks.
For an already approved split-phase fixture, require one committed active plan.
Give
each in-scope domain `Scenario`, `Scenario Outline`, or `Examples` declaration
its own `@todo`. Keep journeys separate; outstanding journeys do not keep the
domain loop running.

Once the plan is active (or when inspecting an approved active fixture), check
the exact commit the workflow will use:

```bash
dev bdd pending HEAD
dev bdd pending HEAD --json
```

`pending` reads an immutable Git snapshot. It reports eligible domain work and
journeys separately, so uncommitted files do not change the answer. An empty
domain list means only that this loop has no more work; it does not mean the
iteration is merged.

Fix errors before launch. The command fails closed when there is not exactly one
active plan, a feature is malformed, iteration ownership is missing or
ambiguous, any scenario is already WIP, or a merged iteration still has a TODO.
A TODO journey left under a merged iteration is also an error. TODOs owned by a
future iteration are allowed but are not choices for the active plan.

Current limitation: if the active work is TODO only through an inherited tag,
`pending` finds no locally pickable declaration and fails closed. Add no
workaround to the runbook; this needs a separate policy decision.

## Useful human commands

List work at another committed snapshot:

```bash
dev bdd pending COMMIT
dev bdd pending COMMIT --json
```

Activate one exact declaration in a completely clean worktree:

```bash
dev bdd pick acceptance-tests/features/member.feature:42
dev bdd pick acceptance-tests/features/member.feature:42 --from COMMIT
```

The line must be the exact `Scenario`, `Scenario Outline`, or `Examples`
declaration and must have its own local `@todo`. `pick` validates the entire
choice before changing only that tag to `@wip`. There may be no staged changes,
unstaged changes to tracked files, or non-ignored untracked files. `--from` also
refuses when the named commit is no longer `HEAD`.

`pick` does not run a model, implement code, run tests, commit, or publish. Its
input is the feature-and-line reference above; selector JSON and implementation
paths are not a human interface.

For a picked Outline or Examples block, all eligible rows belong to one
selection and run as separate tests. The rebased code passed its exact-source
managed gate on 0.389; earlier standalone CLI row-selection proof remains scoped
to 0.316.

## Start the workflow after approval

Check the installed client and actual target server first:

```bash
fabro --no-upgrade-check version --server https://fabro.home.wynne.family --json
```

Both must be the qualified 0.389 version; an upgraded local CLI alone is not a
server upgrade. For a real ready/validated iteration, show the exact plan and
mode to Matt, explain remaining obligations and obtain launch approval, then use:

```bash
bin/dev fabro deliver docs/iterations/NNN-topic/plan.md --domain-only
```

The helper requires clean published main, validates ready plans, checks
predecessors and WIP, commits/pushes the implementing reservation, and binds
public pending output to the requested plan and source SHA. It launches detached
with explicit `memba-dev` and literal `HEAD`, without product publication or
post-merge review. A run ID is launch acknowledgement, not a passing result.
Uncertain acknowledgement preserves the reservation: inspect before retrying.

Only an explicitly approved fixture or split-phase operation that already meets
those prerequisites should use the stock-native entry directly:

```bash
fabro run .fabro/workflows/bdd-plan-implementation/workflow.toml --environment memba-dev
```

The TOML and `workflow.fabro` are siblings. The imported scenario package and
all prompt files are descendants of that directory, as required by stock
0.389's package collector. Keep the nested package canonical; do not copy its
graph or prompts elsewhere.

Do not substitute a SHA or another reference for the run input. Both the
checked-in input and the helper's explicit `-I commit=HEAD` use the literal Git
reference `HEAD`; the selector receives only that reference in its canonical task
body. Every selector visit is truncate-fidelity with no thread ID or output
schema. Stock adds its minimal goal/run-ID preamble, so this is not the same
invocation as the earlier isolated full-fidelity literal-SHA selector trials.
The setup command receives the input through stock command-script substitution
and rejects anything other than exact `HEAD`, so a CLI override stops before
dependency installation or selector execution.

After that guard, the graph runs this declared bootstrap exactly once:

```bash
npm ci --prefix acceptance-tests --no-audit
```

It installs the committed acceptance-test dependencies needed by public
`dev bdd pending` in a fresh managed clone. It does not start the application or
run tests. `/.fabro/tmp/` and `/.fabro/blobs/` are narrow tracked ignore entries;
setup verifies them and does not modify `.git/info/exclude`.

The assembled loop first runs the deterministic public pending check. A separate
fresh, read-only selector inspects the current committed tree, chooses one
eligible declaration, and then deterministic validation captures the current
full SHA and calls `pick --from CURRENT_SHA`. The scenario workflow
uses a fresh driver for each assignment. One implementation navigator
conversation continues across the whole plan.

The navigator and fresh drivers run focused tests as ordinary commands. After
the scenario passes, the graph runs the full `bin/dev check`. A failed focused
or full check returns the same scenario for repair; a successful full check ends
that one scenario and produces the updated checkpoint commit. The pending check
then runs against that commit before a fresh selector chooses again. A scenario
may already be green: record that result and do not invent a failure or
unnecessary code change. Passing the standalone CLI checks does not prove this
coordination loop.

Keep the launch acknowledgement and run ID. If the command returns without a
clear acknowledgement, inspect the workflow in Fabro's run UI and with
`fabro inspect RUN_ID --no-upgrade-check`. Never launch a
duplicate while the first run may exist.

## Find choices and results

Use the run ID once known:

```bash
fabro inspect RUN_ID --no-upgrade-check
fabro events RUN_ID --pretty --tail 200 --no-upgrade-check
fabro logs RUN_ID --tail 300 --no-upgrade-check
fabro artifact list RUN_ID --no-upgrade-check
```

`inspect` is the durable status and checkpoint summary. `events` shows selector,
navigator, command and stage outcomes. `logs` is the raw worker trace. Native
stage artifacts can be copied to an empty private directory when needed:

```bash
fabro artifact cp RUN_ID DESTINATION --tree --no-upgrade-check
```

Fabro 0.389 keeps durable execution state and CAS payloads rather than creating
new `fabro/meta/` branches. Confirm the upgraded server's artifact/workspace
export behavior before treating a copied directory as a complete snapshot; the
new release's static validator does not establish runtime capture behavior.

The workflow archives each previous scenario's entire scratch directory under
`.fabro/tmp/bdd-plan/scenarios/<n>/` before creating fresh `.fabro/tmp/bdd/`.
This retains partial or complete bases, results, check logs and arbitrary logs;
the final scenario remains in active scratch. Current pending state is in
`.fabro/tmp/bdd-plan/pending.json`, preselection Git identities are in
`selection.json`, and successful reasons accumulate in
`selection-notes.jsonl`. Fabro's events, artifacts, checkpoints and run branch
remain the durable run record.

Treat copied artifacts and logs as private. Do not paste credentials, origin
URLs containing credentials, tokens, or environment dumps into issues or
examples. Synthetic selector fixtures are evaluation evidence, not proof of
real workflow use.

## Stop and inspect

Cancel a live run from its Fabro run page, then confirm its terminal state with
`fabro inspect`. The installed CLI has no run-level `fabro stop` command;
`fabro server stop` stops the whole service and is not a substitute.
`fabro steer --interrupt` interrupts an agent turn but is not a reliable way to
stop the workflow.

After cancellation or failure, preserve the run and its sandbox evidence. Do
not restart a stopped sandbox and do not use `fabro rm`. Inspect status, recent
events and logs before deciding what to recover.

**On stock 0.389, `fabro sandbox cp` starts a stopped container and leaves it
running.** It is not a passive read. Do not use it after a terminal run under
the no-restart rule. Prefer stored run artifacts. If they are incomplete, an
operator can use a passive raw Docker filesystem archive/copy from the exact
owned stopped container, without attaching, starting or executing it.

Check the actual Docker host, `fabro` (`192.168.1.201`), not the HTTP service
hostname: `fabro.home.wynne.family` reaches the proxy on `192.168.1.200`.
Confirm the exact container ID, `petri.run` label and image, and retain three
fresh matching stopped-state observations after evidence retrieval. An empty
query on the proxy's Docker daemon is not proof that a run container is absent.

Do not print raw Docker exec events, command arguments, Actor attributes or
process environments: Git transport authentication can appear in that metadata.
Filter to lifecycle start/stop/die/kill events and allowlist only time, action
and container ID before diagnostic output reaches a tool transcript. Sanitising
a saved file afterward does not erase an already exposed credential.

Archive a terminal run only after its evidence has been reviewed:

```bash
fabro archive RUN_ID --no-upgrade-check
```

## Recover manually from a preserved checkpoint

There is no automatic recovery controller. First inspect the failure and the
saved work. List checkpoints without changing the run:

```bash
fabro rewind RUN_ID --list --no-upgrade-check
fabro fork RUN_ID --list --no-upgrade-check
git log fabro/run/RUN_ID --oneline
git diff BASE_COMMIT..fabro/run/RUN_ID
```

Choose a checkpoint only after checking its source diff, scenario tag, test
evidence and next node. Preserve the run branch commit, metadata, artifacts and
logs. Do not run mutating `fork`, `rewind`, `resume`, or sandbox commands from
this unproven procedure. The recovery operation must be agreed and verified to
allocate a fresh owned run and environment, never restart the stopped sandbox.

Never treat a checkpoint, partial test log, or green scenario alone as a
completed full check. Once fresh-run recovery and its launch syntax have been
verified, rerun `dev bdd pending NEW_COMMIT` on the recovered committed source
and let the normal selector-and-pick boundary validate the next scenario.
