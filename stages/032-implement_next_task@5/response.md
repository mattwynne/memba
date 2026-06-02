Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 005 Update Postmark outbound delivery so it does not set \`track_opens: true\` or any equivalent open-tracking option.`

2. **Changes made**
   - Removed outbound Postmark open-tracking provider option:
     - `web/lib/memba/messaging/email_delivery_providers/postmark.ex`
       - Removed `put_provider_option(:track_opens, true)`.
   - Removed default Postmark open-tracking config:
     - `web/config/config.exs`
       - Removed `track_opens: true`.
   - Updated Postmark provider test:
     - `web/test/memba/messaging/email_delivery_providers/postmark_test.exs`
       - Test now expects only correlation metadata.
       - Explicitly asserts `:track_opens` is not present in provider options.
   - Checked off task 005 in:
     - `docs/iterations/017-remove-open-tracking/todo.md`

3. **Focused validation**
   - `cd web && mix format --check-formatted lib/memba/messaging/email_delivery_providers/postmark.ex config/config.exs test/memba/messaging/email_delivery_providers/postmark_test.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `377 tests, 0 failures`.
   - `git diff --check`
     - Passed.
   - Search check:
     - `grep -RInE "track_opens|TrackOpens|OpenTracking|open tracking" web/config web/lib web/test acceptance-tests docs/email-delivery.md`
     - Remaining matches are only tests asserting absence / shared-feature guard text; no active provider/config enablement remains.
   - Note: attempted a focused direct `mix test` for the Postmark test, but it could not run outside the dev wrapper because Postgres was not running. The required `dev check` started services and passed.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 005 Update Postmark outbound delivery so it does not set \`track_opens: true\` or any equivalent open-tracking option.`
   - To:
     - `- [x] 005 Update Postmark outbound delivery so it does not set \`track_opens: true\` or any equivalent open-tracking option.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan does not explicitly reference ADRs.
   - This task only changed the Postmark outbound adapter/configuration and its tests.
   - No aggregate, command routing, projection architecture, Ecto schema, or bounded-context API boundaries were changed, so existing accepted architecture constraints remain intact.