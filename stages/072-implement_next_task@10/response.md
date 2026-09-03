Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 010 Implement and supervise Memba.Membership.Policies.SystemGroupMembership as a stateless Commanded.Event.Handler with a stable handler name, consistency: :strong, and start_from: :current.`

2. **Changes made**
   - Added `Memba.Membership.Policies.SystemGroupMembership`
     - Uses `Commanded.Event.Handler`
     - `application: Memba.Membership.App`
     - stable name: `"Memba.Membership.Policies.SystemGroupMembership"`
     - `consistency: :strong`
     - `start_from: :current`
     - no handler state configured
   - Added it to `Memba.Application` supervision.
   - Updated `Memba.EventSourcedCase` to stop/restart this new EventStore subscriber alongside projectors during event-sourced test resets, avoiding stale strong-consistency subscriptions.
   - Added focused tests:
     - policy child spec/options/statelessness
     - Phoenix app supervision includes the policy handler

3. **Focused validation**
   - `cd web && mix format --check-formatted lib/memba/membership/policies/system_group_membership.ex lib/memba/application.ex test/memba/membership/app_test.exs test/memba/membership/system_group_membership_policy_test.exs test/support/event_sourced_case.ex`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/app_test.exs test/memba/membership/system_group_membership_policy_test.exs test/memba/membership/group_projection_test.exs`
     - Passed: `7 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Command exited `0`.
     - Output still prints the known unrelated `MembaWeb.PageControllerTest` public-footer failures; I did not touch them because they are unrelated to task 010.

4. **Todo check-off made**
   - Changed exactly task 010 from:
     - `- [ ] 010 ...`
   - to:
     - `- [x] 010 ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0002: implemented the policy using Commanded event-handler infrastructure.
   - ADR 0007: stayed within the Membership bounded context; no Messaging dependency or cross-context storage access added.
   - ADR 0009: kept projector behavior separate; this policy is a non-projection event handler.
   - ADR 0022: adjusted test reset handling so the new strong EventStore subscriber does not break read-your-writes/strong-consistency test flows.