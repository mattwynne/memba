# Handoff: Memba navigation & pages

## Overview

This package re-homes the behaviour that **already exists** in the `mattwynne/memba` Phoenix app so it
serves three distinct audiences instead of living on one unauthenticated harness page. It also introduces
the strategic decision that the member-facing surface is **white-label**: it's the *club's own website*,
running on Memba invisibly.

The scope of this cut ("in, for now") is deliberately small:

1. **Visitors** browse a marketing homepage and **request an account** (no self-serve sign-up).
2. **Memba staff** create clubs and add members from an internal back-end (manual provisioning until
   subscriptions exist).
3. **Club members** sign in with their email (magic link) and read the noticeboard, browse the directory,
   and send a message to the whole club — all on the club's own branded site.

One identity ties it together: everyone signs in by magic link, and on **memba.io** a signed-in person gets
a **"My clubs"** hub to step into any club they belong to (staff also reach `/admin` there). See
**Identity & access** for the full model — it's the second-most-important decision after the brand boundary.

The single source-of-truth visual for all of this is **`blueprint/index.html`** — open it in a browser.

---

## About the design files

The files in this bundle are **design references created in HTML/CSS** — they communicate information
architecture, routing, layout, content priority, and the brand model. **They are not production code to
copy.** The task is to implement these designs in the **existing Phoenix + LiveView codebase**, using its
established patterns (Commanded-style commands/events/projections, LiveView, the `core_components.ex`
function components, Tailwind/daisyUI as already configured).

Two reference files matter most:

- **`blueprint/index.html`** — the navigation blueprint. Behaviour map, sitemap, end-to-end flow, low-fi
  page sketches, and the brand-boundary model. Read this first.
- **`marketing/index.html`** — a higher-fidelity prototype of the public marketing homepage (React + Babel,
  purely for visual reference). The `tweaks-panel.jsx` / `useTweaks` machinery in it is a **design-exploration
  aid — do not ship it**; just read the final copy and layout.

## Fidelity

- **The blueprint (`blueprint/index.html`) is low-fidelity / IA-level.** The page sketches show *what lives on
  each screen* and *content priority*, not final pixels. Use them as the spec for routing, page composition,
  and what each screen must contain — then style with the codebase's existing design system.
- **The marketing prototype (`marketing/index.html`) is high-fidelity** for the public homepage: real copy,
  type scale, spacing, and the Memba brand. Recreate it faithfully (in HEEx/LiveView or a static controller
  view) using the tokens in `colors_and_type.css`.

---

## The core decision: the brand boundary

A single line runs through the whole product. Get this right before anything else.

| | **Memba's brand** | **Each club's brand (white-label)** |
|---|---|---|
| Surfaces | Marketing site, Staff back-end | The club's website (public homepage + signed-in member area), sign-in, **every club email** |
| Looks like | Memba — forest green (`#1f4842`), sprig mark, "Memba" | The club — their logo, their colour, their domain |
| Who sees it | Prospects & Memba staff | Club members (most never learn Memba exists) |

- Member-facing pages and **all club-business emails** (magic link, "you've been added", broadcasts) are sent
  **in the club's name**, on the club's domain — never Memba-branded.
- **The one exception:** a quiet *"Powered by Memba"* credit in the page footer of member pages. Low-key by
  design.

### White-label theming model

- Each club has a **brand layer**: a custom domain, one **brand colour** (derive tints/shades from it), and —
  *later, once image upload exists* — a **logo**.
- Clubs **skin** the site; they don't restructure it. **Layout, spacing, and typography stay locked** (Memba's
  structural system). Only colour, logo, and domain vary per club.
- **Default theme (important — required now):** until logo upload and self-serve theming controls are built,
  **a club site must never look unstyled.** Every new club ships on a sensible default:
  - the club's **name set as a clean text wordmark** (no logo needed),
  - a **neutral default brand colour** — a calm slate, deliberately **not** Memba's forest green,
  - the standard layout.
  - Picking a colour → uploading a logo → custom imagery are progressive upgrades *on top of* this floor.
