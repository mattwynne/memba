1. **Selected todo line**
   - `001 Add a private format_message_time/1 helper ... that formats a %DateTime{} like the design ("3 Jun, 7:02am").`

2. **Changes made**
   - Added private `format_message_time/1` in `web/lib/memba_web/controllers/page_html.ex`.
   - It formats `%DateTime{}` with `Calendar.strftime(inserted_at, "%-d %b, %-I:%M%P")`, producing strings like `3 Jun, 7:02am`.
   - Added a temporary private-function reference inside `conversation_entry_card/1` so the helper remains warning-free until the next task renders it.
   - Checked off only todo item `001`.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Ran, but ExUnit reported 4 pre-existing/unrelated failures around redirects/paths in:
       - `MembaWeb.ClubSiteShellSurfacesTest`
       - `MembaWeb.MemberInvitationLive.SendTest`
       - `MembaWeb.Admin.ClubMemberInvitationsLive.NewTest`
   - `cd web && mix compile --warnings-as-errors`
     - Passed.
   - `cd web && mix format --check-formatted lib/memba_web/controllers/page_html.ex`
     - Passed.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 001 Add a private ...`
   - To:
     - `- [x] 001 Add a private ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan did not explicitly reference ADRs.
   - I inspected relevant accepted ADRs:
     - ADR 0015: member app pages use LiveView by default.
     - ADR 0023: visible LiveView state should be URL-addressable.
   - This task only adds a private presentation formatter and does not alter routing, LiveView state, or application behaviour, so it does not conflict with those ADRs.