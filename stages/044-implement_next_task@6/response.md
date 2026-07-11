Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `006 Add/update the allowed @iteration-052 Cucumber scenarios and supporting step definitions if needed.`

2. **Changes made**
   - `acceptance-tests/features/club_message_replies.feature`
     - Added permitted `@iteration-052` coverage only in the allowed feature file.
     - Added two browser-facing scenarios under a new `@not-domain` rule:
       - Message detail confirms:
         - back link reads `All conversations`;
         - old reply helper sentence is absent;
         - composer identifies the replying member;
         - posted note says `Your reply is being sent.`;
         - conversation entries still show sender, timestamp, and body.
       - Club-home Conversations panel confirms the desktop `Prefer email?` card/copy is absent.
   - `acceptance-tests/features/step_definitions/member_message_steps.js`
     - Added matching Cucumber step definitions for the new `@iteration-052` scenarios.
   - `acceptance-tests/features/support/member_message.js`
     - Added Playwright support assertions for:
       - message detail back link;
       - absent old helper sentence;
       - inline replying-as composer identity;
       - quiet composer posted note;
       - sender/timestamp/body conversation entry rendering;
       - absent club-home `Prefer email?` card/copy.
   - `docs/iterations/052-desktop-member-app-design-alignment/todo.md`
     - Checked off task `006` only.

3. **Validation**
   - TDD/step-discovery evidence:
     - `cd acceptance-tests && npx cucumber-js features/club_message_replies.feature --tags @iteration-052 --dry-run`
     - Initially showed the new `@iteration-052` steps as undefined.
   - After adding step definitions:
     - `cd acceptance-tests && npx cucumber-js features/club_message_replies.feature --tags @iteration-052 --dry-run`
     - Result: no undefined steps.
   - Targeted browser acceptance:
     - `PATH="$PWD/bin:$PATH" dev acceptance -- --tags @iteration-052`
     - Result: `2 scenarios (2 passed)`, `22 steps (22 passed)`.
   - Full staged-state quality gate:
     - Staged the final diff, then ran `PATH="$PWD/bin:$PATH" dev check`
     - Result: passed, including `109 scenarios (109 passed)` and `783 steps (783 passed)`.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 006 Add/update the allowed @iteration-052 Cucumber scenarios and supporting step definitions if needed.`
   - To:
     - `- [x] 006 Add/update the allowed @iteration-052 Cucumber scenarios and supporting step definitions if needed.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0003 / ADR 0010 respected: scenarios remain in the shared `acceptance-tests/features` feature file, with browser-layer step plumbing added under `acceptance-tests`.
   - The new scenarios are tagged `@not-domain` because they validate desktop presentation/application chrome, not domain model decisions.
   - No routing, permissions, data model, events, projections, notification, or email behaviour was changed.

Changes are staged; no commit was created.