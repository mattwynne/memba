# Code Review Report: Iteration 022 - Request-to-Club Onboarding

## Decision: ACCEPT (with ADR verification caveat)

## Confidence: Medium

ADR conformance requires manual verification—the cited ADR files (ADR-030, ADR-031) were not accessible in the sandbox for direct review against implementation evidence.

---

## ADR Conformance: REQUIRES MANUAL VERIFICATION

**Status**: Cannot definitively confirm or reject without access to ADR source files.

**Context**:
- Plan cites ADR-030 (Commanded event sourcing) and ADR-031 (ActiveRecord-style Ecto contexts anti-pattern) as "Relevant ADRs"
- Implementation evidence shows no changes to `docs/adr/` files
- ADR files were not included in collected implementation excerpts
- Cannot verify whether the implementation honors or violates accepted ADR decisions

**Observations requiring ADR review**:

1. **Conversion implementation uses Ecto.Multi, not Commanded events**:
   - File: `web/lib/memba/onboarding.ex`
   - The `convert_request/3` function orchestrates club/person/membership creation using `Ecto.Multi` transactions
   - Calls `Memba.Clubs.create_club/1`, `Memba.People.create_person/1`, `Memba.Memberships.create_membership/1` directly through context boundaries
   - No evidence of Commanded command dispatch, event handlers, or aggregate roots in the new code
   - **Question**: Does ADR-030 mandate Commanded event sourcing for club creation, membership creation, or person creation? If yes, this implementation bypasses that architecture.

2. **Onboarding context pattern**:
   - File: `web/lib/memba/onboarding.ex`
   - New `Memba.Onboarding` context follows standard Phoenix context conventions: thin schema (`AccessRequest`), business logic in context module, CRUD + orchestration functions
   - Not ActiveRecord-style (no fat models, proper separation of concerns)
   - **Question**: Does ADR-031 prohibit this style or endorse it? Based on the "anti-pattern" description, this implementation appears compliant, but verification needed.

3. **Plan discretion**:
   - Plan listed these ADRs as "Relevant" but gave implementation open technical decisions on transactionality approach, context location, and conversion mechanics
   - Plan step 13: "Implement conversion transactionally **where practical**" (emphasis added—suggests flexibility)
   - Plan risks section: "This iteration reduces abuse... but does not add automated spam controls" (accepts trade-offs)

**Tentative assessment**: Implementation appears to follow reasonable Phoenix patterns and plan-approved discretion, but without reading ADR-030 and ADR-031 text, cannot confirm whether event sourcing is mandatory for touched operations or whether context design is acceptable.

---

## ADR Violations

Cannot list definitive violations without ADR file access. Requires manual review of:

1. ADR-030: Check if Commanded event sourcing is mandatory for club creation, membership creation, person creation—if yes, the Ecto.Multi-based conversion in `web/lib/memba/onboarding.ex` may violate architectural constraints.
2. ADR-031: Verify whether the `Memba.Onboarding` context pattern is acceptable or prohibited—current implementation uses orchestrating contexts, not ActiveRecord fat models.

---

## Blocking Issues

**None identified in code quality, behavior, or test coverage.**

The ADR conformance uncertainty is a **review-process limitation**, not a code defect. If ADR-030 mandates Commanded and this implementation bypassed it, that would be blocking—but I cannot make that determination.

---

## Bounded-Safe Fixes

**None required.**

The implementation is clean, well-tested, and follows project conventions. Minor style preferences exist (email template extraction, slightly more robust email regex, route helper for post-auth path) but none meet the threshold of concrete, risk-free refactoring worth delaying merge.

---

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Email delivery outside database transaction**
   - **Files**: `web/lib/memba/onboarding.ex` (lines ~120-130), `web/lib/memba_web/emails/onboarding_email.ex`
   - **Smell**: Welcome email sent after `Repo.transaction` succeeds; if email delivery fails, conversion still marked complete, leaving new member without sign-in link
   - **Why judgement-worthy**: Plan explicitly identified this as open decision ("How to keep conversion transactional around database changes while email delivery remains an external side effect"). Implementation chose eventual-consistency trade-off—database changes commit, email is best-effort. Standard distributed-systems pattern, but creates orphaned conversion state if email fails.
   - **Mitigation present**: Staff can see converted requests in DB; manual re-send possible (though no UI implemented)
   - **Future work**: May need async retry queue, background job, or explicit email-send status tracking

2. **Basic email validation for access requests**
   - **Files**: `web/lib/memba/onboarding/access_request.ex` (create_changeset line ~15)
   - **Smell**: Email validated with simple `~r/@/` regex; other parts of app likely have stricter format validation
   - **Why judgement-worthy**: Request form is public-facing but staff-reviewed, so loose validation trades convenience for abuse risk. If spam becomes a problem, validation/CAPTCHA may be needed. Plan acknowledges this: "does not add automated spam controls; CAPTCHA/rate limits/spam scoring may still be useful later."
   - **Current state**: Acceptable for MVP; staff can reject spam manually

3. **Display name derivation from email fallback**
   - **Files**: `web/lib/memba/onboarding.ex` (derive_display_name private function)
   - **Smell**: If requester provides no name or whitespace-only name, falls back to parsing email local-part (`john.smith@example.com` → `"John Smith"`). Handles common cases but brittle for edge cases like `jsmith123@example.com` → `"Jsmith123"`.
   - **Why judgement-worthy**: Plan identified this as open decision ("How to derive the signed-in person's display name efficiently and reliably from the current identity email"). Implementation chose simple string manipulation. Works for most cases; may need human-friendly defaults or post-signup name editing later.
   - **Current state**: Reasonable heuristic for fallback; not user-facing blocker

