# Implementation Review Report

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The iteration plan does not cite specific ADRs. The implementation evidence shows it follows established architectural patterns without introducing competing infrastructure:

- Reuses existing `Auth.create_sign_in_token/2` for magic-link email verification
- Follows Phoenix controller/template conventions
- Uses existing `Onboarding` and `Membership` contexts appropriately
- Maintains Staff notification patterns via existing email/domain events
- No new persistence models, background infrastructure, or auth mechanisms introduced

The implementation builds on existing foundations as expected for an iterative enhancement. No ADR violations identified.

## ADR violations

None identified.

## Blocking issues

None identified.

**Critical workflow observation:** The automated repair attempts in prior stages appear to have applied changes to `web/lib/memba_web/controllers/page_controller.ex` when the implementation lives in `web/lib/memba_web/controllers/get_started_controller.ex`. This repair loop malfunction does not invalidate the implementation (which passes all tests), but it prevented the bounded-safe polish fixes from being applied. This is a workflow/tooling issue requiring human attention.

## Bounded-safe fixes

Despite successful dev check, the following defensive coding improvements would harden the controller against malformed requests:

1. **Add nil-safety to `club_name` parameter trimming**
   
   File: `web/lib/memba_web/controllers/get_started_controller.ex`
   
   Current code:
   ```elixir
   club_name: String.trim(request_params["club_name"])
   ```
   
   Issue: Will raise `FunctionClauseError` if `request_params["club_name"]` is `nil` (malformed POST).
   
   Fix:
   ```elixir
   club_name: String.trim(request_params["club_name"] || "")
   ```
   
   Rationale: Allows changeset validation to handle empty/invalid club names rather than controller raising an exception. The form will always submit the field, but defensive coding should not rely on form behavior.

2. **Clarify requester name selection logic**
   
   File: `web/lib/memba_web/controllers/get_started_controller.ex`
   
   Current pattern builds `attrs` with form-submitted `requester_name`, then conditionally overwrites it if an existing Person is found. This two-stage construction obscures the "existing Person name takes precedence" invariant.
   
   Clearer approach:
   ```elixir
   requester_name =
     if person do
       person.name
     else
       request_params["requester_name"]
     end

   attrs = %{
     requester_email: identity.email,
     requester_name: requester_name,
     club_name: String.trim(request_params["club_name"] || ""),
     note: String.trim(request_params["note"] || "")
   }
   ```
   
   Rationale: Single-pass attrs construction makes the precedence rule explicit and eliminates wasteful intermediate map building.

3. **Consider test coverage for malformed request parameters**
   
   Files: `web/lib/memba_web/controllers/get_started_controller.ex`, `web/test/memba_web/controllers/get_started_controller_test.exs`
   
   Current test suite does not include a case for signed-in request submission with missing/nil required fields. While the form prevents this in normal usage, a regression test proving graceful validation error handling (rather than controller exception) would document defensive behavior.

## Judgement-worthy non-blocking code-health findings

1. **Domain context API relies on caller discipline for verified email invariant**
   
   Files: `web/lib/memba/onboarding.ex`, `web/lib/memba_web/controllers/get_started_controller.ex`
   
   Smell: Controller constructs `attrs` including `requester_email: identity.email` and passes them to `Onboarding.create_onboarding_request/1`. The public web boundary correctly enforces authentication, but the domain API signature does not structurally prevent future internal callers from submitting unverified emails.
   
   Why it merits judgement: This is not a merge blocker—tests prove the public flow works correctly. However, encoding the verification requirement in the API signature would make misuse impossible:
   
   ```elixir
   # Option A: accept verified Identity struct
   Onboarding.create_verified_onboarding_request(identity, attrs)
   
   # Option B: separate verified email parameter
   Onboarding.create_onboarding_request(verified_email, attrs)
   ```
   
   Current design relies on discipline; alternative encodes invariants in types. Trade-off depends on team size, risk tolerance, and whether `Onboarding` functions are public/private boundaries.

2. **Single route/template multiplexes two related but distinct workflows**
   
   Files: `web/lib/memba_web/controllers/get_started_controller.ex`, `web/lib/memba_web/controllers/get_started_html/show.html.heex`
   
   Smell: `/get-started` handles both signed-out email verification and signed-in verified request submission via pattern-matching on `current_identity` assigns. Template conditionally renders two different forms based on authentication state.
   
   Why it merits judgement: This matches the plan's low-friction UX goal and keeps implementation concise. However, if these flows diverge (e.g., adding CAPTCHA, rate limiting, pre-verification saved state), the coupling will require refactoring. Current approach prioritizes simplicity; separation would improve future flexibility at the cost of more files/routes now.

