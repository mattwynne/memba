# Iteration 018 Implementation Review

## Decision: REJECT

## Confidence: High

## ADR Conformance: FAIL

---

## ADR Violations

1. **Plan decision contradiction (plan serves as iteration-level ADR)**
   - **Decision source**: Plan section "Open Technical Decisions → Decisions made during planning" states: "Signed-in non-members at the club subdomain root should see the public club page."
   - **Implementation evidence**: 
     - Test `signed-in non-member sees forbidden on club subdomain private URL` in `web/test/memba_web/controllers/page_controller_test.exs`:
       ```elixir
       conn = get(Map.put(conn, :host, host), "/")
       assert html_response(conn, 403)
       assert conn.resp_body =~ "Access denied"
       ```
     - Router in `web/lib/memba_web/router.ex` routes club subdomain `/` to `ClubLive.Dashboard` within `:club_member_authenticated` live_session, which enforces club membership.
   - **Violation**: The implementation returns 403 forbidden for signed-in non-members at the club subdomain root, directly contradicting the explicit planning decision that they should see the public club page.
   - **Impact**: Changes the product behavior model from "club subdomains show public pages to non-members" to "club subdomains are members-only private areas". This affects user experience and access control boundaries.

---

## Blocking Issues

1. **Plan decision violation requires product/architecture judgement**
   - The plan explicitly decided that signed-in non-members should see the public club page at the club subdomain root.
   - The implementation treats club subdomain root as a private member URL (403 for non-members).
   - While the implemented behavior (403) may be architecturally cleaner (club subdomains = member areas only, public pages = main host only), it contradicts a planning-phase decision.
   - **Resolution required**: Human review to either (a) accept the deviation and update the plan/tests, or (b) revise the implementation to show public club pages to non-members at subdomain root.
   - **Evidence of deliberate implementation choice**: Test naming (`signed-in non-member sees forbidden on club subdomain private URL`) and consistent 403 behavior across tests suggest this was an intentional implementation decision rather than an oversight.

2. **Missing test coverage for planned behavior**
   - Plan task 12 specifies: "Add targeted web tests covering: root public/member/non-member behaviour"
   - Implementation has tests for:
     - Public (signed-out): redirect to sign-in ✓
     - Member: show dashboard ✓
     - Non-member: **403 forbidden** (contradicts plan)
   - No test exists for "signed-in non-member at club subdomain root sees public club page" as specified in plan.

---

## Bounded-Safe Fixes

None. The code quality is high and follows project conventions. The blocking issue is architectural/product-level, not a refactoring opportunity.

---

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Router scope complexity without explanatory comments**
   - **Files**: `web/lib/memba_web/router.ex`
   - **Smell**: Multiple overlapping scopes with different `pipe_through`, `live_session`, and on_mount combinations create complex routing logic that may be difficult to maintain.
   - **Why judgement-worthy**: The routing is functional and tested, but the interaction between `require_club_host` plug, multiple scopes matching `/`, and different authentication/authorization hooks is subtle. Explanatory comments would improve maintainability. Consider whether this complexity is unavoidable or could be simplified with different abstractions.

2. **Per-request club lookup from subdomain**
   - **Files**: `web/lib/memba_web/club_urls.ex` (club_from_host/1), on_mount hooks (not visible in evidence but implied by test behavior)
   - **Smell**: Each request to a club subdomain appears to look up the club from the database via slug. While `RequireClubHost` plug only does string checks, the on_mount hooks likely call `club_from_host/1` which queries `Memba.Clubs.get_club_by_slug(slug)`.
   - **Why judgement-worthy**: This is standard Phoenix practice and acceptable for moderate traffic. However, if club lookups become a performance bottleneck under high load, consider caching strategies (ETS, process dictionary, or conn assigns from plug). Not blocking because tests pass and dev check succeeds.

3. **Hardcoded domain configuration**
   - **Files**: `web/lib/memba_web/club_urls.ex`
   - **Smell**: Club domains are module attributes (`@local_club_domain`, `@production_club_domain`) rather than runtime configuration.
   - **Why judgement-worthy**: This is pragmatic and works for the current deployment model (local dev + single production environment). However, if multiple production environments (staging, preview deploys, etc.) need different club domains, this will require refactoring. Consider whether runtime config (Application.get_env) would be more flexible without adding complexity.

---

## Suggested Fixes

**To unblock merge, one of the following is required:**

### Option A: Revise implementation to match plan (requires human approval for scope change)
1. Modify club subdomain root routing to show public club page for signed-in non-members:
   - Add conditional logic in `ClubLive.Dashboard` or router to redirect non-members to public page
   - OR create a separate route/LiveView for club subdomain root that dispatches based on membership
2. Update test `signed-in non-member sees forbidden on club subdomain private URL` to expect public page instead of 403
3. Add test for non-member seeing public page at subdomain root

### Option B: Accept deviation and update plan (requires human approval)
1. Update plan's "Decisions made during planning" section to state: "Signed-in non-members at the club subdomain root see forbidden/access denied (club subdomains are members-only areas)."
2. Update plan task 12 test requirement to: "root public/member behaviour" (remove "non-member")
3. Document decision rationale: club subdomains = private member areas; public pages = main host only
4. Keep existing tests unchanged

**Recommendation**: Option B (accept deviation) appears more architecturally coherent. Club subdomains as members-only areas is a cleaner boundary than mixing public/private content on the same host. However, this requires explicit product/architecture approval since it changes the planned user experience.

---

## Validation Notes

### Successful validations:
- ✅ dev check passed (396 tests, 0 failures)
- ✅ ADR 0019 compliance: uses `lvh.me` for local subdomain wildcard loopback
- ✅ Club URL generation helpers tested comprehensively
- ✅ Host-based club detection implemented and tested
- ✅ Auth return-to preserves subdomain URLs correctly
- ✅ Legacy `club_id` fallback still functional
- ✅ Main host routing preserved (landing page, member index, admin routes)
- ✅ Unknown subdomain returns 404
- ✅ Cucumber feature correctly tagged `@wip`
- ✅ Code follows Phoenix/LiveView/Elixir conventions
- ✅ Clean working tree before review (preflight_sandbox passed)

### Gap requiring validation:
- ❌ Signed-in non-member behavior at club subdomain root does not match plan specification

### Manual validation recommendation:
After resolving the blocking issue, manually verify the chosen behavior:
- Sign in as member of club A
- Access club B subdomain root
- Confirm either: (a) public club page shown, or (b) 403 forbidden with explicit product approval