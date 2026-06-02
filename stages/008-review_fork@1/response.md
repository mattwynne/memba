# Iteration Implementation Review

**Decision:** ACCEPT  
**Confidence:** High  
**ADR conformance:** PASS

## Summary

The implementation correctly realizes iteration 016's multi-email-address capability with solid event-sourcing patterns, comprehensive test coverage (371 tests, 0 failures), and clean integration across Membership, Auth, Messaging, and staff UI layers. The code follows established Commanded/CQRS conventions, uses database constraints appropriately, and handles legacy event replay correctly.

Minor normalization inconsistency and several judgement-worthy concerns (race-condition UX, deployment backfill strategy, constraint test visibility) exist but don't block merge.

---

## ADR Violations

None identified. No specific ADRs were cited in the plan or visible in the evidence. The implementation follows standard event-sourcing patterns correctly:

- Commands validate before emitting events ✓
- Events are immutable and versioned ✓  
- Projectors handle both new and legacy event shapes ✓
- Aggregates enforce business rules; projectors materialize state ✓
- Database constraints provide final safety net ✓

---

## Blocking Issues

None.

The implementation passed the plan-conformance gate, has comprehensive automated coverage, correctly handles edge cases (legacy replay, primary-email denormalization, alternate-address sign-in), and uses appropriate database constraints for data integrity.

---

## Bounded-Safe Fixes

1. **Normalization single source of truth**  
   **Files:** `web/lib/memba/membership/email_addresses.ex`, `web/lib/memba/accounts/auth.ex`  
   **Issue:** `EmailAddresses.normalize_email/1` only does `String.downcase`, while `Auth.request_sign_in_link/1` does `String.downcase(String.trim(email))` before calling membership queries. This creates redundant normalization and fragility if callers forget to trim.  
   **Fix:** Make `normalize_email/1` do both trim and downcase:
   ```elixir
   def normalize_email(email) when is_binary(email) do
     normalized = email |> String.trim() |> String.downcase()
     {:ok, %{original: email, normalized_email: normalized}}
   end
   ```
   Update Auth to call `normalize_email` once instead of doing its own trim+downcase. This makes normalization logic canonical in one place.

---

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Race-condition UX on duplicate emails**  
   **File:** `web/lib/memba/membership/aggregates/person.ex` (`validate_global_uniqueness/2`)  
   **Smell:** The aggregate validates email uniqueness by querying the projection, but there's a TOCTOU race: two concurrent `ReplacePersonEmailAddresses` commands could both see an email as available, then one fails during projection with a database constraint violation. The database constraint prevents data corruption (good), but the user gets a generic error instead of "email already taken".  
   **Why judgement:** This is a known pattern in event-sourced systems. The safety net works correctly. However, the UX could be poor on concurrent duplicate attempts. Human decision needed on whether to add projector error surfacing, retry logic, or accept the rare poor-UX case.

2. **Data backfill strategy not explicit in code**  
   **Files:** `web/priv/repo/migrations/20250129040000_create_membership_person_email_addresses.exs`, `web/lib/memba/membership/projectors/person.ex`  
   **Smell:** The migration creates `membership_person_email_addresses` but has no data migration to backfill rows for existing people. The projector handles legacy `PersonCreated` events correctly, implying event-store replay will backfill. However, there's no explicit replay task, backfill script, or deployment note in the code.  
   **Why judgement:** The plan says "handle replay deliberately" and the implementation does. But if existing production people exist and the event store isn't replayed, they become un-lookupable by email until replay or edit. Needs human confirmation that operational replay procedure exists or that no production data exists yet.

3. **Database constraint test coverage visibility**  
   **Files:** Test files (not all visible in excerpts)  
   **Smell:** Dev check passed with 371 tests, and the plan validation section says "Run migration/persistence tests for email-address rows, uniqueness, and one-primary constraints." However, the test excerpts don't show explicit database-level tests that:
   - Insert two `PersonEmailAddress` rows with the same `normalized_email` → unique constraint violation
   - Insert two primary email addresses for the same person → one-primary constraint violation
   - Delete a person → cascading delete of email addresses  
   
   These may exist and pass (dev check succeeded), but aren't shown in the excerpts.  
   **Why judgement:** If constraint tests exist only at aggregate/domain level (command validation) but not at Repo/migration level, a future refactoring could accidentally remove the database constraints without breaking domain tests. Human review of full test suite recommended to confirm explicit constraint coverage.

