Prepared exactly one revision handoff for task `004`, bound to checkpoint `34d71d978d6509683dc999308f1f60d2ca297956`.

- Packet: `004-34d71d9-07`, revision attempt seven.
- Scope: prevent source-less raw follows from escaping cleanup after unrelated membership-generation changes, and establish durable ordering for generation-less historical removal/re-add/follow facts.
- Preserved the accepted task-001 line, all pending obligations, and all six cumulative candidate origins.
- Tasks `009`–`017` remain unchanged and excluded.
- Updated [execution-state.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/execution-state.json), [planner-result.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/planner-result.json), and [current-worker-packet.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/current-worker-packet.json).
- JSON parsing, artifact linkage, coverage mapping, baseline consistency, allowed-path checks, and `git diff --check` all pass.

No application code, tests, feature files, ADRs, `plan.md`, or `todo.md` were changed. `dev check` was intentionally left to task `017` and the deterministic gate.