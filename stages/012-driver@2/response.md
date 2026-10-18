Implemented the assigned historical-name no-op repair without changing the acceptance scenario or publishing.

- [person.ex](/workspace/memba/web/lib/memba/membership/person.ex:65) now recognizes an unchanged normalized name before applying the new 100-grapheme limit.
- [person_test.exs](/workspace/memba/web/test/memba/membership/person_test.exs:239) adds regression coverage for a 102-grapheme historical name submitted unchanged with whitespace variation.
- Red observation: 25 tests, one expected `{:error, :name_too_long}` failure.
- Final aggregate test: 25 tests, zero failures.
- Formatting check: passed.
- Final focused acceptance scenario: 132 tests generated, 131 excluded, exactly the assigned scenario executed, zero failures.
- Review found no further issue in the scoped diff.
- Full `dev check` was intentionally left to the later workflow stage, as assigned.

All commands, exit statuses, setup-command failures, and log paths are recorded in [result.md](/workspace/memba/.fabro/tmp/bdd/result.md). Nothing was published.