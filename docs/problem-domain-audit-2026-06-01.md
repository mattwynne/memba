# Problem-domain language audit

Date: 2026-06-01

Scope: acceptance tests, core domain/application code, web naming, migrations, and ADRs. Older plans were not reviewed.

## Summary

The membership model is mostly aligned with the glossary: Person, Club, Club member/member, and Message are clear. The main drift is in authentication and messaging deliverability, where older solution-domain terms still shape module names, event names, projections, routes, selectors, and acceptance-test steps.

## Highest-value alignment work

### 1. Replace “magic link” with “sign-in link” in code

Glossary term: Sign-in link.

Current code uses magic-link language in public modules and functions:

- `Memba.Accounts.MagicToken`
- `request_magic_link/2`
- `create_magic_token/2`
- `generate_magic_token/0`
- `hash_magic_token/1`
- `consume_magic_token/2`
- `/auth/magic/:token`
- `magic-link` HTML IDs

Recommendation:

- Rename domain/application concepts to sign-in language: `SignInToken`, `request_sign_in_link`, `create_sign_in_token`, `consume_sign_in_token`.
- Route paths and HTML IDs can be migrated when convenient; visible product language should use “sign-in link”.

### 2. Replace “operator” with “Memba staff”

Glossary term: Memba staff.

Current code and tests use operator language for deliverability:

- `Memba.Messaging.Projections.MembaStaffEmailDelivery`
- `Memba.Messaging.Projectors.MembaStaffEmailDelivery`
- `messaging_operator_email_deliveries`
- `operator_email_deliverability.feature`
- step text: `Memba staff should see...`
- tests such as `memba_staff_email_delivery_projection_test.exs`

Recommendation:

- Rename this concept to Memba-staff-facing email delivery information.
- Candidate code name: `StaffEmailDelivery` or `MembaStaffEmailDelivery`.
- Candidate feature name: `memba_staff_email_deliverability.feature`.

### 3. Replace “email delivery” with “email delivery”

Glossary term: Email delivery.

Current code models the concept as email delivery:

- `EmailDeliveryCreated`
- `EmailDeliveryDelivered`
- `EmailDeliveryDelayed`
- `EmailDeliveryBounced`
- `EmailDeliverySpamComplaint`
- `EmailDeliveryOpened`
- `Memba.Messaging.Projections.EmailDelivery`
- `messaging_recipient_deliveries`
- fields and docs using `email_delivery`

Recommendation:

- Rename the core event/read-model concept to `EmailDelivery`.
- Candidate event names:
  - `EmailDeliveryCreated`
  - `EmailDeliveryDelivered`
  - `EmailDeliveryDelayed`
  - `EmailDeliveryBounced`
  - `EmailDeliverySpamComplaintReceived`
  - `EmailDeliveryOpened`
- Keep recipient/person fields as attributes of an email delivery.

### 4. Revisit “member email delivery” naming

Glossary currently treats receipt/status as attributes of email delivery, not separate problem-domain concepts.

Current code uses:

- `Memba.Messaging.Projections.MemberEmailDelivery`
- `Memba.Messaging.Projectors.MemberEmailDelivery`
- `messaging_member_email_deliverys`
- `MemberEmailDeliveryPresentation`
- selectors such as `member-receipt`
- acceptance-test text: `status`

Recommendation:

- Rename if we want code to match the pared-down glossary.
- Candidate names: `MemberEmailDelivery`, `MemberDeliveryStatus`, or `MemberEmailDeliveryView`.
- If “receipt” is useful user language, add it back to the glossary deliberately before preserving the term.

### 5. Replace public “club marketing page” language with “public club page”

Glossary term: Public club page.

Current drift:

- `club_marketing_live.ex`
- `#club-marketing-page`
- acceptance scenario: “Logged-out visitor sees a club marketing page”
- steps asserting “marketing page”

Recommendation:

- Rename to `PublicClubPageLive` / `public-club-page` language.

### 6. Replace “staff-only homepage/area” with “Memba staff home/area”

Glossary terms: Memba staff home, Memba staff area.

Current drift:

- acceptance steps say `staff-only homepage` and `staff-only area`
- some tests say `staff admin routes` or `staff admin navigation`

Recommendation:

- Acceptance tests should say `Memba staff home` and `Memba staff area`.
- Internal `/admin` route can remain as a solution-domain URL if we choose, but UI labels and feature text should not say admin.

## Medium-value alignment work

### 7. Reconsider `UserAuth`

Glossary avoids “user”. Code has moved toward “identity” in assigns and session keys, but the module is still:

- `MembaWeb.UserAuth`

Recommendation:

- Rename to `MembaWeb.IdentityAuth` or `MembaWeb.BrowserAuth`.

### 8. Reconsider “active member” in code

Glossary says active membership is not defined yet. Code currently has active-member language:

- `Membership.list_active_members/1`
- `active_member_of_club?`
- `require_active_club_member`
- `Membership.Membership` has `active: true`

Recommendation:

- Either define Active member as current problem-domain language, or remove “active” from current public APIs until inactive/lapsed behaviour exists.

### 9. Clarify `Recipient`

Glossary does not include Recipient. Code has `Memba.Messaging.Recipient`, meaning a resolved delivery target for `SendMessage`.

Recommendation:

- If we keep the term, define it in the glossary.
- If not, rename toward `EmailDeliveryTarget` or make it part of `EmailDelivery` creation.

## ADR notes

ADRs are mostly solution-domain, so drift is less important. Still, these ADRs contain terms now out of tune with the glossary:

- ADR 0005: `email delivery`; also explicitly preferred channel-neutral naming, which conflicts with the new glossary term `Email delivery`.
- ADR 0006: `Memba staff email delivery` and `member-facing delivery status`.
- ADR 0007/0009/0012: `email deliveries`, `member-facing email deliveries`, `Memba staff email delivery`.
- ADR 0015: `member dashboard` vs glossary `Member club home`.

Recommendation:

- Do not rewrite historical ADR decisions wholesale.
- Add a short note or follow-up ADR if we choose to rename `email delivery` to `email delivery`, because ADR 0005 explicitly made the opposite naming choice.

## Acceptance-test drift

Feature files still contain avoid-list terms:

- `operator_email_deliverability.feature`
- `club marketing page`
- `staff-only homepage`
- `staff-only area`
- `status`

Recommendation:

- Update feature wording before or alongside code renames so Cucumber remains the source of ubiquitous language.