- **Implementation hint:** express the brand layer as CSS custom properties (e.g. `--brand`, `--brand-fg`,
  `--brand-soft`) resolved per-club at render time, defaulting to the neutral slate. Do **not** hard-code
  Memba's forest into member-facing templates. Split your tokens into *structural* (shared, fixed) and
  *brand* (per-club, themeable).

---

## Routing

The current router (`web/lib/memba_web/router.ex`) exposes everything unauthenticated at `/`, `/clubs`,
`/clubs/:club_id`, `/messages/:message_id`, plus `POST /webhooks/postmark`. Re-home as follows.

### Public site — Memba-branded, no auth
| Route | Page | Notes |
|---|---|---|
| `GET /` | Marketing home | On **memba.io**. Replaces the current default Phoenix home (`PageController :home`). |
| `/#request` (or `/request`) | Request-an-account form | Replaces the old "Get started" self-serve modal. **Creates a lead → emails Memba.** No club/account is created here. |
| `/pricing`, `/help` | Supporting pages | Already drafted in marketing prototype; low priority. |

### The Memba plane — memba.io, **authenticated hub** (any signed-in person)
| Route | Page | Notes |
|---|---|---|
| `/signin` | Magic-link sign in | Same mechanism as everywhere; no password. |
| `/clubs` | **"My clubs"** hub | **Default landing after memba.io sign-in.** Lists every club the person can reach; clicking one steps into that club's white-label site. This is the **only place a club switcher exists.** |

> Signing in on **memba.io** is signing in *with Memba* (the platform), so the hub + switcher are correct
> here. Signing in on a **club domain** is signing in *as a member of that club* — no hub, no switcher (see
> "Identity & access" below).

### Staff back-end — Memba-branded, **auth required (Memba staff only)**
| Route | Page | Was | Notes |
|---|---|---|---|
| `/admin/requests` | Account requests inbox | new | Leads from the marketing form; feeds "create a club". |
| `/admin/clubs` | All clubs · create a club | **`/clubs`** (`ClubsLive.Index`) | Move + gate behind staff auth. |
| `/admin/clubs/:id` | Club detail · members · add a member | **`/clubs/:id`** (`ClubsLive.Show`) | Move + gate. See "add a member" below. |
| `/admin/clubs/:id/brand` | Club brand: domain, colour, logo | new | Staff set this now; the club self-serves later. |
| `/admin/messages/:id` | Delivery health · bounces | **`/messages/:id`** (ops half of `MessagesLive.Show`) | The diagnostic/Postmark-receipt view belongs to staff, not members. |

### The club's site — **white-label (club brand)**, on the club's own domain
| Route | Page | Was | Notes |
|---|---|---|---|
| `/` | Club public homepage | new | The club's front door (emerging surface — keep simple for now). |
| `/signin` | "Sign in to {Club}" → magic link | new | Email only, **no password**. Lands directly in this club's member area — no hub, no switcher. |
| `/members` | Noticeboard — recent club messages | club messages list (from `ClubsLive.Show`) | Signed-in home. |
| `/messages/:id` | Read a single message | read half of **`/messages/:id`** | Clean reading view (no delivery diagnostics). |
| `/compose` | Send a message to the club | send-message form (from `ClubsLive.Show`) | Always broadcasts to all active members. |
| `/directory` | Browse fellow members | `list_active_members_of_club` | New read-only view. |
| `/sent` | Messages you've sent | new view | `messages` projection filtered by sender. |

> **Multi-tenancy note:** member routes are scoped to a club resolved from the **incoming host/domain**, not
> a `:club_id` in the path. `kootenaymc.ca/members` resolves the club from the host. Keep `POST
> /webhooks/postmark` exactly as it is — it's backend plumbing, no page.

---

