Implemented the plan-conformance repair and left the codebase passing the full gate.

## 1. Plan requirement gaps addressed

The preceding gate output did not include a textual repair brief beyond `plan_conformant: false`, so I repaired the concrete explicit plan mismatches visible from the plan/current state:

1. **Staff bar Tailwind binding mismatch**
   - The plan’s Technical Decisions gave binding class lists for the staff bar inner, tag, link, and icon.
   - Current markup had extra utilities (`flex-wrap`, `shrink-0`, `min-w-0`) not in those binding lists.

2. **Acceptance support did not assert the staff console link copy**
   - The plan requires the visible link copy: “Open the staff console”.
   - `assertHomepageStaffAccess` asserted the link selector and href, but not that the link was the visible console-link copy.

3. **Automated tests needed stronger proof of plan-specific rendering**
   - Added/updated tests proving:
     - visitor pages do not render the staff bar/link,
     - the staff bar is first child inside `#signed-in-home` above `<header>`,
     - exact binding classes are present,
     - the icon class matches the planned icon binding,
     - acceptance support targets the new staff bar and console link.

## 2. Concrete changes made

### Staff bar markup/class binding

Updated `web/lib/memba_web/controllers/page_html/home.html.heex` to match the plan’s binding Tailwind classes exactly:

- Removed `flex-wrap` from the staff bar inner.
- Removed `shrink-0` from the tag.
- Removed `min-w-0` from the staff console link.
- Removed `shrink-0` from the trailing icon.

### Acceptance support assertion

Updated `acceptance-tests/features/support/homepage.js`:

- `assertHomepageStaffAccess` now locates `a#staff-console-link` with `hasText: "Open the staff console"`.
- It still asserts visibility, href `/admin/clubs`, visible “Memba staff” tag, and absence of `a#admin-home-link`.

### Automated test coverage

Updated:

- `acceptance-tests/test/homepage_steps.test.js`
  - Added direct unit coverage for `assertHomepageStaffAccess`.

- `web/test/memba_web/controllers/page_controller_test.exs`
  - Added visitor exclusion checks for `#homepage-staff-bar` and `a#staff-console-link`.
  - Added staff-bar placement assertion.
  - Added exact class assertions for the planned staff bar, inner container, tag, descriptive text, link, and icon.

## 3. Files changed by requirement

### Requirement: exact planned staff bar rendering/classes/icon/link

- `web/lib/memba_web/controllers/page_html/home.html.heex`
- `web/test/memba_web/controllers/page_controller_test.exs`

### Requirement: staff-access acceptance support targets the new staff bar/link

- `acceptance-tests/features/support/homepage.js`
- `acceptance-tests/test/homepage_steps.test.js`

### Requirement: non-staff/visitor exclusion remains proven

- `web/test/memba_web/controllers/page_controller_test.exs`

## 4. Automated tests added or updated

- Added JS unit test:
  - `homepage staff access assertion checks the staff bar and console link`

- Updated Phoenix controller tests to assert:
  - visitor pages do not render staff bar/link,
  - staff bar placement above header,
  - exact planned staff bar classes and icon class.

No `.feature` files were changed.

## 5. Tests run

Passed:

- `cd acceptance-tests && node --test test/homepage_steps.test.js`
  - 6 tests passed.

- `PATH="$PWD/bin:$PATH" dev ci`
  - ExUnit: 798 tests, 0 failures.
  - Acceptance: 82 scenarios passed, 493 steps passed.

## 6. Remaining plan gaps / human questions

None identified.