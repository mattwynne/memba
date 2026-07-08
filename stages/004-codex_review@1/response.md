## Decision: READY

## Confidence: High

## Blocking gaps

None.

## Non-blocking improvements

1. Consider naming the specific test files expected to change, if known, to reduce implementation discovery time.
2. Consider clarifying whether “active roles” means only active role assignments, active role records, or both, although the implementation plan already calls out inspecting projection schemas to confirm field names and active flags.
3. The manual validation examples mention Alice, Bob, and Carol; the plan could briefly align those names with the Cucumber examples if they differ.

## Smallest viable iteration

The current slice is already close to the smallest useful behaviour-facing iteration: show assigned role badges for active members in the club-home Members tab, sorted alphabetically, while preserving active-member-only filtering. Splitting out the domain query without the UI would not deliver the stated member-facing value.

## Required plan edits

None.

## Validation plan

Success can be proven by:

1. Domain/query tests showing:
   - active members include a `roles` list,
   - members with no roles have an empty roles value,
   - multiple roles are sorted alphabetically,
   - removed members remain absent even if they had roles.

2. Presentation/UI tests showing:
   - role badges render in the Members tab,
   - members with no roles show no badges,
   - removed members do not render.

3. Cucumber validation:
   - `acceptance-tests/features/list_members.feature` `@iteration-049` scenarios execute in both domain and browser runners,
   - `@todo-domain` and `@todo-ui` tags are removed.

4. Visual/manual validation:
   - `./bin/dev gallery-walk` comparison against `design-system/wireframes/club-home.html`,
   - manual check of the club home Members tab confirming alphabetical badges and no removed members.

5. Final stop condition:
   - `dev check` passes.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}