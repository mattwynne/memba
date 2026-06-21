Implemented the next unchecked iteration task: **005**.

1. **Selected todo line**
   - `005 Revise club_message_replies.feature per Allowed acceptance feature changes; make the @iteration-040 scenarios executable (domain then browser/email), removing/narrowing @todo-*).`

2. **Changes made**
   - Revised `acceptance-tests/features/club_message_replies.feature`:
     - Replaced the old “reply emailed to every current member” rule with `@iteration-040` “current club-member followers” coverage.
     - Added executable scenarios for:
       - sender/replier auto-follow
       - opt-in default
       - in-app follow/unfollow
       - follower-only reply delivery
       - former-member exclusion
       - valid reply-email stop-follow link
       - tampered stop-follow link changing nothing
     - Preserved the 039 reply/conversation/current-member-reply scenarios.
     - Confirmed no `@todo-domain` / `@todo-ui` tags remain in this feature.
   - Added browser acceptance step/support plumbing in:
     - `acceptance-tests/features/step_definitions/member_message_steps.js`
     - `acceptance-tests/features/support/member_message.js`
   - Added domain Cucumber step plumbing in:
     - `web/test/features/step_definitions/messaging_steps.exs`

3. **Validation run**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/features/step_definitions/messaging_steps.exs`
     - Passed.
   - Direct domain test attempt hit the known sandbox `PGHOST` mismatch, so I reran via devenv:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/features/domain_cucumber_acceptance_test.exs --only domain_cucumber`
     - Passed: `74 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev acceptance features/club_message_replies.feature`
     - Passed: `91 scenarios, 594 steps`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: full ExUnit + browser acceptance suite.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 005 Revise ...`
   - To:
     - `- [x] 005 Revise ...`
   - Left `006 Run dev check` unchecked.

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No `docs/adr/*.md` files are present.
   - Stayed within the plan’s explicit allowed acceptance feature changes for `club_message_replies.feature`.
   - Added only executable acceptance plumbing needed for the selected task.