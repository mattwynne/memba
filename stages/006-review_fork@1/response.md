# Iteration 014 Implementation Review

## Decision: REJECT

## Confidence: High

## ADR Conformance: FAIL

---

## ADR Violations

1. **ADR-015: Single-URL club landing strategy - dispatcher pattern violated**

   **Evidence:**
   - ADR-015 states: "The PageController remains the **initial entry point and routing dispatcher** for `GET /?club_id=<club_id>`"
   - ADR-015 Consequences: "The controller handles public/marketing, auth dispatch, and fallback/forbidden rendering."
   
   **Implementation conflict:**
   ```elixir
   # router.ex - LiveView route comes FIRST with :require_auth
   scope "/", MembaWeb do
     pipe_through [:browser, :require_auth]
     live "/", MemberDashboardLive, :index
   end

   scope "/", MembaWeb do
     pipe_through :browser
     get "/", PageController, :index
   end
   ```
   
   The implementation places the LiveView route **before** the controller route, with `:require_auth` guarding it. This violates the ADR's explicit statement that the controller is the "initial entry point". Phoenix will attempt to match the LiveView route first for authenticated requests, bypassing the controller's dispatcher logic entirely.

   **Test contradiction reveals the problem:**
   - `member_dashboard_live_test.exs`: expects `302` redirect for logged-out user with club_id
   - `page_controller_test.exs`: expects `200` public page for logged-out user with club_id
   
   These tests describe the same scenario but expect opposite outcomes, suggesting the routing logic is broken or the tests are testing different routes inadvertently.

   **Controller redirect loop risk:**
   ```elixir
   # page_controller.ex
   if membership && membership.active do
     Phoenix.Controller.redirect(conn,
       to: ~p"/?#{%{club_id: club_id}}"
     )
   ```
   
   The controller redirects to the same path (`/?club_id=...`), which would create a loop unless Phoenix routing distinguishes between initial requests and redirects (non-standard behavior).

---

## Blocking Issues

1. **Routing architecture contradicts accepted ADR-015**

   The ADR mandates a dispatcher pattern where PageController is the initial entry point that checks auth/membership and either renders public/forbidden pages or redirects to LiveView. The implementation uses competing routes with unclear precedence.

   **Required fix:**
   Either:
   - Remove the `live "/"` route and have the controller use `Phoenix.LiveView.Controller.live_render/3` to render the LiveView inline (matching ADR dispatcher pattern), OR
   - Move the LiveView to a different path like `/dashboard` and redirect there, OR
   - Update ADR-015 to accept the dual-route, pipeline-based approach and document exactly how `:require_auth` determines route matching

2. **Test contradictions indicate incomplete integration**

   The LiveView and controller tests expect different behavior for the same scenario (logged-out user with club_id). One must be wrong, or the tests are not exercising the full routing stack.

   **Required fix:**
   - Verify which route actually handles logged-out users with club_id
   - Fix the incorrect test expectation
   - Add integration test that proves the complete flow: request → routing → auth check → appropriate handler

