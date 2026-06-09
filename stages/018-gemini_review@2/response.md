# Implementation Review Report

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The iteration plan does not explicitly cite any ADRs, and the modified files do not indicate changes to or violations of existing ADRs. The implementation safely reuses the established authentication boundary (magic-link tokens) and the existing `Onboarding` domain context without introducing competing architectural concepts or infrastructure.

## ADR violations

None identified.

## Blocking issues

None identified.

## Bounded-safe fixes

1. **Add nil-safety to parameter trimming in `GetStartedController`**
   - File: `web/lib/memba_web/controllers/get_started_controller.ex`
   - Issue: The signed-in form submission path trims `club_name` directly from the `request_params`. While `note` safely falls back with `|| ""`, `club_name` does not. A malformed POST request missing the `club_name` key would raise a `FunctionClauseError` on `String.trim/1` before the Ecto changeset validation can handle it gracefully.
   - Fix: Use `String.trim(request_params["club_name"] || "")`.

2. **Simplify the attribute map construction for existing Person names**
   - File: `web/lib/memba_web/controllers/get_started_controller.ex`
   - Issue: The controller assigns the `attrs` map using `request_params["requester_name"]`, and then conditionally replaces `requester_name` using `Map.put` if the email belongs to an existing `Person`. It is cleaner to determine the definitive name first.
   - Fix: Resolve `requester_name` in a single variable before constructing the `attrs` map.

## Judgement-worthy non-blocking code-health findings

1. **Domain boundary does not structurally enforce email verification**
   - File: `web/lib/memba/onboarding.ex` and `web/lib/memba_web/controllers/get_started_controller.ex`
   - Smell: The public web boundary properly requires authentication and uses `identity.email` instead of a user-submitted string. However, the `Onboarding.create_onboarding_request/1` API still takes a raw attribute map. 
   - Why it merits judgement: The invariant (only verified emails can create requests) is currently enforced by caller discipline in the web layer. Passing the verified `Identity` struct or a distinct verified-email type directly to the context would structurally prevent future internal callers from bypassing this rule.

2. **Multiplexing workflow states in a single route/template**
   - File: `web/lib/memba_web/controllers/get_started_controller.ex` and `web/lib/memba_web/controllers/get_started_html/show.html.heex`
   - Smell: The `/get-started` route is managing two distinct phases of a funnel (unauthenticated email collection vs. authenticated request submission) using pattern matching on `assigns[:current_identity]`.
   - Why it merits judgement: It effectively serves the iteration's goal of a low-friction UX and keeps the implementation concise. However, if these flows diverge (e.g., adding CAPTCHA, complex pre-verification validation, or saving pre-verification state), splitting them into separate controllers or LiveViews may become necessary to avoid combinatorial complexity.

3. **Duplication of email normalization logic**
   - File: `web/lib/memba_web/controllers/get_started_controller.ex`
   - Smell: The string trimming and downcasing of the submitted email address is manually performed before passing it to `Auth`. 
   - Why it merits judgement: If this exact normalization pattern is repeated wherever users manually type emails (e.g., in staff invitations, sign-in forms), extracting it to a shared helper ensures consistent canonicalization. If it only exists here and in the auth boundary, extraction isn't immediately required.

## Suggested fixes

For the bounded-safe fixes, update `GetStartedController.create/2` targeting authenticated users:

```elixir
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
    # existing branches unchanged
  end
end
```

## Validation notes

- The `dev check` pipeline completed successfully, indicating no warnings, no format issues, and that types remain correct.
- The Acceptance testing suite passed entirely (73 scenarios, 489 steps), preserving domain criteria.
- Based on the testing evidence, the implementation successfully exercises the required behaviours: unauthenticated requests send a magic link with a `return_to` parameter, do not alert staff, and do not create domain records. Submission after magic-link verification successfully respects the identity email and triggers correct staff flows.