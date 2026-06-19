1. **Selected todo line**
   - `006 Extend the badges card with the role / Membership-Admin chips.`

2. **Changes made**
   - Added `design-system/components/badges/badges.card.html`.
   - The card is self-contained with:
     - first-line `@dsCard` header;
     - Google font link;
     - daisyUI prebuilt CDN CSS;
     - inline Memba theme tokens copied from the app theme convention;
     - plain CSS for layout and app-specific chip fidelity.
   - Extended the badge examples to include:
     - existing status badges;
     - existing generic role badges;
     - Membership Admin role chips: `Admin` and `Membership Administrator`;
     - shipped club-admin table chips: `Active membership` and a slug-style chip.
   - No app code, routes, LiveViews, templates, or `.feature` files changed.

3. **Focused validation**
   - `git diff --check -- design-system/components/badges/badges.card.html docs/iterations/036-ds-catchup-member-management-and-auth/todo.md`
     - Passed.
   - Python static badge-card validation:
     - confirmed first-line `@dsCard`;
     - confirmed daisyUI CDN;
     - confirmed no unexpected stylesheet links;
     - confirmed required Membership Admin / membership chips;
     - checked class tokens for Tailwind utility traps;
     - confirmed final newline.
     - Passed.
   - Python whitespace/final-newline validation for touched files:
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed.
     - ExUnit: `799 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 006 Extend the badges card with the role / Membership-Admin chips.`
   - To:
     - `- [x] 006 Extend the badges card with the role / Membership-Admin chips.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan references no ADRs explicitly.
   - This task is a static design-system artifact only, so it does not affect Phoenix routing, LiveView behavior, Commanded/EventStore flows, projections, email delivery, or acceptance scenarios.
   - It stays within the iteration scope and preserves the documented `design-system/` mirror mapping for the later manual DesignSync push.