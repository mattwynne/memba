Prepared revision packet `004-a7f2851-05`, bound to checkpoint `a7f2851f360fb6cdbcffc276e12f41ad4ca9c80d`.

The packet keeps task `004` and addresses the latest review’s two remaining gaps:

- Prevent cleanup from creating a projected follow for an unfollowed shared conversation.
- Preserve group-aware causality so same-generation follows through surviving group B succeed while stale work from removed group A remains rejected.

Updated:

- [current-worker-packet.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/current-worker-packet.json)
- [execution-state.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/execution-state.json)
- [planner-result.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/planner-result.json)

Validation confirmed valid JSON, exact todo/state alignment, complete coverage mapping, all four guard-required candidate origins, matching source baselines, and no edits outside the permitted `.delivery/` directory. `dev check` was intentionally not run for this planner-only handoff; task `017` remains the explicit final-validation obligation.