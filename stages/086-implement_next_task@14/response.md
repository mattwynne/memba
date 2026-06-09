Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 014 Run focused tests for changed web templates/components and email rendering.`

2. **Changes made**
   - No code/config/test changes.
   - Checked off task 014 in `docs/iterations/031-brand-email-navigation-polish/todo.md` after focused validation passed.

3. **Focused validation run**
   - Initial root-relative `bin/mix test web/test/...` attempt hit the known sandbox/Postgres readiness/path issue, then a second attempt reached Mix but paths were incorrect because `bin/mix` changes into `web/`.
   - Successful focused command:
     ```sh
     PATH="$PWD/bin:$PATH:$DEVENV_PROFILE/bin" bin/mix test \
       test/memba_web/controllers/page_controller_test.exs \
       test/memba_web/club_site_test.exs \
       test/memba_web/components/layouts_test.exs \
       test/memba/accounts/auth_email_test.exs \
       test/memba/messaging/inbound_club_rejection_email_test.exs
     ```
     Result: `61 tests, 0 failures`.
   - Also ran:
     ```sh
     git diff --check
     ```
     Result: passed.

4. **Exact todo check-off**
   - Changed only:
     ```md
     - [ ] 014 Run focused tests for changed web templates/components and email rendering.
     ```
     to:
     ```md
     - [x] 014 Run focused tests for changed web templates/components and email rendering.
     ```

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan does not explicitly reference ADRs for this validation-only task.
   - No architecture, feature-file, runner, or code behaviour changes were made; this task only executed the focused validation required by the approved plan.