# Implementation Review Report

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The iteration plan does not cite specific ADRs, and no ADR files appear in the changed file list. The implementation builds on existing infrastructure patterns without introducing parallel systems:

- Reuses `Auth.create_sign_in_token/2` for magic-link email verification
- Follows established Phoenix controller/template conventions
- Uses existing `Onboarding` context functions
- Maintains Staff notification patterns for verified requests only

The implementation introduces no new architectural decisions and follows Phoenix/Elixir/Ecto standard practices throughout. No ADR violations identified.

## ADR violations

None identified.

## Blocking issues

None identified.

## Bounded-safe fixes

1. **Simplify request attribute construction in `GetStartedController.create/2`**

   File: `web/lib/memba_web/controllers/get_started_controller.ex` (lines ~35-45)

   Current pattern builds `attrs` map with `requester_name` from form params, then conditionally overwrites it when an existing Person is found:

   ```elixir
   attrs = %{
     requester_email: identity.email,
     requester_name: request_params["requester_name"],
     club_name: String.trim(request_params["club_name"]),
     note: String.trim(request_params["note"] || "")
   }

   attrs =
     if person do
       Map.put(attrs, :requester_name, person.name)
     else
       attrs
     end
   ```

   Clearer with conditional in initial assignment:

   ```elixir
   requester_name = if person, do: person.name, else: request_params["requester_name"]

   attrs = %{
     requester_email: identity.email,
     requester_name: requester_name,
     club_name: String.trim(request_params["club_name"]),
     note: String.trim(request_params["note"] || "")
   }
   ```

   **Rationale**: Eliminates wasteful intermediate map construction and makes the "use person name when available" logic clearer at first read. Tests already verify this behaviour correctly.

2. **Ensure string trimming is nil-safe**

   File: `web/lib/memba_web/controllers/get_started_controller.ex` (lines ~37-38)

   Current implementation has `String.trim(request_params["note"] || "")` which is safe, but `String.trim(request_params["club_name"])` relies on form validation to guarantee a string is present.

   For defensive robustness against malformed POSTs:

   ```elixir
   club_name: String.trim(request_params["club_name"] || ""),
   note: String.trim(request_params["note"] || "")
   ```

   **Rationale**: Prevents potential runtime errors from hand-crafted or malformed form submissions. The `|| ""` fallback is cheap insurance and allows the changeset to report validation errors instead of the controller raising an exception.

3. **Consider moving string trimming to Onboarding changeset validation**

   Files involved:
   - `web/lib/memba/onboarding.ex` (likely location of context functions)
   - Onboarding request schema/changeset module
   - `web/lib/memba_web/controllers/get_started_controller.ex`

   Manual `String.trim()` calls in the controller for `club_name` and `note` could move to the Onboarding changeset validation for consistency with Ecto conventions.

   **Rationale**: Controllers should delegate data transformation to contexts/changesets. This keeps the controller focused on request flow and makes trimming behaviour testable at the domain layer. If `requester_name` trimming is already in the changeset, moving `club_name` and `note` trimming there maintains consistency.

## Judgement-worthy non-blocking code-health findings

1. **Email normalization pattern may be duplicated**

   File: `web/lib/memba_web/controllers/get_started_controller.ex` (line ~21)

   The pattern `String.trim(email) |> String.downcase()` appears in the signed-out verification path. If this email normalization pattern is used elsewhere in the codebase (e.g., in `Auth`, `Identity`, or `Membership` contexts), consider extracting to a shared helper like `Email.normalize/1`.

   **Why it may need judgement**: Current approach is clear and localized. Extraction only adds value if the pattern repeats across multiple contexts. Requires codebase-wide search to determine if centralization improves or complicates maintenance. If this is the only extra occurrence beyond `Auth.create_sign_in_token/2`, extraction would be unnecessary abstraction.

2. **Two-form conditional rendering creates coupling**

   File: `web/lib/memba_web/controllers/get_started_html/show.html.heex`

   Single template uses `if @current_identity` to control two distinct forms: signed-out email verification and signed-in onboarding request submission. This couples the two workflow states in one file.

   **Why it may need judgement**: Current approach is readable and keeps related flows together. Alternative of separate templates/views would increase file count but improve separation of concerns. Trade-off between cohesion (current) vs separation (alternative) depends on future evolution. If these flows diverge significantly (e.g., adding CAPTCHA, rate limiting, pre-verification state management), splitting becomes clearer. If they remain parallel, current approach is simpler.

