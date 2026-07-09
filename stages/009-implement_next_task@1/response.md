1. **Selected todo line**
   - `001 Add a participants query ... distinct sender_id per conversation_id across replies only (excluding the root sender), ordered by first reply time.`

2. **Changes made**
   - Added participant aggregation inside `Messaging.conversations_for_club_query/1`:
     - builds distinct reply participants by `conversation_id` + `sender_id`
     - excludes the root/originating sender
     - orders participant IDs by first reply timestamp
     - returns `participant_ids: []` for conversations with no qualifying replies
   - Added focused coverage in `web/test/memba/messaging/message_projection_test.exs` proving:
     - no replies => empty participant list
     - originator replies are excluded
     - duplicate repliers are de-duplicated
     - participants are ordered by first reply

3. **Validation**
   - TDD failure observed before implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/messaging/message_projection_test.exs` failed because `participant_ids` was absent.
   - Focused validation after implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/messaging/message_projection_test.exs`
     - Result: `8 tests, 0 failures`
   - Broad quick check attempted:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - It surfaced existing/unrelated suite failures outside this selected task scope, including missing Cucumber steps and unrelated path assertions. I did not fix those because this run is constrained to the first unchecked todo item only.
   - Re-ran focused validation after that:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/messaging/message_projection_test.exs`
     - Result: `8 tests, 0 failures`

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 001 Add a participants query ...`
   - to:
     - `- [x] 001 Add a participants query ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan did not explicitly reference any ADRs.
   - No `docs/adr/*.md` files were found to apply.
   - Followed local project guidance read for this task: `docs/tools/README.md`, `docs/reference/ecto.md`, and `docs/reference/elixir-mix-tests.md`.