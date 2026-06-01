## Files changed

- `docs/iterations/011-member-facing-message-behaviour/plan.md`

## Summary of edits

I made only plan-level edits requested by Opus, without starting implementation:

1. **Marked plan as validated**
   - Updated header status:
     - from `Status: ready`
     - to `Status: validated for implementation`

2. **Strengthened acceptance criteria with deterministic failure outcomes**
   - Added explicit, testable criteria for member message detail access:
     - unauthenticated users redirect to `/auth` (magic-link flow) with return path preserved
     - signed-in users without active membership for `club_id` (including inactive members) get forbidden and see no message details
     - `message_id`/`club_id` mismatch returns not found and sees no message details

3. **Made deterministic failure behavior explicit in implementation plan step 5**
   - Added a sub-bullet list under member message detail covering:
     - redirect to `/auth` for unauthenticated
     - forbidden for signed-in non-member/inactive member
     - not found for message/club mismatch
     - explicit no-leak requirement for message content and operator-only diagnostics

## Opus instructions applied

Applied:

1. ✅ Add/expose clear validation marker near top (`Status: validated for implementation`)
2. ✅ Ensure concrete, stakeholder-visible acceptance criteria (augmented with explicit auth/mismatch outcomes)
3. ✅ Acceptance Scenarios / Feature Files section visibility (already present; retained)
4. ✅ Add deterministic failure behavior for message detail authorization, including no-leak assertions
5. ✅ Re-read and confirm new sections/content are visible in file

## Instructions skipped (need Matt)

- None. All requested edits were applied without needing new product-policy decisions.

## Notes for Opus recheck

- The file already had **Acceptance Criteria** and **Acceptance Scenarios / Feature Files** before this pass; this edit pass focused on:
  - adding the explicit validated status marker
  - making auth and mismatch failure behavior deterministic and visible in both criteria and implementation plan.
- Failure behavior wording is aligned to existing app conventions (redirect to `/auth`, forbidden for unauthorized active-membership checks, and not-found for resource mismatch/non-disclosure cases).