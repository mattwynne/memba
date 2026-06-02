Implemented todo `002`.

1. **Selected todo line**
   - `- [ ] 002 Update shared acceptance feature expectations to remove opened receipts.`

2. **Changes made**
   - Confirmed the two plan-allowed shared feature files already no longer describe opened receipts:
     - `acceptance-tests/features/member_message_deliverability.feature`
     - `acceptance-tests/features/memba_staff_email_deliverability.feature`
   - Updated the plan-allowed harness test:
     - `web/test/features/cucumber_configuration_test.exs`
     - Added a regression test asserting the two deliverability feature files do not contain obsolete opened/open-tracking terms.
   - Updated `docs/iterations/017-remove-open-tracking/todo.md` to check off only task `002`.

3. **Focused validation**
   - `cd web && mix format test/features/cucumber_configuration_test.exs` — passed.
   - `devenv shell -O services.postgres.port:int 15432 -- bash -lc 'cd web && mix test test/features/cucumber_configuration_test.exs'` — passed, `6 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check` — passed, `372 tests, 0 failures`.
   - `grep -RInEi 'opened|opens|open tracking|track_opens' acceptance-tests/features/member_message_deliverability.feature acceptance-tests/features/memba_staff_email_deliverability.feature || true` — no matches.
   - `git diff --check` — passed.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 002 Update shared acceptance feature expectations to remove opened receipts.`
   - To:
     - `- [x] 002 Update shared acceptance feature expectations to remove opened receipts.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Reviewed relevant ADRs `0004`, `0006`, `0012`, and `0016`.
   - This task is limited to shared acceptance expectations/harness validation and does not alter aggregate boundaries or provider behaviour.
   - ADR `0012` still conflicts with the current iteration’s approved policy, but the iteration plan explicitly supersedes opened receipt expectations for this work.