Now I'll review the plan against the five readiness questions.

## Iteration Plan Review: 053-my-settings-email-addresses

**Decision:** READY

**Confidence:** High

### Blocking gaps

None.

### Non-blocking improvements

1. **Token expiry specification:** Step 5 mentions "expire on a short TTL aligned with sign-in links unless implementation finds an existing project constant to reuse." While this is pragmatic and allows implementation flexibility, consider stating an explicit initial TTL value (e.g., "24 hours") so reviewers and future maintainers know the intended security boundary without cross-referencing sign-in token behavior.

2. **Migration guidance:** Step 2 says "with all existing rows backfilled as verified" but doesn't specify whether this is a data migration script or handled within the migration itself. Consider clarifying whether this is `ALTER TABLE ... UPDATE` or a separate backfill task.

3. **Non-primary definition clarity in AC:** Acceptance criteria repeat "non-primary address" several times but never explicitly state that every Person must have exactly one primary address at all times (though Technical Decisions does). Consider adding one explicit AC like: "Every Person always has exactly one primary email address."

### Smallest viable iteration

The plan is already well-scoped. A smaller slice would be:

**Option A (verification-only):** Just add verification state and verification flow without the full `/my/settings` UI—member adds via existing staff surface, verification email is sent, verification proves mailbox control. But this would leave the "member-facing management" goal undelivered.

**Option B (read-only settings first):** Build `/my/settings` with Profile/Clubs/Emails display but defer add/resend/remove/make-primary actions to a follow-up. But this would leave verification incomplete and the member "safely manage their own email addresses" goal undelivered.

Neither is clearly better than the current plan. The plan is already minimal for the stated goal: a member can open settings and manage verified/pending email addresses safely. Splitting would create incomplete capability without meaningful risk reduction.

**Recommendation:** Ship as planned.

### Required plan edits

None. The plan is implementation-ready.

### Analysis by Readiness Question

#### 1. Goal clarity ✓

- **Goal articulated:** Yes—"members can review their profile basics and manage their own email addresses safely."
- **User/business outcome:** Clear—member self-service reduces support burden, verification proves mailbox control before allowing identity/delivery use.
- **Beneficiary clear:** Signed-in club members (resolves to Membership Person).
- **Deliverable capability list:** Lines 10-19 enumerate exactly what a member can do after this iteration.

#### 2. Scope focus ✓

- **One coherent outcome:** Yes—member email-address management with verification.
- **Could it be smaller:** Not meaningfully (see "Smallest viable iteration" above). The plan explicitly defers rate limiting, rich rejection UX, name/profile changes, and shared email addresses.
- **Non-goals clear:** Lines 65-74 enumerate 8 explicit out-of-scope items.
- **Boundaries clear:** In-scope section (lines 38-63) is concrete and comprehensive.

#### 3. Acceptance criteria, BDD scenario decision, and business decisions ✓

- **AC concrete and testable:** Lines 146-171 provide 26 acceptance criteria covering happy paths (add/verify/make-primary), edge cases (duplicate addresses, removed pending address cannot verify), permissions (primary cannot be removed), error states (expired verification link), and state changes (verification updates open LiveView).
- **Coverage complete:** AC addresses primary restrictions, pending restrictions, verification success/failure, removal rules, sign-in-as-verification, inbound rejection, session preservation, and LiveView live refresh.
- **Iteration classified:** Line 77 explicitly states "Behaviour-facing."
- **BDD decision:** Lines 88-110 provide detailed rationale—"required" because the iteration changes member-visible identity and email-address policy—and names the specific feature file (`acceptance-tests/features/person_email_addresses.feature`) plus 9 scenario summaries with tagging strategy (`@iteration-053 @todo-domain @todo-ui`).
- **Business decisions unresolved:** Line 175 states "None known."

#### 4. Implementation plan and technical decisions ✓

- **Steps clear and ordered:** Lines 179-196 provide 17 specific implementation steps in logical dependency order (inspect → model verification → commands/events → staff compatibility → tokens → email → callbacks → sign-in update → inbound rejection → LiveView → UI → tests → acceptance → `dev check`).
- **Files/modules named:** 
  - `Layouts.club_site/1` and club-site-identity-menu (line 120)
  - `design-system/templates/account-settings.html` (line 116)
  - `acceptance-tests/features/person_email_addresses.feature` (line 94)
  - `auth_sign_in_tokens` (line 185)
  - `Memba.ReadModelChanges` (line 203)
  - `app_shell_css_test.exs` (line 189)
- **Data model changes clear:** Add verification state to Person email-address read model/projection, add dedicated verification-token table (lines 180-181, 185-186, 198-199).
- **API/UI/workflow clear:** Lines 123-137 detail the UI layout (three tabs, email row structure, badges, actions). Lines 10-19 enumerate the complete user workflow.
- **Integration points clear:** PubSub notification via `Memba.ReadModelChanges` (line 203), sign-in callback handling (line 187), inbound email sender resolution (line 189).
- **Technical decisions unresolved:** Lines 198-204 document four resolved technical decisions (verification-token storage, command/event shape, invariant enforcement, sign-in-as-verification, PubSub refresh). No unresolved decisions stated.

#### 5. Expected capability and validation ✓

- **What we can do after:** Lines 205-207 state the new capability—"Members can manage their own verified email addresses from a global personal settings page" and "distinguish verified and pending Person email addresses."
- **How to prove success:** Lines 209-243 provide comprehensive validation:
  - `dev check` must pass
  - 10 domain/context test scenarios
  - 7 LiveView/controller test scenarios
  - Acceptance test implementation with specific feature file
  - 10-step manual demo script
- **Stop condition clear:** All acceptance criteria pass, `dev check` passes, and manual demo completes successfully.

### Validation Plan

After implementation is complete:

1. **`dev check` passes** on the exact committed state
2. **Domain tests confirm:**
   - Backfilled rows are verified
   - New addresses start pending
   - Pending cannot become primary
   - Verified non-primary can become primary
   - Primary cannot be removed
   - Duplicate address rejection
   - Sign-in verifies pending address
   - Inbound rejects pending address
3. **LiveView tests confirm:**
   - Avatar menu structure (Account settings, divider, Sign out)
   - `/my/settings` renders correctly
   - Tab selection is URL-addressable and restorable
   - Add/resend/remove/make-primary flows work
   - Verification success/invalid pages show correct copy
   - Live refresh on verification PubSub
4. **Acceptance tests:** All `@iteration-053` scenarios in `person_email_addresses.feature` pass with `@todo-domain @todo-ui` tags removed or narrowed
5. **Manual demo:** Complete the 10-step demo script (lines 233-243) in a staging environment

Success is achieved when all tests pass, `dev check` is green, and the manual demo script executes without error or unexpected behavior.

---

```json
{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}
```