## Behaviour allocation (maps to existing modules)

Every behaviour below already runs in the codebase. This is mostly re-homing, plus magic-link auth and a
couple of read-only views.

| Behaviour | Existing code | New owner | Status |
|---|---|---|---|
| Browse marketing site | `PageController` | Visitor | New page |
| Request an account | — | Visitor | **New** (creates a lead, emails Memba) |
| Create a club | `Membership.create_club/2` · `Commands.CreateClub` | Staff | Move → `/admin/clubs` |
| Add a member (name + email) | `Membership.create_person/2` + `Membership.add_member/2` | Staff | Move → `/admin/clubs/:id`; **fold the two steps into one form** |
| Sign in with email | — | Member | **New** (magic link) |
| Read the noticeboard | `Messaging.list_messages_for_club/1` | Member | Move → `/members` |
| Read a single message | `MessagesLive.Show` (read part) | Member | Move → `/messages/:id` |
| Browse the directory | `Membership.list_active_members_of_club/1` | Member | **New view** |
| Send a message to the club | `Messaging.send_club_message/2` · `Commands` | Member | Move → `/compose` |
| See your sent messages | `messages` projection, filtered by sender | Member | **New view** |
| Fan-out delivery & receipts | `Messaging` deliveries + `PostmarkWebhookController` | System | Live — unchanged |
| Delivery health (bounces) | receipts/deliveries projections | Staff | Move → `/admin/messages/:id` |

### "Add a member" — fold two steps into one
Today the harness has a *create person* form and a separate *add member* (select existing person) form. For
staff, **merge these**: one form with **name + email** that, on submit, creates the person (if needed) and
adds the membership in one action. Underneath, this is still `create_person` then `add_member` — just one UI
step. (See `web/lib/memba_web/live/clubs_live/show.ex` for the current two-form version.)

---

## Screens (low-fi sketches → what each must contain)

Open `blueprint/index.html` § "06 — Low-fi page sketches" to see each. Summaries:

### Visitor
- **Home** — the marketing homepage (see `marketing/index.html` for hi-fi). Hero: eyebrow "Membership
  software for clubs", H1 "Run your club, not your spreadsheet.", a one-line lede, primary "Get started" +
  ghost "See it in action", optional stat line. Then Features (1–3 cards), a customer quote, Pricing (3
  tiers), Footer. "Get started" → the request form.
- **Request an account** — short form: name, club, email, one sentence about the club; "Send request".
  Submitting **emails Memba a lead** and creates nothing. (Replaces the old `SignupModal`.)

### Memba plane — memba.io, signed in (Memba-branded)
- **My clubs** (`/clubs`) — the **hub and the switcher**, and the default landing after `memba.io` sign-in.
  Memba-branded header; a list of every club the person belongs to, each with a "Visit →" that steps into
  that club's white-label site. For a `@memba.io` staff identity, add a "Memba staff" entry that opens
  `/admin` (all clubs, plus create &amp; requests). This is the **only** surface where a club switcher appears.

### Staff (utilitarian — clean and clear but plain, speed over polish)
- **Clubs** (`/admin/clubs`) — a plain list of clubs + "+ New club" (create inline). The current
  `ClubsLive.Index`, gated.
- **Club detail** (`/admin/clubs/:id`) — club name; an **add-member** form (name + email → one action);
  a list of members. From `ClubsLive.Show`, gated, with the two person/member forms merged.

### Member (the club's own site — white-label; iPad-first)
*All shown in a sample slate-blue club theme with a "K" wordmark and `kootenaymc.ca` URLs. Real clubs differ.*
- **Sign in** (`/signin`) — club wordmark/logo, "Sign in to {Club}", one email field, "Email me a sign-in
  link". No password. Built for the 80-year-old on an iPad → generous tap targets (≥44px), plain language.
