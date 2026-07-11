Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `009 Add/update Phoenix/LiveView/rendered tests for: \`All conversations\` back link;`

2. **Changes made**
   - Updated `web/test/memba_web/live/member_message_live/show_test.exs`
     - Strengthened LiveView route coverage to assert the back link still renders:
       - `a#back-to-club-home-link[href='/conversations']`
       - text: `All conversations`
     - Added explicit refutation that the same link no longer renders the old copy:
       - `Club home`
     - Strengthened rendered HTML/LazyHTML coverage for the static GET path with the same old-copy refutation.

3. **Focused validation commands run**
   - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs`
     - Passed: `12 tests, 0 failures`
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `960 tests, 0 failures`
   - Re-ran after todo check-off:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `960 tests, 0 failures`
   - `git diff --check`
     - Passed

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 009 Add/update Phoenix/LiveView/rendered tests for: \`All conversations\` back link;`
   - To:
     - `- [x] 009 Add/update Phoenix/LiveView/rendered tests for: \`All conversations\` back link;`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No ADRs were explicitly referenced by the selected task or the iteration plan for this slice.
   - Scope stayed limited to Phoenix/LiveView/rendered test coverage for an already-implemented presentation copy decision.
   - No routing, permissions, data model, migrations, commands/events/projections, notifications, acceptance feature files, or app UI implementation were changed.