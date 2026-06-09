# Implementation Review Report

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The iteration plan does not cite a specific ADR, and the collected evidence does not show ADR files changed. The implementation appears to preserve existing architecture and infrastructure choices:

- Reuses the existing magic-link sign-in/token flow rather than introducing a parallel verification mechanism.
- Keeps request creation in the existing Onboarding context.
- Preserves Staff inbox and notification behaviour for actual verified onboarding requests.
- Does not introduce new membership-domain side effects during public request submission.

No ADR-level architecture drift is evident from the implementation evidence.

## ADR violations

None identified.

## Blocking issues

None identified.

## Bounded-safe fixes

1. **Simplify request attribute construction in `GetStartedController`**

   File: `web/lib/memba_web/controllers/get_started_controller.ex`

   The request creation path appears to build attrs with `requester_name` from submitted params, then overwrites it when an existing Person is found. This is behaviourally correct, but slightly obscures the invariant that existing Person names win.

   Prefer assigning the value once:

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

2. **Guard string trimming against missing params**

   File: `web/lib/memba_web/controllers/get_started_controller.ex`

   The evidence shows manual trimming for fields such as `club_name` and `note`. Ensure all `String.trim/1` calls receive a binary, especially for malformed or hand-crafted POSTs.

   Safe pattern:

   ```elixir
   String.trim(request_params["club_name"] || "")
   ```

   This is low-risk and avoids turning bad form input into a controller exception before the changeset can report validation errors.

3. **Consider moving trimming into the Onboarding changeset**

   Files likely involved:
   - `web/lib/memba/onboarding.ex`
   - Onboarding request schema/changeset module, if separate
   - `web/lib/memba_web/controllers/get_started_controller.ex`

   Trimming `club_name`, `note`, and possibly `requester_name` in the changeset would centralize data normalization and keep the controller focused on flow control. This is safe if existing tests continue to assert the same persisted values and validation behaviour.

## Judgement-worthy non-blocking code-health findings

1. **Context API still appears caller-discipline based for verified emails**

   Files:
   - `web/lib/memba/onboarding.ex`
   - `web/lib/memba_web/controllers/get_started_controller.ex`

   Smell: The controller constructs attrs including `requester_email: identity.email` and passes them to `Onboarding.create_onboarding_request/1`. That satisfies the public web flow, but the context API still appears to accept a requester email as ordinary attrs.

   Why it may need human judgement: This is not a merge blocker because tests and routing appear to prove the public path no longer trusts a typed email. However, for longer-term safety, the domain API could make verification harder to bypass, for example:

   ```elixir
   create_onboarding_request(verified_identity_email, attrs)
   ```

   or

   ```elixir
   create_verified_onboarding_request(identity, attrs)
   ```

   That would encode the security boundary in the function shape rather than relying on every caller to remember not to pass a typed email.

2. **Email normalization may be duplicated outside the auth boundary**

   File:
   - `web/lib/memba_web/controllers/get_started_controller.ex`

   Smell: The signed-out Get Started verification path normalizes email with trim/downcase before creating a sign-in token.

   Why it may need human judgement: This is fine locally and likely matches existing behaviour. If similar normalization exists in Auth, Identity, Person lookup, and onboarding code, a shared email normalization helper would reduce drift. If this is the only extra occurrence, extraction would be unnecessary abstraction.

3. **One controller action now multiplexes two distinct user intents**

   Files:
   - `web/lib/memba_web/controllers/get_started_controller.ex`
   - `web/lib/memba_web/controllers/get_started_html/show.html.heex`

   Smell: `/get-started` now serves both:
   - signed-out email verification request, and
   - signed-in verified onboarding request submission.

   Why it may need human judgement: This matches the plan and keeps the UX simple. The trade-off is that the controller/template carry two workflows keyed by session state and param shape. If future iterations add resend links, pre-verification state, CAPTCHA, rate limits, or richer onboarding fields, splitting into explicit verification/request helpers or separate components may become worthwhile.

## Suggested fixes

Recommended non-blocking cleanup before or after merge:

1. Refactor request attr construction so the existing-Person name override is expressed directly.
2. Ensure all controller-level `String.trim/1` calls are nil-safe.
3. If desired, move field trimming into the Onboarding request changeset and remove duplicate controller normalization.
4. Consider, in a future hardening pass, changing the Onboarding context API so verified identity email is passed as a separate trusted argument rather than as ordinary attrs.

## Validation notes

Relevant validation already completed:

- `dev ci` passed successfully.
- Full acceptance suite passed: **73 scenarios, 489 steps**.
- Evidence shows coverage for:
  - signed-out `/get-started` email-only verification;
  - sign-in token creation with `return_to=/get-started`;
  - verified signed-in request form;
  - signed-in identity with no Person;
  - signed-in identity with existing Person;
  - Staff inbox visibility for verified submitted requests;
  - no Staff notification and no Staff-visible request for email-only verification;
  - no Membership Person/club/membership/access creation during verified request submission.
- No manual checks required for merge based on the supplied evidence.