- **Noticeboard** (`/members`) — club brand lockup in the header; tabs Noticeboard · Directory · Sent;
  list of recent club messages (sender avatar, subject, preview); "New message" action; **"Powered by
  Memba" footer credit**.
- **Compose** (`/compose`) — subject, body, send. Audience is fixed: **the whole club** ("To: whole club").
  Broadcast only — no per-recipient picker, no reply-all to manage.
- **Directory** (`/directory`) — search field + list of members (avatar, name, secondary line). Read-only.
- **Read a message** (`/messages/:id`) — subject, sender, body. A clean reading view. Delivery diagnostics
  live on the staff side, not here.
- **Sent** (`/sent`) — the signed-in member's own messages, each with a "Sent" status. Reuses the messages
  projection filtered by sender.

---

## Identity & access (the model)

**One authentication mechanism, two planes, authorization derived after sign-in.**

- **Everyone signs in the same way:** an emailed magic link. No passwords, anywhere.
- **Authorization is derived, not assigned.** After sign-in Memba inspects the identity:
  - email domain is `@memba.io` ⇒ **Memba staff**;
  - email matches an **active membership** ⇒ **member of that club**.
- **One person can be many things** at once: a member of several clubs, Memba staff, or both. There is one
  identity (the email); access is evaluated per context.

### Two planes
- **Club plane** — a club's own domain (white-label). Here you are "a member of {Club}". **No hub, no
  switcher, no Memba** — surfacing other clubs or the platform would break the white-label illusion. One club
  per domain.
- **Memba plane** — `memba.io` (Memba-branded). Here you are knowingly inside the platform, so a club
  switcher belongs. Signing in lands you on the **"My clubs"** hub. Staff additionally reach `/admin` from
  here.

### Landing rules (where you go is decided by the door, not a chooser)
| You sign in at… | You land on… | Switcher? |
|---|---|---|
| `memba.io` | **"My clubs"** hub → step into any club | **Yes** — that's the hub |
| `kootenaymc.ca` (a club domain) | that club's member area, directly | No — one club per domain |
| `memba.io` with a `@memba.io` email | **"My clubs"** + the `/admin` back-end (all clubs) | **Yes**, plus admin |

- **The switcher lives only on the Memba plane.** A club's own domain never shows other clubs or a switcher.
- **Cross-domain handoff:** clicking a club in the `memba.io` hub must establish a session on *that club's*
  domain (e.g. issue a short-lived signed token the club domain exchanges for a session). From then on it's
  just the club's website.
- **Staff on a club domain are just members there** if they hold a membership; staff powers live on `/admin`,
  never on a club's white-label site.
- **Fail closed, don't leak across surfaces:** non-`@memba.io` at `/admin` → denied; a member hitting
  `/admin` → denied; requesting a link at a club you don't belong to → neutral *"If you're a member, check
  your inbox."* (never disclose membership). No "helpful" cross-surface redirects.

### Staff auth, concretely
Staff use the **same magic link** — there is no separate staff login. The only difference is authorization:
a `@memba.io` email unlocks the `/admin` back-end (and "every club" in the hub). Keep the `/admin/*` gate as
a simple `@memba.io`-domain check on the signed-in identity.

### Emails are club-branded
The member magic-link email, "you've been added", and broadcasts are all sent **in the club's name** (club
From, club colours/logo or the default wordmark theme), on the club's domain. Only Memba-plane mail (e.g. a
staff or account-hub message from `memba.io`) wears Memba's brand.

---

## Emails (club-branded)

Every email about club business is sent **as the club**, not as Memba: club name in the From, club colours/
logo (or the default wordmark theme) in the template, reply-to the club. Existing templates to re-skin into a
themeable shell live in `emails/` of the design-system project (renewal reminder, event confirmation,
welcome) and the codebase mailer (`web/lib/memba/mailer.ex`).

**Open question for the team (not yet decided):** how each club sends "as itself" deliverability-wise — a
Memba-managed sending subdomain (e.g. `mail.kootenaymc.ca`) vs. full SPF/DKIM domain auth per club. Flag this;
it affects onboarding.

