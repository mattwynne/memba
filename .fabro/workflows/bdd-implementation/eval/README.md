# A repeatable workflow eval

One fixed exercise, one checklist, one result sheet. No eval runner or model-based judge.

## Run it

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
