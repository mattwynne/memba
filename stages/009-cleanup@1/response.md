Implemented and reviewed the assigned cleanup without publishing.

Updated [person_commands.ex](/workspace/memba/web/lib/memba/membership/person_commands.ex:2) so its moduledoc now accurately describes:

- preparation of Person commands without dispatch;
- trusted-actor/self-target authorization for rename preparation;
- projected email ownership as a creation preflight, with aggregate validation retained.

No executable behavior, API, test, or acceptance feature changed. The scenario remains unchanged and untagged from `@wip`.

Validation is green:

- Pre/post focused scenario: `132 tests, 0 failures, 131 excluded`
- Pre/post `person_commands_test.exs`: `8 tests, 0 failures`
- `bin/dev check`: exit `0`
  - LiveQuery: `19 tests, 0 failures`
  - Memba: `1840 tests, 0 failures`
  - Browser acceptance: `7 scenarios passed`, `113 steps passed`
- Independent review: no findings
- `git diff --cached --check`: clean

The source change is staged but not committed or published. Complete command evidence, log paths, statuses, and the resolved unsupported formatter attempt are recorded in [result.md](/workspace/memba/.fabro/tmp/bdd/result.md).