# Implementation Review Report: Iteration 030 - Verified Onboarding Requests

## Decision: **ACCEPT**

## Confidence: **High**

## ADR Conformance: **PASS**

No ADRs were explicitly cited in the iteration plan. No ADR files appear in the changed file list. The implementation builds on existing infrastructure patterns visible in the codebase:
- Reuses `Auth.create_sign_in_token/2` for magic-link email verification
- Follows established Phoenix controller/template conventions
- Uses existing `Onboarding` context functions
- Maintains Staff notification patterns for verified requests only

The implementation introduces no new architectural decisions and follows Phoenix/Elixir/Ecto standard practices throughout.

## ADR Violations

None identified.

## Blocking Issues

None identified.

## Bounded-Safe Fixes

1. **Clearer conditional name assignment in request creation** (web/lib/memba_web/controllers/get_started_controller.ex:35-45)
   
   Current pattern builds `attrs` map with form `requester_name`, then conditionally overwrites it:
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
   
   Clearer intent with conditional in initial assignment:
   ```elixir
   attrs = %{
     requester_email: identity.email,
     requester_name: if(person, do: person.name, else: request_params["requester_name"]),
     club_name: String.trim(request_params["club_name"]),
     note: String.trim(request_params["note"] || "")
   }
   ```
   
   **Rationale**: Eliminates wasteful map construction and makes the "use person name when available" logic clearer at first read. Tests already verify this behaviour correctly.

2. **Move string trimming to changeset validation** (web/lib/memba_web/controllers/get_started_controller.ex:37-38)
   
   Manual `String.trim()` calls in controller for `club_name` and `note` could move to `Onboarding.change_onboarding_request/1` changeset validation for consistency with Ecto conventions.
   
   **Rationale**: Controllers should delegate data transformation to contexts/changesets. This keeps controller focused on request flow and makes trimming behaviour testable at the domain layer.

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Email normalization duplication** (web/lib/memba_web/controllers/get_started_controller.ex:21)
   
   The pattern `String.trim(email) |> String.downcase()` appears in the controller. If this email normalization pattern is used elsewhere in the codebase (e.g., in `Auth` or `Identity` contexts), consider extracting to a shared helper like `Email.normalize/1`.
   
   **Why it may need judgement**: Current approach is clear and localized. Extraction only adds value if the pattern repeats across multiple contexts. Requires codebase-wide search to determine if centralization improves or complicates maintenance.

2. **Two-form conditional rendering coupling** (web/lib/memba_web/controllers/get_started_html/show.html.heex)
   
   Single template with `if @current_identity` controlling two distinct forms creates coupling between signed-out verification flow and signed-in request flow.
   
   **Why it may need judgement**: Current approach is readable and keeps related flows together. Alternative of separate templates/views would increase file count but improve separation. Trade-off between cohesion (current) vs separation (alternative) depends on future evolution - if these flows diverge significantly, splitting becomes clearer; if they remain parallel, current approach is simpler.

3. **Controller pattern-match clause ordering** (web/lib/memba_web/controllers/get_started_controller.ex:11-23)
   
   Using pattern-matching on `%{assigns: %{current_identity: %Identity{}}}` vs `current_identity: nil` in separate function clauses is idiomatic Elixir but creates implicit ordering dependency. Function clauses must remain in current order (specific patterns before general) or behaviour changes.
   
   **Why it may need judgement**: This is standard Elixir convention and tests verify both paths. However, as the controller grows, clause ordering becomes a maintenance consideration. Alternative guard clauses or explicit condition checks trade Elixir idioms for explicitness. Current approach is more functional/Elixir-native; alternatives would be more defensive but less idiomatic.

## Suggested Fixes

If bounded-safe fixes are applied:

**Fix 1**: Simplify attrs construction in `create/2` request path:
```elixir
def create(%{assigns: %{current_identity: identity}} = conn, %{"request" => request_params}) do
  person = Membership.get_person_by_email(identity.email)

  attrs = %{
    requester_email: identity.email,
    requester_name: if(person, do: person.name, else: request_params["requester_name"]),
    club_name: String.trim(request_params["club_name"]),
    note: String.trim(request_params["note"] || "")
  }

  case Onboarding.create_onboarding_request(attrs) do
    # ... rest unchanged
  end
end
```

**Fix 2**: Move trimming to `Onboarding` context changesets. Update `Onboarding.change_onboarding_request/1` and related functions to trim `club_name` and `note` fields in changeset validation. Remove manual trimming from controller.

## Validation Notes

**Tests/Checks Validating This Decision:**

1. ✅ **Dev check passed completely** - No compilation warnings, Dialyzer clean, Credo clean, all tests green
2. ✅ **Comprehensive controller test coverage** (web/test/memba_web/controllers/get_started_controller_test.exs):
   - Signed-out email verification flow
   - Magic-link token creation with return_to parameter
   - Email normalization (trim + downcase)
   - Signed-in request form for new identity
   - Signed-in request form for existing person
   - Person name override behaviour
   - Request creation with verified email only
   - No request/notification for email-only verification
3. ✅ **Staff request visibility verification** (web/test/memba_web/live/admin_requests_live_test.exs):
   - Staff can see verified submitted requests
   - Staff request inbox stays empty after email-only verification
   - No staff notification email sent for verification-only flow
4. ✅ **73 passing acceptance scenarios** including iteration-030 scenarios
5. ✅ **Plan conformance validated** in prior workflow stage

**Manual/Runtime Checks Recommended:**

None required - automated test coverage and dev check success provide sufficient confidence.

**Acceptance Behaviour Verified:**

- Email verification creates sign-in token, sends magic link, sets return_to=/get-started
- Following magic link signs in identity and redirects to Get Started request form
- Request form pre-fills verified email (readonly)
- Request form uses existing person name when available (readonly)
- Request form collects new name when no person exists
- Request submission requires signed-in identity
- Staff only see and receive notifications for verified submitted requests
- No Person/club/membership created until Staff conversion