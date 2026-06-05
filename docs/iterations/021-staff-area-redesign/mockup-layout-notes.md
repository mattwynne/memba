# Mockup layout notes for implementation

Date: 2026-06-05

Sources inspected:

- `mockups/Clubs _ all clubs.html`
- `mockups/Club _ members _drill-in_.html`
- `mockups/Messages _ add _ remove.html`
- `mockups/Deliveries _ full diagnostics.html`
- `mockups/Incoming _ inbound replies.html`

These notes extract reusable layout direction from the supplied HTML mockups for iteration 021. They are intentionally visual and structural, not permission to implement mockup-only product behaviour.

## Overall direction

- Treat the staff area as a calm operations console: muted warm background, white content cards, compact rows, clear section labels, and restrained accent colour.
- Use Inter-style typography already available in the app where possible; keep headings strong but not oversized.
- Prefer dense, scannable lists over marketing-style panels.
- Use small status chips and count badges to communicate operational state without adding new domain semantics.
- Put record identity first, then supporting context, then status/time/action affordances.

Useful colour cues from the mockups:

- page background: warm off-white (`#f7f6f3`);
- primary text: deep green/near-black (`#15201c`);
- secondary text: muted grey-green (`#4b5a55`, `#7d877f`);
- borders/dividers: soft stone/green-grey (`#e6e3dc`, `#d6d2c8`, `#ecf2ee`);
- accent: dark green (`#1f4842`) with lighter green surfaces (`#e6ece4`, `#7aa08c`).

## Staff operations shell

- Left rail structure:
  - product mark and label: `Memba`, `Staff`, `Operations`;
  - grouped navigation rather than a flat list;
  - current/important areas shown as compact nav rows with optional count badges;
  - staff identity block at the bottom (`MK`, name, “Memba operations”).
- Reuse the shell rhythm, but only include working iteration-021 links:
  - Clubs;
  - People, replacing the mockups’ generic `Members` concept;
  - Messages;
  - Deliveries.
- Do not include mockup-only navigation entries in this slice:
  - Roles;
  - Incoming.

## Page header pattern

- Top of each page uses a simple breadcrumb/context line followed by a clear page title.
- Primary action sits at the upper right when the page supports one:
  - `/admin/clubs`: keep `New club`;
  - read-only operational pages: omit mockup-only actions like `Export`, `New message`, `Resend`, and `Delete`.
- KPI cards can be used only when backed by existing data. Avoid inventing:
  - active/trial/paused club lifecycle counts;
  - plan names;
  - commercial metrics;
  - unsupported message or delivery status totals.

## Cards, tables, and density

- Main content should be a rounded, bordered white card on the warm page background.
- Tables are compact:
  - small uppercase or muted column labels;
  - generous but not loose row padding;
  - subtle row dividers;
  - initials avatars for people/club identity where useful;
  - first column carries primary identity plus secondary metadata.
- Use tabs/summary pills as visual grouping only when they do not imply unsupported filtering. In this slice, static section headings and explanatory copy are safer than interactive filter controls.

## Status chips and badges

- Good reusable status-chip treatment:
  - small rounded pill;
  - subdued background;
  - concise label;
  - preserve domain status labels already supported by the app.
- Mockup status labels to avoid unless already backed by current projections/domain:
  - `Trial`;
  - `Paused` for clubs;
  - `Opened`;
  - `Handled`;
  - arbitrary “Has issues” groupings.

## Page-specific extraction

### Clubs index

Reusable ideas:

- Left rail plus page header with `New club`.
- Summary cards above the table if values are honest and cheap.
- Club table shape: identity, supporting location/context if present, member/person count if available, status, last activity.

Iteration-021 adaptation:

- Keep club creation behaviour.
- Do not invent plan/status/lifecycle fields.
- Prefer existing club facts and simple counts over commercial mockup metrics.

### Club detail

Reusable ideas:

- Keep club identity prominent.
- Use local sections/tabs visually to separate the club’s people, memberships, deliveries, and messages.
- Member rows in the mockup combine identity, role, status, email, and joined date in a compact table.

Iteration-021 adaptation:

- Make the Memba domain explicit:
  - club facts/editing;
  - people records;
  - memberships for this club.
- Do not copy mockup roles unless they already exist.
- Remove staff-side `Message club` composition, as required by the plan.
- Replace embedded club messages with a clear route/copy toward global Messages or future filtered views.

### Global People

Reusable ideas inferred from the members mockup:

- Use person identity as the first column with primary contact details nearby.
- Summarise operational relationships in secondary text or compact chips.

Iteration-021 adaptation:

- Call the page `People`, not `Members`.
- Represent one person once even when they have memberships in multiple clubs.
- Show membership summaries across clubs without adding global editing semantics.

### Global Messages

Reusable ideas:

- Message table shape: subject/title, sender, club, recipients/count, status, sent time.
- Diagnostics entry point should be row-oriented and easy to scan.

Iteration-021 adaptation:

- Read-only only.
- No `New message`, selection state, bulk `Resend`, `Delete`, or status filters.
- Link each row to existing message diagnostics.
- Use sender/club context only where current projections can support it simply.

### Deliveries and message diagnostics

Reusable ideas:

- Diagnostics table shape: recipient, club, message, status, provider event/reason, time, provider/message id.
- Keep detailed provider information visible for staff.

Iteration-021 adaptation:

- Preserve existing diagnostics semantics.
- Restyle around the same calm card/table pattern.
- Do not add mockup filters or unsupported status counters in this slice.

### Incoming

Reusable ideas:

- The same operations-shell/table treatment works for future inbound reply/rejection workflows.

Iteration-021 adaptation:

- Do not add an Incoming page or nav link.
- Keep any inbound inbox work as a follow-up.

## Implementation guardrails

- Use the mockups for layout rhythm, density, colour, and action placement.
- Keep Memba’s current domain language honest:
  - people are identity/contact records;
  - memberships connect people to clubs;
  - messages and deliveries are diagnostics/read-model records.
- Avoid copying controls that imply unavailable behaviour: filters, exports, bulk actions, role management, incoming inbox, club lifecycle, plans, or staff-side composition.
