Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 010 Run targeted tests while changing each layer, then run \`dev check\` and fix regressions.`

2. **Changes made**
   - `bin/dev`
     - Made nested `devenv` calls run from the repository root so `dev check` can find `devenv.nix` reliably.
   - `bin/mix`
     - Made fallback `devenv processes ...` calls run from the repository root when the Mix wrapper needs to ensure Postgres is available.
     - This fixed the observed `dev check` regression where `mix precommit` was launched from `web/` and nested `devenv` could not find `devenv.nix`.
   - `docs/iterations/017-remove-open-tracking/todo.md`
     - Checked off task 010 only.

3. **Focused validation commands/results**
   - Focused Mix tests:
     - Ran targeted tests for Cucumber config/runtime, Messaging/domain/projections, Postmark provider/webhook handling, member presentation/loaders/LiveViews, dashboard, and staff deliveries.
     - Result: `79 tests, 0 failures`.
   - Search validation:
     - `rg` was unavailable in the shell, so equivalent `grep -RniE 'opened|track_opens|open tracking|open-tracking|opens|not opened' ...` was run.
     - Remaining matches are compatibility shims, historic-row tests, unsupported-open webhook tests, negative assertions, unused acceptance plumbing, or unrelated “opens a page” wording.
   - Acceptance suite:
     - Initial `dev acceptance` failed because npm dependencies were not installed (`cucumber-js: command not found`).
     - Ran `npm ci` in `acceptance-tests/`.
     - Reran `PATH="$PWD/bin:$PATH" dev acceptance`.
     - Result: `25 scenarios (25 passed), 174 steps (174 passed)`.
   - Full gate:
     - Initial `dev check` exposed the wrapper regression described above.
     - After wrapper fixes, final `PATH="$PWD/bin:$PATH" dev check` passed:
       - `380 tests, 0 failures`.
   - Final diff hygiene:
     - `git diff --check` passed.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 010 Run targeted tests while changing each layer, then run \`dev check\` and fix regressions.`
   - To:
     - `- [x] 010 Run targeted tests while changing each layer, then run \`dev check\` and fix regressions.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Read relevant ADRs: 0004, 0006, 0010, 0012, 0016, and 0018.
   - Wrapper fixes conform to ADR 0018 by continuing to use devenv/process-compose primitives and only correcting the working directory for nested calls; no new public process command or low-level Postgres ownership logic was added.
   - Acceptance validation conforms to ADR 0010 by exercising shared feature coverage through the Elixir Cucumber/Mix path and the JS acceptance harness.
   - Older open-tracking ADR assumptions in 0012/related ADRs are superseded by the validated iteration plan; this task did not reintroduce open tracking and left the final app checks passing.