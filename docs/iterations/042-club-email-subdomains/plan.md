# Club email subdomains

Date: 2026-06-21
Status: merged

## Goal

Move Memba's club inbound email addresses from a flat club-slug address to a Topicbox-style club email subdomain.

After this iteration, members email a club-wide message to:

```text
everyone@<club-slug>.clubs.memba.io
```

For example, Kootenay Mountaineering Club members use:

```text
everyone@kmc.clubs.memba.io
```

This replaces the current `kmc@clubs.memba.io` shape. The `everyone` local part is the only supported route in this slice. Reply-by-email behaviour from iteration 041 stays header-based: the visible reply destination changes to the new `everyone@<club>.clubs.memba.io` address, while `In-Reply-To` / `References` still decide whether inbound mail is a reply or a new club-wide message.

## Background / Context

Iteration 019 introduced inbound club messages at `<club-slug>@clubs.memba.io`, and iteration 020 moved production inbound mail to Postmark. Iteration 041 is in progress and keeps the simple visible club address while adding header-based reply routing.

Matt noticed Topicbox uses a per-group subdomain, such as `kmc.topicbox.com`. We want the same mental model for Memba email while keeping the namespace away from root `memba.io` subdomains such as `www`, `mail`, `admin`, or future app/service hosts. The agreed shape is therefore under `clubs.memba.io`, not `memba.io`:

```text
everyone@kmc.clubs.memba.io
```

A read-only Postmark investigation found that Postmark supports wildcard inbound domains such as `*.yourdomain.com` with an MX record pointing to `inbound.postmarkapp.com`. Current production Postmark is configured for `clubs.memba.io`; Matt will update Postmark/DNS to the wildcard setup before the iteration implementation runs.

## Related Problems

- [`docs/problems/2026-06-02-send-club-message-by-email.md`](../../problems/2026-06-02-send-club-message-by-email.md): **refines a resolved problem.** Iterations 019/020 resolved the ability to send club messages by email. This iteration answers the remaining address-shape question with the new canonical `everyone@<club>.clubs.memba.io` convention.
- [`docs/problems/2026-06-01-cant-reply-to-email-message.md`](../../problems/2026-06-01-cant-reply-to-email-message.md): **depends on iteration 041 and preserves its resolution.** This iteration should keep reply-by-email header routing working while changing the visible reply destination address.
- [`docs/problems/2026-06-04-rejected-inbound-emails-not-visible.md`](../../problems/2026-06-04-rejected-inbound-emails-not-visible.md): **intentionally unresolved.** Unsupported local parts, unknown club subdomains, and old flat addresses may create rejection records, but this iteration does not add a staff/moderator inbox for rejected inbound mail.

## Scope

### In scope

- Replace the canonical inbound club-wide address with `everyone@<club-slug>.clubs.memba.io`.
- Treat `everyone` as the only supported route/local part in this slice.
- Resolve the club slug from the first label before `.clubs.memba.io`, for example `kmc` from `everyone@kmc.clubs.memba.io`.
- Reject unsupported local parts such as `committee@kmc.clubs.memba.io` without creating a club message.
- Reject unknown club subdomains such as `everyone@unknown.clubs.memba.io` without creating a club message.
- Hard cutover from the old flat address: `kmc@clubs.memba.io` is no longer a member-facing or accepted address.
- Update member-facing address display on the member dashboard and member compose surfaces.
- Update generated reply destinations after iteration 041 so reply notification emails use `everyone@<club-slug>.clubs.memba.io` as the reply destination while preserving 041's header-based reply-vs-new decision.
- Update inbound rejection copy only where needed to explain unsupported/unknown recipient addresses safely.
- Update Postmark/DNS documentation and runbooks to describe the new wildcard setup.
- Update production smoke-test configuration, assertions, and docs from `test@clubs.memba.io` to `everyone@test.clubs.memba.io`.
- Run the production inbound smoke test after Matt has completed the Postmark/DNS prerequisite setup.
- Keep `dev check` green.

### Out of scope

- Channels/groups beyond the `everyone` route.
- Aliases such as `all@` or `members@`.
- Accepting arbitrary local parts as club-wide messages.
- Supporting the old `kmc@clubs.memba.io` shape as a compatibility alias.
- Root wildcard mail under `*.memba.io`.
- Club-owned custom inbound domains.
- Mutating Postmark or DNS from the implementation agent. Matt will perform the external configuration before implementation runs.
- Adding staff/moderator UI for rejected inbound email.
- Changing the reply-by-email matching policy from iteration 041. Header matching remains the routing mechanism for replies.

## Iteration Type

Behaviour-facing.

The user-observable rule changes from “email `<club-slug>@clubs.memba.io`” to “email `everyone@<club-slug>.clubs.memba.io`.” The visible address on member pages and reply emails changes, and inbound mail sent to unsupported routes, unknown club subdomains, or the old flat address is rejected safely.

