## Summary

I implemented the smallest production capability needed for the `@wip` scenario **"Eve asks to join Board"** in `acceptance-tests/features/custom_group_access_requests.feature` to go green, using the pre-recorded `predicted_red` evidence in `docs/iterations/066-request-group-access/.delivery/goal-directed-bdd/before.json` as the outer-loop target (missing function `Memba.Messaging.request_group_access/2`).

**What was added** (`web/lib/memba/messaging.ex`, +105 lines):
- `Messaging.request_group_access/2` — the `RequestGroupAccess` composite command described in the plan's domain model. It accepts only `:message_id`, `:club_id`, `:requester_person_id`, `:group_id`; resolves the requester's **current active club membership authoritatively** (`Membership.active_member_of_club_authoritatively?/2`) inside the existing `authorize_at_stable_checkpoint` pattern (same ordering guarantee used by `send_club_message_as_current_member`); rejects built-in groups and cross-club groups; composes the fixed subject/body naming the requester and group plus the safe `/groups/:group_id/members/add/:person_id` URL; and dispatches the existing `SendMessage` command to the club's Admin Group using the existing recipient-resolution helper. Client-supplied `sender_id`/`subject`/`body`/`audience_group_id` are structurally ignored since the command builder never reads them from caller input.
- No new aggregate, event, or request entity — matching the plan's explicit constraint.

**Tests written first and run** (`web/test/memba/messaging/request_group_access_test.exs`, new file, 5 tests, all passing):
1. Happy path: fixed message, exact subject/body, Admin recipients, write access grant, no group membership, no follow/read access for Eve.
2. Rejects a requester who is not currently an active club member (`{:error, :member_not_active}`).
3. Rejects a request targeting a built-in group (`{:error, :built_in_group}`).
4. Rejects a group belonging to another club (`{:error, :group_not_found}`).
5. Ignores client-supplied sender/subject/body/audience overrides.

**Verification performed** (via `./bin/dev test ...`, Postgres-backed, targeted runs only):
- `test/memba/messaging/request_group_access_test.exs` — 5/5 passing.
- The focused acceptance scenario exactly as the gate ran it: `mix test test/features/domain_cucumber_acceptance_test.exs --only "scenario_name:Eve asks to join Board"` — **1 test, 0 failures, 176 excluded** (previously 1 failure per `before.json`).
- Full `web/test/memba/messaging/` directory — 284 tests, 0 failures (no regressions to existing Messaging behaviour).
- `mix compile --warnings-as-errors --force` — clean, no new warnings.

**Not run**: the full `dev check` / browser acceptance suite, per the explicit instruction to avoid an unbounded suite in this worker node, and the `@todo` outlier scenario in the same feature (out of scope for this rehearsal).

**Scope respected**: no edits to the feature file (`@wip` left intact), no edits to `.delivery/goal-directed-bdd/`, no edits to the plan/domain-model docs, no widening of generic messaging/compose permissions (the generic `send_club_message_as_current_member` authorization path is untouched), no commit created — the working tree is left as the checkpoint for `observe_green` and review to evaluate.