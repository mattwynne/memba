# Iteration 044 Review: Shared App Shell

## Decision: REJECT

## Confidence: High

## ADR conformance: PASS

No ADR violations were evident from the supplied plan/evidence. The plan does not cite a specific ADR, and this iteration is primarily Phoenix layout/CSS/UI plumbing rather than domain modeling, CQRS, event-sourcing, aggregates, projections, or read-model architecture. The implementation appears to keep the shared shell in the Phoenix layout layer and does not appear to replace ADR-style infrastructure with local substitutes.

## ADR violations

None found.

## Blocking issues

1. **Missing email-local-part fallback for signed-in member display name**

   The iteration plan explicitly decided that signed-in member surfaces should pass a new optional `member_name` assign with an email-local-part fallback:

   > “Identity name/initials plumbing: decided — a new optional `member_name` assign on `club_site`, passed by the four signed-in member surfaces, with an email-local-part fallback…”

   The implementation evidence indicates the signed-in surfaces assign `member.name` directly, for example:

   ```elixir
   assign(:member_name, member.name)
   ```

   If `member.name` is `nil`, `member_name` is also `nil`. The layout then uses the presence of `member_name` to render the identity dropdown. That means a valid signed-in member without a stored name may not see the identity dropdown or its Sign out action.

   This is both a plan-fidelity gap and a behavioural/coverage gap. Existing tests pass because test members appear to provide names, so the nil-name case is not exercised.

## Bounded-safe fixes

1. **Harden `Layouts.initials/1` for blank strings**

   If `Layouts.initials/1` receives `""` or whitespace-only input, it can produce an empty string instead of a fallback such as `"?"`.

   This is low-risk to fix while addressing the display-name fallback issue, especially if member names can be blank strings as well as `nil`.

## Judgement-worthy non-blocking code-health findings

1. **Files:** `lib/memba_web/components/layouts/club_site.html.heex`, `web/assets/css/app.css`  
   **Smell:** Identity dropdown appears to rely on CSS hover/focus-style interaction rather than an explicit LiveView/JS click interaction.  
   **Why it may need human judgement:** This is acceptable for a first shared-shell slice if the design-system mirror uses the same behaviour, but it may be fragile on touch devices and for keyboard/accessibility expectations. I would not block this iteration on it unless mobile/touch sign-out access is a current requirement.

2. **Files:** `lib/memba_web/controllers/club_home_controller.ex`, `lib/memba_web/live/member_conversation_live/show.ex`, `lib/memba_web/live/member_message_detail_live/show.ex`, `lib/memba_web/live/member_message_compose_live/show.ex`  
   **Smell:** Shared shell assigns such as `club_name` and `member_name` are repeated across multiple signed-in club surfaces.  
   **Why it may need human judgement:** The duplication is currently small and understandable. However, future slices mention role badges/member metadata; if more shell identity data is added, this could drift. A small helper or plug may become worthwhile, but extracting now is optional.

## Suggested fixes

To unblock:

1. Add a single helper for deriving the member display name, treating nil and blank names as missing:

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

   Place this somewhere appropriate for web/UI identity display logic, then use it consistently from the four signed-in member surfaces.

2. Update the four signed-in club surfaces to assign the derived name, not `member.name` directly.

3. Add automated coverage for a signed-in member with `name: nil`, preferably at one rendered surface level, verifying that:
   - the app shell still renders,
   - the identity dropdown is present,
   - the display name uses the email local part,
   - the Sign out form/action remains available.

4. Harden `Layouts.initials/1` for blank/whitespace input, for example:

   ```elixir
   def initials(name) when is_binary(name) do
     name
     |> String.trim()
     |> case do
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

5. Re-run the required project check after the fix.

## Validation notes

- `dev check` / `dev ci` passed before review.
- The acceptance run reported `85 scenarios (85 passed)` and `523 steps (523 passed)`.
- The green check is meaningful for the existing behaviour, but it does not cover the explicit nil-name/email-fallback case required by the plan.
- No feature-file changes are requested.
- The main shared-shell capability appears implemented: shared `club_site` app frame/card, app bar, identity dropdown for signed-in surfaces, public-page gating, and CSS component class porting. The rejection is limited to the missing fallback and test coverage for that plan-required behaviour.