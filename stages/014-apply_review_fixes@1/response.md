Implemented the automatic repair for `fix-cucumber-inventory-tag-scope`. No product behaviour or acceptance feature files were changed.

### Issue-to-fix mapping

| Review issue | Resolution | Files/tests |
|---|---|---|
| Cucumber inventory exclusions did not reliably include inherited tags | Replaced the handwritten feature scanner—which discarded `Rule:` tags—with the official Gherkin AST parser. Scenario inventory now combines feature, rule, and scenario tags while preserving rule scope. | [cucumber_config.test.js](/workspace/memba/acceptance-tests/test/cucumber_config.test.js:262) |
| Prove tag inheritance and prevent leakage between rules | Added regression assertions covering feature inheritance, rule inheritance, scenario-local tags, and the end of a rule’s scope. | [cucumber_config.test.js](/workspace/memba/acceptance-tests/test/cucumber_config.test.js:57) |
| Make the parser dependency explicit | Added the already-installed `@cucumber/gherkin` version as a direct development dependency and updated the lockfile root declaration. | [package.json](/workspace/memba/acceptance-tests/package.json:13), [package-lock.json](/workspace/memba/acceptance-tests/package-lock.json:12) |

### Validation

- `npm run test:config`: 68 tests passed.
- Offline package-lock dry run: up to date.
- `git diff --check`: passed.
- Full `dev check`: passed on the exact unchanged repair diff.
  - 1,292 ExUnit tests, 0 failures.
  - 145 browser acceptance scenarios passed.
  - 1,052 acceptance steps passed.

No commits were created.

There are no remaining gaps for the selected review issue. One future-only limitation remains outside this repair’s scope: the inventory represents each Scenario Outline once and does not model tags attached to individual `Examples:` blocks. The repository currently has no tagged `Examples:` blocks, so this does not affect current exclusions or test results.