1. **Selected todo line**
   - `001 Inventory every opened/Opened reference in lib/, test/, and acceptance-tests/ (baseline grep) and classify each as remove vs retain-as-shim.`

2. **Changes made**
   - Added `docs/iterations/035-obliterate-opened-delivery-status/inventory.md`.
     - Captures the baseline grep command.
     - Notes that the app paths are `web/lib` and `web/test`.
     - Classifies all 111 clean baseline references as:
       - remove,
       - retain-as-shim / replay regression coverage,
       - or unrelated non-status wording.
   - Updated `docs/iterations/035-obliterate-opened-delivery-status/todo.md` to check off only task 001.

3. **Focused validation run**
   - `git log --oneline --decorate -20` — inspected recent Fabro checkpoints.
   - `git status --short` — confirmed clean tree before editing.
   - `grep -RInE 'opened|Opened' web/lib web/test acceptance-tests --exclude-dir=deps --exclude-dir=node_modules || true` — produced clean baseline inventory.
   - `grep -RInE 'opened|Opened' web/lib web/test acceptance-tests --exclude-dir=deps --exclude-dir=node_modules | wc -l` — confirmed 111 baseline references.
   - `grep -E '^\| \`[^\`]+:[0-9]+\` ' docs/iterations/035-obliterate-opened-delivery-status/inventory.md | wc -l` — confirmed 111 classified inventory entries.
   - `git diff --check` — passed.

   I did **not** run `dev check` because this task was docs/inventory-only and made no code, config, migration, test, or app-behaviour changes.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 001 Inventory every ...`
   - To:
     - `- [x] 001 Inventory every ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan does not explicitly reference any ADRs.
   - `docs/adr/*` is absent/empty in this repo, so there were no accepted ADRs to apply for this docs-only inventory task.