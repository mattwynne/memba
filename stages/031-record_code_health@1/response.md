I’ll append the supported judgement-worthy review findings to `docs/code-health.md` in the project’s existing format, without changing product behaviour.CODE_HEALTH_RECORDING_FAILED: I’m unable to edit `docs/code-health.md` in this environment because no file-editing tools are available in the current API session.

Findings that still need recording under a dated section for `docs/iterations/030-verified-onboarding-requests/plan.md`:

1. **Verified-email invariant is enforced by the web caller rather than structurally encoded in the domain API**
   - Evidence: Reviewers noted `GetStartedController` correctly uses `identity.email`, but `Onboarding.create_onboarding_request/1` still accepts a raw attrs map including `requester_email`.
   - Risk: Future internal callers could accidentally bypass the verified-email requirement.
   - Suggested next action: Consider a context API such as `create_verified_onboarding_request(identity, attrs)` or `create_onboarding_request(verified_email, attrs)`.

2. **`/get-started` multiplexes signed-out verification and signed-in request submission**
   - Evidence: Same controller/template handles unauthenticated email collection and authenticated request submission based on `current_identity`.
   - Risk: Future additions like CAPTCHA, resend flows, rate limiting, or saved pre-verification state may make the route/template harder to maintain.
   - Suggested next action: Keep as-is for now; split helpers/templates/routes if workflow complexity grows.

3. **Email normalization may be duplicated**
   - Evidence: Signed-out Get Started flow manually trims/downcases email before creating the sign-in token.
   - Risk: Multiple local normalization implementations may drift across auth, membership, invitations, and onboarding flows.
   - Suggested next action: Search for repeated email normalization and consider a shared helper only if duplication is meaningful.

4. **Controller clause ordering carries implicit flow behaviour**
   - Evidence: Reviewers noted `GetStartedController` uses separate function clauses matching signed-in vs fallback states.
   - Risk: As states/param shapes grow, ordering mistakes could alter behaviour.
   - Suggested next action: Leave idiomatic clause matching for now; consider explicit helpers/conditionals if the controller grows.

The review synthesis omitted these human-judgement findings, but the independent reviewer reports consistently supported them.