## Acceptance Scenarios / Feature Files

BDD decision: **Required.**

This iteration changes the public email address convention, club resolution rule, unsupported-address policy, reply destination, and production smoke-test expectations. Stakeholder-readable examples are useful because the address shape is the product behaviour.

Updated during planning:

- `acceptance-tests/features/member_message_deliverability.feature`
  - Inbound club-message scenarios now describe the post-042 address convention: the accepted path, alternate sender path, unsafe-mail rejection paths, and body-stripping path use `everyone@kmc.clubs.memba.io`.
  - Added examples for unsupported local parts, unknown club subdomains, and the old flat `kmc@clubs.memba.io` address being rejected.
- `acceptance-tests/features/club_message_replies.feature`
  - Reply-by-email and no-header inbound examples now describe the post-042 visible destination, `everyone@kmc.clubs.memba.io`, while preserving 041's header-based reply routing rule.
- `acceptance-tests/features/email_branding.feature`
  - The club rejection-branding example now uses the post-042 `everyone@kmc.clubs.memba.io` address.

The `@todo-domain` / `@todo-ui` tags mark scenarios that describe the post-042 truth but will fail against the current pre-042 implementation, preserving the green mainline until implementation removes or narrows those tags.

## Allowed acceptance feature changes

- `acceptance-tests/features/member_message_deliverability.feature`: remove or narrow `@todo-domain` / `@todo-ui` as the post-042 `everyone@kmc.clubs.memba.io` scenarios become executable; preserve examples for unsupported local parts, unknown club subdomains, and old flat address rejection.
- `acceptance-tests/features/club_message_replies.feature`: remove or narrow `@todo-domain` / `@todo-ui` as reply-by-email examples using `everyone@<club-slug>.clubs.memba.io` become executable; preserve 039/040/041 conversation, follower, and header-routing rules.
- `acceptance-tests/features/email_branding.feature`: remove or narrow `@todo-domain` / `@todo-ui` from the inbound rejection branding example once the new address convention is implemented and the same branding coverage is executable.
- `smoke-tests/features/inbound_club_email.feature`: during implementation, update production smoke examples and support to use `everyone@test.clubs.memba.io` for the smoke club.

## Designs

No new design mock is needed.

This iteration changes visible copy/address text on existing surfaces rather than adding a new page, component, or state:

- Member dashboard inbound-address note: covered by `design-system/wireframes/club-home.html`, which already includes the “Prefer email?” note and mailto address.
- Member compose and message surfaces: covered by the existing member messaging designs and sketches, including `design-system/wireframes/member-messaging.html` and the reply-threading sketch in `docs/specs/2026-06-17-reply-threading-design-sketch.md`.
- Reply notification email: covered by the existing reply-notification design referenced by iterations 040/041; 042 changes the `Reply-To` destination address, not the email layout.

## Acceptance Criteria

- The KMC member dashboard shows `everyone@kmc.clubs.memba.io` as the address members can email to message the club.
- The KMC member compose page shows `everyone@kmc.clubs.memba.io` as the address members can email to message the club.
- `everyone@kmc.clubs.memba.io` resolves to Kootenay Mountaineering Club by the existing `kmc` club slug.
- An inbound email to `everyone@kmc.clubs.memba.io` from Alice's primary email address creates a KMC club message from Alice.
- An inbound email to `everyone@kmc.clubs.memba.io` from one of Alice's alternate email addresses also creates a KMC club message from Alice.
- Accepted inbound messages keep the same authorization, body handling, attachment rejection, idempotency, delivery, and visibility semantics already implemented for inbound club email.
- `committee@kmc.clubs.memba.io` and other unsupported local parts are rejected without creating a club message.
- `everyone@unknown.clubs.memba.io` and other unknown club subdomains are rejected without creating a club message.
- `kmc@clubs.memba.io` is no longer displayed as a member-facing address and is rejected if it reaches the app.
- Reply notification emails generated after iteration 041 use `everyone@<club-slug>.clubs.memba.io` as the reply destination.
- Reply-by-email still routes by recognized same-club `In-Reply-To` / `References` headers; no recognized same-club header still means a new club-wide message at the addressed club.
- Inbound emails addressed to the new shape preserve safe rejection behaviour for unknown senders, inactive members, non-members, unsupported attachments, and missing usable plain text.
- Postmark/DNS docs describe the prerequisite wildcard setup: `*.clubs.memba.io` as the inbound domain and wildcard MX to `inbound.postmarkapp.com`.
- Production smoke-test docs and config defaults use `everyone@test.clubs.memba.io` for the smoke club.
- After Matt applies the Postmark/DNS prerequisite, the production inbound smoke test passes against `everyone@test.clubs.memba.io`.
- `dev check` passes.

## Open Business Decisions

None known.

Confirmed decisions:

