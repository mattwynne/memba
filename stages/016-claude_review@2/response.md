# Iteration Review Report

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The implementation demonstrates adherence to all architectural decisions stated in the plan:

- ✅ Invitation tokens use separate database-backed storage (not Phoenix.Token)
- ✅ Email normalization matches PersonEmailAddress conventions
- ✅ No incomplete person records created before profile completion
- ✅ Profile completion state lives in session/journey (via `put_session(:invitation_email, ...)`)
- ✅ Token not consumed on first link open for unknown invitees
- ✅ Existing person flow accepts invitation, creates membership, consumes token, and redirects

No ADR files were cited by number in the plan or included in implementation evidence, but the plan's explicit architectural decisions are fully implemented.

## ADR violations

None identified.

## Blocking issues

None remaining. The critical data migration issue identified in the first review has been properly resolved by the repair agent.

## Bounded-safe fixes

None required. The repair agent correctly identified that three of the four initially flagged issues were false positives:

1. ❌ **Empty AcceptInvitationPlug** - does not exist in the codebase
2. ❌ **Hardcoded club path** - code uses `ClubSite.url(club, "/")` and verified routes
3. ❌ **Unescaped HTML in email** - `EmailTemplates.invitation_html/2` explicitly calls `html_escape/1`

The fourth issue (data migration) was legitimately blocking and has been fixed.

## Judgement-worthy non-blocking code-health findings

### 1. Migration timestamp oddity (Severity: Low - cosmetic)

**Files**: `web/priv/repo/migrations/20250607031033_add_person_email_addresses_table.exs`, `web/priv/repo/migrations/20260602024629_backfill_membership_person_email_addresses.exs`

**Smell**: The backfill migration has a timestamp from June 2026 while the table creation is from June 2025. The backfill correctly runs *after* table creation (20260602 > 20250607 numerically), but the year gap suggests the test/dev environment clock is set to 2026.

**Why it may need human judgement**: Functionally correct but cosmetically odd. If this is deployed to production, migration timestamps from 2026 might confuse maintainers in 2025. Consider regenerating with current timestamps if cosmetic consistency matters.

---

### 2. Virtual email field without accessor helper (Severity: Low - DX)

**Files**: `web/lib/memba/accounts/person.ex`

**Smell**: `Person.email` is virtual; after loading from database, `person.email` is `nil`. Code must navigate `person.email_addresses |> Enum.find(&(&1.is_primary)) |> Map.get(:email)` to access email.

**Why it may need human judgement**: The implementation preloads associations in queries like `find_person_by_email/1`, which works. But ad-hoc code accessing a loaded person might be confused. Consider adding `Person.primary_email/1` helper or documenting the pattern explicitly if maintaining current structure.

---

### 3. Synchronous email delivery (Severity: Low - performance)

**Files**: `web/lib/memba/invitations.ex`

**Smell**: `Memba.Mailer.deliver(email)` is called synchronously during the Staff invitation HTTP request.

**Why it may need human judgement**: Couples UI latency and error handling to email provider response time. Acceptable for MVP with low invitation volume. Consider async job queue (Oban) if invitation volume or deliverability reliability becomes important.

---

### 4. Invitation token generation in projection handler (Severity: Low - architecture)

**Files**: `web/lib/memba/membership/projections/invitation.ex`

**Smell**: `InvitationToken.build_hashed_token()` is called in the projection `handle/2` function when handling `InvitationCreated` events, rather than being produced deterministically from the event data.

**Why it may need human judgement**: In event-sourced systems, projection rebuilds should be deterministic. Rebuilding projections would generate different token hashes, invalidating outstanding invitation links. Acceptable for MVP where:
- Invitations are one-use anyway
- Projection rebuilds should be rare
- Outstanding invitations can be manually reissued if needed

Document this trade-off explicitly if projection rebuild procedures are formalized.

---

### 5. No database constraint on pending invitation uniqueness (Severity: Low - data integrity)

**Files**: `web/lib/memba/invitations.ex`, invitations table migration

**Smell**: Duplicate detection happens in application code (`cond do pending_invitation = find_pending_invitation(...)`). No partial unique index exists for `(club_id, normalized_email)` where `status = 'pending'`.

**Why it may need human judgement**: Concurrent invites for the same email/club could create duplicate pending invitations and send duplicate emails. Impact is low:
- Worst case: duplicate emails sent
- Only one invitation is consumed on acceptance
- Manual cleanup possible

Adding a partial unique constraint would provide stronger guarantees but add migration complexity. Current approach is acceptable if duplicate emails are tolerable for MVP.

---

## Suggested fixes

None required. The implementation is production-ready after the repair pass.

## Validation notes

### Repair pass results:
- ✅ Added/improved `20260602024629_backfill_membership_person_email_addresses.exs` migration with:
  - Normalization and deduplication via `DISTINCT ON`
  - Skips blank/null emails
  - Checks for existing normalized emails (global uniqueness)
  - Checks for existing primary emails (per-person uniqueness)  
  - Preserves legacy row timestamps
  - Proper down migration
- ✅ Added test coverage for backfill edge cases in `person_email_address_projection_test.exs`
- ✅ Correctly identified three false positives from first review

### Test coverage:
- ✅ 722 ExUnit tests, 0 failures (increased from earlier evidence)
- ✅ 69 Cucumber scenarios, 466 steps, all passing
- ✅ Domain tests cover invitation lifecycle, duplicates, acceptance flows
- ✅ Controller tests cover profile completion, existing person flow, token validation
- ✅ LiveView tests cover Staff invitation UI
- ✅ Email delivery tests verify templates and recipients
- ✅ Migration backfill tests cover null/blank/duplicate handling

### Dev check:
- ✅ Compilation clean
- ✅ Formatter clean  
- ✅ All tests green
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

---

**Overall Assessment**: The repair pass successfully resolved the data migration concern, and the implementation is now production-ready. The false positives in the initial review suggest overly aggressive synthesis; the actual implementation had already addressed those concerns correctly (HTML escaping, route helpers). The remaining non-blocking findings are legitimate MVP trade-offs that don't warrant blocking merge. Accept and proceed to integration.