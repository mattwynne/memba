# Iteration Review Report

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The plan did not cite specific ADR numbers. The implementation adheres to all architectural decisions stated in the plan:

- ✅ Invitation tokens use separate database-backed storage via `InvitationToken` module
- ✅ Email normalization follows `PersonEmailAddress` conventions  
- ✅ No incomplete person records created before profile completion
- ✅ Profile completion state managed via session (`put_session(:invitation_email, ...)`)
- ✅ Token not consumed on first link open for unknown invitees
- ✅ Existing person flow: accept → create membership → consume token → sign in → redirect to club

No ADR files are referenced in the plan or visible in the implementation evidence that would govern this domain.

## ADR violations

None identified.

## Blocking issues

None.

**Note on pipeline state**: The synthesis stage is incorrectly flagging a workflow blocker (`make-gemini-review-visible`) due to a failed Gemini review stage. This is a pipeline/toolchain issue, not an implementation defect. Both Claude and Codex reviews consistently ACCEPT across multiple passes with no code blockers identified. The repair agent correctly diagnosed this as a workflow visibility problem rather than a code quality issue.

## Bounded-safe fixes

None required. The implementation is production-ready.

## Judgement-worthy non-blocking code-health findings

### 1. Migration timestamp anomaly (Severity: Low - cosmetic)

**Files**: `web/priv/repo/migrations/20250607031033_add_person_email_addresses_table.exs`, `web/priv/repo/migrations/20260602024629_backfill_membership_person_email_addresses.exs`

**Smell**: Backfill migration timestamp is dated June 2026 while table creation is June 2025. Numerically correct order but year gap suggests dev/test clock set to 2026.

**Why it may need human judgement**: Functionally correct but may confuse maintainers if deployed with future-dated timestamps. Consider regenerating with current dates if cosmetic consistency matters for production deployment.

---

### 2. Virtual email field access pattern (Severity: Low - DX)

**Files**: `web/lib/memba/accounts/person.ex`

**Smell**: `Person.email` is virtual; loaded records have `person.email == nil`. Code must navigate `person.email_addresses |> Enum.find(&(&1.is_primary)) |> Map.get(:email)`.

**Why it may need human judgement**: Pattern works where associations are preloaded (as in current queries), but ad-hoc code accessing loaded persons may be confused. Consider adding `Person.primary_email/1` helper or explicit documentation if maintaining current structure.

---

### 3. Synchronous email delivery (Severity: Low - performance)

**Files**: `web/lib/memba/invitations.ex`

**Smell**: `Memba.Mailer.deliver(email)` called synchronously during Staff invitation HTTP request.

**Why it may need human judgement**: Couples UI latency and error handling to mail provider response time. Acceptable for MVP with low Staff invitation volume. Consider async job queue (e.g., Oban) if invitation volume or deliverability reliability becomes critical.

---

### 4. Invitation token generation in projection (Severity: Low - architecture)

**Files**: `web/lib/memba/membership/projections/invitation.ex`

**Smell**: `InvitationToken.build_hashed_token()` called in projection handler rather than produced deterministically from event data.

**Why it may need human judgement**: Event-sourced projection rebuilds are ideally deterministic. Rebuilding would generate different token hashes, invalidating outstanding links. Acceptable for MVP where:
- Invitations are one-use
- Projection rebuilds rare
- Outstanding invitations can be manually reissued

Document this trade-off if projection rebuild procedures become operationally important.

---

### 5. Pending invitation uniqueness (Severity: Low - data integrity)

**Files**: `web/lib/memba/invitations.ex`, invitations table migration

**Smell**: Duplicate detection via application code (`cond do pending_invitation = find_pending_invitation(...)`). No partial unique index on `(club_id, normalized_email)` where `status = 'pending'`.

**Why it may need human judgement**: Concurrent Staff invites for same email/club could create duplicate pending invitations and duplicate emails. Impact low:
- Worst case: duplicate emails sent
- Only one consumed on acceptance  
- Manual cleanup possible

Adding partial unique constraint would provide stronger guarantees but add migration complexity. Current approach acceptable if duplicate emails tolerable for MVP.

---

## Suggested fixes

None required for merge. Implementation is production-ready.

Optional follow-ups:
- Regenerate migration timestamps if future dates problematic for production
- Add `Person.primary_email/1` helper for clearer email access
- Consider async/durable email delivery if usage scales
- Document projection-time token generation trade-off before operationalizing rebuilds
- Consider partial unique index if duplicate pending invites become operationally problematic

## Validation notes

### Test coverage:
- ✅ ExUnit: `722 tests, 0 failures` (multiple passes)
- ✅ Acceptance: `69 scenarios`, `466 steps`, all passing
- ✅ Domain tests cover invitation lifecycle, duplicates, acceptance flows
- ✅ Controller tests cover profile completion, existing person flow, token validation  
- ✅ LiveView tests cover Staff invitation UI
- ✅ Email delivery tests verify templates and recipients
- ✅ Migration backfill tests cover null/blank/duplicate handling

### Dev check:
- ✅ Compilation clean across multiple runs
- ✅ Formatter clean
- ✅ All tests green in multiple passes
- ✅ Sandbox runtime check passed

### Plan conformance:
- ✅ All 16 numbered implementation steps delivered
- ✅ Invitation aggregate with pending/accepted/expired states
- ✅ Separate invitation token storage  
- ✅ Staff invite route under `/admin/clubs/:club_id/invite`
- ✅ Invitation callback with token validation
- ✅ Profile completion for unknown invitees
- ✅ Existing staff onboarding preserved
- ✅ Acceptance feature scenarios implemented and passing

### Consistency check:
Both Claude and Codex reviewers independently reached identical ACCEPT decisions across multiple review passes (stages 8-15, 17-22), with consistent identification of the same five non-blocking findings. The repair agent correctly diagnosed the pipeline gate issue as a workflow artifact visibility problem rather than an implementation defect.

---

**Overall Assessment**: The implementation is complete, well-tested, and production-ready. The pipeline is blocked by a workflow issue (missing Gemini review artifact), not by code quality concerns. The five identified findings are legitimate low-severity observations about MVP trade-offs that should not block merge. Accept and proceed to integration.