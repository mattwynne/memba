1. **Selected todo line**
   - `010 Add tests: the delivery route renders the per-recipient breakdown for a message; it enforces the same authz as the conversation; the conversation kebab links to it; the conversation no longer renders the inline delivery sections.`

2. **Changes made**
   - Added two authorization-parity tests in:
     - `web/test/memba_web/live/member_message_delivery_live/show_test.exs`
   - New coverage asserts:
     - signed-in users outside the requested club get `403 Forbidden`
     - forbidden responses do not leak message, recipient, or bounce-reason details
     - unauthenticated visitors are redirected to `/auth`
     - the delivery route preserves the return path in session
   - Existing tests in the same slice already covered:
     - per-recipient delivery breakdown + bounce reason
     - delivered group collapsed / problem group expanded
     - Back to conversation link
     - kebab delivery links on conversation entries
     - removal of inline conversation delivery sections

3. **Validation run**
   - Passed:
     ```sh
     PATH="$PWD/bin:$PATH" dev test \
       test/memba_web/live/member_message_delivery_live/show_test.exs \
       test/memba_web/live/member_message_live/show_test.exs \
       test/memba_web/controllers/member_message_detail_test.exs \
       test/memba_web/controllers/page_controller_test.exs
     ```
     Result: `59 tests, 0 failures`.

   - Also attempted broader quick validation:
     ```sh
     PATH="$PWD/bin:$PATH" dev check --quick
     ```
     Result: failed with 6 existing broader failures unrelated to this delivery-test change, all around tests expecting `/` while the app redirects signed-in members to `/conversations`.

   - Re-ran the failing files independently:
     ```sh
     PATH="$PWD/bin:$PATH" dev test \
       test/memba_web/club_site_shell_surfaces_test.exs \
       test/memba_web/live/admin/club_member_invitations_live/new_test.exs \
       test/memba_web/live/member_invitation_live/send_test.exs
     ```
     Result: reproduced unrelated failures: `10 tests, 4 failures`.

4. **Todo check-off made**
   - Changed exactly:
     ```md
     - [ ] 010 Add tests: the delivery route renders the per-recipient breakdown for a message; it enforces the same authz as the conversation; the conversation kebab links to it; the conversation no longer renders the inline delivery sections.
     ```
   - To:
     ```md
     - [x] 010 Add tests: the delivery route renders the per-recipient breakdown for a message; it enforces the same authz as the conversation; the conversation kebab links to it; the conversation no longer renders the inline delivery sections.
     ```

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan references no ADRs explicitly, and `docs/adr/*.md` is absent in this checkout.
   - The tests preserve the planned architecture: no delivery status computation changes, no acceptance feature changes, and the delivery route is verified to use the same member authorization boundary as conversation viewing.