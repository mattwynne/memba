1. **Selected todo line**
   - `008 Remove the inline #member-receipt-summary section and the "Members by delivery status" grouped section from message.html.heex.`

2. **Changes made for this task**
   - Removed the inline delivery summary section and inline grouped delivery-status section from `web/lib/memba_web/controllers/page_html/message.html.heex`.
   - Removed now-unused `PageHTML` receipt helper functions and `MemberEmailDeliveryPresentation` alias from `web/lib/memba_web/controllers/page_html.ex`.
   - Updated member message/page tests to assert the conversation no longer renders:
     - `#member-receipt-summary`
     - `#member-receipts-section`
     - `#member-receipts`
     - inline receipt summary/group test IDs
     - `"Members by delivery status"`
   - Updated acceptance support (not `.feature` files) so existing member-facing delivery assertions read the relocated delivery details page instead of the removed inline conversation rows.
   - Kept the conversation header “sent to N members” meta line untouched because that is task `009`.

3. **Validation commands run and results**
   - TDD expected failure after changing test expectations:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs`
     - Failed as expected because `#member-receipt-summary` still existed.
   - Focused tests after implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs`
       - Passed: `10 tests, 0 failures`
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/controllers/member_message_detail_test.exs`
       - Passed: `4 tests, 0 failures`
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/controllers/page_controller_test.exs`
       - Passed: `40 tests, 0 failures`
   - Formatting:
     - `cd web && mix format --check-formatted ...`
       - Passed.
   - Acceptance support unit tests:
     - `cd acceptance-tests && npm run test:config`
       - Passed: `48 tests, 0 failures`
   - Final full validation on the final diff:
     - `PATH="$PWD/bin:$PATH" dev check`
       - Passed, including acceptance: `85 scenarios (85 passed)`, `523 steps (523 passed)`.

4. **Exact todo check-off made**
   - Changed only:
     - `- [ ] 008 Remove the inline #member-receipt-summary section ...`
   - To:
     - `- [x] 008 Remove the inline #member-receipt-summary section ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR / project-rule conformance**
   - The plan did not explicitly reference ADR files, and no `docs/adr/*.md` files were present in this checkout.
   - Followed local Phoenix/HEEx/LiveView guidance:
     - Removed HEEx blocks cleanly.
     - Kept stable selector-based tests using `has_element?` / `LazyHTML`.
   - Preserved delivery status semantics; only relocated/removes inline presentation.
   - No acceptance `.feature` files were changed.
   - Existing acceptance executable support was updated only to follow the already-implemented delivery details route, keeping shared scenarios green after the inline UI removal.