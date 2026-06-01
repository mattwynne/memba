# Code Review Report: Iteration 011 - Member-Facing Message Behaviour

## Decision: ACCEPT

## Confidence: High

The implementation is solid, well-tested, and conforms to the plan. Dev check passed with 217 tests and 0 failures. The code follows Phoenix conventions, has comprehensive test coverage, and stays within scope. Minor refactoring opportunities exist but do not block merge.

## ADR Conformance: PASS

No specific ADRs were cited in the plan. The implementation follows established Phoenix/Elixir patterns without introducing architectural divergence:
- Uses plugs for authorization following Phoenix patterns
- Follows Phoenix controller/route conventions
- Presenter pattern is lightweight and doesn't replace infrastructure
- Test organization matches project structure

## ADR Violations

None identified.

## Blocking Issues

None identified.

## Bounded-Safe Fixes

1. **Return path construction in `ClubMemberRequired` plug** (`web/lib/memba_web/plugs/club_member_required.ex:21-22`):
   - Current code: `conn.request_path <> "?" <> conn.query_string`
   - Issue: Creates trailing `?` when query_string is empty
   - Fix:
     ```elixir
     return_path = if conn.query_string == "" do
       conn.request_path
     else
       "#{conn.request_path}?#{conn.query_string}"
     end
     redirect(to: "/auth?return_to=#{URI.encode_www_form(return_path)}")
     ```

2. **Unclear `with` pattern in `PageController.show_message/2`** (`web/lib/memba_web/controllers/page_controller.ex:18-20`):
   - Current code: `true <- message.club_id == club_id`
   - Issue: Unusual pattern matching on boolean literal; intent unclear
   - Fix: Extract to named validation function:
     ```elixir
     defp validate_club_ownership(message, club_id) do
       if message.club_id == club_id, do: :ok, else: {:error, :forbidden}
     end
     
     # Then in with:
     with {:ok, message} <- Memba.Messages.get_message(message_id),
          :ok <- validate_club_ownership(message, club_id) do
     ```
   - Add comment explaining both error branches return 404 to avoid leaking club membership info

3. **Missing security documentation for `raw()` call** (`web/lib/memba_web/controllers/page_html/show_message.html.heex:11`):
   - Current code: `<%= raw(@message.body_html) %>`
   - Issue: No visible comment explaining why `raw()` is safe
   - Fix: Add explanatory comment:
     ```heex
     <%!-- body_html is sanitized server-side when messages are created --%>
     <%= raw(@message.body_html) %>
     ```

4. **Hard-coded auth route in plug** (`web/lib/memba_web/plugs/club_member_required.ex:21`):
   - Current code: `redirect(to: "/auth?return_to=...")`
   - Issue: Couples plug to specific route string; reduces maintainability
   - Fix: Use route helper if available, or at least extract to module attribute:
     ```elixir
     @auth_path "/auth"
     # ... later:
     redirect(to: "#{@auth_path}?return_to=...")
     ```

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Query-string `club_id` pattern coupling** (files: `web/lib/memba_web/plugs/club_member_required.ex`, `web/lib/memba_web/controllers/page_controller.ex`, templates):
   - Smell: Query-string `club_id` now exists in multiple places (home, message detail, plug validation)
   - Why judgement-worthy: Plan acknowledges this is temporary until custom domains exist. When migrating to subdomain/path-based club context, all these locations need coordinated updates. Consider whether a higher-level "club context resolution" abstraction would smooth that future migration, or whether the current plug-based approach is sufficient.
   - Not blocking: Pattern is documented as temporary in plan, plug makes it reusable, tests cover it well.

2. **Message ownership validation error handling** (`web/lib/memba_web/controllers/page_controller.ex:29-35`):
   - Smell: Returns 404 for both "message not found" and "message belongs to different club"
   - Why judgement-worthy: Correct per plan (don't leak info about message existence or club membership), but makes debugging legitimate user errors harder (e.g., wrong club_id in manually constructed URL). Consider whether server-side logging of the actual rejection reason would help operations while preserving user-facing security.
   - Not blocking: Behaviour matches plan requirements; security-first approach is sound.

3. **Presenter pattern usage** (`web/lib/memba_web/presenters/message_presenter.ex`):
   - Smell: Uses struct-based presenter with module functions, slightly non-standard for Phoenix which typically uses view helpers or assigns
   - Why judgement-worthy: Pattern is clean and testable, but if it spreads to many presenters, consider documenting as project convention or consolidating into a shared helper pattern. Current implementation is fine, but project-wide consistency matters as the codebase grows.
   - Not blocking: Code is well-structured, tests are clear, pattern doesn't violate any conventions.

4. **Missing club_id format validation** (`web/lib/memba_web/plugs/club_member_required.ex:10-35`):
   - Smell: Plug accepts any string as `club_id` and passes to database query without format validation
   - Why judgement-worthy: Database query will fail safely on invalid format, but early validation would provide clearer error messages and avoid unnecessary DB calls. Depends on whether you want plug-level validation or rely on downstream layers. Current approach is defensible but could be more explicit.
   - Not blocking: Safe due to database constraints; no security or correctness issue.

5. **Template calls presenter module functions directly** (`web/lib/memba_web/controllers/page_html/show_message.html.heex:16-30`):
   - Smell: Template calls `MembaWeb.Presenters.MessagePresenter.status_icon(status)` and `member_status_label(status)` directly
   - Why judgement-worthy: Works but slightly verbose. Could assign function references in controller action for cleaner template syntax. Current approach is explicit and testable; cleaner approach would be more idiomatic Phoenix.
   - Not blocking: Code works, is testable, doesn't violate conventions.

## Suggested Fixes

Apply the four bounded-safe fixes listed above to improve code clarity and maintainability. All are low-risk refactorings that don't change behaviour:

1. Clean up return path construction in `ClubMemberRequired`
2. Extract club ownership validation to named function in `PageController`
3. Add security comment explaining `raw()` usage in template
4. Extract auth path to module attribute in `ClubMemberRequired`

The judgement-worthy findings are design considerations for future work, not fixes for this iteration.

## Validation Notes

- ✅ Dev check passed: 217 tests, 0 failures
- ✅ Plan conformance verified (prior stage)
- ✅ Acceptance tests updated: `member_message_deliverability.feature` untagged from `@wip`
- ✅ Implementation scope matches plan: member message detail, home page updates, member-friendly receipts
- ✅ Authorization coverage: unauthenticated redirects, non-member forbidden, message-club ownership validation
- ✅ Edge cases covered: missing club_id (400), invalid message_id (404), club mismatch (404)
- ✅ Presenter tests: status labels, icons, recipient grouping
- ✅ Route tests: pipeline configuration verified
- ✅ No operator-only diagnostics on member pages (per plan requirement)
- ✅ Staff/admin routes unchanged (per plan requirement)
- ✅ Step definitions use member sessions for assertions (per plan requirement)

**Test organization**: Tests are well-organized across controller tests, plug tests, presenter tests, and acceptance tests. Coverage is thorough for the added functionality.

**Manual validation**: Plan includes manual demo script at `docs/iterations/011-member-facing-message-behaviour/manual-demo-script.md` (not reviewed here but referenced).