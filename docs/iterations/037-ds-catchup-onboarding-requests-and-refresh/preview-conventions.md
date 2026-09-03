# DS preview conventions

Task 002 confirmation for where iteration 037 repo-side DS previews live and what each self-contained preview must include.

## Sources inspected

- `docs/iterations/036-ds-catchup-member-management-and-auth/preview-conventions.md`
- `design-system/wireframes/invite-a-member.html`
- `design-system/wireframes/profile-completion.html`
- `design-system/wireframes/check-email-delivery-progress.html`
- `design-system/components/badges/badges.card.html`
- `docs/specs/2026-06-17-phase2-ds-previews-design.md`
- `web/assets/css/app.css`
- `spikes/ds-convert/emails/reply-notification.html`

## Repo location decision

Use the iteration 036 `design-system/` mirror directory for all new or refreshed preview deliverables. Files are authored as if `design-system/` is the cloud DS root; the PM can push them by stripping the `design-system/` prefix during the manual DesignSync step.

Existing `spikes/ds-convert/` and `spikes/daisyui-preview/` files remain reference material only. Do not add 037 deliverables there.

| Repo path | Cloud DS path | Purpose |
| --- | --- | --- |
| `design-system/wireframes/onboarding-request-flow.html` | `wireframes/onboarding-request-flow.html` | Public `/get-started` account-request flow, including signed-out email verification and verified/signed-in request states. |
| `design-system/wireframes/admin-request-review.html` | `wireframes/admin-request-review.html` | Staff request inbox/review plus convert-to-club panel for `/admin/requests` and `/admin/requests/:request_id`. |
| `design-system/emails/new-request-notification.html` | `emails/new-request-notification.html` | Staff new-request notification email from `Memba.Onboarding.NewRequestEmail`. |
| `design-system/wireframes/member-empty-states.html` | `wireframes/member-empty-states.html` | Canonical first-run/empty member states if they read clearest as a standalone card. If task 006 chooses to fold these into the refreshed club-home preview, do not create this separate file. |
| `design-system/wireframes/club-home.html` | `wireframes/club-home.html` | Refreshed member club-home preview, including current messages/members and any folded-in empty states. |
| `design-system/wireframes/member-messaging.html` | `wireframes/member-messaging.html` | Refreshed member messaging/read preview, mirroring the post-034 message-detail surface and receipt breakdown. |

Each new or changed preview starts with an `@dsCard` header. Use clear groups such as `Onboarding Requests`, `Emails`, and `Member App`; preserve any existing group/name if refreshing a file that already exists in the cloud DS.

## Relative asset paths

Author paths as if `design-system/` is the DS root:

- From `design-system/wireframes/*.html` to DS-root assets: `../brand/...`.
- From `design-system/emails/*.html` to DS-root assets: `../brand/...`, though email previews should prefer inline SVG/CSS-safe marks because email clients do not reliably load external assets.
- From deeper component paths, walk up one level per directory (for example, `design-system/components/badges/*.html` uses `../../brand/...`).
- Prefer inline SVGs, text marks, initials, or CSS-only marks where that is enough to mirror the shipped surface.
- Do not point previews at Phoenix app static paths.
- Do not link `styles.css`, `memba.css`, `app.css`, or other app build output. Each preview must carry the CDN links and CSS it needs.

## App-page self-contained head block

Use this shape for non-email previews. Adjust only the `<title>` and page-specific layout CSS. The raw tokens and daisyUI variables are copied from `web/assets/css/app.css`; keep them in sync if the app theme changes.

