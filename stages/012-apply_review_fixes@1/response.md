Implemented the automatic repair brief for iteration 037.

## Issue-to-fix mapping

| Review issue | Fix applied | Files |
| --- | --- | --- |
| `remove-tailwind-utilities-from-ds-previews` | Verified the review-cited Tailwind utility examples were not present in the changed DS previews. Renamed ambiguous email preview classes (`container`, `gutter`, `h1`) to semantic local classes (`email-container`, `email-gutter`, `email-heading`) to avoid Tailwind-utility ambiguity. | `design-system/emails/new-request-notification.html` |
| `clarify-ds-preview-maintenance-structure` | Added comments explaining that duplicated preview tokens are intentional for self-contained cloud DS previews. Added lightweight section comments to larger/multi-state previews. | All six changed preview files listed below |

## Files changed

### Utility-class hardening
- `design-system/emails/new-request-notification.html`
  - Renamed:
    - `.container` → `.email-container`
    - `.gutter` → `.email-gutter`
    - `.h1` → `.email-heading`

### Maintenance comments / structure clarification
- `design-system/emails/new-request-notification.html`
- `design-system/wireframes/admin-request-review.html`
- `design-system/wireframes/club-home.html`
- `design-system/wireframes/member-empty-first-run-states.html`
- `design-system/wireframes/member-messaging.html`
- `design-system/wireframes/onboarding-request-flow.html`

Each now has:
- A self-contained-token comment above the duplicated `:root` theme/token block.
- Section comments for major preview states/regions.

## Validation run

Passed:

```sh
git diff --check
```

Passed targeted static-preview validation:

```sh
python3 - <<'PY'
# checks changed DS previews for reviewed Tailwind utility classes
# and confirms self-contained token comments are present
PY
```

Result:

```text
Static DS preview validation passed: no reviewed utility classes found; self-contained token comments present.
```

I did not rerun full `dev check` because this repair only changes static design-system HTML previews and comments/classes inside those previews; no app code, routes, LiveViews, tests, config, or acceptance features changed.

## Remaining gaps / human questions

None for the selected review-gate issues.

Note: `.fabro/tmp/` remains untracked from the review workflow baseline and was not modified as part of the repair.