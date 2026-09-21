Prepared one ready worker packet: `004-72f5ddc-01`, bound to checkpoint `72f5ddc7caca697256cc264ef502c03fd028b5b5`.

I combined pending lines 004–008 into one bounded obligation covering:

- Explicit-removal cleanup completion through the existing 062 policy.
- Manual, root-sender, and reply-author auto-follows.
- Remove/re-add/follow race and replay safety.
- Unrelated and shared-conversation follow preservation.
- Existing Everyone/Admin behavior.

The packet identifies the current reply auto-follow projection/write-model mismatch, completion-ordering gap, access-projection lag risk, focused validation commands, and required completion evidence.

Updated only permitted artifacts:

- [todo.md](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/todo.md)
- [execution-state.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/execution-state.json)
- [planner-result.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/planner-result.json)
- [current-worker-packet.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/current-worker-packet.json)

Validation completed:

- All three JSON artifacts parse successfully.
- Accepted and pending obligations exactly match `todo.md`.
- Coverage references every accepted and pending line.
- The packet matches the first unchecked task.
- Candidate provenance from accepted task 001 is resolved.
- `git diff --check` passes.

No application code, tests, feature files, ADRs, or `plan.md` were edited. `dev check` was not run for this planning-only handoff; final validation remains task 017.