4. **Module documentation for domain API**  
   **Files:** `web/lib/memba/membership/commands/replace_person_email_addresses.ex`, `web/lib/memba/membership/email_addresses.ex`, others  
   **Smell:** Several domain modules lack `@moduledoc`. The code is clean and well-named (self-documenting style), but command/event modules define the domain's public API and would benefit from docstrings explaining intent, usage, and versioning.  
   **Why judgement:** Not a functional defect. Consistent with codebase style (minimal comments). But commands/events are part of the permanent event-sourced history and deserve explicit documentation. Human decision on whether to enforce docstring standards for domain modules.

5. **Fixture backward-compatibility surface area**  
   **File:** `web/test/support/fixtures/membership_fixtures.ex`  
   **Smell:** `membership_person_fixture/1` maintains backward compatibility by accepting either `:email` or `:email_addresses`, defaulting to creating a single primary email address from `:email`. This is good for migration but increases fixture complexity. Over time, as tests migrate to `:email_addresses` style, the old `:email` path becomes dead code.  
   **Why judgement:** Technical debt in test fixtures. Not urgent, but consider deprecating the old style in a future cleanup iteration. Human decision on when to remove backward compatibility once tests have migrated.

---

## Suggested Fixes

**If bounded-safe fix is accepted:**

Apply the normalization single-source-of-truth refactoring:

1. Update `web/lib/memba/membership/email_addresses.ex`:
   ```elixir
   def normalize_email(email) when is_binary(email) do
     normalized = email |> String.trim() |> String.downcase()
     {:ok, %{original: email, normalized_email: normalized}}
   end
   ```

2. Update `web/lib/memba/accounts/auth.ex` in `request_sign_in_link/1`:
   ```elixir
   def request_sign_in_link(email) when is_binary(email) do
     # Remove: email = String.downcase(String.trim(email))
     # normalize_email now does both trim and downcase
     
     cond do
       staff_email?(email) ->
         # ...
       
       person = Membership.person_by_email(email) ->
         # person_by_email now calls normalize_email which trims+lowercases
         # Email.magic_link still needs the normalized form
         {:ok, %{normalized_email: normalized_email}} = 
           Memba.Membership.EmailAddresses.normalize_email(email)
         
         with {:ok, link} <- generate_sign_in_link(person.person_id) do
           Email.magic_link(normalized_email, link)
           |> Mailer.deliver()
         end
       
       true ->
         # unknown email case
     end
   end
   ```

3. Run targeted Auth and Membership tests to confirm behavior unchanged:
   ```bash
   cd web && mix test test/memba/accounts/ test/memba/membership/
   ```

**If no fixes applied (ACCEPT as-is):**

No code changes needed. The implementation is production-ready with the understanding that:
- Normalization works correctly despite redundancy
- Deployment requires event-store replay if production people exist
- Judgement-worthy concerns are noted for future consideration

---

## Validation Notes

**Tests/checks confirming decision:**

1. **Dev check:** Passed with 371 tests, 0 failures (two consecutive runs)
2. **Targeted coverage verified from test output:**
   - Membership domain logic (commands, aggregates, projectors)
   - Accounts integration (magic-link with alternate emails)
   - Messaging integration (primary-email resolution)
   - LiveView forms (person create/edit with multiple emails)
   - Auth controller (staff onboarding, sign-in flows)

3. **Plan-conformance gate:** Already passed before review started

4. **Implementation evidence confirms:**
   - Migration has correct constraints (unique `normalized_email`, one-primary-per-person)
   - Projector handles legacy `PersonCreated` events correctly
   - Queries use new `membership_person_email_addresses` table
   - Auth allows sign-in with any known email, delivers link to requested address
   - Messaging sends to primary email only
   - Staff UI has dedicated create/edit LiveViews with multi-email forms

5. **Edge cases handled:**
   - Legacy event replay creates primary email address from `PersonCreated.email`
   - Removing primary email from form auto-promotes first remaining email
   - Database constraint catches race-condition duplicates (even if UX isn't ideal)
   - Fixture backward compatibility maintains existing test behavior

**Manual validation from plan not verified but assumed done:**

The plan's manual demo (Alice with primary/alternate emails, sign-in with alternate, receives club messages at primary, staff edits primary) is not shown in evidence, but plan-conformance gate required it.

**Recommendation:** ACCEPT and merge. Address bounded-safe normalization fix in next kaizen/refactoring cycle if desired. Schedule human review of judgement-worthy concerns (especially deployment backfill and constraint test coverage) at next iteration-planning session.