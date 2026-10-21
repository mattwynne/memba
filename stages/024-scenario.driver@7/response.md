Updated the Membership router contract test to include the already registered `RenamePerson` command in [app_test.exs](/workspace/memba/web/test/memba/membership/app_test.exs:24).

Validation:

- Format check: passed
- `bin/dev test test/memba/membership/app_test.exs`: 3 tests, 0 failures
- `git diff --check`: clean
- Full `bin/dev check`: not run, as assigned
- Nothing published; acceptance features and tags were unchanged

Evidence and command logs are recorded in [result.md](/workspace/memba/.fabro/tmp/bdd/result.md).