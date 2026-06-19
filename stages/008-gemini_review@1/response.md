# Iteration 036 Review Report

## Decision: REJECT

## Confidence: High

This is a procedural rejection due to a scope and review-boundary mismatch. The reviewed commit range (`9d699054c173f9dc30454056a03230357a6a1d38..HEAD`) includes significant application, domain, and test code for club slugs and public subdomains. The Iteration 036 plan explicitly mandates: *"No app code, routes, LiveViews, templates, or `.feature` files are changed."* 

If this application work is from a previous iteration (e.g., Iteration 035), the review was run against an incorrect base SHA and needs to be re-run against the DS-only diff. If it was intentionally added to this iteration, it violates the plan's strict constraints and requires a revised plan or human approval.

## ADR Conformance: PASS

No ADR violations were detected in the visible evidence. The domain/CQRS patterns visible in the out-of-scope slug implementation appear to align with established project patterns.

## ADR Violations

None found.

## Blocking Issues

1. **Scope Violation / Incorrect Review Base:** The commit range contains extensive changes to application behaviour and tests (e.g., public club subdomain routing, smoke-test club filtering, and `staff_club_slugs.feature`), which directly contradicts the plan's rule that no app code or tests be modified. This must be corrected either by fixing the branch/review-base so only the Design System preview files are evaluated, or by obtaining explicit human approval for the expanded scope.

## Bounded-Safe Fixes

*(These apply to the DS preview files once the scope is corrected)*

1. **Remove Tailwind Utility Classes in Static Previews:** Previous agent reviews noted the presence of Tailwind utilities like `mx-auto` and inline styles like `max-width: 480px` in the new preview HTML files (`design-system/wireframes/auth/check-email.html`, etc.). The plan explicitly states previews must *"not rely on Tailwind utility classes."* 
   - **Fix:** Replace these with standard CSS classes defined in the file's `<style>` block (e.g., `.preview-container { max-width: 480px; margin: 0 auto; }`).

2. **Organize File-Local CSS:** Add structural comments within the `<style>` blocks of each preview file to separate the copied theme variables, base layout rules, and component overrides.

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Theme Variable Duplication (design-system/wireframes/*.html):**
   - **Smell:** Each self-contained preview duplicates the application's root theme CSS variables. 
   - **Why it needs judgement:** This satisfies the plan's requirement that every preview be "self-contained" and not rely on the bespoke shared component CSS. However, it introduces a maintainability burden if the core theme colors/spacing change. A future architectural decision may be needed to determine if a build step should inject these variables rather than duplicating them manually.

2. **Reserved Slug Filtering Architecture (lib/memba/clubs/aggregates/club.ex & routing):**
   - **Smell:** The application (visible in the broader commit range) appears to prevent the "test" slug both via aggregate validation and runtime subdomain filtering.
   - **Why it needs judgement:** If the club slug work is eventually merged, ensuring a single source of truth for reserved subdomains (e.g., via a module attribute or centralized configuration) would prevent drift between aggregate boundaries and web-tier routing constraints. 

## Suggested Fixes

1. **Resolve Review Boundary:** Identify the correct base SHA that isolates only the Design System preview file changes, and re-run the `dev check` and review workflow against that specific diff.
2. **Apply Local CSS:** Strip out any leftover Tailwind utility classes in the DS previews and replace them with plain CSS as mandated by the iteration plan.

## Validation Notes

- The `dev check` passed with 82 scenarios and 493 steps all green, confirming that the underlying application (including the out-of-scope slug work) is stable.
- The plan's validation mechanism for the DS previews themselves relies on headless Chrome renders and manual DesignSync pushes, which are confirmed to happen outside of this automated verification slice.