1. **Selected todo line**
   - `001 Inspect current routing, PageController, member dashboard LiveView, member message routes, compose route, auth return-to handling, and URL generation helpers.`

2. **Changes made**
   - Added `docs/iterations/018-member-club-subdomains/inspection.md` with durable inspection notes covering:
     - current routing and host handling;
     - `PageController` public subdomain logic;
     - dashboard and member message LiveViews;
     - auth/authorization and return-to handling;
     - current query-string URL generation;
     - config/endpoint state;
     - relevant tests and acceptance support.
   - Updated only the selected todo line in `docs/iterations/018-member-club-subdomains/todo.md`.

3. **Focused validation**
   - Ran `git diff --check` — passed with no whitespace errors.
   - Inspected final diff/status — only the task note and selected todo check-off are changed.
   - Did **not** run `dev check` because this task was docs/inspection-only and made no code/config/app-behaviour changes, consistent with `AGENTS.md`.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 001 Inspect current routing, ...`
   - To:
     - `- [x] 001 Inspect current routing, ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Read accepted ADR 0019.
   - Inspection note explicitly records ADR 0019 constraints:
     - configurable club-site base domain;
     - production `clubs.memba.io`;
     - local/test `lvh.me`;
     - normal member navigation should use slug subdomains;
     - `?club_id=<uuid>` remains only a temporary fallback.