Implemented and reviewed the assigned behavior-preserving cleanup. Nothing was committed or published.

- [`prepare_rename/3`](/workspace/memba/web/lib/memba/membership/person_commands.ex:32) now separates trusted actor context, target Person identity, and editable attributes.
- Authorization still occurs before editable attributes are read or a command is constructed.
- All callers now pass the target separately; editable maps contain only `name` and `expected_name`.
- [Authorization tests](/workspace/memba/web/test/memba/membership/person_commands_test.exs:91) cover malformed targets plus ordinary, no-op-shaped, and confirmation-shaped target mismatches.
- The acceptance feature, commands/events, aggregate, projections, and live-query handling were unchanged.

Final validation:

- Changed-file formatting check: exit 0.
- Supporting suite: 10 tests, 0 failures.
- Ordinary focused scenario: exactly 1 included test, 0 failures.
- `git diff --check`: exit 0.
- Independent final review: no remaining findings.
- Full `dev check` was intentionally not run, as the assignment reserves it for the navigator.

The initial test attempt could not find `dev` because repository `bin/` was absent from PATH; this is logged, followed by the successful pre-edit rerun. Complete command results and log paths are in [result.md](/workspace/memba/.fabro/tmp/bdd/result.md:1). No unresolved problems.