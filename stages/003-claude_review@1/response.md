Now I'll conduct a thorough readiness review of this iteration plan.

---

# Iteration Plan Readiness Review: 042 - Club email subdomains

## Decision: READY

## Confidence: High

## Blocking Gaps

None.

## Non-blocking Improvements

1. **Background timing**: The plan mentions "Iteration 041 is in progress" (line 26) but the README shows iteration 041 as "merged" on 2026-06-19, and this is iteration 042 on 2026-06-21. This status inconsistency is historical context only and doesn't affect the plan's readiness—the integration risk is properly documented in Risks/Follow-ups.

2. **Smoke test ordering**: Step 14 says "After Matt confirms Postmark/DNS are configured for `*.clubs.memba.io`, run the production inbound smoke test and record/report the result." This could more clearly state whether this is a validation step that must pass before the iteration is considered complete, or an optional post-deployment verification. However, the Acceptance Criteria line 127 ("After Matt applies the Postmark/DNS prerequisite, the production inbound smoke test passes") makes it clear this is required.

## Smallest Viable Iteration

The plan is already appropriately scoped as the smallest viable iteration. It:
- Changes only the address convention (one coherent change)
- Supports only `everyone@` (deliberately minimal)
- Defers channels, aliases, and backwards compatibility
- Hard-cuts over rather than maintaining dual paths

Any smaller scope (e.g., add new addresses but keep old ones working) would reduce value without reducing complexity, as the code would need to handle both conventions. The hard cutover is the simplest viable approach given the pre-launch state.

## Required Plan Edits

None. The plan is ready for implementation as written.

## Validation Plan

The plan includes a comprehensive validation strategy (lines 175-189):

**Unit/domain level:**
- Address generation tests (`kmc` → `everyone@kmc.clubs.memba.io`)
- Destination resolution tests (accepts valid, rejects unsupported local parts, unknown subdomains, old flat addresses)

**Integration level:**
- Existing inbound email acceptance scenarios rerun under new address shape
- Reply-by-email tests from iteration 041 rerun with new destination
- Member UI tests verify displayed addresses and mailto links

**Documentation:**
- Review Postmark/DNS setup instructions

**Production:**
- Smoke tests updated and run after prerequisite DNS/Postmark configuration
- Full `dev check` passes

**Success proof:**
1. All scenarios in `member_message_deliverability.feature` and `club_message_replies.feature` pass with `@iteration-042` tags removed
2. Production smoke test passes against `everyone@test.clubs.memba.io`
3. Member dashboard and compose pages display the new address format
4. Inbound email to the new format creates messages; old format is rejected
5. Reply-by-email preserves conversation threading while using new address

**Stop condition:** `dev check` passes with all `@todo-domain @todo-ui` tags removed from iteration-042 scenarios, production smoke test passes, and the old flat address format is rejected.

---

## Detailed Review Against Readiness Questions

### 1. Goal Clarity ✅

**Is the goal clearly articulated?**
Yes. Lines 6-22 state the outcome precisely: move from `<club-slug>@clubs.memba.io` to `everyone@<club-slug>.clubs.memba.io` with a concrete example.

**Does it state the user/business outcome, not just tasks?**
Yes. The goal focuses on what members will do differently ("members email a club-wide message to...") rather than implementation mechanics.

**Is the intended beneficiary clear?**
Yes. Members are the beneficiaries—they get a clearer, more scalable email address namespace that enables future channels/groups.

### 2. Scope Focus ✅

**Is the scope focused on one coherent outcome?**
Yes. The entire iteration is about changing the inbound club email address convention and rejection policy. All in-scope items (lines 44-58) directly support this single outcome.

**Could the iteration be any smaller while still useful?**
No. The hard cutover approach is already the minimal viable change:
- Must update address generation, parsing, resolution, and rejection together
- Must update UI display consistently
- Must update documentation and smoke tests to match
- Supporting both old and new addresses would be more complex, not less

**Are non-goals and boundaries clear?**
Excellent. Lines 60-71 explicitly exclude channels, aliases, compatibility modes, custom domains, DNS mutations, staff UI for rejections, and changes to reply-routing policy. Each exclusion is justified.

### 3. Acceptance Criteria, BDD Decision, and Business Decisions ✅

