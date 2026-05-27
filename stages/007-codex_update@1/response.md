### Files changed

- `docs/iterations/001-member-message-deliverability/plan.md`

### Summary of edits

- Removed the earlier scattered/legacy `## Acceptance Criteria` section near the top of the plan.
- Added a new dedicated `## Acceptance Criteria` section **immediately before** `## Validation Plan`.
- Populated that section with the 10 numbered, objectively testable criteria from the Opus repair brief (wording kept aligned with the brief).
- Left all other sections intact in content and intent (Implementation Plan, Open Technical Decisions, New Capability, Validation Plan, Risks/Follow-ups, etc.).

### Which Opus instructions were applied

Applied all requested instructions from the Codex Repair Brief:

1. Added a dedicated **Acceptance Criteria** section.
2. Placed it immediately before **Validation Plan**.
3. Consolidated criteria into a numbered, testable checklist matching the provided list.
4. Avoided introducing new product/domain/technical decisions.
5. Did not edit any app code or unrelated files.

### Instructions skipped (require Matt’s judgment)

- None.

### Anything Opus should pay special attention to in recheck

- Confirm there is now exactly one canonical `## Acceptance Criteria` section in the intended location (before `## Validation Plan`).
- Confirm criteria are pass/fail testable and map cleanly to existing plan scope/ADRs without adding new scope.