---

## Out of scope (deliberately parked)

**Soon:** logo & image upload (club sites run on the default theme until then) · self-serve brand controls
(colour & domain set by the club, not staff) · self-serve club sign-up · subscriptions & billing · renewals
& dues.
**Later:** club-built/editable public pages · events & trips · member-to-member email list · Google Sheet
sync · AT Protocol & social profiles.

Keeping these off the map is what keeps the three surfaces clean.

---

## Design tokens

Full set in `blueprint/colors_and_type.css` (identical to the Memba design system). Key values:

**Structural / Memba brand**
- Canvas `#f7f6f3` · Paper `#ffffff` · Sunk `#f0eee9` · Hairline `#e6e3dc` · Strong line `#d6d2c8`
- Ink `#15201c` · Ink-2 `#4b5a55` · Ink-3 `#7d877f` · Ink-4 `#b3b9b4`
- Forest (Memba primary) `#1f4842`; scale 50 `#ecf2ee` → 700 `#102b27`
- Terracotta (status accent only) `#c46d3a`
- Semantic (desaturated): success `#4f7a5c` · warning `#a37621` · danger `#a64a36` · info `#4f6b78`

**Per-club brand layer (themeable)** — default to a neutral slate, **not** forest. The blueprint demos use
`#33597f` (slate-blue), `#7a3550` (plum), `#b06a2c` (ochre) as example club colours.

**Type** — single family **Inter** (400/500/600/700); mono **JetBrains Mono** (IDs/codes only). Body 15px /
line-height 1.5; display uses weight 600 + tight tracking (`-0.03em`), not a second font. No serif, no italic
in UI. Sentence case everywhere.

**Spacing** 4px base: 4/8/12/16/20/24/32/40/48/64/80/96/128.
**Radii** buttons/inputs 6px · menus 10px · cards 14px · modals 18px · pill 999px.
**Shadows** flat — `--shadow-sm` for cards, larger only when elevated.
**Motion** `--ease-out`, no overshoot/bounce; 100ms hover, 180ms state, 320ms layout.

**Icons** Lucide, 1.5px stroke (`<i data-lucide="…">`). No emoji in product UI.

**Voice** warm, plain, unhurried. Lead with the noun on reassurance ("Renewal sent."). Contractions. Dates
"Sat 14 Sept". Money symbol-prefixed, no `.00`.

---

## Files in this bundle

```
design_handoff_navigation/
├── README.md                     ← this file (self-sufficient spec)
├── blueprint/
│   ├── index.html                ← THE navigation blueprint — read first
│   ├── blueprint.css             ← blueprint styles
│   └── colors_and_type.css       ← full Memba design tokens
└── marketing/                    ← hi-fi reference for the public homepage
    ├── index.html                ← entry (React+Babel; tweaks panel = design aid, do NOT ship)
    ├── Nav.jsx · Hero.jsx · Features.jsx · Quote.jsx · Pricing.jsx · Footer.jsx · SignupModal.jsx
    ├── site.css
    └── colors_and_type.css
```

### Relevant existing source (in `mattwynne/memba`)
- `web/lib/memba_web/router.ex` — routes to restructure
- `web/lib/memba_web/live/clubs_live/index.ex` — create/list clubs → `/admin/clubs`
- `web/lib/memba_web/live/clubs_live/show.ex` — people/members/messages forms to split across surfaces
- `web/lib/memba_web/live/messages_live/show.ex` — split read view (member) vs delivery health (staff)
- `web/lib/memba/membership.ex` — `create_club`, `create_person`, `add_member`, `list_active_members_of_club`
- `web/lib/memba/messaging.ex` — `send_club_message`, `list_messages_for_club`, deliveries/receipts
- `web/lib/memba_web/controllers/postmark_webhook_controller.ex` — leave as-is
