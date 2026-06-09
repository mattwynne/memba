1. **Selected todo line**
   - `- [ ] 015 Run the affected acceptance tests if executable.`

2. **Changes made**
   - No code/config/test changes.
   - Checked off task 015 in `docs/iterations/031-brand-email-navigation-polish/todo.md` after affected executable acceptance scenarios passed.

3. **Focused validation run**
   - Ran affected iteration acceptance scenarios:
     ```sh
     PATH="$PWD/bin:$PATH" dev acceptance --tags @iteration-031
     ```
     Result:
     - `4 scenarios (4 passed)`
     - `13 steps (13 passed)`
   - Ran:
     ```sh
     git diff --check
     ```
     Result: passed.

4. **Exact todo check-off**
   - Changed:
     ```md
     - [ ] 015 Run the affected acceptance tests if executable.
     ```
     to:
     ```md
     - [x] 015 Run the affected acceptance tests if executable.
     ```

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Acceptance execution used the shared Cucumber/browser acceptance path, consistent with ADR 0003 and ADR 0010.
   - Club subdomain coverage ran through the browser acceptance flow using the project’s local subdomain strategy, consistent with ADR 0019.
   - No feature files or step definitions were edited in this task.