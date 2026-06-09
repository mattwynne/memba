# Brand, email, and navigation polish

Date: 2026-06-08
Status: merged

## Goal

Improve first impressions and everyday trust by clearing a small set of visible branding, email-context, and navigation problems without changing core membership, onboarding, or messaging workflows.

After this iteration:

- Memba's homepage again leads with the stronger volunteering promise.
- Sign-in emails use the correct Memba sprig branding and standard footer treatment.
- Transactional emails have consistent footer treatment where this slice touches them.
- Rejection emails for club-addressed inbound messages identify the relevant club in the sender name.
- Public club pages offer an obvious path back to the main Memba homepage.

## Background / Context

The current problem list contains several small, high-friction issues that are too small to deserve separate iterations but make Memba feel less polished and less trustworthy. They are concentrated in copy, email rendering, display names, and simple navigation.

This is intentionally a polish/quick-wins iteration. It should avoid larger product decisions such as reply/threading behaviour, club switching, custom hostnames, pending invitation lifecycle, staff person merging, or richer onboarding/member data collection.

## Related Problems

- [`docs/problems/2026-06-06-sign-in-email-wrong-memba-icon.md`](../../problems/2026-06-06-sign-in-email-wrong-memba-icon.md): expected to resolve. The sign-in email should use the Memba sprig icon instead of the check icon.
- [`docs/problems/2026-06-06-inconsistent-email-footers.md`](../../problems/2026-06-06-inconsistent-email-footers.md): expected to resolve for the transactional emails touched in this iteration, and preferably all current transactional templates if that remains mechanical. If a template needs a separate product decision, leave it as a follow-up rather than broadening the slice.
- [`docs/problems/2026-06-07-club-rejection-email-from-name.md`](../../problems/2026-06-07-club-rejection-email-from-name.md): expected to resolve. Rejection emails for inbound club messages should use a club-aware sender name such as `Kootenay Mountaineering Club via Memba`.
- [`docs/problems/2026-06-07-club-homepage-no-memba-home-link.md`](../../problems/2026-06-07-club-homepage-no-memba-home-link.md): expected to resolve. Public club pages should link back to the main Memba homepage.
- [`docs/problems/2026-06-07-club-homepage-no-cross-site-navigation.md`](../../problems/2026-06-07-club-homepage-no-cross-site-navigation.md): partially addressed. This iteration adds the Memba-home path, but deliberately does not design a signed-in club switcher or “other clubs” navigation.
- [`docs/problems/2026-06-07-homepage-lost-volunteering-hero-vision.md`](../../problems/2026-06-07-homepage-lost-volunteering-hero-vision.md): expected to resolve. The homepage hero should lead with the volunteering-focused promise rather than privacy/current-feature limitations.

## Scope

### In scope

- Restore or rewrite the homepage hero around the promise that volunteering should not feel like work.
- Keep homepage copy honest about today's product while leading with the larger outcome Memba is aiming for.
- Replace the sign-in email's check icon with the Memba sprig icon.
- Standardise the footer content/style for sign-in email and club-message rejection email.
- If the shared transactional email layout makes it mechanical, apply the same standard footer to all current transactional emails.
- Set the sender/display name for inbound club-message rejection emails to `<club name> via Memba`.
- Preserve the underlying sender address and reply/support behaviour unless an existing helper already makes the display-name change safely.
- Add a clear link from public club pages back to the main Memba homepage.
- Preserve the existing “Powered by Memba” footer unless the implementation naturally turns that into the homepage link.
- Add or update automated tests for the changed templates, display names, and navigation/copy.

### Out of scope

- Email replies or threading through Memba.
- Changing reply-to behaviour for club messages or rejection emails.
- Designing signed-in club switching or “other clubs” navigation from club pages.
- Staff person merge workflows.
- Custom club domains or DNS/HTTPS work.
- Pending invitation management or invitation expiry.
- Required onboarding/member profile details beyond existing fields.
- New email-template architecture beyond small reuse of the existing transactional email helpers/components.
- Rewriting the whole marketing site.

## Iteration Type

Behaviour-facing polish iteration.

The user-observable rules changed are:

- Visitors see Memba's volunteering promise on the homepage.
- People receiving Memba emails see consistent Memba branding and footer treatment.
- People receiving a club-message rejection email can tell which club the rejection is about from the sender name.
- Visitors on a public club page have a simple path back to Memba.

## Acceptance Scenarios / Feature Files

BDD decision: Required.

Although these are quick wins, they are user-visible trust and navigation behaviours. Stakeholder-readable scenarios help keep the slice focused on observable outcomes instead of template internals.

Planning adds these future-facing scenarios:

- `acceptance-tests/features/homepage.feature`
  - `@iteration-031 @not-domain @todo-ui` — `Scenario: Robin sees the volunteering vision first`
- `acceptance-tests/features/member_club_subdomains.feature`
  - `@iteration-031 @not-domain @todo-ui` — `Scenario: Robin returns from a club page to Memba`
- `acceptance-tests/features/email_branding.feature`
  - `@iteration-031 @todo-domain @todo-ui` — `Scenario: Alice receives a branded sign-in email`
  - `@iteration-031 @todo-domain @todo-ui` — `Scenario: Robin receives a KMC rejection email`

The scenarios are tagged with temporary runner-debt tags because this plan is ahead of implementation and the current runners do not yet have all supporting steps/behaviour.

## Allowed acceptance feature changes