3. **Email normalization pattern may be duplicated**
   
   File: `web/lib/memba_web/controllers/get_started_controller.ex`
   
   Smell: The signed-out verification path manually performs `String.trim(email) |> String.downcase()` before passing to `Auth.create_sign_in_token/2`.
   
   Why it merits judgement: Localized normalization is clear and works. If this pattern repeats across Auth, Membership, and other identity contexts, extracting to a shared helper (e.g., `Email.normalize/1`) would ensure consistent canonicalization. If this is the only or second occurrence, extraction would be premature abstraction. Requires codebase-wide search to determine if centralization adds value.

4. **Controller function clause ordering creates implicit pattern-match dependency**
   
   File: `web/lib/memba_web/controllers/get_started_controller.ex`
   
   Smell: Separate function clauses for `show/2` and `create/2` pattern-match on `%{assigns: %{current_identity: %Identity{}}}` vs general `conn`. More specific patterns must appear before general fallback or behavior changes.
   
   Why it merits judgement: This is idiomatic Elixir and well-tested. However, as the controller grows (more states, more param shapes), clause ordering becomes a maintenance consideration. Alternative approaches (guard clauses, explicit conditionals) trade Elixir idioms for explicitness. Current design is functional/native; alternatives would be defensive but less idiomatic. Team style/preference decision.

## Suggested fixes

If bounded-safe fixes are desired before merge, apply manually:

```elixir
# web/lib/memba_web/controllers/get_started_controller.ex
def create(%{assigns: %{current_identity: identity}} = conn, %{"request" => request_params}) do
  person = Membership.get_person_by_email(identity.email)

  requester_name =
    if person do
      person.name
    else
      request_params["requester_name"]
    end

  attrs = %{
    requester_email: identity.email,
    requester_name: requester_name,
    club_name: String.trim(request_params["club_name"] || ""),
    note: String.trim(request_params["note"] || "")
  }

  case Onboarding.create_onboarding_request(attrs) do
    {:ok, request} ->
      conn
      |> put_flash(:info, "Your request has been submitted.")
      |> redirect(to: ~p"/")

    {:error, changeset} ->
      conn
      |> put_status(:unprocessable_entity)
      |> put_flash(:error, "Please fix the errors below.")
      |> render(:show, changeset: changeset, current_identity: identity)
  end
end
```

Optionally add regression test for malformed parameters in `get_started_controller_test.exs`.

**Note:** Automated repair attempts in prior workflow stages appear to have targeted the wrong file (`page_controller.ex` instead of `get_started_controller.ex`), preventing these fixes from being applied. This workflow bug should be investigated separately.

## Validation notes

**Completed validation from workflow evidence:**

1. ✅ **Dev check passed completely** — No compilation warnings, Dialyzer clean, Credo clean, all tests green
2. ✅ **755 ExUnit tests passed** (0 failures)
3. ✅ **73 acceptance scenarios passed** (489 steps, 0 failures)
4. ✅ **Comprehensive controller test coverage** (`get_started_controller_test.exs`):
   - Signed-out email verification flow with redirect
   - Magic-link sign-in token creation with `return_to=/get-started`
   - Email normalization (trim + downcase)
   - Signed-in request form for new identity (no existing Person)
   - Signed-in request form for existing Person
   - Person name override (existing Person name takes precedence)
   - Request creation requires signed-in identity email
   - No onboarding request or Staff notification for email-only verification
5. ✅ **Staff visibility verification** (`admin_requests_live_test.exs`):
   - Staff see verified submitted requests in inbox
   - Staff request inbox empty after email-only verification
   - No Staff notification email sent for verification-only flow
   - Staff see request details (email, club name, note) for verified requests
6. ✅ **Plan conformance gate passed** in prior workflow stage
7. ✅ **Acceptance feature files unchanged** (domain criteria preserved)

**Behavioural acceptance validated:**

- Email verification creates sign-in token, sends magic link, sets `return_to=/get-started`
- Following magic link establishes identity session, redirects to Get Started form
- Request form pre-fills verified email (readonly)
- Request form uses existing Person name when available (readonly)
- Request form collects new name when no Person exists
- Request submission requires signed-in identity (no typed/untrusted email accepted)
- Staff only see and receive notifications for verified submitted requests
- No Person/club/membership/club access created during request submission (correctly deferred to Staff conversion)

**Manual/runtime checks:**

None required. Automated test coverage and dev check success provide sufficient confidence for merge acceptance.