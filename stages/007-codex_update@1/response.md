## Files changed

- `docs/iterations/051-conversation-participant-avatar-stack/plan.md`

## Summary of edits

- Added the required `## Acceptance Scenarios / Feature Files` section.
- Named the shared Cucumber feature file:
  - `acceptance-tests/features/club_message_replies.feature`
- Named the existing rule to extend:
  - `Rule: On the club home, each conversation is one entry with its reply count`
- Listed stakeholder-readable scenario coverage for:
  - no replies shows no avatar stack;
  - 1–3 distinct repliers shown in first-reply order;
  - originator excluded;
  - duplicate replies by the same participant de-duplicated;
  - 4+ distinct repliers show first 3 avatars plus `+N`.
- Tightened acceptance criteria to explicitly mention de-duplication.
- Clarified CSS scope as the row-relevant `.conversation`, `.conversation__*`, and `.avatar-stack` classes only.

## Opus instructions applied

- Added `## Acceptance Scenarios / Feature Files`.
- Named the relevant shared Cucumber feature file.
- Listed scenarios requested by Gemini/Codex review.
- Preserved the existing plan status; did **not** mark it `validated`.
- Did not edit app code or unrelated files.

## Instructions skipped because they require Matt's judgment

- None.

## Anything Opus should pay special attention to in recheck

- Confirm the newly added acceptance scenario section satisfies the behaviour-facing plan requirement.
- Confirm the CSS scope clarification is acceptable and does not narrow the intended implementation too far.