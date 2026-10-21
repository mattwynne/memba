Goal: Implement the planned domain scenarios, one at a time; do not publish
Run ID: 01M5E6ZE4B4J1PG6391VFND4KW


You are a fresh driver for one assignment. Read the iteration plan whose path is recorded in `.fabro/tmp/bdd-plan/plan-path`, its relevant links, project guidance, `.fabro/tmp/bdd/base` and `.fabro/tmp/bdd/change.md`. Re-read the exact current WIP selection and relevant code. Work on that one planned change, not the rest of the scenario or iteration. Do not publish or weaken agreed examples. Do not start or delegate a review or a separate refactoring pass.

Use shell commands for all file writes and edits, including notes and feature tags (for example, Python invoked through the shell). Do not use `apply_patch`, native file-write tools or uploads: on this Fabro version they can change file ownership and prevent subsequent command writes. Do not repair ownership with chmod/chown.

Use the navigator's observed starting result only if the current source, scenario and setup still match the assignment. Otherwise treat it as stale, predict and rerun the test before editing; return without edits if the result differs from your expectation.

You may use unit-test red/green cycles within this change. Predict the result and reason before each test command. Run ordinary commands and save their actual output and exit status in distinct logs under `.fabro/tmp/bdd/`. Check that the intended tests actually executed. Format changes and run supporting tests before the final acceptance observation. Leave the full `bin/dev check` run to the workflow's check stage.

While the scenario is tagged, run `bin/dev test:wip`. Its nonzero exit can mean either a real failure or a passing scenario whose tag must be removed: read the test output. Stop immediately at the navigator's predicted next failure or actual green result. An unexpected acceptance result also means return. The same known failure permits continuing this change only. Leave tag removal to the navigator. For later repairs use the ordinary focused command in the assignment.

Always write `.fabro/tmp/bdd/result.md` with what changed, commands and actual results, log paths, and anything to reconsider. An incomplete change or incorrect assignment can always return. No special verdict or success declaration is needed.