Summary:

1. Review issue from gate
   - `remove-tailwind-layout-utilities-from-ds-previews`
   - Requested fix: replace `max-w-2xl`, `max-w-4xl`, and `mx-auto` Tailwind layout utilities in static DS previews with preview-local CSS.

2. Changes made
   - No code/config/test changes were needed.
   - The reviewed paths from synthesis (`docs/design-system/...`) do not exist in this checkout.
   - The actual iteration 037 preview files live under `design-system/`, per `docs/iterations/037-ds-catchup-onboarding-requests-and-refresh/preview-conventions.md`.
   - I scanned the actual changed HTML previews and found no `max-w-*` or `mx-auto` usage to replace.
   - Because the concrete selected issue is already absent, patching unrelated layout CSS would exceed the bounded repair brief.

3. Files changed, grouped by issue
   - Issue: `remove-tailwind-layout-utilities-from-ds-previews`
     - Files inspected:
       - `design-system/wireframes/admin-request-review.html`
       - `design-system/wireframes/member-empty-first-run-states.html`
       - all changed `design-system/**/*.html`
     - Files changed: none.

4. Tests/checks run
   - Targeted changed-file scan:
     - Command checked all changed `.html` files for `max-w-*` and `mx-auto`.
     - Result: no matches.
   - Broader design-system scan:
     - Checked `design-system/` for class attributes containing `max-w-` or `mx-auto`.
     - Result: no matches.
   - Final status:
     - No repair diff created.
     - Worktree has only existing untracked `.fabro/tmp/` artifacts from the workflow.

5. Remaining gaps or human questions
   - None for the selected bounded repair.
   - The synthesis appears to reference stale or incorrect paths/names for this checkout. The actual implementation already conforms to the selected “no `max-w-*` / `mx-auto` Tailwind layout utilities” concern.

Issue-to-fix mapping:

| Review issue | Addressed by | Result |
|---|---|---|
| `remove-tailwind-layout-utilities-from-ds-previews` | Targeted scan of actual changed DS preview files under `design-system/` | No matching utilities found; no code change required |