## 1. Decision: NOT READY

## 2. Confidence: Medium

## 3. What Codex fixed successfully

No successful fix is verifiable from the latest `Read Updated Plan` output.

Codex stated it would “tighten deterministic failure behavior” and “mark the plan as validated,” but the visible updated plan excerpt still shows the same implementation and validation sections, and does not visibly include the previously requested structural fixes.

Because the top 112 lines are omitted from the displayed output, it is possible some edits were made there, but the required fixes cannot be confirmed from the provided updated plan text.

## 4. Remaining blocking gaps

The same readiness blockers appear unresolved or unverifiable:

1. **Acceptance criteria are not visibly concrete/testable**
   - The visible plan has a “New Capability” and “Validation Plan,” but no clearly visible `## Acceptance Criteria` section with stakeholder-visible pass/fail outcomes.

2. **Behaviour-facing iteration lacks a visible `## Acceptance Scenarios / Feature Files` section**
   - This is required by the readiness standard for behaviour-facing work.
   - The plan references `member_message_deliverability.feature`, but the required dedicated section is not visible.

3. **Deterministic failure behaviour is still not visible**
   - Step 5 says to authorize active membership and ensure the message belongs to the club, but does not visibly define the expected outcome for:
     - unauthenticated access;
     - authenticated non-member access;
     - inactive-member access;
     - message/club mismatch.
   - The plan should specify whether these redirect, return 404, flash an error, or otherwise fail.

4. **Validated status is not visibly confirmed**
   - The stated goal is to mark the plan validated without implementation.
   - The visible updated text does not show a validation/status marker.

## 5. Follow-up repair instructions for Codex

Another Codex edit pass is justified because the fixes are editorial/structural and can be made from already-stated plan intent.

Please update `docs/iterations/011-member-facing-message-behaviour/plan.md` only. Do not start implementation.

Make these exact plan-only edits:

1. Add or expose a clear validation marker near the top, for example:

   ```md
   Status: Validated for implementation
   ```

2. Add an `## Acceptance Criteria` section with objective stakeholder-visible outcomes, derived from the existing plan. Include criteria such as:

   - An active member can send a club message from the member club home page.
   - An active member can open a member-facing message detail page for a message in their club.
   - The member-facing detail page shows subject, body, sender, and addressed members with member-friendly receipt labels/icons.
   - Member-facing pages do not expose operator-only delivery diagnostics.
   - Staff/admin diagnostics remain available unchanged under `/admin/messages/:message_id` and `/admin/deliveries`.
   - Non-members, inactive members, unauthenticated users, and club/message mismatches cannot view member message detail.

3. Add an `## Acceptance Scenarios / Feature Files` section naming the shared Cucumber feature file:

   ```md
   - `features/member_message_deliverability.feature`
   ```

   Briefly state that the `@wip` tag will be removed when the member-facing scenarios pass through the real member experience.

4. Add deterministic failure behaviour for member message detail authorization. Do not invent new UX if the app already has a convention; document the existing convention. If there is no existing convention, use the safest explicit implementation target already implied by the plan:

   - unauthenticated access redirects to the existing member sign-in/magic-link flow;
   - authenticated users without active membership for `club_id` are denied without exposing message details;
   - message/club mismatch is denied without exposing message details;
   - tests assert the chosen status/redirect and that no message content or operator-only fields leak.

5. Re-read the plan after editing and ensure the added sections are visible in the file.

## 6. Questions for Matt

None at this time. The remaining issues appear to be structural plan edits, not unresolved product decisions.

## 7. Final validation plan

The iteration will be considered successful when:

- `dev check` passes.
- `member_message_deliverability.feature` is untagged and passes.
- Browser evidence shows:
  - setup may use staff/admin routes;
  - Alice sends from an authenticated member session;
  - Alice and Bob view receipt statuses from authenticated member sessions;
  - member assertions do not navigate to `/admin/*`.
- Phoenix tests cover:
  - member route authorization;
  - message/club ownership checks;
  - receipt status label/icon mapping;
  - member detail rendering without operator-only fields.
- Staff/admin diagnostics remain unchanged on `/admin/messages/:message_id` and `/admin/deliveries`.
- The manual demo script remains available at `docs/iterations/011-member-facing-message-behaviour/manual-demo-script.md`.

{"context_updates":{"plan_ready":false,"plan_needs_fix":true,"plan_needs_human":false}}