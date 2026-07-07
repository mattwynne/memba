### Decision
**VALID**

### Evidence
- Completed todo/check-off evidence found.
  - `/tmp/fabro-pre-validate-snapshot.md` shows a clean validation snapshot.
  - Live `git status --short` and `git diff` are clean.
  - Recent implement checkpoint `64209c2 fabro(...): implement_next_task (succeeded)` changes exactly one ordinary todo line:
    - task `004` from `- [ ]` to `- [x]`.
  - The parent todo state shows task `004` was the first unchecked task after `001`–`003`.

- Implementation artifacts found.
  - `web/lib/memba_web/controllers/page_html/message.html.heex` now wraps the subject and follow control in:
    - `#member-message-heading-row.detail-head`
    - `.detail-head__main`
    - `h1#member-message-subject`
  - The existing `#member-conversation-follow-control` was moved into the detail-head row beside the title while preserving current follow/unfollow card/button behavior for later tasks.
  - `web/test/memba_web/live/member_message_live/show_test.exs` adds a focused LiveView assertion that the subject and follow control render as direct children/contents of the detail-head row.
  - No acceptance `.feature` files were changed.

- Tests run/results found.
  - I reran:
    - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs`
  - Result: passed, `11 tests, 0 failures`.
  - The implementation summary also reports the reply regression test and `dev check` passing.

- ADR/plan conformance notes.
  - Work matches plan task `004` only: structural HEEx placement of the subject and existing follow control in the `detail-head` row.
  - It does not prematurely implement task `005`/`006` toggle behavior, task `008` composer ordering, or task `009` card treatment.
  - No routing, server-side events, permissions, business rules, delivery behavior, or acceptance coverage were changed.
  - The checkpoint is small and independently useful.

{"context_updates":{"task_valid":true,"task_retry_available":false}}