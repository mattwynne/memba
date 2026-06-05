# Staff area redesign follow-ups from mockup analysis

Date: 2026-06-05

These notes capture behaviour implied by the supplied HTML mockups that is intentionally out of scope for iteration 021.

## Mockup principles to keep

- Staff pages should be utilitarian, dense, and calm.
- Staff navigation should feel like an operations console.
- Lists should favour scannable tables with clear status chips and concise row actions.
- The UI should use visual grouping to show what kind of record staff are looking at.

## Domain guardrail

Do not let the mockups collapse Memba’s domain model:

- Person: an identity/contact record with email addresses.
- Membership: a relationship between a person and a club.
- A person can have memberships in multiple clubs.

Future designs should make these concepts clearer, not hide them behind a single generic “member” object.

## Candidate follow-up iterations

### Global people editing and membership management

Problem:

- Iteration 021 adds a read-only global People page, but editing remains in existing club-scoped flows.

Useful next slice:

- Add a global person detail page showing email addresses and memberships across clubs.
- Let staff add/remove memberships from that person detail page while preserving club-scoped membership management.

Open questions:

- Should a person be editable outside any club context?
- What should happen when a person has no memberships?
- Should staff see inactive/removed memberships, or only active ones?

### Club-filtered operations views

Problem:

- Mockups imply tabs/filters for Members, Deliveries, and Messages within a club drill-in.
- Iteration 021 avoids implementing filters.

Useful next slice:

- Add club-filtered links or query params for `/admin/people`, `/admin/messages`, and `/admin/deliveries`.
- Let staff move from a club to that club’s operational records without duplicating lists on club detail.

Open questions:

- Should filters be represented in the URL?
- Should filtered pages keep global navigation context or club detail context?

### Incoming/rejected inbound inbox

Problem:

- The `Incoming _ inbound replies.html` mockup and `docs/problems/2026-06-04-rejected-inbound-emails-not-visible.md` point to an operations inbox for inbound email outcomes.

Useful next slice:

- Add `/admin/incoming` showing inbound emails Memba accepted or rejected, with sender, recipient address, club, reason/status, and provider message id.

Open questions:

- Is this Memba staff only, or also club moderators later?
- Should accepted inbound messages appear here, or only rejected/needs-attention ones?
- What counts as “handled”?

### Roles

Problem:

- Mockups include Roles and club member roles such as Chair, Secretary, Trip leader.
- The current slice does not add a role model.

Useful next slice:

- Discover whether club roles are operational metadata, permissions, public directory labels, messaging groups, or all of these.

Open questions:

- Are roles per membership?
- Can one person have multiple roles in one club?
- Do roles affect authorization or only display?

### Read-only global Messages improvements

Problem:

- Iteration 021 adds a simple read-only global Messages page.
- The mockup implies richer operational behaviour.

Potential slices:

- Add club/status/search filters.
- Add sent/delivery summary columns backed by existing projections.
- Add a message detail split between content summary and diagnostics.

Explicit non-goals unless separately approved:

- Staff “New message”.
- Bulk resend.
- Delete.
- Opened status.

### Delivery diagnostics improvements

Problem:

- The Deliveries mockup includes filters, status counts, and full diagnostics.
- Current delivery statuses intentionally exclude “opened”.

Potential slices:

- Add delivery status filters.
- Add issue-focused default view for bounces, delays, and spam complaints.
- Add club/message/person filters.

Policy reminder:

- Do not reintroduce open tracking or “opened” status without a new product decision reversing iteration 017.

### Club lifecycle and commercial fields

Problem:

- Mockups include plan, active/trial/paused status, KPI cards, and member totals.
- These concepts are not currently first-class product behaviour.

Useful next slice:

- Discover club lifecycle states and what staff need to do with them.

Open questions:

- Is “trial” a sales/onboarding state or subscription state?
- What does “paused” mean for member access and message delivery?
- Are plan names meaningful before billing exists?

### Staff identity and permissions

Problem:

- The current staff model is `@memba.io` email authorization.
- The problem note `docs/problems/2026-06-01-memba-staff-identity-and-club-access.md` records unresolved staff identity questions.

Useful next slice:

- Decide how Memba staff identity should be represented when staff access needs more precise behaviour.

Open questions:

- Are Memba staff also person records?
- Can staff access member-only club areas without being club members?
- Should staff actions be audited against a person record?
