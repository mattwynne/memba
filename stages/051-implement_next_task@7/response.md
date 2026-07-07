1. **Selected todo line**
   - `007 Add a per-message **⋮ menu** to conversation_entry_card (page_html.ex) with a Delivery details item linking to /messages/#{message_id}/delivery.`

2. **Changes made for this task only**
   - Added a per-message kebab menu in `conversation_entry_card/1`:
     - Stable menu/button/link IDs per message.
     - `Delivery details` menu item.
     - Link points to `/messages/:message_id/delivery` for that exact original/reply message.
     - Preserves club-host behavior and `ClubSite.url/2` behavior for non-host routes.
   - Updated `message.html.heex` to pass `@selected_club` and `club_id_source` into each conversation entry card.
   - Added focused LiveView test coverage proving both the original message and a reply render their own delivery-details menu links.
   - Checked off only task `007` in `docs/iterations/047-conversation-delivery-details/todo.md`.

3. **Focused validation commands run and results**
   - TDD failing check after adding the test:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs`
     - Failed as expected: missing `#member-conversation-entry-menu-...`.
   - Focused test after implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs`
     - Passed: `14 tests, 0 failures`.
   - Formatting:
     - `cd web && mix format --check-formatted lib/memba_web/controllers/page_html.ex lib/memba_web/controllers/page_html/message.html.heex test/memba_web/live/member_message_live/show_test.exs`
     - Passed.
   - Full validation on final worktree:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance: `85 scenarios (85 passed)`, `523 steps (523 passed)`.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 007 Add a per-message **⋮ menu** to conversation_entry_card (...)`
   - To:
     - `- [x] 007 Add a per-message **⋮ menu** to conversation_entry_card (...)`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Reviewed relevant accepted ADRs:
     - ADR 0015: kept member app behavior in LiveView.
     - ADR 0019: preserved host-based club routing and `ClubSite.url/2` URL generation.
     - ADR 0013: added user-visible web test coverage; used existing `Phoenix.LiveViewTest` style for this LiveView-specific test file.
     - ADR 0006: did not alter delivery status semantics.
   - No acceptance feature files changed.