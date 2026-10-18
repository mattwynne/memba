# A repeatable workflow eval

A complete-workflow exercise and a small navigator decision eval. Neither uses a model-based judge or changes the production workflow's control flow.

## Navigator unit eval: after review repairs

[The fixed case](cases/after-review-repairs.md) supplies the state just before the failed handoff in run `01M56FPDS23ZHB8G3J2YK9RWS6`: repairs finished, focused tests green, previous full check stale. Its source is navigator visit12 / driver visit8. The case is a distilled set of observations, not the entire historical conversation.

**Required decision: `preferred_next_label: check`.** Stopping, choosing another coding assignment, referring back to refactoring, or omitting a route fails. This specifies the new direct-to-checks behaviour we want; the current prompt does not offer that choice. This is not an estimate of the old end-to-end stop rate. The expected answer lives in the scorer, not in the case sent to the model.

From the repository root, with normal Fabro authentication:

```sh
python3 .fabro/workflows/bdd-implementation/eval/navigator.py run \
  --runs 20 --out .fabro/workflows/bdd-implementation/eval/results/navigator-before
```

Choose the sample size **before** running. The command snapshots the current production navigator prompt, case and production model/environment configuration, then makes that many sequential, independent native Fabro prompt calls. It uses the same model and high reasoning setting, but no tools, drivers, checks or reviewers. Full fidelity suppresses earlier trials' preambles; prompt nodes have no shared conversation. Normal managed Docker lifecycle stops the sandbox on termination.

Change the navigator only after observing the baseline, then use the same sample size and case with a new output directory (for example `navigator-after`). `--prompt PATH` can test a candidate prompt without editing the production prompt. Do not change the case between versions or replace unfavourable trials. Compare both success rates and their uncertainty; a small difference is not proof of improvement.

The report shows successes / observed responses, a **95% Wilson confidence interval**, and missing/error responses separately. These intervals describe this fixed decision case, not reliability across other situations; they assume independent samples. Infrastructure failures are not silently dropped: their requested trial slots remain visible and make the batch incomplete. No automatic repair, retry or replacement of a trial. The process exits nonzero unless every requested trial passes; that is useful red/green feedback, not a statistical guarantee. Fabro's batch status alone is **not** the grade.

Raw prompts, responses, native extracted route labels, launch ID and statistics remain in the ignored output directory. Recompute a report without model calls:

```sh
python3 .fabro/workflows/bdd-implementation/eval/navigator.py report \
  .fabro/workflows/bdd-implementation/eval/results/navigator-before
python3 -B -m unittest discover -s .fabro/workflows/bdd-implementation/eval -p 'test_*.py'
```

An interrupted runner does not cancel or relaunch its native run. Inspect the saved `launch.json` and finish retrieving its dump before reporting; never start a replacement for an unknown launch acknowledgement. Existing output directories are refused. The dump must be at `<output>/dump/` for `report`.

This eval measures the navigator's **decision given supplied evidence**. It does not test tool use, long conversation memory, actual `dev check` execution, or graph wiring. Those still need the complete-workflow exercise below. Adding this eval does not add a “blocked” branch or change production routing.

## Complete-workflow exercise

1. Prepare [the name-change case](cases/name-change.md). Record its exact prepared Git commit, workflow/test-tooling commit, model and Docker image.
2. Freeze those versions for a batch of **three independent runs**. Start every run from that same prepared source in a fresh normal Fabro environment, never a previous run's implementation.
3. Launch the normal workflow with the iteration plan as its only input. Do not steer agents, edit their files or rescue the work during an eval. Keep every failed run as well as successes.
4. Inspect the actual resulting diff, test output and native session records against the checklist below. The workflow's own review is evidence, not the eval verdict.
5. Save a result in `results/<date>-<run-id>.md`. This directory is Git-ignored. Keep code snapshots in Git and raw logs in Fabro; link to them. Preserve important findings in the existing kaizen note.

**Success means all three runs finish without human help**, preserve the agreed behaviour, pass full checks and complete fresh review. A human intervention fails the unattended criterion even if a later rescue finishes. Three successes demonstrate repeatability on this one case, not general delivery reliability.

Fixes, stopping a batch and deciding to rerun are manual decisions. Never automatically repair and restart the eval until it passes. Any code, prompt, model, image or fixture change starts a new version's results; do not mix successes across versions. Time/cost limits are deferred: record elapsed time and available cost rather than invent new limits. Fabro's native defaults still apply; no old admission is renewed.

## Checklist

Mark each item **observed**, **failed**, or **not observed**, with a link or log location. Do not award credit for an agent merely saying it followed a rule.

### Finished job

- Exactly the intended `@wip` scenario executed and initially failed for a real missing implementation or assertion, not a setup error.
- That scenario later passed. Its `@wip` tag was removed, its wording/assertions were preserved, and ordinary regression coverage still includes it.
- The code implements the agreed rule through real Membership commands/events/projections/queries; it does not fake the outcome in test context or weaken authorization, historical replay or other plan constraints.
- The actual final full check passed on the resulting code, followed by a fresh combined review. Necessary fixes were checked and reviewed again.
- No human intervention was needed. The native run completed successfully and its owned sandbox stopped.

### How it worked

- Predictions preceded test execution and described a concrete expected result/reason.
- If an initial prediction was wrong, no edits preceded returning the observation for reconsideration.
- Drivers returned at the predicted acceptance result or an unexpected acceptance result, rather than solving a different next obstacle.
- Native records show navigator conversation reuse across visits and fresh driver sessions. Review did not inherit the implementation conversation.
- Any refactoring started with the relevant tests green and considered the cumulative diff. No worthwhile cleanup is a valid outcome; forced refactoring is not a goal.
- Ordinary selector/assignment mistakes were reconsidered without human help.

Conditional behaviour that never happened is **not observed**, not passed. Missing evidence for a required finished-job item prevents success.

## Result sheet

```markdown
# Run <number> of <batch/version>
- Prepared source / workflow+tooling source:
- Model / reasoning / image:
- Fabro run / result commit:
- Started / finished / elapsed / available cost (estimate or billing?):
- Human interventions:
- Finished-job checklist, with evidence:
- How-it-worked checklist, with evidence:
- Verdict and remaining unknowns:
```

Keep preparation errors and failed launches too. Do not replace a run with an uncertain launch acknowledgement. Evidence retrieval and read-only evaluation are not interventions in the agents' work. Stop only the exact owned resources through normal Fabro lifecycle; retain logs and checkpoints.
