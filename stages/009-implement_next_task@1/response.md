Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `001 Inspect the current design-system CSS definitions for .message*, .composer*, and .page-title and port them into web/assets/css/app.css using exact class names.`

2. **Changes made**
   - Added design-system-aligned CSS rules to `web/assets/css/app.css` for:
     - `.page-title`
     - `.message`, `.message--original`, `.message__avatar`, `.message__body`, `.message__head`, `.message__name`, `.message__time`, `.message__text`, `.message__menu`, `.message__kebab`, `.message-menu`
     - `.composer`, `.composer__head`, `.composer__title`, `.composer__as`, `.composer__actions`, `.composer__note`, `.composer__error`
   - Added a focused CSS asset test in `web/test/memba_web/app_css_test.exs` proving those selectors/key rules exist.
   - Kept the CSS compatible with the current Tailwind-heavy message markup until the next task rewrites the HEEx structure.

3. **Validation run**
   - TDD/focused failure first:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/app_css_test.exs` failed as expected before CSS was added.
   - Focused validation after implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/app_css_test.exs` — passed, `6 tests, 0 failures`.
   - Full required browser-facing quality gate:
     - `PATH="$PWD/bin:$PATH" dev check` — passed, including `107 scenarios (107 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 001 Inspect ...`
   - to:
     - `- [x] 001 Inspect ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan referenced no ADRs, and there are no `docs/adr/*.md` files in this repo.
   - Followed relevant project/frontend guidance: preserved Tailwind v4 import structure, avoided `@apply`, made a focused CSS/test-only change for this selected task, and ran full `dev check` because CSS is browser-facing.