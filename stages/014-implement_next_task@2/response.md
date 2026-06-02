1. **Selected todo line**
   - `002 Update shared acceptance feature expectations to remove opened receipts.`

2. **Changes made**
   - Added a Cucumber configuration test in `web/test/features/cucumber_configuration_test.exs` asserting the two shared deliverability feature files do not describe opened/open receipt behaviour:
     - `acceptance-tests/features/member_message_deliverability.feature`
     - `acceptance-tests/features/memba_staff_email_deliverability.feature`
   - Did not edit the `.feature` files because they already contained the revised expectations: Sending, Delivered, and Delivery problem only; no staff opened scenario.
   - Did not change step definitions, matching the plan’s instruction to update expectations without changing Cucumber step definitions.

3. **Focused validation**
   - `cd web && mix test test/features/cucumber_configuration_test.exs`
     - Failed in the bare shell because PostgreSQL was not available at the inherited `PGHOST=/tmp/devenv/postgres`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `354 tests, 0 failures`.
   - Searched shared feature files for opened/open receipt wording:
     - `acceptance-tests/features/*.feature`: no `opened`, `open`, or `opens` matches in the deliverability features.

4. **Todo check-off**
   - Changed:
     - `- [ ] 002 Update shared acceptance feature expectations to remove opened receipts.`
   - To:
     - `- [x] 002 Update shared acceptance feature expectations to remove opened receipts.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Read relevant ADRs `0004`, `0006`, `0012`, and `0016`.
   - This task only updates living-documentation/test expectations and does not alter the aggregate, projections, provider handling, or app behaviour.
   - The added expectation aligns with the current iteration plan’s policy that opened receipts are no longer current behaviour, while leaving the broader ADR reconciliation for the later documentation task.