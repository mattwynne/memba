Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `007 Render the identity dropdown's avatar + label from member_name, falling back to the current_identity email local-part (label and initials) when member_name is nil.`

2. **Changes made**
   - Updated `web/lib/memba_web/components/layouts.ex`:
     - Identity dropdown avatar now uses `member_name` initials when present.
     - Identity dropdown label now uses `member_name` when present.
     - Fallback label/initials now derive from the signed-in email local-part, e.g. `alice@example.com` → `alice` / `A`.
     - Added blank-name fallback handling.
   - Updated `web/test/memba_web/components/layouts_test.exs`:
     - Proves fallback label is `alice`, not `alice@example.com`.
     - Proves provided `member_name` renders as the dropdown label and drives initials.
   - Updated browser-facing validation helpers to expect the new club identity label behavior:
     - `acceptance-tests/features/support/authentication.js`
     - `acceptance-tests/features/support/club_member_invitations.js`
     - `acceptance-tests/features/support/request_account.js`
     - `smoke-tests/lib/browser.js`
   - No acceptance `.feature` files changed.

3. **Validation run**
   - TDD red check:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/components/layouts_test.exs`
     - Failed as expected before implementation: old layout still rendered email/full fallback.
   - Focused test after implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/components/layouts_test.exs`
     - Passed: `6 tests, 0 failures`.
   - Formatting:
     - `cd web && mix format --check-formatted lib/memba_web/components/layouts.ex test/memba_web/components/layouts_test.exs`
     - Passed.
   - Full final check on the post-check-off working tree:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance: `85 scenarios (85 passed), 523 steps (523 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 007 Render the identity dropdown's avatar + label from member_name, falling back to the current_identity email local-part (label and initials) when member_name is nil.`
   - To:
     - `- [x] 007 Render the identity dropdown's avatar + label from member_name, falling back to the current_identity email local-part (label and initials) when member_name is nil.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan references no ADRs explicitly.
   - No `docs/adr/*.md` files are present.
   - Changes stay within task 007 scope: rendering from `member_name` with email-local-part fallback.
   - Acceptance feature files remained untouched.