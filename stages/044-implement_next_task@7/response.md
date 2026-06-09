Implemented next unchecked task 007.

1. **Selected todo line**
   - `- [ ] 007 Change the club-message rejection email sender/display name to <club name> via Memba while preserving sender address, reply-to/support guidance, and rejection content.`

2. **Changes made**
   - Updated `Memba.Messaging.InboundClubRejectionEmail`:
     - Rejection emails with resolved `club_name` now use sender display name:
       - `"<sanitized club name> via Memba"`
     - Sender email address remains the configured/fallback messaging address.
     - Generic/no-club rejection emails keep the existing configured sender tuple.
   - Updated focused tests:
     - `web/test/memba/messaging/inbound_club_rejection_email_test.exs`
       - Asserts sanitized club-aware sender display name.
       - Asserts no-club fallback remains `{"Memba", "messages@mail.memba.test"}`.
     - `web/test/memba/messaging/inbound_club_message_acceptance_test.exs`
       - Asserts the full inbound rejection flow produces `{"Kootenay Mountaineering Club via Memba", "messages@mail.memba.test"}` for resolved club rejections.
       - Keeps unknown/no-club rejections generic.

3. **Focused validation run**
   - TDD red check:
     - `devenv shell -- bash -lc 'real_mix=$(which -a mix | grep -v "$(pwd)/bin/mix" | head -1); cd web; "$real_mix" test test/memba/messaging/inbound_club_rejection_email_test.exs'`
     - Failed as expected before implementation: current sender was `{"Memba", "messages@mail.memba.test"}`.
   - Focused unit tests:
     - Same command after implementation.
     - Passed: `4 tests, 0 failures`.
   - Focused inbound flow tests:
     - `devenv shell -- bash -lc 'real_mix=$(which -a mix | grep -v "$(pwd)/bin/mix" | head -1); cd web; "$real_mix" test test/memba/messaging/inbound_club_message_acceptance_test.exs'`
     - Passed: `15 tests, 0 failures`.
   - Broad quick validation:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `757 tests, 0 failures`.
   - Whitespace:
     - `git diff --check`
     - Passed.

4. **Exact todo check-off made**
   - Changed only task 007 from:
     - `- [ ] 007 Change the club-message rejection email sender/display name to <club name> via Memba while preserving sender address, reply-to/support guidance, and rejection content.`
   - To:
     - `- [x] 007 Change the club-message rejection email sender/display name to <club name> via Memba while preserving sender address, reply-to/support guidance, and rejection content.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0016 respected: kept the existing Swoosh/Mailer path and provider switchability; no new provider boundary or HTTP client was introduced.
   - Sender display-name change is localized to rejection email construction.
   - Reply-to, support copy, provider metadata/tags, rejection content, and no-club fallback behaviour are preserved.
   - No acceptance feature files were edited.