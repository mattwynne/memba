# Iteration 031 Implementation Review

**Run ID:** 01KTP93QJMPN6T387GRBVC1QXN  
**Plan:** `docs/iterations/031-brand-email-navigation-polish/plan.md`  
**Commit range:** `f8dc9335a51468eb9e94b0e2a8637d22ea75be8e..HEAD`

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The implementation appears to conform to the ADR-relevant architecture for the touched areas, especially the transactional-email footer direction introduced around this work.

Evidence indicates:

- A reusable transactional footer component exists and is used by the sign-in and rejection emails.
- The footer uses the shared Memba sprig/logo branding rather than local one-off markup.
- The footer is tested independently and in-context.
- The implementation did not replace ADR-directed shared email layout/component infrastructure with local per-template substitutes.
- The public club-page root-home navigation uses a host-aware URL helper rather than a relative `/` link, preserving correct behaviour from club subdomains.

No ADR conflict is visible in the collected evidence.

## ADR violations

None.

## Blocking issues

None.

The implementation passed `dev ci`, including the full automated suite and 77 acceptance scenarios. I do not see a behavioural gap or missing safety coverage that should block merge.

## Bounded-safe fixes

None identified.

The implementation looks appropriately scoped and does not need a mandatory clean-up pass before merge.

## Judgement-worthy non-blocking code-health findings

1. **Root-domain derivation is starting to become domain-routing logic**

   - **Files:** `web/lib/club_site_web.ex`
   - **Smell:** The helper that produces the main Memba root URL from a club-site context appears to rely on host parsing/subdomain stripping.
   - **Why it may need human judgement:** This is fine for the current iteration, especially with tests proving that club-subdomain pages link back to the main Memba host rather than `/`. If Memba adds more host families later — staff, API, custom club domains, regional domains, staging domains — this logic may want to move into a dedicated URL/domain configuration module rather than accumulating string-shaping rules in the club web layer.

2. **Contextual sender display-name format is inline**

   - **Files:** `web/lib/memba/messaging/inbound/reject_message.ex`
   - **Smell:** The rejection email sender name uses the product-specific format `<club name> via Memba` directly at the call site.
   - **Why it may need human judgement:** This is not duplicated enough to justify extraction now. If future transactional emails also use contextual sender names — for example, organizer names, club names, or activity names “via Memba” — a small sender identity helper may avoid inconsistent formatting.

3. **Support contact remains partly hardcoded**

   - **Files:** `web/lib/memba_web/components/email_layout/transactional_footer.ex`, rejection email content/templates
   - **Smell:** `support@memba.io` appears to be used as a literal in email-facing copy/component defaults.
   - **Why it may need human judgement:** This is acceptable for current production behaviour. If support contact details become environment-specific, tenant-specific, or need operational rotation, centralizing the support address in application configuration would reduce future maintenance risk.

4. **Email rendering correctness is covered structurally, not client-realistically**

   - **Files:** email rendering tests for sign-in and rejection emails
   - **Smell:** Tests verify the generated HTML shape, sprig/footer presence, sender shape, and copy, but do not verify rendering in real email clients.
   - **Why it may need human judgement:** This is normal for the current automated suite and should not block. If transactional email presentation becomes more business-critical, preview tooling or real-inbox smoke checks could catch issues that DOM assertions cannot, such as client-specific SVG/CSS/footer rendering quirks.

## Suggested fixes

No required fixes before merge.

Future optional improvements, if related work touches these areas:

- Centralize public/root host generation if more domain patterns are introduced.
- Extract a small sender-name builder if more emails use “via Memba” display names.
- Move support contact details to shared config if the address needs environment or operational flexibility.

## Validation notes

Relevant completed validation:

- `dev ci` passed successfully.
- Acceptance suite passed: **77 scenarios, 502 steps**.
- Evidence shows coverage for:
  - homepage volunteering-first copy;
  - public club page link back to the main Memba home URL;
  - prevention of relative `/` links from club subdomains;
  - sign-in email Memba sprig branding;
  - sign-in email transactional footer;
  - inbound rejection email sender display name;
  - inbound rejection email transactional footer;
  - reusable transactional footer component behaviour.

Optional manual checks before release, not merge blockers:

- Send a sign-in email to a real inbox and verify the sprig/footer render acceptably.
- Send a club-message rejection email and verify the provider displays `<club name> via Memba` as intended.
- Click the public club-page “Memba home” link from a real club subdomain/staging host and confirm it lands on the main Memba homepage.