3. **Missing `:require_auth` plug definition**

   The router references `:require_auth` but the plug implementation is not in the evidence. Without seeing this plug, it's impossible to verify:
   - Whether it halts (preventing fallthrough to second scope)
   - Whether it redirects to login (contradicting plan's "public visitor sees public page")
   - Whether it has special LiveView-aware logic

   **Required fix:**
   Include `:require_auth` plug implementation in review evidence, or document its behavior clearly

---

## Bounded-Safe Fixes

1. **Inconsistent avatar_url nil handling**
   
   **Location:** `web/lib/memba_web/live/member_dashboard_live.html.heex`
   
   Active member card checks for nil avatar_url and shows fallback:
   ```heex
   <%= if member.avatar_url do %>
     <img src={member.avatar_url} ... />
   <% else %>
     <div class="... bg-gray-300 ...">
       <%= String.first(member.name) %>
     </div>
   <% end %>
   ```
   
   But receipt glance avatar stack doesn't check:
   ```heex
   <%= for avatar <- msg.receipt_glance.sample_avatars do %>
     <img src={avatar.avatar_url} alt={avatar.name} ... />
   <% end %>
   ```
   
   If `avatar.avatar_url` is nil, this renders `<img src="">`, creating broken images.
   
   **Fix:** Add the same nil check pattern to receipt glance avatars.

2. **Inefficient receipt glance building**

   **Location:** `web/lib/memba_web/member_dashboard_presentation.ex:build_receipt_glance/3`
   
   ```elixir
   defp build_receipt_glance(message, receipts, members) do
     message_receipts =
       Enum.filter(receipts, fn r -> r.message_id == message.message_id end)
     # ... uses Enum.filter again for delivered/failed/pending
   ```
   
   For 10 messages with 100 total receipts, this is O(n×m) = 1000 operations. Not critical at current scale, but could be optimized by grouping receipts by message_id once:
   
   ```elixir
   receipts_by_message = Enum.group_by(receipts, & &1.message_id)
   message_receipts = Map.get(receipts_by_message, message.message_id, [])
   ```

3. **Missing explicit test coverage for stated acceptance criteria**

   Plan §10 requires tests for:
   - Receipt glance renders with member-facing vocabulary (not tested)
   - Timestamp labels use `inserted_at` when available and omitted when unavailable (not tested)
   - Empty states render (not tested)
   - No operator-only fields leak (not tested)

   These are implicitly covered by template inspection, but explicit tests would provide regression protection.

---

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Presentation layer API could be simplified**

   **Location:** `web/lib/memba_web/member_dashboard_presentation.ex:load/3`
   
   ```elixir
   def load(club_id, current_user, clubs) do
     current_user_email = Map.get(current_user, :email)
     membership = Enum.find(clubs, &(&1.club_id == club_id))
   ```
   
   Function takes `current_user` map but only uses `:email`. Takes `clubs` list but only uses it to find one membership. Could be simplified to:
   
   ```elixir
   def load(club_id, current_user_email, membership)
   ```
   
   **Why judgement-worthy:** The current API might be intentional for future flexibility or consistency with other presentation modules. Simplification would reduce cognitive load but might not align with broader patterns.

2. **Query organization could be optimized with preloads**

   **Location:** `web/lib/memba_web/member_dashboard_presentation.ex:load/3`
   
   Loads messages, receipts, and members as three separate queries:
   ```elixir
   messages = Repo.all(from m in Message, ...)
   receipts = Repo.all(from r in MessageReceipt, ...)
   members = Repo.all(from m in Membership, join: p in Person, ...)
   ```
   
   Could potentially use Ecto preloads or a more sophisticated query strategy to reduce round-trips. However, at 10 messages max, the current approach is clear and maintainable.
   
   **Why judgement-worthy:** Premature optimization vs. simplicity trade-off. Current approach is readable and testable. Optimization would add complexity without proven need.

3. **Membership check repeats work already done by router/plug**

   **Location:** `web/lib/memba_web/member_dashboard_presentation.ex:load/3`
   
   ```elixir
   cond do
     is_nil(membership) ->
       {:error, :not_found}
     not membership.active ->
       {:error, :forbidden}
   ```
   
   This checks membership/active status that should have already been validated by the router/plug layer (according to ADR-015). Duplicating auth checks can lead to inconsistency if one location is updated but not the other.
   
   **Why judgement-worthy:** Defense-in-depth vs. DRY. Presentation layer should arguably trust that callers are authorized, but paranoid validation can catch bugs. Needs architectural judgement call.

---

## Suggested Fixes

### Critical (Must Fix Before Merge)

1. **Resolve routing architecture to match ADR-015**

   Option A (matches ADR exactly): Use controller as sole entry point
   ```elixir
   # router.ex - remove live "/" route
   scope "/", MembaWeb do
     pipe_through :browser
     get "/", PageController, :index
     # ... other routes
   end

   # page_controller.ex
   def index(conn, params) do
     # ... existing logic ...
     if membership && membership.active do
       Phoenix.LiveView.Controller.live_render(conn, MembaWeb.MemberDashboardLive, session: %{"club_id" => club_id})
     else
       render_forbidden(conn)
     end
   end
   ```

   Option B: Use separate LiveView path
   ```elixir
   # router.ex
   scope "/", MembaWeb do
     pipe_through [:browser, :require_auth]
     live "/dashboard", MemberDashboardLive, :index
   end

   # page_controller.ex
   if membership && membership.active do
     redirect(conn, to: ~p"/dashboard?#{%{club_id: club_id}}")
   ```

   Option C: Update ADR-015 to accept dual-route approach and document `:require_auth` behavior

2. **Fix test contradictions**

   Determine correct behavior for logged-out user with club_id, then fix either:
   - `member_dashboard_live_test.exs` to expect 200 public page, OR
   - `page_controller_test.exs` to expect 302 redirect

   Then add integration test proving full flow:
   ```elixir
   test "full routing flow for logged-out user with club_id" do
     club = create_club()
     conn = build_conn() |> get("/?club_id=#{club.club_id}")
     # Assert final outcome matches plan: public page rendered
     assert html_response(conn, 200) =~ "Climbing, backcountry ski"
   end
   ```

3. **Add `:require_auth` plug to evidence or document its behavior**

### Optional (Bounded-Safe)

4. **Add nil avatar_url check to receipt glance**

   ```heex
   <%= for avatar <- msg.receipt_glance.sample_avatars do %>
     <%= if avatar.avatar_url do %>
       <img src={avatar.avatar_url} alt={avatar.name} class="h-6 w-6 rounded-full ring-2 ring-white" />
     <% else %>
       <div class="h-6 w-6 rounded-full bg-gray-300 ring-2 ring-white flex items-center justify-center text-xs font-medium text-gray-600">
         <%= String.first(avatar.name) %>
       </div>
     <% end %>
   <% end %>
   ```

5. **Add explicit tests for untested acceptance criteria**

   ```elixir
   test "receipt glance shows member-facing vocabulary" do
     # Create message with receipts in various states
     # Assert template renders "delivered", "pending", "failed" (not operator terms)
   end

   test "message row omits timestamp when inserted_at is nil" do
     # Create message with nil inserted_at
     # Assert no <time> element rendered
   end
   ```

---

## Validation Notes

- `dev check` passed: ✅ All ExUnit tests green, compilation clean
- Browser Cucumber not run: ⚠️ Plan requires `acceptance-tests/features/member_message_deliverability.feature` but review stage didn't execute it
- Manual demo not performed: ⚠️ Review is code-only; validation plan items not verified

---

## Conclusion

**This iteration cannot be accepted** due to a critical ADR-015 violation. The routing implementation contradicts the accepted architecture decision that specifies the controller as the "initial entry point and routing dispatcher". The dual-route setup with unclear precedence creates fragility and produces contradictory test expectations.

The receipt glance implementation (ADR-016) is correct and well-structured. The LiveView template, presentation layer, and most tests are good quality. However, the fundamental routing architecture must be corrected before merge.

**Recommended action:** Fix routing to match ADR-015 dispatcher pattern (Option A or B above), resolve test contradictions, and resubmit for review.