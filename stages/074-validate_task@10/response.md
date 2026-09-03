{
  "preferred_next_label": "valid",
  "outcome": "succeeded",
  "failure_reason": "",
  "suggested_next_ids": [],
  "context_updates": {
    "task_valid": true,
    "task_retry_available": false
  },
  "decision": "VALID",
  "evidence": {
    "completed_todo_checkoff": "Live worktree is clean. Current HEAD ad06a89 is an empty pre-validation checkpoint; the latest substantive implementation checkpoint is 261366c. `git show 261366c -- docs/iterations/056-group-audience-foundation/todo.md` shows exactly one ordinary todo line changed: task 010 from `- [ ]` to `- [x]`. The diff context shows tasks 001-009 already checked and task 010 was the first unchecked task.",
    "implementation_artifacts": "Checkpoint 261366c adds `web/lib/memba/membership/policies/system_group_membership.ex`, defining `Memba.Membership.Policies.SystemGroupMembership` with `use Commanded.Event.Handler`, `application: Memba.Membership.App`, stable name `\"Memba.Membership.Policies.SystemGroupMembership\"`, `consistency: :strong`, and `start_from: :current`. It adds the policy to `Memba.Application` supervision and updates `Memba.EventSourcedCase` to include this non-projector EventStore subscriber in reset/restart/checkpoint handling.",
    "tests_run_results": "Checkpoint 261366c adds focused tests in `web/test/memba/membership/system_group_membership_policy_test.exs` and extends `web/test/memba/membership/app_test.exs` to assert supervision. I reran live: `PATH=\"$PWD/bin:$PATH\" dev test test/memba/membership/app_test.exs test/memba/membership/system_group_membership_policy_test.exs test/memba/membership/group_projection_test.exs`; result: 7 tests, 0 failures. Worktree remained clean afterward.",
    "adr_plan_conformance": "The work matches plan task 010 as a standalone first slice of implementation-plan item 5; tasks 011-013 remain unchecked for handler behavior, stateless idempotency details, and strong command/queryability flow. It stays within Membership infrastructure, uses Commanded per ADR 0002, does not cross Membership/Messaging storage boundaries per ADR 0007, keeps projection logic separate per ADR 0009, and preserves projection-barrier/test reset coherence per ADR 0022. No `.feature` or `acceptance-tests` files were modified."
  }
}