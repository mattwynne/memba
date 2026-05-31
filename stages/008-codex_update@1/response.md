## Files changed

- `docs/iterations/007-deliveries-overview/plan.md`

## Summary of edits

I made the obvious plan-clarification edits identified by review/synthesis, without changing scope:

1. **Specified required visible table fields more explicitly**
   - Added **event timestamp** to the listed diagnostic columns in scope.
   - Added **event timestamp** to acceptance criteria row field requirements.

2. **Made ordering an explicit acceptance requirement**
   - Added acceptance criterion: rows are ordered by **event timestamp descending (newest first)**.
   - Aligned the technical-shape note to the same concrete ordering requirement.

3. **Specified stable row selector contract for browser assertions**
   - Added acceptance criterion requiring a stable `data-test-id` row selector pattern based on a stable delivery identifier (example: `delivery-row-<id>`).

## Which Opus instructions were applied

Applied all obvious requested fixes from the review context:

- Add explicit acceptance criteria for required table fields/columns.
- Add explicit acceptance criterion for deterministic row ordering.
- Add explicit acceptance criterion for stable row/test selector identity for browser assertions.

## Instructions skipped (needs Matt’s judgment)

- **None skipped.**  
  All requested fixes were applied in a minimal, non-speculative way.

## Recheck notes for Opus

- Please verify the new acceptance criteria wording is sufficiently specific for implementation/testing:
  - field set now includes timestamp,
  - ordering is explicit and testable,
  - row selector contract is explicit with an example pattern.