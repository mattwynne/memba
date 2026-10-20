# Operating the BDD plan implementation workflow

> **Draft:** the workflow is not assembled or proven yet. The checked-in graph
> still uses the old navigator and plan input. Do not launch it from this guide.
> Confirm the final launch command, stop procedure, artifact paths and recovery
> steps against the assembled graph and one real rehearsal first.

This opt-in workflow implements the domain scenarios in one active plan. It does
not implement journeys, refactor or review the result, publish it, or mark the
iteration merged. The normal `fabro deliver` command is unchanged.

## Prepare the committed plan and TODOs

Start with one committed active plan and committed acceptance features. Give
each in-scope domain `Scenario`, `Scenario Outline`, or `Examples` declaration
its own `@todo`. Keep journeys separate; outstanding journeys do not keep the
domain loop running.

Check the exact commit the workflow will use:

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
workaround to the runbook; resolve this policy in the assembled workflow.

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

Current limitation: picking a multi-row Outline or Examples block works, but
`dev test:wip` currently rejects the multiple expanded rows. Resolve that before
claiming the loop works for general plans.

## Eventually start the workflow

**Launch command: to be confirmed after assembly and rehearsal.** Do not reuse
the current README command or invent input flags.

The assembled loop should first run the deterministic pending check. A separate
fresh, read-only selector receives only the updated commit, chooses one eligible
declaration, and then `pick --from COMMIT` activates it. The scenario workflow
uses a fresh driver for each assignment. One implementation navigator
conversation continues across the whole plan.

The graph owns focused checks and the full checks. A failed check returns the
same scenario for repair; a successful full check ends that one scenario and
produces the updated checkpoint commit. The pending check then runs against that
commit before a fresh selector chooses again. A scenario may already be green:
record that result and do not invent a failure or unnecessary code change.
Passing the standalone CLI checks does not prove this coordination loop.

Keep the launch acknowledgement and run ID. If the command returns without a
clear acknowledgement, inspect the workflow in Fabro's run UI and with
`fabro inspect bdd-plan-implementation --no-upgrade-check`. Never launch a
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

The assembled workflow is expected to archive each previous scenario's scratch
notes, logs and base under `.fabro/tmp/bdd-plan/scenarios/` before clearing
`.fabro/tmp/bdd/`. Confirm the exact final layout after the boundary changes are
integrated. These files explain a scenario handoff; Fabro's events, artifacts,
checkpoints and run branch remain the durable run record.

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
events and logs before deciding what to recover. Archive a terminal run only
after its evidence has been reviewed:

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
evidence and next node. Prefer `fork` when the old run must remain untouched.
`rewind` replaces and archives a terminal source run, so use it only when that
is the intended disposition. Both commands create a new run that still needs an
explicit resume:

```bash
fabro fork RUN_ID NODE@VISIT
# or: fabro rewind RUN_ID NODE@VISIT
fabro resume NEW_RUN_ID
```

Before using these mutation commands, confirm their exact behaviour against the
assembled workflow and preserved-sandbox policy. Never treat a checkpoint,
partial test log, or green scenario alone as a completed full check. If recovery
changes the source commit, rerun `dev bdd pending NEW_COMMIT` and let the normal
selector-and-pick boundary validate the next scenario.
