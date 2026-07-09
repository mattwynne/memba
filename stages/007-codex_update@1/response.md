## Files changed

- `docs/iterations/050-club-home-conversation-and-member-row-fidelity/plan.md`

## Summary of edits

- Added the required `## Acceptance Scenarios / Feature Files` section.
- Named the relevant shared Cucumber feature files:
  - `acceptance-tests/features/club_message_replies.feature`
  - `acceptance-tests/features/list_members.feature`
- Listed the scenarios/coverage areas for:
  - Club-home conversation previews.
  - Removed “Recent club messages” heading.
  - Removed conversation-entry badges.
  - Removed duplicate “From {sender}” line.
  - Removed “Current members” heading.
  - Exactly one visible “Invite member” action.
- Added rationale that heading scale should be validated by targeted Phoenix/LiveView tests and gallery-walk rather than Gherkin CSS assertions.
- Tightened the heading acceptance criterion to reference `.page-title` scale.
- Updated the implementation and validation plans to reference the named acceptance scenarios.
- Reworded “New Capability” to clarify this is not a new workflow capability, but does create observable fidelity improvements.

## Opus instructions applied

- Added the missing `## Acceptance Scenarios / Feature Files` section.
- Named specific acceptance feature files and scenario coverage.
- Made the “normal page heading” criterion more objective.
- Clarified the observable capability while preserving the fidelity/polish intent.
- Kept the scope limited to the existing presentation-fidelity slice.

## Instructions skipped because they require Matt’s judgment

- None.

## Notes for Opus recheck

- I did **not** change `Status:` to `validated`, per the instruction that only the deterministic `publish_ready` stage may do that.
- I did not run `dev check` because this was a docs-only plan edit.