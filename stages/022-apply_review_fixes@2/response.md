Summary:

1. **Review issue from the gate**
   - `document-static-ds-preview-class-conventions`
   - Requested fix: document the static design-system preview class/CSS conventions so future previews clearly distinguish allowed daisyUI component/theme classes from disallowed Tailwind utilities.

2. **Changes made**
   - Added `design-system/README.md` with a concise durable convention note:
     - Static previews must be self-contained HTML and not depend on the Phoenix app build.
     - Allowed: daisyUI CDN CSS, app theme `:root` values, daisyUI component/theme classes like `btn`, `card`, `badge`, `bg-base-100`, `shadow-xl`.
     - Disallowed: Tailwind layout/spacing/sizing/typography/flex/grid utilities like `mx-auto`, `max-w-*`, `px-*`, `gap-*`, `text-sm`, `flex`, `grid`.
     - Preview layout/responsive rules should live in local `<style>` blocks with semantic classes.
     - Email previews should remain self-contained but use email-safe markup/inline styles rather than daisyUI classes.

3. **Files changed**
   - Issue: `document-static-ds-preview-class-conventions`
     - Added: `design-system/README.md`

4. **Tests/checks run**
   - Read back `design-system/README.md` to verify the content.
   - Checked `git status --short`.
   - Did **not** run `dev check` because this is a docs-only change and repo instructions say not to run it for docs-only/prose-only edits unless explicitly requested or executable examples/scripts changed.

5. **Remaining gaps / human questions**
   - None for the selected repair issue.
   - Existing untracked workflow artifacts remain under `.fabro/tmp/`; I left them unchanged.

Issue-to-fix mapping:

| Review issue | Addressed by | Result |
|---|---|---|
| `document-static-ds-preview-class-conventions` | `design-system/README.md` | Durable static-preview class/CSS convention documented |