```html
<!doctype html>
<html lang="en" data-theme="light">
<head>
  <meta charset="utf-8">
  <title>Preview title · Memba</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Figtree:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap">

  <!-- daisyUI component CSS, prebuilt — renders the app's daisyUI components with no build step. -->
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/daisyui@5">

  <style>
    /* Memba raw tokens (mirror of web/assets/css/app.css @theme). */
    :root {
      --color-sage-50:#eef1e6;
      --color-sage-100:#dde3cf;
      --color-sage-200:#bccaa6;
      --color-sage-300:#98ab80;
      --color-sage-400:#6f8760;
      --color-sage-500:#5a7050;
      --color-sage-600:#475a40;
      --color-sage-700:#36462f;
      --color-sage-800:#232e1e;

      --color-cream:#f6f5ea;
      --color-paper:#fffef9;
      --color-apricot:#d2925a;
      --color-apricot-soft:#f6e8d6;
      --color-apricot-deep:#925f2e;

      --color-ink:#25291d;
      --color-ink-2:#555a47;
      --color-ink-3:#878b76;

      --color-line:#e8e6d4;
      --color-line-strong:#d9d6bf;
      --color-success:#5f7a4f;
      --color-warning:#a8772e;
      --color-error:#a8503a;
      --color-info:#4f6b78;
      --color-success-soft:#e9eedd;
      --color-warning-soft:#f3ecd8;
      --color-error-soft:#f1ddd3;
      --color-info-soft:#e3e9ec;

      --font-sans:"Figtree",ui-sans-serif,system-ui,sans-serif;
      --font-mono:"JetBrains Mono",ui-monospace,SFMono-Regular,Menlo,monospace;
    }

    /* daisyUI "light" theme — copied from web/assets/css/app.css. */
    :root {
      color-scheme:light;
      --color-base-100:#fffef9;
      --color-base-200:#f6f5ea;
      --color-base-300:#e8e6d4;
      --color-base-content:#25291d;
      --color-primary:#5a7050;
      --color-primary-content:#f6f5ea;
      --color-secondary:#555a47;
      --color-secondary-content:#f6f5ea;
      --color-accent:#d2925a;
      --color-accent-content:#25291d;
      --color-neutral:#25291d;
      --color-neutral-content:#f6f5ea;
      --color-info:#4f6b78;
      --color-info-content:#f6f5ea;
      --color-success:#5f7a4f;
      --color-success-content:#f6f5ea;
      --color-warning:#a8772e;
      --color-warning-content:#f6f5ea;
      --color-error:#a8503a;
      --color-error-content:#f6f5ea;
      --radius-selector:0.375rem;
      --radius-field:0.375rem;
      --radius-box:0.75rem;
      --size-selector:0.25rem;
      --size-field:0.25rem;
      --border:1px;
      --depth:0;
      --noise:0;
    }

    * { box-sizing:border-box; }
    html, body { margin:0; }
    body {
      min-height:100vh;
      background:var(--color-base-200);
      color:var(--color-base-content);
      font-family:var(--font-sans);
      -webkit-font-smoothing:antialiased;
      text-rendering:optimizeLegibility;
    }

    /* Page-specific layout CSS goes here. Use plain CSS, not Tailwind utilities. */
  </style>
</head>
```

## Email-preview convention

Use the existing email-preview style for `design-system/emails/new-request-notification.html`, not the app-page daisyUI head:

- Keep the preview self-contained with an `@dsCard` header and a full email document.
- Use conservative table markup and inline styles, matching `Memba.EmailTemplates` and `spikes/ds-convert/emails/reply-notification.html`.
- Include email-safe metadata (`viewport`, `X-UA-Compatible`, `color-scheme`, `supported-color-schemes`) and a minimal `<style>` block for font import and mobile media queries.
- Do not use daisyUI classes inside email markup; email previews should mirror the rendered email shell rather than browser app components.
- Use the shipped email palette from `surface-notes.md`: canvas `#ece9e0`, paper `#ffffff`, line `#e6e3dc`, ink `#15201c`, forest/action `#1f4842`.

## Class-mapping rules

Use daisyUI components plus plain CSS for app-page previews. Do not rely on Tailwind utility classes in static CDN previews; they silently fail without the app build.

| App / bespoke pattern | Static preview pattern |
| --- | --- |
| `btn btn--primary`, app primary button | `btn btn-primary` |
| `btn btn--secondary`, secondary app button | `btn btn-soft` |
| `btn btn--ghost`, back/cancel link button | `btn btn-ghost` |
| `btn btn--color-error`, destructive action | `btn btn-error` |
| `btn--lg` / `btn--sm` | `btn-lg` / `btn-sm` |
| `pill p-ok`, delivered/active status | `badge badge-success badge-soft` |
| `pill p-info`, informational status | `badge badge-info badge-soft` |
| `pill p-warn`, sending/pending status | `badge badge-warning badge-soft` |
| `pill p-bad`, failed/rejected status | `badge badge-error badge-soft` |
| Shared `status_badge` dot | `badge badge-soft ...` plus a tiny `currentColor` dot in plain CSS. |
| Shared `avatar` component | `avatar avatar-placeholder` plus plain CSS sizing/colour classes if needed. |
| App `input` / `textarea` | daisyUI `input` / `textarea` |
| App form labels/hints | `fieldset`, `label`, `fieldset-label`, or equivalent plain CSS for exact spacing. |
| Tailwind layout classes (`flex`, `gap-4`, `max-w-3xl`, `rounded-xl`, `text-sm`) | Local preview classes such as `.request-shell`, `.review-card`, `.message-grid`, authored in the page `<style>`. |

Before task 008 can be checked off, render each new/changed preview in headless Chrome against live CDNs and fix any broken/unstyled components.
