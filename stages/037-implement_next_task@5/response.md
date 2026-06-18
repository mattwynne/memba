1. **Selected todo line**
   - `005 Keep events/email_delivery_opened.ex as the deserialization tombstone with a deprecation comment.`

2. **Changes made**
   - Updated `web/lib/memba/messaging/events/email_delivery_opened.ex`
     - Replaced the old active-behaviour moduledoc with an explicit tombstone/deprecation moduledoc.
     - Documents that `EmailDeliveryOpened` is retained only so historic event-store records deserialize during aggregate replay/projection rebuilds.
     - Explicitly says not to emit, extend, or add behaviour around the event.
   - Updated `docs/iterations/035-obliterate-opened-delivery-status/todo.md`
     - Checked off only task `005`.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba/messaging/events/email_delivery_opened.ex`
     - Passed.
   - `PATH="$PWD/bin:$PATH" bin/mix compile --warnings-as-errors`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Ran broad quick check.
     - Output still reports 8 pending opened-related test failures in member/staff delivery UI tests, which are covered by the next unchecked task `006`.
   - `git diff --check`
     - Passed.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 005 Keep events/email_delivery_opened.ex as the deserialization tombstone with a deprecation comment.`
   - To:
     - `- [x] 005 Keep events/email_delivery_opened.ex as the deserialization tombstone with a deprecation comment.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan does not explicitly reference any ADR files.
   - This task preserves the event-sourcing replay-safety constraint in the plan: the historic event struct remains available for deserialization, but the documentation makes clear it is a replay-only tombstone and not live product behaviour.