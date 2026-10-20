# Implement one BDD scenario

`bdd-scenario-implementation` implements one agreed domain scenario. It does not refactor or review the finished work, publish code, or change `fabro deliver`.

```text
Predict and run the starting scenario
                 ↓
       Navigator assigns one change
                 ↓
          Fresh driver makes it
                 ↓
       Navigator reads the results
          │                  │
     more work          scenario and
          │         supporting tests pass
          └── repeat         ↓
                    Remove only @wip
                    Confirm it still passes
                             ↓
                         dev check
                        │         │
                      fails     passes
                        │         ↓
                  assign a fix   Done
```

Refactoring and review belong in separate workflows. They are not included here, and this change does not create those workflows. “Done” means the scenario is implemented and the checks pass—not that someone has reviewed it or approved publication.

## Run it

Supply `plan` as the path to the existing iteration plan, with its links to ADRs and designs. Mark exactly one domain scenario `@wip` and remove its `@todo` tag. Use the normal managed checkout and pinned Docker image in [workflow.toml](workflow.toml).

The navigator predicts the first failure before running `bin/dev test:wip`. That command rejects zero or multiple selected scenarios. It also exits nonzero when the scenario passes, asking the navigator to remove `@wip`. The actual test output tells the navigator which happened.

The navigator uses the literal full-fidelity thread `bdd-navigator`. When this graph is imported by the plan workflow, the parent navigator uses that same thread, so one conversation continues across every scenario in the plan. Memory of earlier work is useful context, but the prompts require current selection, source, setup and test evidence to be re-read for each scenario. Every truncate-fidelity driver starts fresh, works on one self-contained assignment and returns at the predicted next acceptance failure or actual green result.

An already-covered selected scenario may start green. That is valid evidence, not a reason to fabricate a red result or make unnecessary changes. The navigator removes the WIP tag once the scenario and supporting tests pass, confirms the same scenario with an ordinary focused command, and sends it to `dev check`. Failed checks return for repair; passing checks finish the workflow. The check node gives the stock command runner 1800 seconds because observed complete `dev check` runs can exceed the old ten-minute allowance.

## Stock Fabro compatibility

This graph can run standalone or be reused by the plan workflow through Fabro's
built-in `import`. A tiny `checked` node gives the import its required unconditional
exit boundary; failures still go back to the navigator or stop, never to that exit.

Both agents are instructed to write/edit files using shell commands, not native
`apply_patch`/upload tools. Fabro `0.316.0-nightly.0` uploads can change a user-owned
file to root ownership. Shell writes avoid that upload path without changing
Fabro or repairing permissions. Following that instruction is not tool-enforced;
it still needs observation in the model eval.

## What the roles share

Both roles use ordinary files under `.fabro/tmp/bdd/`:

- `change.md`: the assignment, starting result and predicted next result.
- `result.md`: what the driver changed, test results and links to logs.
- `check.log`: the actual output from `bin/dev check`.
- `base`: the starting Git commit, so later workflows can inspect the complete change.

Nothing parses these notes or approves a handback. There is no controller or separate reviewer. The graph routes the work and checks the full test command's exit status. The roles are instructed not to run extra full checks or delegate review/refactoring inside this workflow.

The plan graph archives the entire scratch directory, including any distinct driver logs, before it recreates the directory for the next scenario. The final scenario's scratch remains in place when the plan finishes. This keeps each scenario's `base`, assignments, results and check evidence without adding a parsed state protocol.

See the [eval instructions](eval/README.md) for the navigator decision test and the complete scenario exercise. Older results from `bdd-implementation` remain under the ignored `eval/results/` directory and in their saved Git commits; they are not results for this smaller workflow.
