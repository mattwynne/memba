# Running the scenario-implementation evals

We have two evals:

- **Navigator unit eval:** give the navigator a situation and see what it chooses next.
- **Full workflow eval:** ask the workflow to implement a scenario and pass the checks, without human help.

Neither uses another model to decide whether it passed. Refactoring and review are outside this workflow.

## Navigator unit eval: the scenario passes

### What we're testing

The selected scenario and its supporting tests pass. The navigator has removed only `@wip` and confirmed that the same scenario still passes. No full check has run on the implementation yet.

We want the navigator to choose `check`. More coding, refactoring, review, stopping or giving no choice fails this eval. [The case](cases/scenario-passes.md) supplies the observations, but doesn't tell the model which answer earns a pass.

### Run it before and after changing the instructions

From the repository root, with Fabro signed in:

```sh
python3 .fabro/workflows/bdd-plan-implementation/scenario/eval/navigator.py run \
  --runs 20 --out .fabro/workflows/bdd-plan-implementation/scenario/eval/results/scenario-before
```

Choose the number of trials before starting. This asks the navigator the same question 20 times, one at a time. Each trial starts fresh and cannot see earlier answers. It uses the workflow's model and reasoning settings, but no tools, drivers or test commands.

The runner saves the instructions, case, settings and every answer. It won't overwrite an existing results directory or retry a failed trial. Fabro stops the run's Docker container when it finishes.

After changing the navigator, use a new results directory, such as `scenario-after`. Keep the case, number of trials, model and other settings the same. `--prompt PATH` lets you try a separate instructions file. Keep every result; don't keep rerunning until the numbers look good.

### Read the results

The report shows how many answers chose `check`, a **95% Wilson confidence interval** showing uncertainty in that success rate, and how many requested trials produced no answer. Missing answers remain visible and make the run incomplete.

Compare both the rates and their uncertainty. A small difference may be chance. The statistics assume independent trials and apply only to this case, not every situation the navigator could encounter.

The command exits with an error unless every requested trial passes. That makes failures easy to spot, but even a perfect score isn't a reliability guarantee. Fabro saying its run succeeded only means it finished running the trials.

To read saved results again without model calls:

```sh
python3 .fabro/workflows/bdd-plan-implementation/scenario/eval/navigator.py report \
  .fabro/workflows/bdd-plan-implementation/scenario/eval/results/scenario-before
```

If you interrupt the command, Fabro may still be running. Check the run ID in `launch.json` before starting anything else. The report needs the downloaded Fabro records in `<output>/dump/`. If a launch didn't return a clear answer, find out whether it started rather than launching a replacement.

To test the runner, scoring and workflow connections without model calls:

```sh
python3 -B -m unittest discover -s .fabro/workflows/bdd-plan-implementation/scenario/eval -p 'test_*.py'
```

This unit eval checks a decision given supplied information. It doesn't test gathering that information, remembering a long conversation, or actually implementing the scenario and running the checks.

## Full workflow eval

1. Prepare [the name-change case](cases/name-change.md). Record the starting code and workflow commits, model and Docker image.
2. Run it **three times with the same code and settings**, each in a fresh Fabro environment. Never use another run's implementation as the starting point.
3. Supply the iteration plan. Don't steer the agents, edit their files or fix things for them.
4. Inspect the actual code changes, test output and agent records using the checklist below. This inspection is part of our eval, not a reviewer inside the workflow.
5. Write up every result, including failures, in `results/<date>-<run-id>.md`. Keep code snapshots in Git and logs in Fabro, and link to them. Results are Git-ignored; put important lessons in the kaizen note.

All three runs must implement the agreed behaviour, pass the final full checks and finish without human help. We no longer require a refactoring phase or a review inside this workflow. Three successes show repeated completion of this exercise, not reliability on every task.

Decide manually whether to stop, change something or try again. Don't automatically repair and rerun until it passes. A change to the code, instructions, case, model or image starts a separate set of results. Record time and available cost; no extra limits have been added, and Fabro's defaults still apply.

### Did it finish the job?

Mark each item **observed**, **failed** or **not observed**, with evidence:

- Exactly the intended WIP scenario initially ran and failed because implementation was missing, not because the test setup broke.
- The scenario and supporting tests then passed. Only its WIP tag was removed; its wording, assertions, iteration tag and unrelated pending examples stayed intact.
- The same scenario passed under the ordinary focused command after removing the tag.
- The implementation uses real Membership commands, events, projections and queries. It doesn't fake test results or weaken authorization, historical replay or other agreed rules.
- `dev check` passed on the final code, and the workflow finished. Fixes for failed checks went through the checks again.
- No refactoring or review stage ran, and the agents did not delegate those jobs to other agents.
- No human help was needed, and the run's Docker container stopped.

### Did it work as intended?

- Predictions came before tests and said what result was expected and why.
- A wrong starting prediction caused a return without code edits.
- Drivers returned at the predicted next acceptance result or an unexpected result, rather than taking on the next assignment themselves.
- The navigator kept its conversation and each driver started fresh.
- Agents corrected ordinary test-selection and assignment mistakes without human help.

A situation that never arose is **not observed**, not passed. Missing evidence that the job finished prevents a successful result. Keep preparation failures and uncertain launches too. Reading logs and inspecting results don't count as helping the agents.

## Earlier results

The old `bdd-implementation` workflow included refactoring and review. Its saved results remain in `results/` and its source is retained in Git. The earlier navigator unit case was about completed **review repairs**, not a newly passing scenario. Do not combine those measurements with this case or count the old full-workflow runs as tests of the new scope.
