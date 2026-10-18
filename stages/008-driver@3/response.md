Implemented and reviewed the single assigned stale-submit change. Nothing was committed or published.

- Added the stale submission step in [member_profile_steps.exs](/workspace/memba/web/test/features/step_definitions/member_profile_steps.exs:56). It preserves the trusted Person identity, original baseline, raw draft, exact dispatch result, and authoritative conflict name.
- Added the production dispatch sequence test in [person_command_dispatch_test.exs](/workspace/memba/web/test/memba/membership/person_command_dispatch_test.exs:180).
- Focused supporting suite passed twice: 5 tests, 0 failures.
- Independent review found no correctness or scope issues.
- `dev test:wip` selected exactly the intended scenario and exited 2 at the predicted next undefined step:
  `Then the change should be rejected because their name changed elsewhere`.
- `dev check` also stopped on that same deliberately undefined step: 1,838 application tests, one failure. No out-of-scope repair was made.
- Full evidence and log paths are recorded in [result.md](/workspace/memba/.fabro/tmp/bdd/result.md).

The two code changes are staged; the `@wip` tag and all agreed feature assertions remain unchanged.