The change is incomplete because the final WIP result was unexpected.

I added both historical-author bindings in [member_profile_steps.exs](/workspace/memba/web/test/features/step_definitions/member_profile_steps.exs). They use `MemberMessageDetail.load/3`, exact fixture message IDs, Alice’s authenticated email, the selected active club, and distinguish the preserved reply from the `"Summer rides"` root.

Results:

- Formatter: exit 0.
- Cucumber configuration: 2 tests, 0 failures.
- `bin/dev test:wip`: unexpected exit 2; exactly one scenario ran, but the runner still reported the first new binding as undefined.

Per the assignment, I stopped immediately without diagnosing or repairing the unexpected result. The `@wip` tag remains, and I did not run `bin/dev check`.

Full details and log paths are recorded in [result.md](/workspace/memba/.fabro/tmp/bdd/result.md).