Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `005 Build a receipt presentation model for the LiveView:`

2. **Changes made**
   - Extended `MembaWeb.MemberReceiptPresentation` with `present_receipts/1`, producing a LiveView-ready receipt model:
     - all four summary statuses in order: `Opened`, `Delivered`, `Sending`, `Delivery problem`;
     - member-facing descriptions;
     - counts and independently rounded whole percentages;
     - zero-receipt safe `0%` handling;
     - non-empty groups only, with presented receipts attached.
   - Updated `MembaWeb.MemberMessageDetail` to use the new model and assign:
     - `:member_receipts`
     - `:member_receipt_count`
     - `:member_receipt_summary`
     - `:member_receipt_groups`
   - Added focused tests for:
     - ordered summary data;
     - descriptions, counts, percentages;
     - non-empty groups only;
     - independent rounding;
     - zero-count/zero-receipt behaviour.
   - Updated loader test coverage to prove the LiveView detail assigns include the summary model.

3. **Validation**
   - `cd web && mix format --check-formatted lib/memba_web/member_receipt_presentation.ex lib/memba_web/member_message_detail.ex test/memba_web/member_receipt_presentation_test.exs test/memba_web/member_message_detail_loader_test.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `225 tests, 0 failures`.
   - Note: a direct standalone `mix test test/memba_web/member_receipt_presentation_test.exs` attempt failed because the unmanaged Postgres socket was unavailable; the required managed `dev check` environment then passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 005 Build a receipt presentation model for the LiveView:`
   - To:
     - `- [x] 005 Build a receipt presentation model for the LiveView:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0006: Keeps member-facing receipt vocabulary simple and uses existing labels/icons without exposing operator diagnostics.
   - ADR 0013: Added automated tests for user-facing presentation behaviour.
   - ADR 0015: Builds the model for the LiveView-backed member message detail page, ready for upcoming rendering and interaction tasks.