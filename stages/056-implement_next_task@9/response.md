Implemented the next unchecked task.

1. **Selected todo line**
   - `009 Update Accounts sign-in eligibility to search all known addresses for active members, while preserving staff @memba.io sign-in behaviour.`

2. **Changes made**
   - Updated `web/lib/memba/accounts.ex`
     - Clarified `request_sign_in_link/2` docs to say member eligibility includes any known email address attached to an active member.
     - Renamed the private eligibility helper from `sign_in_link_recipient?/1` to `eligible_sign_in_email?/1` to match the broader eligibility rule.
     - Preserved existing staff `@memba.io` eligibility behaviour.
   - Updated `web/test/memba/accounts_test.exs`
     - Added coverage proving an active member can request a sign-in token using an alternate email address.
     - Extended the local test helper to create people with multi-address payloads for this Accounts test only.
   - Updated `docs/iterations/016-person-email-addresses/todo.md`
     - Checked off task `009` only.

3. **Validation run**
   - `cd /workspace/memba/web && mix format --check-formatted lib/memba/accounts.ex test/memba/accounts_test.exs`
     - Passed.
   - `cd /workspace/memba/web && PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 mix test test/memba/accounts_test.exs`
     - Passed: `9 tests, 0 failures`.
   - `git diff --check`
     - Passed.
   - `PATH="/workspace/memba/bin:$PATH" dev check`
     - Passed: `333 tests, 0 failures`.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 009 Update Accounts sign-in eligibility to search all known addresses for active members, while preserving staff @memba.io sign-in behaviour.`
   - To:
     - `- [x] 009 Update Accounts sign-in eligibility to search all known addresses for active members, while preserving staff @memba.io sign-in behaviour.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0002: Kept Accounts using application/query APIs; no CRUD write path or aggregate bypass introduced.
   - ADR 0007: Accounts continues depending on Membership’s public query API, not Membership projection storage details.
   - ADR 0009: Continued relying on Membership projections through public queries for eligibility.
   - ADR 0010 / acceptance lock: No acceptance feature files were changed.
   - ADR 0011: Email remains mutable identity data; person identity remains UUID-based, not email-based.