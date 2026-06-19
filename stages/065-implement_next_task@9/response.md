1. **Selected todo line**
   - `009 Run \`dev check\` to confirm the static files leave the build green.`

2. **Changes made**
   - Ran the required final full project validation.
   - Updated only `docs/iterations/036-ds-catchup-member-management-and-auth/todo.md` to mark task 009 complete.

3. **Validation commands/results**
   - `PATH="$PWD/bin:$PATH" dev check` — passed.
     - ExUnit: `799 tests, 0 failures`
     - Acceptance tests: `82 scenarios (82 passed)`, `493 steps (493 passed)`
   - `git diff --check` — passed.
   - Confirmed no unchecked todo items remain.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 009 Run \`dev check\` to confirm the static files leave the build green.`
   - To:
     - `- [x] 009 Run \`dev check\` to confirm the static files leave the build green.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan does not reference any explicit ADRs.
   - This task only performed final validation and checked off the matching todo item.
   - No app code, routes, LiveViews, templates, behavior, or acceptance `.feature` files were changed.