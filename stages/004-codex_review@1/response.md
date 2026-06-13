## Decision: NOT READY

## Confidence: High

I read the complete plan file at `docs/iterations/032-auth-email-delivery-progress/plan.md` through line 143.

## Blocking gaps

1. **Business decisions are explicitly unresolved.**  
   The plan has an `## Open Business Decisions` section covering exact progress copy, timing thresholds, and unknown-email progress behavior. These directly affect acceptance criteria, privacy posture, and test expectations.

2. **Technical decisions are explicitly unresolved.**  
   The plan has an `## Open Technical Decisions` section covering persistence model, PubSub publishing surface, retention period, and old `/auth/check-email` behavior. The implementation plan gives defaults, but does not state that those defaults are final decisions.

3. **Acceptance criteria contain non-objective timing language.**  
   Criteria such as “short-lived,” “short period,” and “timing-sensitive first response” are not objectively testable without concrete values or explicit implementation policy.

4. **Fallback and failure-state behavior is under-specified.**  
   The plan says delayed, bounced, spam complaint, malformed, duplicate, and missing-correlation webhook events must be handled safely, but does not define the resulting persisted states, UI states, or whether any requester-visible copy changes.

## Non-blocking improvements

1. Name likely modules/files to reduce implementation ambiguity, such as auth LiveView modules, Postmark webhook controller, mailer/auth email module, migration location, and test files.

2. Define the expected status/state machine for auth email progress, for example `requested`, `sending`, `provider_accepted`, `delayed`, `failed_internal`, `expired`, while keeping requester-visible UI neutral.

3. Clarify whether operational diagnostics may expose more detail to logs/admin-only contexts while requester UI remains anti-enumeration safe.

4. Add an explicit stop condition such as: “The iteration is complete when the feature scenarios pass without todo tags, targeted tests pass, and `dev check` passes.”

## Smallest viable iteration

The smallest useful slice is:

- Create an opaque auth-email request record for every submitted email address.
- Redirect both known and unknown submissions to the same request-ID-based check-email page.
- For known recipients, attach correlation metadata to the Postmark auth email.
- Record Postmark provider-accepted webhook events and update the LiveView.
- Keep unknown/failed/no-webhook UI neutral.
- Add BDD scenarios and focused automated tests for known accepted delivery and unknown-address privacy.

Defer richer diagnostic/failure distinctions, retention automation beyond a simple expiry policy, and old-route refinements unless necessary for compatibility.

## Required plan edits

1. Replace `## Open Business Decisions` with finalized decisions for:
   - exact or approved-progress copy,
   - fallback timing threshold,
   - unknown-email progress behavior,
   - whether artificial delay is used or explicitly avoided.

2. Replace `## Open Technical Decisions` with finalized decisions, or explicitly state that the listed defaults are binding for implementation:
   - simple Ecto table vs event-sourced/projection flow,
   - PubSub/read-model-change publishing surface,
   - retention duration,
   - old `/auth/check-email` behavior.

3. Make timing-related acceptance criteria objective:
   - define “short-lived,”
   - define “short period,”
   - define any minimum/maximum response-delay policy needed for anti-enumeration.

4. Define expected behavior for delayed, bounced, spam complaint, malformed, duplicate, and missing-correlation webhook events:
   - persisted state change,
   - idempotency behavior,
   - requester-visible UI behavior,
   - logging/diagnostic behavior if relevant.

## Validation plan

To prove the iteration succeeded:

1. Add/update shared Cucumber scenarios in `acceptance-tests/features/authentication.feature` for:
   - known user sees provider-accepted progress,
   - unknown email receives indistinguishable neutral waiting experience.

2. Add focused persistence/context tests for auth-email request creation, opaque request lookup, status transitions, expiry/retention expectations, and idempotency.

3. Add mail construction tests proving known-recipient auth emails include Postmark metadata with the opaque request correlation and correct auth stream.

4. Add webhook controller tests for delivered/provider-accepted, delayed, bounced, spam complaint, malformed payload, duplicate event, and missing correlation.

5. Add LiveView tests proving:
   - neutral initial copy,
   - no account-existence disclosure for unknown requests,
   - live update after committed provider-accepted state,
   - fallback guidance when no accepted event arrives within the finalized threshold.

6. Confirm existing sign-in-link behavior still works for known members/staff and remains unavailable to unknown users.

7. Run the updated acceptance scenarios after removing or narrowing todo tags.

8. Run `dev check` before completion.

{"context_updates":{"codex_review_decision":"NOT READY","codex_review_confidence":"High","codex_review_blocking_gap_count":4,"codex_review_blocking_gaps":"Business decisions remain open for copy, timing thresholds, and unknown-email progress; Technical decisions remain open for persistence, PubSub surface, retention, and old route behavior; Timing-related acceptance criteria are not objectively testable; Failure and fallback state behavior for webhook edge cases is under-specified","codex_review_required_edits":"Finalize business decisions or make defaults binding; Finalize technical decisions or make defaults binding; Replace vague timing terms with concrete thresholds/policies; Define persisted and UI behavior for delayed, bounced, spam complaint, malformed, duplicate, and missing-correlation events"}}