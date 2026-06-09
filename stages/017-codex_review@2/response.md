# Implementation Review Report

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The iteration plan does not cite any specific ADRs, and the supplied implementation evidence does not show ADR files being changed. Based on the evidence, the implementation follows existing architectural paths rather than introducing competing infrastructure:

- Reuses the existing magic-link sign-in/token flow for email verification.
- Keeps onboarding request creation in the existing `Onboarding` context.
- Preserves Staff request inbox and notification behaviour for submitted verified requests.
- Avoids creating Membership-domain records during public verified request submission.
- Does not introduce new HTTP clients, background infrastructure, persistence models, or alternate auth mechanisms.

No ADR-level conflict is evident from the supplied plan, diff evidence, or test output.

## ADR violations

None identified.

## Blocking issues

None identified.

## Bounded-safe fixes

1. **Make `String.trim/1` calls nil-safe in `GetStartedController`**

   File: `web/lib/memba_web/controllers/get_started_controller.ex`

   The signed-in request submission path appears to trim `club_name` directly from params while `note` already has a fallback. A malformed hand-crafted POST without `club_name` could raise before the onboarding changeset can return a validation error.

   Prefer:

   ```elixir
   club_name: String.trim(request_params["club_name"] || ""),
   note: String.trim(request_params["note"] || "")
   ```

2. **Simplify request attribute construction for existing Person name override**

   File: `web/lib/memba_web/controllers/get_started_controller.ex`

   The current implementation appears to build attrs using the submitted `requester_name`, then conditionally overwrites it when the verified email belongs to an existing Person. This is correct, but slightly obscures the invariant.

   Prefer assigning the trusted requester name once:

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

3. **Consider centralizing request-field trimming in the Onboarding changeset**

   Files likely involved:

   - `web/lib/memba/onboarding.ex`
   - Onboarding request schema/changeset module
   - `web/lib/memba_web/controllers/get_started_controller.ex`

   If trimming is currently split between controller and domain validation, moving normalization for `requester_name`, `club_name`, and `note` into the changeset would keep controllers focused on flow and make all callers receive consistent normalization.

   This is not required for merge if current behaviour is covered and green, but it is a safe maintainability improvement if done carefully.

## Judgement-worthy non-blocking code-health findings

1. **Verified-email invariant is still partly caller-discipline based**

   Files:

   - `web/lib/memba/onboarding.ex`
   - `web/lib/memba_web/controllers/get_started_controller.ex`

   Smell: The controller constructs attrs with `requester_email: identity.email` and passes them into `Onboarding.create_onboarding_request/1`. This satisfies the public web flow, but the context API may still accept requester email as ordinary caller-provided attrs.

   Why it may need human judgement: For long-term security hardening, it may be preferable for the context API to encode the trusted boundary structurally, for example:

   ```elixir
   create_verified_onboarding_request(identity, attrs)
   ```

   or:

   ```elixir
   create_onboarding_request(verified_email, attrs)
   ```

   That would make future misuse harder. This is not a blocker because the implemented controller path and tests prove the intended public behaviour.

2. **`/get-started` now multiplexes two related workflows**

   Files:

   - `web/lib/memba_web/controllers/get_started_controller.ex`
   - `web/lib/memba_web/controllers/get_started_html/show.html.heex`

   Smell: The route now handles both signed-out email verification and signed-in verified request submission, keyed by session state and param shape.

   Why it may need human judgement: This matches the plan and keeps the UX low-friction. However, if future work adds CAPTCHA, resend behaviour, rate limiting, saved pre-verification state, or more complex onboarding fields, splitting helpers/templates/components may become clearer.

3. **Email normalization may be duplicated**

   File:

   - `web/lib/memba_web/controllers/get_started_controller.ex`

   Smell: The signed-out verification path normalizes email using trim/downcase before creating a sign-in token.

   Why it may need human judgement: This is fine locally. If the same normalization exists across Auth, Membership Person lookup, onboarding, and identity creation code, a shared normalization helper could reduce drift. If this is only one localized duplication, extraction would be unnecessary abstraction.

4. **Controller clause ordering relies on idiomatic but implicit Elixir dispatch**

   File:

   - `web/lib/memba_web/controllers/get_started_controller.ex`

   Smell: Separate clauses for signed-in versus general `show/create` behaviour likely depend on the more specific `%{assigns: %{current_identity: %Identity{}}}` clause appearing before the fallback clause.

   Why it may need human judgement: This is idiomatic Elixir and well covered by tests. It only becomes a maintainability concern if the controller grows more states or more param-shape-specific clauses.

## Suggested fixes

If applying polish before merge, keep it bounded to the controller-level safe cleanup:

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

A later hardening pass can consider moving trimming into the Onboarding changeset and/or reshaping the context API around a verified identity argument.

## Validation notes

Completed validation from the supplied workflow evidence:

- `dev ci` passed.
- ExUnit suite passed.
- Acceptance suite passed: **73 scenarios, 489 steps**.
- Evidence shows coverage for:
  - signed-out `/get-started` email-only verification;
  - magic-link token creation;
  - `return_to=/get-started`;
  - signed-in verified request form;
  - verified identity with no existing Person;
  - verified identity with existing Person;
  - using the signed-in identity email rather than a typed requester email;
  - no Staff-visible onboarding request from email-only verification;
  - no Staff notification from email-only verification;
  - Staff visibility and actions for verified submitted requests;
  - no Person, club, membership, or club access creation during request submission.
- Acceptance feature files appear to have remained stable as domain criteria.
- No manual checks required for merge based on the supplied evidence.