- Use `clubs.memba.io` as the namespace, not root `memba.io`.
- Hard cutover; do not keep the old flat address as an alias.
- Support only `everyone` in this slice.
- Defer channels/groups and aliases.
- Matt performs external Postmark/DNS setup before implementation.

## Implementation Plan

1. Inspect the current inbound address helper, destination resolver, Postmark/Resend inbound parsers, member dashboard/compose display, reply email generation from iteration 041, production smoke-test config, and Postmark docs.
2. Update the inbound address helper so a club slug renders as `everyone@<slug>.<configured inbound domain>`, where the production/default inbound namespace remains `clubs.memba.io`.
3. Update destination resolution to parse `local_part@host` where `host` is `<club-slug>.<configured inbound domain>`.
4. Accept only `local_part == "everyone"` for now.
5. Resolve `<club-slug>` through the existing Membership slug lookup.
6. Reject unsupported local parts, unknown club subdomains, unsupported domains, and the old flat address using the existing inbound rejection pathway where possible.
7. Update member dashboard and member compose copy/mailto links to display the new address.
8. After integrating with 041's result, update reply notification email `Reply-To` / reply destination generation to use the new address while preserving 041's `Message-ID` / `In-Reply-To` / `References` header behaviour.
9. Update provider parser or provider-neutral inbound email tests where recipient-address normalization assumes the old flat address.
10. Update acceptance step support to generate and submit new-address inbound webhook payloads; remove/narrow `@todo-domain` / `@todo-ui` tags as scenarios become executable.
11. Update `docs/postmark-email.md` and any production cutover/runbook text that describes inbound club-message email.
12. Update `smoke-tests/lib/config.js`, smoke-test assertions, and `smoke-tests/README.md` so the default smoke address is `everyone@test.clubs.memba.io` and Postmark diagnostics look for that recipient.
13. Run `dev check`.
14. After Matt confirms Postmark/DNS are configured for `*.clubs.memba.io`, run the production inbound smoke test and record/report the result.

## Open Technical Decisions

None that require product decisions before implementation.

Implementation choices left to the implementer, with constraints:

- The configured inbound namespace should remain environment-configurable, so local/dev can use a different domain while preserving the `everyone@<club>.<namespace>` shape.
- Rejection reason atoms/copy may reuse existing unsupported-recipient wording or add more specific `unsupported_inbound_route` / `unknown_club_subdomain` reasons if that keeps tests and support diagnostics clearer.
- If Postmark delivers `OriginalRecipient` with case, display name, or angle-bracket wrapping, normalization should remain case-insensitive and preserve enough original address for diagnostics.
- If 041 lands with specific message-id mapping modules, 042 should adapt to that design rather than introducing a parallel reply routing path.

## New Capability

Memba has a clearer club email namespace: each club owns a subdomain under `clubs.memba.io`, and the first route on that subdomain is `everyone`. This is a better foundation for future addresses such as channels or special-purpose routes while avoiding root `memba.io` subdomain reservation problems.

## Validation Plan

- Unit/domain tests for inbound address generation: `kmc` renders as `everyone@kmc.clubs.memba.io`.
- Unit/domain tests for destination resolution:
  - accepts `everyone@kmc.clubs.memba.io`;
  - rejects unsupported local parts;
  - rejects unknown club subdomains;
  - rejects unsupported domains;
  - rejects or no longer accepts `kmc@clubs.memba.io`.
- Existing inbound email acceptance tests rerun under the new address shape for primary address, alternate address, unknown sender, non-member, attachment rejection, HTML-only rejection, and quote/signature stripping.
- Reply-by-email tests from 041 rerun under the new reply destination address.
- Member dashboard and compose tests assert the new displayed address and mailto link.
- Documentation/runbook review confirms Postmark/DNS setup instructions use `*.clubs.memba.io` and `everyone@test.clubs.memba.io` for smoke tests.
- Production smoke tests are updated and run after Matt's Postmark/DNS prerequisite setup.
- Full `dev check`.

## Risks / Follow-ups

- **External prerequisite risk:** implementation expects Matt to configure Postmark/DNS first. If wildcard inbound mail is not live, automated app tests can pass but the production smoke test will fail at the provider/DNS boundary.
- **041 integration risk:** 041 is in progress. 042 must adapt to its final message-id/reply-destination implementation without regressing header-based reply routing.
- **Hard cutover risk:** any manual habits, seed data, docs, or smoke tests that still use `kmc@clubs.memba.io` will fail until updated. This is accepted because the app is still pre-launch.
- **Future channel semantics:** only `everyone` is accepted now. Channels such as `trips@kmc.clubs.memba.io` should be a separate future iteration with explicit membership/audience rules.
- **Rejected inbound visibility remains unresolved:** unsupported or unknown recipient mail can be rejected and recorded, but there is still no staff/moderator UI for rejected inbound email.
