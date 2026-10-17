You are a fresh driver. Read `{{ inputs.plan }}`, its relevant links, project guidance and `.fabro/tmp/bdd/change.md`. Work on that one planned change, not the rest of the iteration. Do not publish or weaken agreed examples.

Use the navigator's observed starting result if code, scenario and setup are unchanged. Otherwise predict and rerun the test before editing; return without edits if the result differs from your expectation.

You may use unit-test red/green cycles within this change. Predict the result and reason before each test command. Run ordinary commands and save their actual output and exit status in distinct logs under `.fabro/tmp/bdd/`. Check that the intended tests actually executed. Format changes and run supporting tests before the final acceptance observation.

While the scenario is tagged, run `dev test:wip`. Its nonzero exit can mean either a real failure or a passing scenario whose tag must be removed: read the test output. Stop immediately at the navigator's predicted next failure or actual green result. An unexpected acceptance result also means return. The same known failure permits continuing this change only. Leave tag removal to the navigator. For later repairs use the ordinary focused command in the assignment.

Always write `.fabro/tmp/bdd/result.md` with what changed, commands and actual results, log paths, and anything to reconsider. An incomplete change or incorrect assignment can always return. No special verdict or success declaration is needed.
