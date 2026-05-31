# Iteration Plan Review: Routing and LiveView Surface Split

## Decision: READY

## Confidence: High

The plan is well-structured, comprehensive, and contains all necessary information for successful implementation. The goal is clear, scope is focused, acceptance criteria are testable, and the implementation plan is detailed and ordered.

## Blocking gaps

**None.** All necessary decisions are present with stated preferences.

## Non-blocking improvements

1. **Section header clarity**: The "Open Technical Decisions" section lists three decisions that are already resolved with clear preferences ("Prefer X"). Consider renaming to "Technical Decisions" or "Finalized Technical Decisions" to avoid confusion during implementation.

2. **Test coverage clarity**: Step 6 mentions "Update controller and LiveView tests" but the plan focuses heavily on LiveView modules. Consider being explicit that PageController tests (if any) may not need changes since public routes remain at `/`.

3. **Layout function detail**: The club-site layout acceptance criterion could specify what "CSS custom properties" means in practice (e.g., `--club-primary-color`, `--club-accent`), though the stated "neutral slate default" is sufficient for implementation.

## Smallest viable iteration

The plan is already appropriately scoped. The club-site layout seam is the smallest potentially deferrable piece, but keeping it makes sense as a clear foundation for future work without adding implementation complexity.

The plan correctly:
- Focuses on routing and module organization (one coherent outcome)
- Explicitly excludes authentication, real club resolution, and member-facing routes
- Treats the club-site surface as a structural seam rather than a full implementation

## Required plan edits

**Rename "Open Technical Decisions" to "Technical Decisions"** or similar, since each item states a clear preference that should be followed:
- Move files to match module names (not leave in place)
- Use `:staff_browser` pipeline (not keep generic `:browser`)  
- Create real layout function (not placeholder)

These preferences are effectively finalized decisions and should be presented as such to avoid implementation uncertainty.

## Validation plan assessment

The validation plan is **comprehensive and practical**:

**Automated coverage:**
- Public pages still work
- Admin routes render moved pages
- Old harness routes no longer work
- Postmark webhook remains operational
- `bin/dev check` passes

**Manual smoke test** covers seven specific scenarios across all three surfaces (public, admin, and club-site layout verification).

**Clear success criteria:**
- All existing functionality accessible at new paths
- Old paths return 404 or redirect appropriately
- Three layout functions exist with correct theming infrastructure
- Module names reflect surface boundaries

**Suggested addition** (non-blocking): After manual testing, verify that no dead links exist by checking that all `~p` verified route helpers compile and match actual routes.

## Implementation readiness

**Ready to implement:**
- All files and modules are named (router, LiveViews, layouts)
- Route structure is fully specified with paths and scopes
- Module renames are listed explicitly
- Layout responsibilities are clear
- Test update requirements are stated
- Integration points (webhook) are preserved

**Clear handoff:**
The implementer can proceed with:
1. Following the 8-step implementation plan in order
2. Using the stated preferences from "Open Technical Decisions" as firm choices
3. Following the validation plan after each major step
4. Using acceptance criteria as completion checklist

The plan demonstrates excellent iteration discipline: it solves one problem (surface organization), establishes foundation for future work (club-site seam), and explicitly defers follow-up concerns (auth, member features).

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"Rename 'Open Technical Decisions' to 'Technical Decisions' to reflect that preferences are finalized decisions"}}