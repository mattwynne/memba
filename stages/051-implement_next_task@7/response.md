Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `007 Add/update Phoenix/LiveView/rendered tests for: ported class usage on message entries/composer/title;`

2. **Changes made**
   - Updated `web/test/memba_web/live/member_message_live/show_test.exs`
   - Added a focused LiveView rendered test asserting the message detail page uses the ported design-system classes for:
     - `h1#member-message-subject.page-title`
     - original and reply `.message` entries
     - `.message--original`
     - `.message__avatar`
     - `.message__body`
     - `.message__head`
     - `.message__name`
     - `.message__time`
     - `.message__text`
     - `.message__menu`
     - `.message__kebab`
     - `.message-menu`
     - `.composer`
     - `.composer__head`
     - `.composer__title`
     - `.composer__as`
     - `.composer__actions`

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs`
     - Passed: `12 tests, 0 failures`
   - `git diff --check`
     - Passed
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `960 tests, 0 failures`

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 007 Add/update Phoenix/LiveView/rendered tests for: ported class usage on message entries/composer/title;`
   - To:
     - `- [x] 007 Add/update Phoenix/LiveView/rendered tests for: ported class usage on message entries/composer/title;`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan did not explicitly reference any ADRs for this task.
   - This task only adds Phoenix/LiveView rendered test coverage.
   - No acceptance feature files, routes, permissions, data model, commands/events/projections, notifications, or email behaviour were changed.
   - LiveView test guidance was followed by asserting key DOM IDs/classes with `has_element?/3` rather than raw HTML string matching.