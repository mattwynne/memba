1. **Selected todo line**
   - `004 Show each recipient's bounce reason for the "didn't go through" group, from the existing receipt presentation fields; keep the delivered group collapsed with a count.`

2. **Changes made for this task only**
   - Added a virtual `:reason` field to `MemberEmailDelivery` projection schema.
   - Updated `Messaging.list_member_email_deliverys/1` to left-join staff delivery details and expose provider reason text through the existing member receipt list pipeline.
   - Updated `MemberEmailDeliveryPresentation.present_receipt/1` to carry a trimmed `reason` only for normalized `"delivery problem"` receipts.
   - Updated `MemberMessageDeliveryLive.Show` recipient rows to render the problem receipt reason in `.recipient__reason`, falling back to the status label when no reason exists.
   - Extended `MemberMessageDeliveryLive.ShowTest` to create a bounced/problem delivery with a reason and assert the delivery details page renders it.

3. **Focused validation commands run and results**
   - TDD failing check after adding the new assertion:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_delivery_live/show_test.exs`
     - Failed as expected: missing `"Address does not exist"` in `.recipient__reason`.
   - Focused LiveView test after implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_delivery_live/show_test.exs`
     - Passed: `2 tests, 0 failures`.
   - Compatibility test for member delivery projection/query:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/messaging/member_email_delivery_projection_test.exs`
     - Passed: `4 tests, 0 failures`.
   - Formatting:
     - `cd web && mix format --check-formatted lib/memba/messaging.ex lib/memba/messaging/projections/member_email_delivery.ex lib/memba_web/member_email_delivery_presentation.ex lib/memba_web/live/member_message_delivery_live/show.ex test/memba_web/live/member_message_delivery_live/show_test.exs`
     - Passed.
   - Full validation on final task state:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance suite: `85 scenarios (85 passed)`, `523 steps (523 passed)`.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 004 Show each recipient's bounce reason for the "didn't go through" group, from the existing receipt presentation fields; keep the delivered group collapsed with a count.`
   - To:
     - `- [x] 004 Show each recipient's bounce reason for the "didn't go through" group, from the existing receipt presentation fields; keep the delivered group collapsed with a count.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No ADR files were present under `docs/adr/`, and the plan did not explicitly reference an ADR file to read.
   - Preserved the existing member-facing status vocabulary and ADR-0006-style mapping: no delivery statuses or status computation changed.
   - Kept the route/page data flow aligned with the plan by continuing to use `Messaging.list_member_email_deliverys/1 |> MemberEmailDeliveryPresentation.present_receipts/1`.
   - No acceptance feature files were changed.