3. **Onboarding context API still caller-discipline based for verified emails**

   Files:
   - `web/lib/memba/onboarding.ex` (presumed location based on usage)
   - `web/lib/memba_web/controllers/get_started_controller.ex`

   The controller constructs attrs including `requester_email: identity.email` and passes them to `Onboarding.create_onboarding_request/1`. This satisfies the public web flow, but the context API still appears to accept requester email as ordinary attrs rather than enforcing verification at the domain boundary.

   **Why it may need judgement**: This is not a merge blocker because tests and routing prove the public path no longer trusts a typed email. However, for longer-term safety, the domain API could make verification harder to bypass by encoding the security boundary in the function signature:

   ```elixir
   create_onboarding_request(verified_identity_email, attrs)
   # or
   create_verified_onboarding_request(identity, attrs)
   ```

   This would make it structurally impossible for future callers to forget the verification requirement. Current design relies on discipline; alternative design uses types to enforce invariants. Deciding between these approaches depends on risk tolerance, team size, and how public vs private the `Onboarding` context functions are.

4. **Controller pattern-match clause ordering creates implicit dependency**

   File: `web/lib/memba_web/controllers/get_started_controller.ex` (lines ~11-23)

   Using pattern-matching on `%{assigns: %{current_identity: %Identity{}}}` vs general `conn` in separate function clauses for `show/2` is idiomatic Elixir but creates implicit ordering dependency. Function clauses must remain in current order (specific patterns before general) or behaviour changes.

   **Why it may need judgement**: This is standard Elixir convention and tests verify both paths. However, as the controller grows, clause ordering becomes a maintenance consideration. Alternative approaches (guard clauses or explicit condition checks) trade Elixir idioms for explicitness. Current approach is more functional/Elixir-native; alternatives would be more defensive but less idiomatic. This is a team style/preference decision rather than a correctness issue.

## Suggested fixes

If bounded-safe fixes are applied:

**Fix 1**: Simplify attrs construction in `create/2` signed-in request path:

```elixir
def create(%{assigns: %{current_identity: identity}} = conn, %{"request" => request_params}) do
  person = Membership.get_person_by_email(identity.email)
  requester_name = if person, do: person.name, else: request_params["requester_name"]

  attrs = %{
    requester_email: identity.email,
    requester_name: requester_name,
    club_name: String.trim(request_params["club_name"] || ""),
    note: String.trim(request_params["note"] || "")
  }

  case Onboarding.create_onboarding_request(attrs) do
    # ... rest unchanged
  end
end
```

**Fix 2**: Move field trimming to `Onboarding` context changesets. Update `Onboarding.change_onboarding_request/1` and related functions to trim `club_name`, `note`, and possibly `requester_name` fields in changeset validation. Remove manual trimming from controller.

**Fix 3**: Add nil-safe fallback to `club_name` trimming even if Fix 2 is deferred:

```elixir
club_name: String.trim(request_params["club_name"] || "")
```

## Validation notes

**Tests/Checks Validating This Decision:**

1. ✅ **Dev check passed completely** - No compilation warnings, Dialyzer clean, Credo clean, all tests green
2. ✅ **Comprehensive controller test coverage** (`web/test/memba_web/controllers/get_started_controller_test.exs`):
   - Signed-out email verification flow with redirect
   - Magic-link sign-in token creation with `return_to=/get-started` parameter
   - Email normalization (trim + downcase)
   - Signed-in request form for new identity (no existing Person)
   - Signed-in request form for existing Person
   - Person name override behaviour (existing Person name wins)
   - Request creation with verified identity email only
   - No onboarding request or Staff notification created for email-only verification step
3. ✅ **Staff request visibility verification** (`web/test/memba_web/live/admin_requests_live_test.exs`):
   - Staff can see verified submitted onboarding requests in inbox
   - Staff request inbox stays empty after email-only Get Started verification
   - No Staff notification email sent for verification-only flow
   - Staff see request details (email, club name, note) for verified requests
4. ✅ **73 passing acceptance scenarios** (489 steps) including iteration-030 scenarios
5. ✅ **Plan conformance validated** in prior workflow stage

**Manual/Runtime Checks Recommended:**

None required - automated test coverage and dev check success provide sufficient confidence for acceptance.

**Acceptance Behaviour Verified:**

- Email verification creates sign-in token, sends magic link email, sets `return_to=/get-started`
- Following magic link signs in identity and redirects to Get Started request form
- Request form pre-fills verified email as readonly
- Request form uses existing Person name when available (readonly)
- Request form collects new name when no Person exists for the verified email
- Request submission requires signed-in identity (no typed/trusted email)
- Staff only see and receive notifications for verified submitted onboarding requests
- No Person/club/membership/club access created during request submission (deferred to Staff conversion)