1. **Selected todo line**
   - `004 Author the staff request review & convert preview.`

2. **Changes made**
   - Added `design-system/wireframes/admin-request-review.html`.
   - The preview includes:
     - `@dsCard` and `@startingPoint` headers.
     - Self-contained daisyUI CDN + Memba theme `:root` variables.
     - Staff admin shell treatment with active Requests nav.
     - `/admin/requests` active request inbox:
       - summary cards,
       - active toolbar,
       - table with requester/club/note/submitted/actions,
       - hidden shipped empty-row copy.
     - `/admin/requests/:request_id` conversion panel:
       - requester details,
       - club name and slug fields,
       - slug help/availability feedback,
       - cancel and convert actions.
     - Supporting shipped states:
       - converted-request success flash,
       - inactive deep-link panel,
       - rejection affordance note without inventing a rejection email preview.
   - Updated only `todo.md` to check off task 004.

3. **Focused validation commands run and results**
   - Static marker/shipped-copy check:
     - `python3 ...` — passed.
   - Static class scan for accidental Tailwind utility reliance:
     - `python3 ...` — passed.
   - Whitespace check:
     - `git diff --check` — passed.
   - Broad per-task validation:
     - `PATH="$PWD/bin:$PATH" dev check --quick` — passed.
     - Result: `799 tests, 0 failures`.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 004 Author the staff request review & convert preview.`
   - To:
     - `- [x] 004 Author the staff request review & convert preview.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0015 respected: no member application rendering architecture or LiveView behavior changed.
   - ADR 0016 respected: no email provider/delivery boundary changed.
   - This task only adds a static design-system preview artifact and does not modify app code, routes, LiveViews, templates, acceptance features, or behavior.