- `acceptance-tests/features/homepage.feature`: implement the planned homepage hero scenario, then remove or narrow `@todo-ui` when the browser runner can execute it green. Keep `@not-domain` because homepage visual/copy prominence is not meaningful domain acceptance coverage.
- `acceptance-tests/features/member_club_subdomains.feature`: implement the planned public club-page return-to-Memba scenario, then remove or narrow `@todo-ui` when the browser runner can execute it green. Keep `@not-domain` because the public-page link is UI/navigation behaviour.
- `acceptance-tests/features/email_branding.feature`: implement the planned email-branding scenarios, then remove or narrow `@todo-domain`/`@todo-ui` as the domain and browser/email runners gain meaningful coverage. Preserve the rules that sign-in emails use Memba branding and club rejection emails identify the club.

## Acceptance Criteria

- The homepage hero includes the volunteering-focused promise, using or closely preserving the line “volunteering shouldn't feel like work”.
- The homepage still makes it clear Memba is for volunteer-run clubs.
- The homepage remains responsive on phone-sized screens.
- The sign-in email shows the Memba sprig icon, not the check icon.
- The sign-in email uses the standard Memba footer content/style.
- Inbound club-message rejection emails use the sender/display name format `<club name> via Memba`, for example `Kootenay Mountaineering Club via Memba`.
- Inbound club-message rejection emails use the standard Memba footer content/style.
- Footer text and styling are consistent across the transactional email templates touched by this iteration.
- If applying the standard footer to all current transactional emails is a small mechanical change through shared layout/helpers, do it in this iteration.
- If any current transactional email cannot safely use the standard footer without a product decision, leave that template unchanged and record it as a follow-up.
- Public club pages include a clear link to the main Memba homepage.
- The public club-page Memba link works from a club subdomain such as `kmc.clubs.memba.io` and points to the root Memba site, not to the club subdomain root.
- Existing public club page content and the “Powered by Memba” footer remain present unless replaced by an equivalent Memba-home link.
- Existing sign-in, inbound email rejection, and public club-page behaviours keep working.
- The new or changed acceptance scenarios pass after implementation with temporary `@todo-*` tags removed or narrowed where appropriate.
- `dev check` passes.

## Open Business Decisions

None known.

Confirmed decisions:

- The homepage should lead with the volunteering vision.
- Public club pages need a path back to the main Memba homepage.
- This iteration should not attempt broader signed-in club switching.
- Club rejection sender names should use `<club name> via Memba`.

## Implementation Plan

1. Inspect the current homepage template/component and identify the smallest copy/template change that restores the volunteering-first hero.
2. Update homepage tests or browser acceptance support so the volunteering promise is asserted without depending on fragile layout details.
3. Inspect the transactional email layout/helpers from iteration 024 and identify the canonical footer component or helper.
4. Replace the sign-in email icon with the Memba sprig asset/component used elsewhere in Memba branding.
5. Ensure the sign-in email uses the standard transactional email footer.
6. Inspect inbound club-message rejection email construction and the email request/provider shape for display-name support.
7. Change the club-message rejection email sender/display name to `<club name> via Memba` while preserving sender address, reply-to/support guidance, and rejection content.
8. Ensure the club-message rejection email uses the standard transactional email footer.
9. If the footer is already centralized, migrate any remaining current transactional templates to it with focused tests. Do not redesign templates.
10. Inspect public club-page template/layout and add a clear link to the main Memba homepage.
11. Ensure the homepage link resolves to the root Memba host when rendered from a club subdomain.
12. Add or update template/unit/LiveView/browser tests for the homepage copy, public club-page Memba link, sign-in email icon/footer, rejection sender name, and rejection footer.
13. Remove or narrow `@todo-*` tags from the planned acceptance scenarios once their runners can execute them meaningfully.
14. Run focused tests for changed web templates/components and email rendering.
15. Run the affected acceptance tests if executable.
16. Run `dev check`.

## Open Technical Decisions

- Exact asset/helper name for the Memba sprig icon in email templates.
- Exact shared footer helper/component to use after iteration 024's email template redesign.
- Exact URL helper/config source for linking from a club subdomain page to the main Memba homepage.

These are implementation details and should not need product decisions.

## New Capability

Memba presents a more coherent, trustworthy first impression: visitors see the volunteering promise, email recipients see consistent Memba branding, club rejection emails carry club context, and public club pages no longer strand visitors away from the main Memba site.

## Validation Plan

- Review the new acceptance scenarios as domain/stakeholder language before delivery.
- Run feature parsing/configuration checks to confirm the new `@iteration-031` scenarios are tagged correctly and excluded while future-facing.
- Run focused tests for homepage rendering and public club-page navigation.
- Run focused tests for sign-in email rendering, including icon and footer assertions.
- Run focused tests for inbound club-message rejection email rendering, including display name and footer assertions.
- Run affected browser acceptance scenarios after implementation removes/narrows `@todo-ui` tags.
- Run affected domain acceptance scenarios after implementation removes/narrows `@todo-domain` tags.
- Run full `dev check` before delivery is complete.

## Risks / Follow-ups

- Email footer standardisation could reveal older templates that need broader design decisions. Keep the iteration mechanical; record any non-mechanical template as follow-up.
- The public club-page homepage link only partially addresses broader cross-site navigation. A signed-in club switcher remains a separate product slice.
- Homepage copy can expand accidentally into a full marketing rewrite. Keep the change focused on the hero promise and any nearby copy needed for coherence.
- Provider-specific sender display-name support may differ. Tests should cover the provider request shape used in production, especially Postmark.
