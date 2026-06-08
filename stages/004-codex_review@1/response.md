## Decision: READY

## Confidence: High

I read the complete plan file directly from `docs/iterations/030-verified-onboarding-requests/plan.md` through line 168.

## Blocking gaps

1. None.

## Non-blocking improvements

1. The `## Open Technical Decisions` section lists implementation-discovery items. They do not block readiness, but the plan would be clearer if they were renamed to “Implementation notes” or explicitly marked “non-blocking.”
2. The plan could name likely Phoenix modules/files once known, such as the Get Started controller/LiveView, auth token/session modules, onboarding request context, Staff inbox UI, and mailer modules. The current implementation plan is still clear enough to proceed.
3. Consider adding an explicit acceptance criterion that invalid/expired magic links continue to use the existing auth failure behaviour and do not create requests or Staff notifications. This is likely covered by “existing general magic-link sign-in keeps working,” but could be more objective.
4. Consider adding a small copy/UX note for the email-first step so implementation preserves the intended “low-friction” experience.

## Smallest viable iteration

The smallest useful slice is the plan as written: signed-out visitors enter only email, verify through the existing magic-link flow, return signed in to complete the request, and only then create a Staff-visible onboarding request/notification. Splitting this smaller would either leave Staff still exposed to unverified requests or introduce verification without an end-to-end usable request flow.

## Required plan edits

None required.

## Validation plan

Success can be proven by:

1. Updating `acceptance-tests/features/request_account.feature` with the planned stakeholder-readable scenarios.
2. Adding web/controller/LiveView tests for:
   - signed-out email-only Get Started step;
   - magic-link `return_to` back to Get Started;
   - verified requester with no existing Person;
   - verified requester with existing Person;
   - abandoned email-only verification creating no Staff-visible request and no Staff notification.
3. Adding domain/context tests proving verified request submission:
   - requires a signed-in verified identity email;
   - does not trust a typed requester email;
   - does not create Person, club, membership, or club access.
4. Verifying Staff workflows still work for verified requests:
   - active inbox lists verified submitted requests;
   - rejection retains existing behaviour;
   - conversion creates/reuses Person correctly, creates club and first membership, removes the request from active inbox, and sends welcome email.
5. Running the updated Cucumber scenarios with `@todo-domain` / `@todo-ui` removed or narrowed as appropriate.
6. Running `dev check`.
7. Stop condition: verified onboarding request behaviour is implemented end-to-end, all relevant automated tests pass, and `dev check` passes.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}