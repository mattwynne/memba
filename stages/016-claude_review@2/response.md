# Iteration 036 Review Report

## Decision: REJECT

## Confidence: High

This is a procedural rejection due to scope and review-boundary mismatch, not a code-quality rejection. The reviewed commit range contains substantial application work that violates the iteration plan's explicit constraints.

## ADR conformance: PASS

No ADR violations detected in the visible implementation. The club slug/subdomain work (though out-of-scope for this iteration's stated plan) appears to follow proper CQRS/ES patterns: aggregate validation, command/event structure, projection updates, and read-model usage for uniqueness checks.

## ADR violations

None found in the code itself.

## Blocking issues

1. **Scope violation: commit range includes substantial out-of-scope application work**

   - **Plan constraint:** "No app code, routes, LiveViews, templates, or `.feature` files are changed."
   - **Evidence from commit range `9d699054c173..HEAD`:**
     - New acceptance file: `features/staff_club_slugs.feature`
     - Aggregate changes: `lib/memba/clubs/aggregates/club.ex`
     - Public club subdomain routing and controller logic
     - Test file: `test/memba_web/controllers/club_site_controller_test.exs`
     - Domain/CQRS/event-sourcing implementation for club slug validation and subdomain behavior
   - **Why this blocks:** The plan explicitly limits scope to design-system preview files only. The commit range includes a complete feature implementation (club slugs and public subdomains) with domain logic, routing, tests, and acceptance criteria. This is either:
     - Wrong base SHA (should review a different range containing only DS files)
     - Multiple iterations accidentally combined
     - Plan is outdated and doesn't reflect what was implemented
   - **Required resolution:** Human must clarify which work belongs to iteration 036 and provide the correct commit range, or approve expanded scope with an updated plan.

2. **Synthesized repair blocker was misidentified**

   - **Synthesis selected:** `ds-preview-static-css-cleanup` (Replace Tailwind utilities with file-local CSS)
   - **Repair agent finding:** No problematic patterns found in current DS preview files
   - **Actual blocking issue:** Scope violation (#1 above)
   - **Why this blocks:** The pipeline synthesized a non-existent CSS issue as the sole blocker, while all three independent review agents correctly identified the scope violation as the primary rejection reason. This synthesis failure prevented proper resolution of the actual blocking issue.
   - **Required resolution:** Re-run synthesis or manually route to human input for scope clarification.

## Bounded-safe fixes

None applicable until scope is clarified. The DS preview files themselves appear clean and don't require the CSS fixes that were synthesized as a blocker.

## Judgement-worthy non-blocking code-health findings

*(These apply only if the club slug/subdomain work is confirmed in-scope after human resolution)*

1. **Reserved slug handling split across layers**
   - **Files:** `lib/memba/clubs/aggregates/club.ex` (validation), public club subdomain routing/lookup
   - **Smell:** The "test" slug is reserved via aggregate validation (`validate_exclusion(:slug, ["test"], ...)`) and also filtered at runtime for public club subdomain routing
   - **Why it needs judgement:** If reserved slugs expand (e.g., `www`, `api`, `admin`), maintaining consistency across aggregate validation and runtime routing requires coordination. Consider whether a single source of truth (module attribute, shared config, or dedicated module) would reduce drift risk.

2. **Hardcoded reserved slug list**
   - **File:** `lib/memba/clubs/aggregates/club.ex`
   - **Pattern:** `validate_exclusion(:slug, ["test"], message: "is reserved")`
   - **Why it needs judgement:** Single reserved slug is fine as inline list. If more are added, extracting to `@reserved_slugs ~w(test www api admin)` module attribute would be clearer and easier to maintain/document. Not urgent for single-item list.

3. **Iteration/review boundary ambiguity**
   - **Evidence:** Plan describes DS-only scope; commit range includes substantial feature work
   - **Impact:** Future reviews need crisp iteration boundaries to avoid evaluating unrelated changes together
   - **Why it needs judgement:** May indicate tooling/process issue with how base SHAs are determined or how iterations are merged. Human should review iteration workflow to prevent recurrence.

## Suggested fixes

**For immediate action:**

1. **Resolve scope before proceeding**
   - If club slug work belongs to a prior iteration: determine correct base SHA for iteration 036 (DS-only range) and re-run review workflow
   - If work is intentionally combined: obtain human approval and update plan to document actual scope
   - If plan is outdated: update plan to match implementation or split work into separate iterations

**For DS preview files (once scope is resolved):**

The DS preview files appear clean based on the repair agent's investigation. No CSS fixes are required.

**For club slug work (if confirmed in-scope):**

If the club slug/subdomain implementation is approved as part of this iteration, consider extracting the reserved slug list to a module attribute for future maintainability:

```elixir
# lib/memba/clubs/aggregates/club.ex
@reserved_slugs ~w(test)

# Then in validation:
|> validate_exclusion(:slug, @reserved_slugs, message: "is reserved")
```

## Validation notes

1. **Tests:** `dev check` passed with 82 scenarios, 493 steps all green, including new `staff_club_slugs.feature` acceptance coverage
2. **Working tree:** Clean at review start
3. **Sandbox:** Passed runtime check
4. **Repair cycle outcome:** Repair agent correctly identified no CSS issues in DS preview files; verification failed because no changes were made (expected for misidentified blocker)
5. **All three independent review agents agreed:** Claude, GPT-5.5, and Gemini all identified scope violation as primary rejection reason
6. **Synthesis failure:** Selected minor CSS concern instead of the scope violation that all three agents flagged

**The implementation quality is good**—tests pass, patterns are correct, ADRs are followed. The rejection is purely procedural: the commit range being reviewed doesn't match the plan's documented scope. Human must resolve which work belongs to iteration 036 before meaningful code review can proceed.