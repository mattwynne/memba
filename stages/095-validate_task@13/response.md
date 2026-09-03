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
    "completed_todo_checkoff": "Live worktree is clean. `/tmp/fabro-pre-validate-snapshot.md` also showed a clean tree at HEAD `1c7f51c`. Recent commits show implementation checkpoint `1c7f51c` followed by pre-validation checkpoint `d1603fb`. `git diff 1c7f51c^ 1c7f51c -- docs/iterations/056-group-audience-foundation/todo.md` shows exactly one ordinary task line changed from unchecked to checked: task 013. The parent todo had tasks 001-012 checked and task 013 as the first unchecked task.",
    "implementation_artifacts": "Checkpoint `1c7f51c` modifies `web/lib/memba/membership.ex`, `web/test/memba/membership/group_projection_test.exs`, and `web/test/memba/membership/public_api_test.exs`. The code routes member and Admin-role lifecycle APIs through `dispatch_system_group_membership_command/2`, upgrading omitted or eventual consistency to wait for `Memba.Membership.Policies.SystemGroupMembership` and augmenting explicit handler lists. Invitation acceptance membership creation paths also wait for the system-group policy. The existing group projectors are configured with `consistency: :strong`, and the checkpoint adds tests asserting that configuration.",
    "tests_run_results": "Focused validation run live: `PATH=\"$PWD/bin:$PATH\" dev test test/memba/membership/group_projection_test.exs test/memba/membership/public_api_test.exs` passed with `34 tests, 0 failures`. Formatting run live: `cd web && mix format --check-formatted lib/memba/membership.ex test/memba/membership/group_projection_test.exs test/memba/membership/public_api_test.exs` passed. Worktree remained clean afterward.",
    "adr_plan_conformance": "The task stays within the approved Membership-context scope and respects ADR 0007 by keeping Membership projection details behind Membership APIs; Messaging is not coupled to Membership schemas in this task. No acceptance feature files were edited. No todo work was deleted, weakened, split, or reordered. The checkpoint is small and independently useful for task 013."
  }
}