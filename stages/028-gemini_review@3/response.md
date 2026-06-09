# Implementation Review Report

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The iteration plan does not explicitly cite any ADRs, and the modified files do not indicate changes to or violations of existing ADRs. The implementation safely reuses the established authentication boundary (magic-link tokens) and the existing `Onboarding` domain context without introducing competing architectural concepts or infrastructure.

## ADR violations

None identified.

## Blocking issues

None identified. The implementation conforms to the plan and the full automated suite passed.

*(Note on workflow/tooling: Prior automated repair attempts mistakenly targeted `page_controller.ex` instead of the actual `get_started_controller.ex`. The pipeline caught this, but it prevented the bounded-safe polish fixes from being applied automatically. The underlying implementation remains valid and mergeable.)*

## Bounded-safe fixes

1. **Make signed-in Get Started request parameter trimming nil-safe**
   File: `web/lib/memba_web/controllers/get_started_controller.ex`
   The signed-in request submission path trims `club_name` directly:
   ```elixir
   club_name: String.trim(request_params["club_name"])
   ```
   A malformed POST missing the `club_name` key would raise a `FunctionClauseError` on `String.trim/1` before Ecto changeset validation can handle it gracefully. This should be fixed safely to:
   ```elixir
   club_name: String.trim(request_params["club_name"] || "")
   ```

2. **Clarify trusted requester-name selection**
   File: `web/lib/memba_web/controllers/get_started_controller.ex`
   The implementation builds the `attrs` map with the form-submitted `requester_name`, then conditionally overwrites it if the verified email belongs to an existing `Person`. The behaviour is correct, but the invariant would be clearer if the trusted requester name were definitively selected *before* building the `attrs` map.

3. **Add a malformed-param regression test**
   File: `web/test/memba_web/controllers/get_started_controller_test.exs`
   Add a test verifying that a signed-in POST with missing `club_name` gracefully returns `422`, renders validation errors, creates no onboarding request, and sends no Staff notification.

## Judgement-worthy non-blocking code-health findings

1. **Verified-email invariant is enforced by the web caller rather than structurally encoded in the domain API**
   - Files: `web/lib/memba/onboarding.ex`, `web/lib/memba_web/controllers/get_started_controller.ex`
   - Smell: The public web boundary properly requires authentication and uses `identity.email` instead of a user-submitted string. However, the `Onboarding.create_onboarding_request/1` API still takes a raw attribute map.
   - Why it merits judgement: The invariant (only verified emails can create requests) is currently enforced by caller discipline in the web layer. Passing the verified `Identity` struct or a distinct verified-email type directly to the context would structurally prevent future internal callers from bypassing this rule.

2. **Multiplexing workflow states in a single route/template**
   - Files: `web/lib/memba_web/controllers/get_started_controller.ex`, `web/lib/memba_web/controllers/get_started_html/show.html.heex`
   - Smell: The `/get-started` route manages two distinct phases of a funnel (unauthenticated email collection vs. authenticated request submission) using pattern matching on `assigns[:current_identity]`.
   - Why it merits judgement: It serves the iteration's goal of a low-friction UX and keeps the implementation concise. However, if these flows diverge (e.g., adding CAPTCHA, complex pre-verification validation, or saving pre-verification state), splitting them into separate controllers or LiveViews may become necessary to avoid combinatorial complexity.

3. **Duplication of email normalization logic**
   - File: `web/lib/memba_web/controllers/get_started_controller.ex`
   - Smell: The string trimming and downcasing of the submitted email address is manually performed before passing it to `Auth`.
   - Why it merits judgement: If this exact normalization pattern is repeated wherever users manually type emails (e.g., in staff invitations, sign-in forms), extracting it to a shared helper ensures consistent canonicalization. If it only exists here and in the auth boundary, extraction isn't immediately required.

## Suggested fixes

Apply the bounded-safe fixes manually to `GetStartedController` (not `PageController`):

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
    {:ok, _request} ->
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

## Validation notes

- **`dev check` / `dev ci`:** Passed successfully (0 compilation warnings, Dialyzer clean, Credo clean).
- **ExUnit:** 755 tests passed with 0 failures.
- **Acceptance Tests:** 73 scenarios, 489 steps passed successfully.
- **Plan Conformance:** Verified via workflow evidence. The implementation correctly transitions users through unauthenticated magic-link generation to an authenticated submission form, enforcing verified identity requirements securely. Domain requirements and acceptance criteria remain perfectly preserved.