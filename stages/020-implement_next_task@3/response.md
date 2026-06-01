Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `003 Update member step definitions so:`

2. **Changes made**
   - Updated `acceptance-tests/features/step_definitions/member_message_steps.js` so member-facing steps now use `withMemberHarness`:
     - `When Alice sends...` signs in as Alice and sends via `GET/POST /?club_id=<club_id>` club home flow.
     - `When Alice/Bob views...` signs in as that member and opens `/messages/:message_id?club_id=<club_id>`.
     - Member receipt assertions use member-facing receipt rows, labels, and icon metadata.
   - Added missing executable step definitions for the current member feature language:
     - Alice/Bob/Carol/Dana people and membership setup.
     - `has been reported as delayed/bounced because...`
     - `has opened the email...`
   - Added member-facing acceptance support helpers in `acceptance-tests/features/support/member_message.js`:
     - `openMemberClubHome`
     - `openMemberMessage`
     - `sendMemberMessageToKootenayMembers`
     - `assertMemberSeesMessageInClub`
     - `assertMemberMessageAddressedTo`
     - `assertMemberMessageNotAddressedTo`
     - `assertEveryAddressedMemberReceiptStatus`
     - `assertMemberReceiptStatus`
     - receipt label → Heroicon-name assertion support for browser tests.
   - Extended `acceptance-tests/test/member_message_steps.test.js` to prove:
     - member send uses `/?club_id=...`, not `/admin/*`;
     - member message opening uses `/messages/:message_id?club_id=...`;
     - member assertions read member-facing recipient rows, labels, and Heroicon names.

3. **Focused validation**
   - `cd acceptance-tests && node --test test/member_message_steps.test.js test/member_harness.test.js`
     - Passed: `22` tests, `0` failures.
   - `cd acceptance-tests && npm test -- --dry-run`
     - Passed: `17` scenarios skipped/dry-run, step definitions loaded.
   - `cd acceptance-tests && ... npx cucumber-js features/member_message_deliverability.feature ... --dry-run --tags @wip ...`
     - Passed: `3` scenarios skipped/dry-run, `39` steps defined.
   - `git diff --check`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `203 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 Update member step definitions so:`
   - To:
     - `- [x] 003 Update member step definitions so:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0003 / ADR 0010: did not edit shared feature files; only added executable browser-runner plumbing for existing shared scenarios.
   - ADR 0006: member-facing assertions now use simplified labels/icons while leaving internal projection/status values unchanged.
   - Staff/admin diagnostic paths and operator steps remain available for setup/operator scenarios; member `When`/`Then` paths now use member sessions and avoid `/admin/*`.