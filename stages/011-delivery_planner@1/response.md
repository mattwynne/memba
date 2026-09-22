Prepared the next bounded worker handoff for task 004 as revision packet `004-b7e41db-08`.

- Bound all planner artifacts to checkpoint `b7e41db78381f6b41e19ea099e883fbe7d78d6df`.
- Preserved task identity, the seven cumulative candidate origins, the accepted task 001 record, and all pending obligations.
- Scoped the revision to the two outstanding review gaps:
  - source-less raw follows on conversations created after cleanup;
  - generation-less reply-author follows stored on reply streams.
- Left [plan.md](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/plan.md), [todo.md](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/todo.md), application code, and tests unchanged.
- Updated [execution-state.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/execution-state.json), [planner-result.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/planner-result.json), and [current-worker-packet.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/current-worker-packet.json).

JSON parsing, `git diff --check`, file-scope checks, and the deterministic planner validations all pass. `dev check` was not run because this was a planning-only handoff and the packet correctly reserves full validation for task 017.