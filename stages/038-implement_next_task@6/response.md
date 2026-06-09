1. **Selected todo line**
   - `- [ ] 006 Inspect inbound club-message rejection email construction and the email request/provider shape for display-name support.`

2. **Changes made for this task only**
   - Added inspection note:
     - `docs/iterations/031-brand-email-navigation-polish/task-006-inbound-club-rejection-email-inspection.md`
   - Documented:
     - inbound rejection email call path;
     - where club context is available;
     - current `from` construction;
     - Postmark/Resend/Swoosh display-name support;
     - implementation direction for task 007 without changing sender address, reply-to, support copy, or provider metadata/tags.
   - Updated only the selected todo line in:
     - `docs/iterations/031-brand-email-navigation-polish/todo.md`

3. **Focused validation commands run and results**
   - `git diff --check`
     - Passed.
   - Python trailing-whitespace check for changed markdown files, including the new untracked inspection note:
     - Passed: `No trailing whitespace in changed markdown files`
   - `git status --short`
     - Shows expected task changes only:
       - modified `todo.md`
       - new task 006 inspection note
   - I did **not** run `dev check` because this was a docs-only inspection/prose task, and project guidance says not to run it for docs-only changes.

4. **Exact todo check-off made**
   - Changed exactly:
     - `- [ ] 006 Inspect inbound club-message rejection email construction and the email request/provider shape for display-name support.`
   - To:
     - `- [x] 006 Inspect inbound club-message rejection email construction and the email request/provider shape for display-name support.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan did not explicitly reference any ADRs.
   - No architecture, provider boundary, delivery configuration, or application behaviour was changed.
   - ADR-style constraints previously noted for this iteration remain respected:
     - no provider-switching or Swoosh delivery boundary changes;
     - no acceptance feature changes;
     - no browser/UI behaviour changes.