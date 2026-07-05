Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `009 Pass member_name into club_site from member_message_live/new.ex (compose) and member_invitation_live/new.ex (invitation).`

2. **Changes made**
   - Updated `web/lib/memba_web/live/member_message_live/new.ex`
     - Passes `member_name={@current_member && @current_member.name}` into `<Layouts.club_site>`.
   - Updated `web/lib/memba_web/live/member_invitation_live/new.ex`
     - Passes `member_name={@current_member && @current_member.name}` into `<Layouts.club_site>`.
   - Updated focused LiveView tests:
     - `web/test/memba_web/live/member_message_live/new_test.exs`
       - Asserts compose shell identity label/avatar render `Alice Adams` / `AA`.
     - `web/test/memba_web/live/member_invitation_live/new_test.exs`
       - Asserts invitation shell identity label/avatar render `Robin Rivers` / `RR`.

3. **Validation commands run**
   - TDD red, before implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/new_test.exs test/memba_web/live/member_invitation_live/new_test.exs`
     - Failed as expected: shell identity still showed fallback email local-part.
   - Focused pass:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/new_test.exs test/memba_web/live/member_invitation_live/new_test.exs`
     - Passed: `16 tests, 0 failures`.
   - Formatting:
     - `cd web && mix format --check-formatted lib/memba_web/live/member_message_live/new.ex lib/memba_web/live/member_invitation_live/new.ex test/memba_web/live/member_message_live/new_test.exs test/memba_web/live/member_invitation_live/new_test.exs`
     - Passed.
   - Full check on final working tree after todo check-off:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance: `85 scenarios (85 passed), 523 steps (523 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 009 Pass member_name into club_site from member_message_live/new.ex (compose) and member_invitation_live/new.ex (invitation).`
   - To:
     - `- [x] 009 Pass member_name into club_site from member_message_live/new.ex (compose) and member_invitation_live/new.ex (invitation).`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan references no ADRs explicitly.
   - Relevant ADRs inspected:
     - ADR 0015: LiveView remains the implementation model for member app pages.
     - ADR 0013: tests continue using existing LiveView-focused selector assertions where appropriate for shell mechanics.
   - No acceptance `.feature` files were changed.