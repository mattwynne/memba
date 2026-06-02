# Iteration 016 Review Report

## Decision: ACCEPT

## Confidence: High

## ADR Conformance: PASS

### ADR Violations
None. The implementation correctly follows ADR-004 (Email Addresses Normalization and Lookups):

- ✓ Both `email` and `normalized_email` columns present in schema and migration
- ✓ Normalization uses `String.trim() |> String.downcase()` via `EmailAddresses.normalize_email/1`
- ✓ All lookups use `normalized_email` (accounts, membership queries, projector)
- ✓ Global uniqueness constraint on `normalized_email` enforced at database level
- ✓ Display and delivery use original `email` form
- ✓ Migration backfill uses `LOWER(TRIM(email))` which is functionally equivalent to app-level normalization for email addresses

## Blocking Issues
None.

## Bounded-Safe Fixes
None required. The implementation is clean and maintainable as-delivered.

## Judgement-Worthy Non-Blocking Code-Health Findings
None. The implementation represents deliberate, well-documented design trade-offs:

- Denormalization of `membership_people.email` is an explicit plan decision with projector-enforced consistency
- Form validation vs. aggregate validation separation follows standard Phoenix/DDD patterns
- Dynamic email address list management uses a pragmatic approach appropriate for current scope

## Validation Notes

**Plan Conformance:**
- All 18 implementation steps completed per plan
- Routes moved to dedicated `/admin/clubs/:club_id/people/new` and `/admin/clubs/:club_id/people/:person_id/edit` paths
- Atomic replace-all command/event pattern (`ReplacePersonEmailAddresses`/`PersonEmailAddressesReplaced`)
- Legacy `PersonCreated` event handling creates primary email address row
- Migration includes backfill of existing people

**Test Coverage (336 tests, 0 failures):**
- Aggregate validation: at-least-one, exactly-one-primary, format, duplicates
- Projection: replace-all, primary update, constraint enforcement
- Queries: alternate email lookup, normalization before lookup
- Accounts: alternate email sign-in, magic link delivery to requested address
- Messaging: primary address resolution, once-per-person delivery
- LiveView: form validation, add/remove addresses, primary selection
- Migration: table structure, constraints, backfill

**Database Constraints:**
- Global unique index on `normalized_email` ✓
- Partial unique index `(person_id) WHERE is_primary = true` ✓
- Non-null constraints on required columns ✓
- Verified via migration tests

**Event Sourcing Patterns:**
- Command handlers in aggregate with proper validation guards
- Event application to aggregate state maintains denormalized `email` field
- Projector uses `Ecto.Multi` for atomic operations
- Legacy event replay handled explicitly in projector

**Integration Points:**
- Accounts sign-in flow queries `PersonEmailAddress` by normalized_email ✓
- Messaging recipient resolution uses primary email ✓
- Staff `@memba.io` sign-in unchanged ✓
- Test helpers maintain backward compatibility ✓

**Code Quality Signals:**
- Clear separation: EmailAddresses context, projection, aggregate, queries
- Consistent error handling via `:ok`/`{:error, reason}` tuples
- Email address display ordering: primary first, then by `inserted_at`
- Phoenix/LiveView conventions followed throughout
- Ecto changeset validations at projection layer
- Aggregate-level validation as authoritative guard

The implementation is production-ready with comprehensive automated coverage, correct ADR adherence, and clean separation of concerns. The deliberate trade-offs (denormalized primary email, form validation duplication) are appropriate for this iteration's scope and well-documented in the plan.