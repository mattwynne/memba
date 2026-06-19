# Iteration 036 Review Report

## Decision: ACCEPT

## Confidence: Medium

The code quality is solid and patterns are correct. Confidence is medium due to apparent scope confusion: the commit range includes both DS preview files (matching the plan) and a full club slug/subdomain feature implementation (not mentioned in the plan). However, given the explicit statement that plan conformance was already validated, I'm treating this as evidence collection showing a broader range than this specific iteration.

## ADR Conformance: PASS

No ADR violations found. The club slug implementation (if part of this iteration) correctly follows CQRS/ES patterns: aggregate validation, event structure, read-model usage for uniqueness checks, proper projection updates.

## ADR Violations

None.

## Blocking Issues

None. Tests pass, code patterns are correct, coverage is comprehensive.

## Bounded-Safe Fixes

1. **Extract inline styles to CSS classes in DS preview files**
   - Files: `design-system/wireframes/auth/check-email.html`, `design-system/wireframes/member-invitations/*.html`
   - Pattern: `<div style="max-width: 480px" class="mx-auto">` appears in multiple files
   - Fix: Define `.preview-container { max-width: 480px; margin: 0 auto; }` in the `<style>` section and use it consistently
   - Benefit: Separation of concerns, easier to maintain consistent layout

2. **Add structural comments to DS preview CSS sections**
   - Files: All 5 new DS preview HTML files
   - Add comments marking theme variables section, layout section, component overrides
   - Example:
     ```css
     /* Theme Variables */
     :root { ... }
     
     /* Layout Utilities */
     .preview-container { ... }
     
     /* Component Overrides */
     .custom-button { ... }
     ```

3. **Consider module constant for reserved slugs**
   - File: `lib/memba/clubs/aggregates/club.ex`
   - Current: `validate_exclusion(:slug, ["test"], message: "is reserved")`
   - Better: Define `@reserved_slugs ["test"]` at module level, then use `validate_exclusion(:slug, @reserved_slugs, ...)`
   - Benefit: Single source of truth when more reserved slugs are added (www, api, admin, etc.)

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Theme variable duplication across DS preview files**
   - Files: `design-system/wireframes/auth/check-email.html`, `design-system/wireframes/member-invitations/invite-a-member-{admin,staff}.html`, `design-system/wireframes/member-invitations/profile-completion.html`, `design-system/components/badges/badges.card.html`
   - Smell: Each file contains a full copy of the theme CSS variables (~20-30 variables defining colors, spacing, typography)
   - Impact: Theme updates require touching all preview files; risk of inconsistency
   - Trade-off: Self-contained files (good for portability, matches plan requirement) vs maintainability (harder to keep in sync)
   - Why human judgement: Need product decision on whether self-contained duplication is acceptable or whether to introduce shared CSS generation/inclusion mechanism

2. **Smoke-test club slug filtering architecture**
   - Files: `lib/memba/clubs/aggregates/club.ex` (validation), router plug implementation (visible), `ClubSite.club_from_subdomain/1` (not shown), tests in `test/memba_web/controllers/club_site_controller_test.exs`
   - Smell: The aggregate prevents creating slug "test", and tests prove `test.lvh.me` returns 404, but the routing plug doesn't visibly implement this filtering
   - Current visible code: `public_club_subdomain` plug calls `ClubSite.club_from_subdomain(conn.host)` which presumably handles the "test" slug rejection
   - Impact: The filtering logic is hidden in a helper module not shown in evidence; coupling between aggregate validation and runtime filtering isn't explicit
   - Why human judgement: Should the smoke-test filtering be more explicit at the routing layer, or is the current hidden-in-helper approach acceptable? Related: should reserved slug handling be centralized vs split between aggregate validation and runtime filtering?

3. **Commit range appears broader than iteration scope**
   - Files: Entire diff range `9d699054c173..HEAD`
   - Smell: Plan describes DS preview files only; diff shows both preview files AND a complete club slug/subdomain routing feature (aggregate changes, commands, events, projections, routing, controllers, tests, new feature file)
   - Impact: Evidence collection might be showing accumulated changes from multiple iterations or wrong base commit
   - Why human judgement: Either (a) the base SHA is wrong and includes prior iterations, (b) multiple iterations were combined, (c) plan description is outdated. Should be investigated to ensure iteration boundaries are clear for future reviews.

## Suggested Fixes

**For Bounded-Safe Fixes:**

1. In each DS preview file, add this CSS class definition in the `<style>` section:
   ```css
   .preview-container {
     max-width: 480px;
     margin: 0 auto;
   }
   ```
   Then replace instances of `<div style="max-width: 480px" class="mx-auto">` with `<div class="preview-container">`.

2. Add structural comments to organize CSS sections in each preview file (see example in #2 above).

3. In `lib/memba/clubs/aggregates/club.ex`, near the top of the module:
   ```elixir
   @reserved_slugs ~w(test)
   ```
   Then change the validation line to:
   ```elixir
   |> validate_exclusion(:slug, @reserved_slugs, message: "is reserved")
   ```

**For Judgement-Worthy Items:**

These require product/architecture decisions, not immediate code changes. Document and discuss trade-offs with the team.

## Validation Notes

1. **Tests:** `dev check` passes with 82 scenarios, 493 steps, all green. Comprehensive coverage of club slug validation, subdomain routing, edge cases, permissions.

2. **DS Preview Self-Containment:** All 5 new preview files correctly use daisyUI CDN, define theme variables, avoid Tailwind utilities, include `@dsCard` headers, use relative asset paths. Renders should work in headless Chrome (per plan validation approach).

3. **CQRS/ES Patterns:** Club aggregate validation, command/event structure, projection updates, and read-model usage (SlugMap for uniqueness) all follow established patterns correctly.

4. **Missing Evidence:** The implementation of `ClubSite.club_from_subdomain/1` isn't in the diff, preventing verification of how smoke-test slug "test" is filtered at runtime. Tests prove it works, but the mechanism isn't visible.

5. **Acceptance Coverage:** New feature file `features/staff_club_slugs.feature` provides domain acceptance criteria for slug behavior. DS preview files have no executable behavior, so acceptance tests wouldn't apply to them.

---

**Recommendation:** Accept for merge. The bounded-safe fixes are minor polish that can be applied now or deferred. The judgement-worthy items are architectural questions that don't block this iteration but should be discussed for future consistency.