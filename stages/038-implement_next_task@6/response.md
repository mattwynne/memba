Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `006 Add LiveView progress rendering and subscription. Refresh from persistence after receiving committed-change notifications.`

2. **Changes made**
   - Added `Memba.AuthEmailProgressChanges` topic/subscription helper:
     - Narrow per-request PubSub topic.
     - Payloads are designed to carry only the opaque auth-email request ID.
     - No sensitive email/account-existence data is published or subscribed through the topic.
   - Updated `MembaWeb.AuthLive.SignIn`:
     - Loads persisted auth-email progress for `/auth/check-email/:request_id`.
     - Renders a progress card with key DOM IDs:
       - `#auth-email-progress`
       - `#auth-email-progress-message`
     - Shows plan-required copy for:
       - Created/pre-send: `Preparing your sign-in link…`
       - Sent/neutral: `If this email can sign in, the link is on its way.`
       - Provider accepted: `Your mailbox provider has accepted the email. It should appear shortly.`
       - Fallback after 60s: `If it does not arrive, check junk mail or ask for another link.`
       - Expired neutral guidance.
     - Subscribes when connected to the request-specific auth progress topic.
     - Refreshes from persistence after receiving `{:auth_email_progress_changed, %{request_id: ...}}`.
     - Schedules the neutral fallback refresh without inventing progress.
   - Added focused LiveView tests in `auth_controller_test.exs` for:
     - Initial created progress rendering.
     - Sent and provider-accepted rendering.
     - 60-second fallback rendering.
     - Live refresh after a committed progress notification broadcast.

3. **Validation commands run**
   - New focused tests initially failed before implementation as expected.
   - Focused tests after implementation:
     - `devenv shell -- bash -lc 'cd web && PATH="$PWD/../bin:$PATH" mix test test/memba_web/controllers/auth_controller_test.exs:79 test/memba_web/controllers/auth_controller_test.exs:94 test/memba_web/controllers/auth_controller_test.exs:124 test/memba_web/controllers/auth_controller_test.exs:145'`
     - Result: `4 tests, 0 failures`
   - Full focused auth test file:
     - `devenv shell -- bash -lc 'cd web && PATH="$PWD/../bin:$PATH" mix test test/memba_web/controllers/auth_controller_test.exs'`
     - Result: `29 tests, 0 failures`
   - Formatting check:
     - `devenv shell -- bash -lc 'cd web && mix format --check-formatted lib/memba/auth_email_progress_changes.ex lib/memba_web/live/auth_live/sign_in.ex test/memba_web/controllers/auth_controller_test.exs'`
     - Result: passed
   - Whitespace:
     - `git diff --check`
     - Result: passed
   - Full quality gate because this changed LiveView/UI behaviour:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: passed, including `77 scenarios (77 passed)`

4. **Todo check-off made**
   - Changed exactly:
     - From: `- [ ] 006 Add LiveView progress rendering and subscription. Refresh from persistence after receiving committed-change notifications.`
     - To: `- [x] 006 Add LiveView progress rendering and subscription. Refresh from persistence after receiving committed-change notifications.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Followed ADR 0021’s committed-change discipline from the LiveView side: the LiveView reacts to a change notification by reloading persisted state rather than trusting PubSub payload state.
   - Kept ADR 0022 separation intact: no projection barrier or read-your-writes mechanism was introduced.
   - The auth progress notification topic is narrow and request-scoped.
   - PubSub payloads contain only the opaque auth-email request ID; no email address or account-existence information is broadcast.
   - Publishing after DB commit is intentionally left for task 008; this task implemented rendering/subscription and persistence reload behavior only.