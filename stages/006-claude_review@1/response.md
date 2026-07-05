# Iteration 044 Review: Shared App Shell

## Decision: REJECT

## Confidence: High

## ADR Conformance: CANNOT ASSESS

**Limitation**: The plan does not cite specific ADRs, and no ADR files from `docs/adr/` are included in the review context. Without access to ADRs governing layout architecture, CSS organization, authentication/identity handling, or component structure, I cannot provide a definitive PASS/FAIL assessment of ADR conformance. No obvious violations of standard Phoenix/LiveView patterns were detected, and the implementation follows the plan's explicit architectural decisions (CSS porting approach, shared layout strategy, identity assign pattern).

## ADR Violations

None detected (but see ADR conformance limitation above).

## Blocking Issues

1. **Email-local-part fallback missing**: The plan's Implementation Plan step 4 explicitly specifies: "add `member_name` (derived from the member as `member.name || local_part_of(member.email)`, or a similar small computation/helper)". The implementation assigns `member.name` directly without a fallback:

   ```elixir
   # In controllers/LiveViews (lib/memba_web/controllers/club_home_controller.ex, etc.)
   conn |> assign(:member_name, member.name)  # No fallback
   ```

   **Impact**: If `member.name` is nil, `member_name` will be nil, causing the identity dropdown (including the Sign out button) to be hidden due to `<%= if assigns[:member_name] do %>` in the layout. This prevents signed-in members without names from signing out via the UI — a behavioural gap.

   **Evidence**: The plan's technical decision states "with an email-local-part fallback", and the validation plan does not test this case. All test members provide names, masking the gap.

   **Fix required**: Controllers should compute `member_name` with the email fallback before assigning. Example:
   ```elixir
   member_name = member.name || email_local_part(member.email)
   conn |> assign(:member_name, member_name)
   ```
   A small helper to extract the email local part (e.g., `"alice@example.com" -> "alice"`) should be added, and tests should cover a member with nil name showing the dropdown with email-derived initials.

## Bounded-Safe Fixes

1. **Empty string initials edge case**: The `Layouts.initials/1` function (lib/memba_web/components/layouts.ex) correctly handles `nil` by returning `"?"`, but an empty string `""` would match the first clause and return `""` instead of `"?"`:

   ```elixir
   # Current:
   def initials(name) when is_binary(name) do
     name |> String.split() |> Enum.take(2) |> Enum.map(&String.first/1) |> Enum.map(&String.upcase/1) |> Enum.join()
   end
   def initials(_), do: "?"
   
   # initials("") returns "", not "?"
   ```

   **Fix**: Add a guard clause before the main binary clause:
   ```elixir
   def initials(""), do: "?"
   def initials(name) when is_binary(name) do
     # ... existing logic
   end
   def initials(_), do: "?"
   ```

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Files**: `lib/memba_web/components/layouts/club_site.html.heex`, `web/assets/css/app.css`  
   **Smell**: CSS-only dropdown interaction using `:hover` does not work on touch devices  
   **Why judgement**: The identity dropdown uses `data-dropdown` with CSS `:hover` to show/hide the menu. On mobile/touch devices, users cannot hover, so they might be unable to open the dropdown to sign out. This is a UX gap but not a blocking bug — the plan does not specify mobile/accessibility requirements, and adding touch/click handling is a future enhancement. Consider whether mobile support is required before merge or acceptable as follow-up work.

2. **Files**: `lib/memba_web/controllers/club_home_controller.ex`, `lib/memba_web/live/member_conversation_live/show.ex`, `lib/memba_web/live/member_message_detail_live/show.ex`, `lib/memba_web/live/member_message_compose_live/show.ex`  
   **Smell**: Repetitive code — four locations each assign `club_name` and `member_name` identically  
   **Why judgement**: The duplication is minimal (2 assigns per location, 4 locations), and extracting into a plug might add indirection without clear benefit. However, as more shared-layout assigns are added (e.g., member role for badges in a future iteration), this duplication could grow. Consider whether a shared plug or mount helper for club-site assigns would reduce future maintenance burden.

## Suggested Fixes

### To unblock (blocking issue #1):

**Step 1**: Add an `email_local_part/1` helper to `lib/memba_web/components/layouts.ex`:
```elixir
defp email_local_part(email) when is_binary(email) do
  email |> String.split("@") |> List.first()
end
defp email_local_part(_), do: nil
```

**Step 2**: Update all four controllers/LiveViews to use the fallback:
```elixir
# In ClubHomeController.show, MemberConversationLive.mount, etc.
member_name = member.name || email_local_part(member.email)
conn |> assign(:member_name, member_name)
# (or socket |> assign(:member_name, member_name) for LiveViews)
```

**Step 3**: Add a test for the fallback behavior in `test/memba_web/components/layouts_test.exs`:
```elixir
test "identity dropdown shows email-derived initials when member has no name" do
  html = render_component(&club_site/1,
    club_name: "Alpine Club",
    member_name: "alice",  # derived from "alice@example.com"
    inner_block: fn _, _ -> ~H"" end
  )
  
  assert html =~ ~s(<div class="identity-initial">A</div>)
  assert html =~ ~s(<div class="identity-name">alice</div>)
end
```

And add an integration test to `test/memba_web/controllers/club_home_controller_test.exs` (or similar) that creates a member with `name: nil` and verifies the dropdown appears.

### For bounded-safe fix #1 (empty string initials):

In `lib/memba_web/components/layouts.ex`, add before the main clause:
```elixir
def initials(""), do: "?"
```

## Validation Notes

- **dev check**: Passed (green) — all existing tests pass, but the email fallback case is not covered
- **Automated tests**: Cover app-bar rendering, identity dropdown presence/absence, sign-out form structure, and all club_site surfaces rendering with the app shell. However, no test verifies the email fallback for members without names.
- **Manual validation**: The plan's step 13 (gallery-walk comparison to design-system wireframes) is a manual step not verifiable from the review evidence. Assuming this was completed as part of the implementation-conformance workflow.
- **Plan conformance**: The implementation-conformance workflow marked this as plan-conforming, but the email fallback (an explicit step in the Implementation Plan) is missing. This suggests the conformance check may have focused on structural/visual conformance rather than line-by-line step verification.

---

**Summary**: The implementation delivers the core app shell capability (shared layout, app-bar, identity dropdown, app-card wrapper, design-system CSS porting) successfully. However, the explicit email-local-part fallback specified in the plan is missing, creating a behavioural gap where members without names cannot sign out. This must be implemented and tested before merge. The empty-string initials edge case is a low-risk fix. Mobile dropdown UX and controller duplication are non-blocking but worth noting for future work.