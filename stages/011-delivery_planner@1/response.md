Prepared exactly one ready revision packet for task 004: `004-0bc4306-06`, bound to checkpoint `0bc43067626f7163f1b7066f55fd7ca2c285a225`.

The packet directs the worker to:

- Prevent raw `follow_conversation/2` callers from forging trusted `authorizing_group_ids`.
- Add the remove → forged follow → re-add regression.
- Exercise surviving-group root follows through `send_club_message_as_current_member/2`.
- Preserve all five cumulative candidate origins and the existing task/revision identity.
- Run only the focused task-004 suites; final `dev check` remains assigned to task 017.

Updated:

- [current-worker-packet.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/current-worker-packet.json)
- [execution-state.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/execution-state.json)
- [planner-result.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/planner-result.json)

The approved plan and todo were unchanged. JSON structure, baseline binding, todo alignment, candidate origins, coverage mapping, focused-validation scope, and allowed-file diff all validated successfully. `git diff --check` passes. Per the project’s planning-only rule, I did not run `dev check`.