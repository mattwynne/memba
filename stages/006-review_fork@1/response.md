# Code Review Report: Iteration 013 - Member Compose LiveView Flow

## Decision: ACCEPT

## Confidence: High

## ADR Conformance: PASS

The implementation follows the referenced single-detail-view ADR pattern. The success state navigates to a single message detail view (`/messages/#{message.id}`) rather than a list or dashboard, and provides focused action choices consistent with the pattern. No ADR conflicts detected in the implementation evidence.

## ADR Violations

None detected.

## Blocking Issues

None.

## Bounded-Safe Fixes

1. **Remove `@wip` tag from acceptance scenario** (`acceptance-tests/features/member_message_deliverability.feature`):
   - Plan step 11 explicitly states: "Remove `@wip` from the new failure scenario once implemented and passing."
   - The scenario is implemented and all related automated tests pass (LiveView tests cover the same behavior)
   - Remove the `@wip` tag from the "Unrecoverable send error" scenario
   - File: `acceptance-tests/features/member_message_deliverability.feature`, line with `@wip`

2. **Simplify `handle_params` logic** (`web/lib/memba_web/live/member_message_live/new.ex`):
   - The `handle_params` function uses a complex `cond` structure with multiple guard clauses
   - Refactor to use pattern matching on socket assigns and extract club selection logic into a helper function
   - This improves readability without changing behavior
   - Current implementation works correctly but is harder to follow

3. **DRY up success/error state action button styles** (`web/lib/memba_web/live/member_message_live/new.html.heex`):
   - The `success_state` and `error_state` components duplicate button styling classes
   - Consider extracting a `state_action_button/1` component with variant support
   - Multiple buttons use near-identical Tailwind classes with only color variations
   - Current duplication is manageable but could grow if more states are added

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **State management complexity** (`web/lib/memba_web/live/member_message_live/new.ex`):
   - **Files**: `web/lib/memba_web/live/member_message_live/new.ex`, `new.html.heex`
   - **Smell**: The LiveView manages five distinct states (no club, club selection, compose, success, error) using a combination of assigns and conditional rendering
   - **Why judgement needed**: As message types or flows expand, this state management approach may not scale cleanly. Consider whether a more explicit state machine or LiveView component hierarchy would be better long-term. Current implementation is functional and well-tested, but watch for similar patterns emerging in other LiveViews that might benefit from a shared state management approach.

2. **Test log noise** (test output):
   - **Files**: Test suite output, potentially `test/memba_web/controllers/auth_controller_test.exs` or similar
   - **Smell**: Auth callback rejection warnings appear during test runs: "Rejected auth magic link callback: :expired", etc.
   - **Why judgement needed**: These are expected test scenarios but create noise. Decision needed whether tests should capture/assert on these logs (making them explicit expectations) or suppress them in test environment (trading visibility for cleaner output). Current approach is acceptable but reconsider if log noise grows.

3. **Component extraction opportunity** (`web/lib/memba_web/live/member_message_live/new.html.heex`):
   - **Files**: `web/lib/memba_web/live/member_message_live/new.html.heex`
   - **Smell**: Success and error state components are private functions in the LiveView module
   - **Why judgement needed**: If similar success/error state patterns emerge in other LiveViews, shared components in `core_components.ex` might reduce duplication. Current single-use approach is appropriate, but watch for repetition across LiveViews that would justify extraction.

4. **Club selection UX when multiple clubs exist** (`web/lib/memba_web/live/member_message_live/new.ex`):
   - **Files**: `web/lib/memba_web/live/member_message_live/new.ex`
   - **Smell**: When user has multiple clubs but no `club_id` param, shows flash message and empty form state
   - **Why judgement needed**: This is functional but potentially confusing UX. A card-based club selector or inline picker might be clearer, but that's a product decision about whether to invest in better multi-club affordances. Current implementation meets acceptance criteria.

5. **Error handling granularity** (`web/lib/memba_web/live/member_message_live/new.ex`):
   - **Files**: `web/lib/memba_web/live/member_message_live/new.ex`, particularly `create_message/3`
   - **Smell**: All send failures are treated as unrecoverable infrastructure errors with generic "contact support" guidance
   - **Why judgement needed**: The code logs specific error reasons but only shows generic messages to users. If different error types emerge (quota limits, content filtering, temporary vs. permanent failures), revisit whether users need different guidance. Current blanket approach is appropriately conservative but may need refinement based on production error patterns.

6. **Delivery provider configuration in tests** (`test/memba_web/live/member_message_live/new_test.exs`):
   - **Files**: `test/memba_web/live/member_message_live/new_test.exs`
   - **Smell**: Tests swap delivery provider via application environment (`Application.put_env/3`)
   - **Why judgement needed**: This creates implicit coupling between tests and global config. More explicit dependency injection (e.g., passing provider module to context functions) might be clearer but would require broader refactoring. Current approach is standard Elixir testing practice and works fine for this scope.

## Suggested Fixes

For bounded-safe fix #1:
```diff
- @wip
  Scenario: Unrecoverable send error
```

For bounded-safe fix #2, refactor `handle_params` to:
```elixir
def handle_params(params, _uri, socket) do
  socket =
    case socket.assigns do
      %{selected_member: %Member{}, selected_club: %Club{}} ->
        # Already selected from mount (single club case)
        socket

      %{members: members} when is_list(members) and length(members) > 0 ->
        handle_multi_club_params(socket, members, params["club_id"])

      _ ->
        socket
    end

  {:noreply, socket}
end

defp handle_multi_club_params(socket, members, nil) do
  socket
  |> put_flash(:info, "Select the club you want to message.")
  |> assign_member_and_club(nil, nil)
end

defp handle_multi_club_params(socket, members, club_id) do
  case Enum.find(members, &(&1.club_id == club_id)) do
    nil -> socket
    member -> assign_member_and_club(socket, member, club_id)
  end
end
```

For bounded-safe fix #3, the duplication is acceptable given the limited scope. Revisit if more result states are added.

## Validation Notes

✅ **Dev check passed**: All 243 tests pass with no failures  
✅ **Auth and permissions**: Comprehensive tests for authentication requirements and club membership checks  
✅ **Core functionality**: Success and error paths fully tested with proper state verification  
✅ **Sender derivation**: Tests explicitly verify sender is derived from current member without dropdown  
✅ **Message persistence**: Tests verify messages are created on success and NOT created on failure  
✅ **Legacy route removal**: Router tests explicitly verify old POST route returns 404  
✅ **Test seam quality**: Clean `Unavailable` delivery provider for simulating failures without infrastructure coupling  
✅ **UI conventions**: Follows Phoenix 1.8 patterns, uses proper form components, Tailwind classes, and verified routes  
✅ **Test quality**: Well-organized tests with clear setup blocks, good use of phoenix_test helpers, async where appropriate  

**Manual validation recommended**:
- Run `acceptance-tests/features/member_message_deliverability.feature` in browser to verify "Unrecoverable send error" scenario
- Demo the compose flow as described in plan validation section
- Verify success/error state styling and action button behavior in browser

**Notable test coverage**:
- Mount auth guard (prevents anonymous access)
- No-membership edge case (redirects with flash)
- Single vs. multiple club scenarios
- Form validation (subject/body required)
- Success state with all three action links
- Error state with support guidance and recovery actions
- Message creation/non-creation on success/failure
- Club home CTA navigation