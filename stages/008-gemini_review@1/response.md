# Iteration 044 Review: Shared App Shell

## Decision: REJECT

## Confidence: High

## ADR conformance: PASS

No ADR violations were evident from the supplied plan and implementation evidence. The plan does not cite specific ADRs, and this iteration appears limited to Phoenix layout/CSS/UI shell plumbing rather than domain modeling, Commanded aggregates, projections, event streams, read models, or CQRS infrastructure.

## ADR violations

None found.

## Blocking issues

1. **Missing required email-local-part fallback for signed-in member identity**

   The plan explicitly decided that signed-in member surfaces should pass a new optional `member_name` assign with an email-local-part fallback:

   > “Identity name/initials plumbing: decided — a new optional `member_name` assign on `club_site`, passed by the four signed-in member surfaces, with an email-local-part fallback…”

   The implementation evidence indicates the signed-in surfaces assign `member.name` directly, e.g. conceptually:

   ```elixir
   assign(:member_name, member.name)
   ```

   This is a plan-fidelity and behavioural gap. If a signed-in member has `name == nil`, then `member_name` is also `nil`. The shared layout gates the identity dropdown on the presence of `member_name`, so the dropdown — including the Sign out action — can disappear for a valid signed-in member.

   Existing tests passed because they appear to create members with names, so the nil-name fallback case is not covered.

## Bounded-safe fixes

1. **Harden `Layouts.initials/1` for blank or whitespace-only strings**

   The initials helper should treat `""` and whitespace-only names the same as missing names. Returning an empty avatar label is avoidable and low-risk to fix while touching the identity-display path.

2. **Add focused automated coverage for member identity fallback**

   Add at least one rendered signed-in club-surface test where the member has `name: nil` and a valid email. The test should verify that the app shell still renders the identity dropdown, displays the email local part, and includes the Sign out form/action.

## Judgement-worthy non-blocking code-health findings

1. **Files:** `lib/memba_web/components/layouts/club_site.html.heex`, `web/assets/css/app.css`  
   **Smell:** Identity dropdown interaction appears CSS-driven, likely hover/focus based.  
   **Why it may need human judgement:** This is acceptable if it intentionally mirrors the design-system shell for this slice, but it may be fragile for touch devices and keyboard/accessibility expectations. I would not block this iteration on it unless mobile/touch sign-out access is considered required for the current release.

2. **Files:** `lib/memba_web/controllers/club_home_controller.ex`, `lib/memba_web/live/member_conversation_live/show.ex`, `lib/memba_web/live/member_message_detail_live/show.ex`, `lib/memba_web/live/member_message_compose_live/show.ex`  
   **Smell:** Shared shell assigns such as `club_name` and `member_name` are repeated across multiple signed-in club surfaces.  
   **Why it may need human judgement:** The duplication is small today and may be clearer than premature abstraction. However, future iterations mention additional identity/member metadata such as role badges; if more shell assigns are added, a shared helper or plug-style assign path may prevent drift.

## Suggested fixes

To unblock:

1. Add a single helper for deriving the signed-in member display name, treating both `nil` and blank strings as missing:

   ```elixir
   def member_display_name(member) do
     member.name
     |> blank_to_nil()
     || email_local_part(member.email)
   end

   defp email_local_part(email) when is_binary(email) do
     email
     |> String.split("@", parts: 2)
     |> List.first()
     |> blank_to_nil()
   end

   defp email_local_part(_), do: nil

   defp blank_to_nil(value) when is_binary(value) do
     case String.trim(value) do
       "" -> nil
       trimmed -> trimmed
     end
   end

   defp blank_to_nil(_), do: nil
   ```

   Place it in an appropriate web/presentation-layer module or shared helper used by the signed-in club surfaces.

2. Update all signed-in `club_site` surfaces to assign the derived display name instead of `member.name` directly.

3. Add automated coverage for a signed-in member with no stored name. The test should prove:

   - the shared app shell renders,
   - the identity dropdown is present,
   - the displayed identity uses the email local part,
   - the Sign out form/action remains available.

4. Harden `Layouts.initials/1` for blank strings:

   ```elixir
   def initials(name) when is_binary(name) do
     case String.trim(name) do
       "" ->
         "?"

       trimmed ->
         trimmed
         |> String.split()
         |> Enum.take(2)
         |> Enum.map(&String.first/1)
         |> Enum.map(&String.upcase/1)
         |> Enum.join()
     end
   end

   def initials(_), do: "?"
   ```

5. Re-run the required project check after changes.

## Validation notes

- Pre-review working tree was clean.
- Sandbox check passed.
- `dev ci` / dev check passed before review.
- Acceptance output reported `85 scenarios (85 passed)` and `523 steps (523 passed)`.
- Green test output is meaningful for the existing covered paths, but it does not cover the explicit nil-name/email-local-part fallback required by the iteration plan.
- No feature-file changes are requested.
- The core shared-shell implementation appears otherwise aligned with the plan: shared `club_site` app frame/card, app bar, identity dropdown gating, public-page no-identity behavior, sign-out form wiring, and design-system CSS class porting. The rejection is limited to the missing required fallback and its coverage.