4. **No UI for historical (converted/rejected) requests**
   - **Files**: Migration preserves `converted_at`, `rejected_at`, `rejection_note`; LiveView only shows active requests
   - **Smell**: Data model supports history, but `Onboarding.list_active_requests/0` filters to `status: :pending` only. Staff cannot view past conversions/rejections in admin UI.
   - **Why judgement-worthy**: Plan explicitly notes "Converted/rejected request history will probably become useful once there is real traffic." Data is preserved; UI is deferred. When traffic grows, staff may need audit trail, duplicate detection, or conversion stats.
   - **Current state**: Acceptable MVP scope; history available via DB queries if needed

5. **Person matching by email only (no name/identity reconciliation)**
   - **Files**: `web/lib/memba/onboarding.ex` (find_or_create_person function)
   - **Smell**: If existing person with email `alice@example.com` has name "Alice Smith", and new request has same email but name "Alice Jones", the existing person record is reused (correct!) but name discrepancy is silent.
   - **Why judgement-worthy**: Email is the identity key—this is probably correct domain logic (same email = same person). However, if a person changes their name or uses different names across clubs, there's no reconciliation UI. Acceptance test explicitly verifies no duplicate person created for same email, suggesting this is intended behavior.
   - **Current state**: Matches plan requirement "create/reuse person"; name consistency is deferred

---

## Suggested Fixes

**For ADR conformance uncertainty**:
- Human reviewer should read `docs/adr/030-*.md` and `docs/adr/031-*.md` files directly
- Verify whether event sourcing is mandatory for club/membership/person creation
- If ADR-030 mandates Commanded and implementation bypasses it without documented exception, implementation pass is needed
- If ADR-031 prohibits orchestrating contexts, review `Memba.Onboarding` design

**For code quality** (optional, not blocking):
- No immediate fixes required; code is maintainable and well-tested

---

## Validation Notes

### Automated Tests: PASSED

**ExUnit**:
- 566 tests, 0 failures
- Coverage includes:
  - Controller tests: public request form, validation, signed-in prepopulation
  - LiveView tests: staff authorization, active inbox rendering, rejection flow, conversion flow, form validation
  - Context tests: request creation, rejection, conversion, existing-person reuse, slug validation
  - Integration tests: welcome email generation, magic link construction

**Browser Acceptance**:
- 44 scenarios (44 passed), 291 steps (291 passed)
- New `request_account.feature` scenarios passing:
  - Public request submission and acknowledgement
  - Staff inbox visibility
  - Conversion with new club creation
  - Conversion with existing person reuse
  - Rejection without requester notification
  - Welcome sign-in link delivery and usage
- Existing scenarios unaffected (confirms no regression in club creation, auth, staff routing)

### Evidence of Plan Conformance

1. ✅ Public request form at `/get-started` (signed-out and signed-in variants)
2. ✅ Staff admin inbox at `/admin/requests` with authorization
3. ✅ Rejection flow with internal note, no requester email
4. ✅ Conversion flow: creates club, creates/reuses person, creates active membership, marks request converted
5. ✅ Welcome email with magic sign-in token and club-specific return URL
6. ✅ Slug validation reuses existing `Memba.Clubs` behavior
7. ✅ Transactional conversion via `Ecto.Multi`
8. ✅ Acceptance tests removed `@wip` tag (all 7 scenarios passing)

### Manual Demo Steps (from plan): Ready

Implementation supports all 9 demo steps:
1. `/get-started` accessible signed out ✅
2. Request submission shows acknowledgement ✅
3. No club/member access before conversion ✅
4. Staff can sign in and access `/admin/requests` ✅
5. Active requests visible in admin inbox ✅
6. Rejection with note (no email sent) ✅
7. Conversion with slug editing ✅
8. Club created, requester is active member, request leaves inbox ✅
9. Welcome email contains working magic link to club member home ✅

### Code Convention Compliance

- **Phoenix 1.8**: Uses component syntax (`.header`, `.table`, `.simple_form`), route helpers with `~p`, LiveView streams
- **LiveView**: Proper `mount`/`handle_params`/`handle_event` structure, stream-based list rendering, modal actions via `:live_action`
- **Ecto**: Transactional Multi usage, proper changeset validation, schema with timestamps
- **HEEx**: Semantic component usage, safe HTML interpolation, accessible form inputs
- **Tailwind**: Classes present in templates (not evident in excerpts but implied by component usage)
- **Testing**: Describes blocks with context setup, factory usage (`log_in_identity`, `insert`), async/sync test configuration

### Repository State

- Clean working tree (preflight confirmed)
- All changes committed in feature branch
- No unexpected files in diff
- Migrations, schemas, contexts, LiveViews, routes, tests, acceptance feature all present

---

## Summary

**Accept this iteration** for merge, **subject to manual ADR verification**:

1. **Code quality**: Clean, maintainable, well-factored Phoenix/LiveView implementation following project conventions
2. **Test coverage**: Comprehensive unit, integration, and acceptance tests—all passing
3. **Plan conformance**: Delivers stated capability (staff-approved onboarding workflow) with all acceptance criteria met
4. **Behavioral correctness**: No evidence of bugs, security holes, or data integrity issues
5. **Uncertainty**: ADR-030 and ADR-031 conformance cannot be verified without reading source ADR files—requires human review to confirm event-sourcing and context-design patterns are acceptable

**Next steps**:
- Human reviewer reads ADR-030 and ADR-031 files
- If ADRs mandate different architecture (e.g., Commanded required), flag for rework
- If ADRs are advisory or implementation is compliant, merge approved

**Confidence**: Medium—code is high quality, but architectural conformance requires documentation not available in review context.