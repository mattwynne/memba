Packet `001-6d7bb960-1` is `ready_for_review`.

Implemented `Membership.resolve_custom_group_target_authoritatively/3` in [membership.ex](/workspace/memba/web/lib/memba/membership.ex:1435). It:

- Resolves active membership, club, custom-group facts, and current participation from authoritative Club aggregate state.
- Reads projected person display data only after authoritative identity checks.
- Rejects malformed, missing, cross-club, built-in-group, and inactive-member inputs with documented errors.
- Returns a plain public summary without exposing aggregate or projection internals.

Added focused coverage in [authoritative_custom_group_target_test.exs](/workspace/memba/web/test/memba/membership/authoritative_custom_group_target_test.exs:1) and updated the public API boundary assertion in [no_crud_spike_test.exs](/workspace/memba/web/test/memba/membership/no_crud_spike_test.exs:27).

Validation passed:

```text
PATH="$PWD/bin:$PATH" dev test test/memba/membership/authoritative_custom_group_target_test.exs test/memba/membership/no_crud_spike_test.exs test/memba/membership/add_custom_group_member_dispatch_test.exs
18 tests, 0 failures
```

The required artifact is valid and matches the packet identifiers: [latest-worker-result.json](/workspace/memba/docs/iterations/066-request-group-access/.delivery/latest-worker-result.json:1).

`todo.md` remains untouched. No command, event, projection, schema, migration, Messaging, web, acceptance, or admission behavior was changed. Per packet constraints, `dev check` was not run; the workflow’s later deterministic gate owns that validation.