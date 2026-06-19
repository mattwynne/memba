# Iteration 036 Review Report

## Decision: REJECT

## Confidence: High

This is a procedural rejection due to a direct contradiction between the iteration plan's constraints and the provided commit range. The implementation contains substantial out-of-scope application work.

## ADR conformance: PASS

No ADR violations were detected in the visible implementation evidence. The out-of-scope domain and CQRS work (club slugs) appears to align with established project patterns for aggregates and read models.

## ADR violations

None found.

## Blocking issues

1. **Scope Violation / Incorrect Review Boundary**
   - **Plan constraint:** The iteration plan explicitly states: *"No app code, routes, LiveViews, templates, or `.feature` files are changed."*
   - **Evidence:** The collected implementation evidence for the commit range (`9d699054c173f9dc30454056a03230357a6a1d38..HEAD`) includes a new acceptance feature (`features/staff_club_slugs.feature`), changes to domain aggregates (`lib/memba/clubs/aggregates/club.ex`), and public club subdomain routing/controller tests (`test/memba_web/controllers/club_site_controller_test.exs`).
   - **Why this blocks:** The commit range contains a complete feature implementation for club slugs and subdomains, which is entirely outside the scope of adding static Design System preview files. This indicates that either the base SHA for the review is incorrect (evaluating a different iteration's work) or the work was intentionally bundled and the plan is outdated.
   - **Required resolution:** A human must intervene to either provide the correct base SHA that isolates only the Iteration 036 Design System preview files, or explicitly approve the expanded scope by updating the plan.

## Bounded-safe fixes

None applicable until the scope boundary is resolved. The previously synthesized issue regarding Tailwind-style CSS cleanup in the Design System static previews was investigated by the repair agent and found to be unsupported by the actual file contents (the files correctly avoid utility classes).

## Judgement-worthy non-blocking code-health findings

*(These apply only if the club slug/subdomain work is eventually approved as in-scope)*

1. **Reserved slug knowledge split across layers**
   - **Files:** `lib/memba/clubs/aggregates/club.ex`, public club subdomain routing logic.
   - **Smell:** The "test" slug is reserved during aggregate validation (`validate_exclusion(:slug, ["test"])`) and also filtered at runtime for public routing.
   - **Why it needs judgement:** If the reserved subdomains expand (e.g., to include `www`, `api`, `admin`), maintaining consistency across the domain aggregate validation and the web routing constraints will require coordination. Introducing a single source of truth (like a module attribute or shared configuration) could reduce the risk of drift.

## Suggested fixes

1. **Resolve the scope boundary mismatch (Human Input Required):**
   - If the club slug work belongs to a prior iteration, determine the correct base SHA for Iteration 036 and rerun the review workflow to isolate the DS preview files.
   - If the club slug work is intentionally part of this merge, obtain human approval and update the iteration plan to reflect the actual scope.
2. **Discard the stale CSS cleanup blocker:** The repair agent successfully confirmed that the Design System preview files do not contain the problematic inline styles or utility classes originally flagged. No churn is necessary there.

## Validation notes

- **Tests:** `dev check` successfully passed, executing 82 scenarios and 493 steps (all green), proving that the underlying application and the visible out-of-scope slug work is stable.
- **Sandbox:** Sandbox runtime check passed cleanly.
- **Repair Cycle:** The repair agent correctly verified that no file-local CSS fixes were needed for the DS previews, confirming the static files are well-formed according to the plan's rules.
- **Conclusion:** The code quality is high, but the merge must be blocked procedurally until the iteration boundary is clarified.