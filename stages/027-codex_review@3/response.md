# Implementation Review Report

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The iteration plan does not cite a specific ADR, and the provided implementation evidence does not show ADR files being changed. Based on the plan, diff evidence, and successful validation, the implementation appears to follow existing architectural constraints:

- Reuses the existing magic-link authentication/sign-in-token flow for requester email verification.
- Keeps onboarding request creation in the existing `Onboarding` context.
- Keeps identity/session concerns in the existing auth boundary.
- Preserves Staff request inbox and notification behaviour for verified submitted requests.
- Avoids creating Membership-domain records during public request submission.
- Does not introduce alternate auth, persistence, HTTP, job, or notification infrastructure.

No ADR-level conflict is evident.

## ADR violations

None identified.

## Blocking issues

None identified.

The implementation appears plan-conforming, and the full automated suite passed. The remaining findings are polish / hardening items, not merge blockers.

## Bounded-safe fixes

1. **Make signed-in Get Started request parameter trimming nil-safe**

   File: `web/lib/memba_web/controllers/get_started_controller.ex`

   The review evidence indicates the signed-in request submission path trims `club_name` directly:

   ```elixir
   club_name: String.trim(request_params["club_name"])
   ```

   A hand-crafted or malformed POST missing `club_name` could raise before the onboarding changeset can return a normal validation error. This is low-risk to fix without changing intended product behaviour:

   ```elixir
   club_name: String.trim(request_params["club_name"] || "")
   ```

2. **Clarify trusted requester-name selection**

   File: `web/lib/memba_web/controllers/get_started_controller.ex`

   The implementation appears to build attrs with the submitted `requester_name`, then conditionally overwrite it when the verified email belongs to an existing `Person`. The behaviour is correct, but the invariant would be clearer if the trusted requester name were selected before building the attrs map.

3. **Add a small malformed-param regression test, if the nil-safe fix is applied**

   File: `web/test/memba_web/controllers/get_started_controller_test.exs`

   A signed-in POST with missing `club_name` should return `422`, render validation errors, create no onboarding request, and send no Staff notification.

4. **Workflow/tooling note: prior repair evidence appears to target the wrong controller**

   The review-repair stage reports changes to:

   - `web/lib/memba_web/controllers/page_controller.ex`
   - `web/test/memba_web/controllers/page_controller_test.exs`

   But the repeated review output still identifies the relevant implementation as:

   - `web/lib/memba_web/controllers/get_started_controller.ex`
   - `web/test/memba_web/controllers/get_started_controller_test.exs`

   This does not block the implementation because the full suite is green and the underlying issue is bounded-safe polish, but if the polish fix is applied, it should be applied to the actual Get Started controller/test.

## Judgement-worthy non-blocking code-health findings

1. **Verified-email invariant is enforced by the web caller rather than structurally encoded in the domain API**

   Files:

   - `web/lib/memba/onboarding.ex`
   - `web/lib/memba_web/controllers/get_started_controller.ex`

   Smell: The public controller correctly uses `identity.email` and does not trust a typed requester email, but `Onboarding.create_onboarding_request/1` still appears to accept a raw attrs map containing `requester_email`.

   Why it may need human judgement: This is acceptable for this iteration and is covered by tests at the public boundary. Longer term, a context API such as `create_verified_onboarding_request(identity, attrs)` or `create_onboarding_request(verified_email, attrs)` would make future misuse harder by encoding the verification boundary in the function signature.

2. **`/get-started` multiplexes two workflow states**

   Files:

   - `web/lib/memba_web/controllers/get_started_controller.ex`
   - `web/lib/memba_web/controllers/get_started_html/show.html.heex`

   Smell: The same route/template handles both signed-out email verification and signed-in verified request submission.

   Why it may need human judgement: This matches the plan and keeps the UX low-friction. If future work adds CAPTCHA, rate limiting, resend UI, pre-verification saved state, or more complex request fields, splitting the two phases into clearer helpers/templates/routes may become worthwhile.

3. **Email normalization may be duplicated**

   File:

   - `web/lib/memba_web/controllers/get_started_controller.ex`

   Smell: The signed-out email verification path manually trims and downcases email before creating the sign-in token.

   Why it may need human judgement: Local normalization is fine if this is isolated. If the same normalization pattern exists across Auth, Membership, invitations, Staff flows, and onboarding, a shared email normalization helper could reduce drift.

4. **Controller clause ordering carries implicit flow behaviour**

   File:

   - `web/lib/memba_web/controllers/get_started_controller.ex`

   Smell: The controller likely uses separate function clauses for signed-in and signed-out `show/create` behaviour based on `%{assigns: %{current_identity: %Identity{}}}` versus fallback clauses.

   Why it may need human judgement: This is idiomatic Elixir and well tested. If the controller grows more states or param-shape-specific behaviour, explicit helpers or conditionals may become easier to maintain.

## Suggested fixes

If applying the bounded-safe polish before merge, target `GetStartedController`, not `PageController`:

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

Optional regression coverage:

- Signed-in identity posts `request` params missing `club_name`.
- Response is `422`.
- Validation error is rendered.
- `Onboarding.list_active_requests()` remains empty.
- No Staff notification email is sent.

## Validation notes

Validation from the provided workflow evidence:

- `dev ci` / dev check passed.
- ExUnit suite passed: `755 tests, 0 failures`.
- Acceptance suite passed: `73 scenarios`, `489 steps`, all passed.
- Acceptance feature files appear unchanged.
- Evidence shows automated coverage for:
  - signed-out `/get-started` email-only verification;
  - magic-link sign-in token creation;
  - `return_to=/get-started`;
  - email normalization on verification request;
  - signed-in verified request form for an identity without a `Person`;
  - signed-in verified request form for an existing `Person`;
  - using the verified session email instead of a typed requester email;
  - no onboarding request from email-only verification;
  - no Staff notification from email-only verification;
  - Staff visibility for verified submitted requests;
  - no Person, club, membership, or club access creation during request submission.

No manual checks are required for merge based on the supplied evidence.