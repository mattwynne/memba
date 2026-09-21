Prepared revision packet `004-7c6bec2-06` for task 004, bound to checkpoint `7c6bec273ecb2b4f6689911210440ecf41aa1636`.

The packet directs the worker to:

- Prevent raw `follow_conversation/2` callers from supplying trusted source-group causality.
- Add the remove-A/forged-B/re-add-A regression.
- Exercise surviving-group root auto-follow through `send_club_message_as_current_member/2`.
- Preserve the existing cleanup, replay, idempotency, and accepted task-001 behavior.

Updated:

- [current-worker-packet.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/current-worker-packet.json)
- [execution-state.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/execution-state.json)
- [planner-result.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/planner-result.json)

All artifacts parse as JSON, coverage and five cumulative candidate origins are preserved, source baselines and first-unchecked-task bindings match, and `git diff --check` passes. The approved plan and todo were unchanged. Per the planner contract, `dev check` was not run; the packet contains focused validation only.