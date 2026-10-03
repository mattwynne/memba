Packet `task-006a-d3c06ca-bob-sees-alice-2` is `ready_for_review`.

Added [live_club_member_list_steps.exs](/workspace/memba/web/test/features/step_definitions/live_club_member_list_steps.exs), which owns the three previously undefined steps. The five scenario steps now map uniquely:

- Bob’s existing membership: `Memba.Cucumber.AuthenticationSteps`
- Bob opens the member list: `Memba.Cucumber.LiveClubMemberListSteps`
- Alice is not yet a member: `Memba.Cucumber.ClubMemberInvitationSteps`
- Alice joins: `Memba.Cucumber.LiveClubMemberListSteps`
- Bob sees Alice: `Memba.Cucumber.LiveClubMemberListSteps`

The scenario plumbing:

- Opens one connected `/members` LiveView using Bob’s context-derived email and the context-derived Kootenay club host.
- Confirms Bob is rendered and Alice is initially absent.
- Calls `Memba.Membership.add_member/2` with a fresh membership ID and `consistency: :strong`.
- Relies on the Membership projector’s normal `after_update/3` publication and the existing `{:club_members, club_id}` invalidation.
- Asserts `#club-member-<Alice person_id>` and Alice’s name against the original connected LiveView, without remounting, reloading, patching, or navigating.

Supporting validation passed:

- Domain Cucumber/configuration tests: 5 tests, 0 failures.
- Dashboard LiveView tests: 57 tests, 0 failures.
- `bin/mix format --check-formatted`: passed.
- `git diff --check`: passed.

The locked feature, its `@wip` tag, and `todo.md` were untouched. Per packet instructions, I did not run the selected scenario or full `dev check`; the trusted after-worker and deterministic quality-gate nodes own those runs. No unresolved issues were recorded.

The routing artifact is at [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json).