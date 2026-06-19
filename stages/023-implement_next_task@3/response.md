1. **Selected todo line**
   - `003 Author the invite-a-member preview (member-admin + staff variants).`

2. **Changes made**
   - Added `design-system/wireframes/invite-a-member.html`.
   - The preview includes both shipped invite surfaces in one self-contained file:
     - Member-admin invitation variant for `/members/invitations/new`.
     - Staff/admin invitation variant for `/admin/clubs/:club_id/invitations/new`.
   - Mirrored real shipped copy, IDs/data attributes, form fields, placeholders, buttons, context cards, and representative feedback/error states from the LiveViews.
   - Used daisyUI CDN + copied Memba theme tokens + plain CSS only.
   - Did not modify app code, routes, LiveViews, templates, acceptance features, or later DS preview tasks.

3. **Focused validation run**
   - `git diff --check -- docs/iterations/036-ds-catchup-member-management-and-auth/todo.md`
     - Passed.
   - Python static preview validation:
     - Confirmed `@dsCard` header is first line.
     - Confirmed daisyUI CDN is linked.
     - Confirmed no shared/app CSS links.
     - Confirmed no Tailwind-like utility classes in HTML class attributes.
     - Confirmed final newline/trailing whitespace.
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed.
     - ExUnit: `799 tests, 0 failures`.
   - Full `dev check` remains the explicit final todo task `009`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 Author the invite-a-member preview (member-admin + staff variants).`
   - To:
     - `- [x] 003 Author the invite-a-member preview (member-admin + staff variants).`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan references no ADRs explicitly.
   - Inspected relevant accepted ADRs:
     - ADR 0015: preview mirrors the shipped member LiveView surface without changing LiveView/app implementation.
     - ADR 0016: preview stays provider-neutral; it does not introduce provider-specific email code or wording.
     - ADR 0006: no member-facing delivery-status model changes were introduced.
   - Acceptance feature files remained untouched, consistent with the plan’s “BDD not applicable” decision.