**Are acceptance criteria concrete, clear, complete, and objectively testable?**
Yes. Lines 112-128 provide 18 specific, testable criteria covering:
- Display on dashboard and compose (lines 113-114)
- Club resolution (line 115)
- Accepted paths for primary and alternate addresses (lines 116-117)
- Rejection of unsupported local parts, unknown subdomains, old flat address (lines 119-121)
- Reply destination and routing preservation (lines 122-123)
- Safe rejection semantics (line 124)
- Documentation and smoke tests (lines 125-127)
- dev check passing (line 128)

**Do they cover happy paths, edge cases, permissions, errors, and state changes?**
Yes:
- Happy: `everyone@kmc.clubs.memba.io` creates message (line 116)
- Alt sender: alternate email addresses work (line 117)
- Unsupported routes: `committee@kmc.clubs.memba.io` rejected (line 119)
- Unknown clubs: `everyone@unknown.clubs.memba.io` rejected (line 120)
- Old format: `kmc@clubs.memba.io` rejected (line 121)
- Authorization: preserves existing safe rejection (line 124)
- Integration: reply routing preserved (lines 122-123)

**Does the plan classify iteration type and include BDD scenarios?**
Yes. Lines 72-76 classify this as "Behaviour-facing" with clear justification. Lines 78-93 document the BDD decision as "Required" and specify exactly which feature files are updated (`member_message_deliverability.feature` and `club_message_replies.feature`) with concrete examples of what scenarios were added during planning.

**Are business/product decisions resolved?**
Yes. Lines 130-141 explicitly state "None known" and list all confirmed decisions:
- Use `clubs.memba.io` namespace (not root `memba.io`)
- Hard cutover (no backwards compatibility)
- Support only `everyone` route in this slice
- Matt performs external setup

### 4. Implementation Plan and Technical Decisions ✅

**Are implementation steps clear, ordered, and specific?**
Yes. Lines 142-158 provide 14 sequenced steps from inspection through smoke test execution. Each step is actionable.

**Are files, modules, and integration points named?**
Where useful, yes:
- Feature files: `member_message_deliverability.feature`, `club_message_replies.feature` (lines 86, 89)
- Documentation: `docs/postmark-email.md` (line 154)
- Smoke tests: `smoke-tests/lib/config.js`, `smoke-tests/README.md` (line 155)
- Integration points: Postmark/Resend inbound parsers, member dashboard/compose, reply email generation (line 144)

**Are data model, API, UI, workflow changes clear?**
Yes:
- Data model: no schema changes; uses existing club slug lookup (line 148)
- API: inbound webhook parsing changes to extract subdomain (line 146)
- UI: member dashboard and compose display updated (lines 113-114, 150)
- Workflow: destination resolution algorithm detailed (lines 146-149)

**Are technical decisions resolved?**
Yes. Lines 159-168 state "None that require product decisions" and enumerate implementation choices left to the implementer with clear constraints (environment config, rejection atoms, normalization, 041 integration).

### 5. Expected Capability and Validation ✅

**What can we do after this that we cannot do now?**
Lines 171-172 state this clearly: "Memba has a clearer club email namespace: each club owns a subdomain under `clubs.memba.io`, and the first route on that subdomain is `everyone`." This enables future channels/routes without subdomain conflicts.

**How will we prove success?**
Lines 175-189 detail comprehensive validation from unit tests through production smoke tests. See "Validation Plan" section above.

**Is there a clear stop condition?**
Yes: `dev check` passes, all iteration-042 scenarios are executable (no `@todo-domain @todo-ui` tags remain), and production smoke test passes against the new address (lines 127-128, 188-189).

---

## Summary

This iteration plan demonstrates exceptional readiness:

1. **Goal**: Crystal clear with concrete before/after examples
2. **Scope**: Minimal viable change with well-justified exclusions
3. **Acceptance**: 18 testable criteria covering all critical paths; BDD scenarios added during planning with explicit feature file references; all business decisions resolved
4. **Implementation**: 14 ordered steps with named files and integration points; technical choices appropriately delegated to implementer
5. **Validation**: Comprehensive strategy from unit to production with clear stop condition

The plan is self-contained, implementation-ready, and includes appropriate risk mitigation for external prerequisites (Postmark/DNS) and in-progress dependency (iteration 041).

---

```json
{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}
```