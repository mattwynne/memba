Prepared revision packet `001-8319b25-03` for task 001, bound to checkpoint `8319b25d483c15f44634c0f9994751db7804a3b7`.

The packet directs a documentation-only ADR 0025 revision covering:

- Safe disposition of legacy queued deliveries without authorization provenance.
- Root-send-before-auto-follow ordering, preserving outside-group send-without-follow behavior.
- Precise historic-follow reconciliation precedence.
- Immutable multiple subscription grants and explicit unfollow semantics.
- Unambiguous membership-wide versus conversation-scoped revocation events.

Updated artifacts:

- [current-worker-packet.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/current-worker-packet.json)
- [execution-state.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/execution-state.json)
- [planner-result.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/planner-result.json)

Both unresolved candidate origins are preserved. All 25 todo obligations remain pending, with task 001 still first and unchanged. JSON parsing, whitespace checks, source-baseline consistency, coverage mapping, candidate provenance, and the repository’s non-mutating planner-contract validations passed.

No application, test, feature, ADR, plan, or todo file was changed. `dev check` was not run because this was planning-only work and the selected revision is documentation-only.