# Memba Canvas

This is the single canonical strategy canvas for Memba. It combines the Lean Canvas summary and the Startup Canvas detail so HTML exports contain the whole strategy in one document.

## Table of Contents

- [Lean Canvas Summary](#lean-canvas-summary)
- [Core thesis](#core-thesis)
- [1. Problem](#problem)
  - [Problem A: Volunteer-run organizations are drowning in fragmented admin](#problem-a-volunteer-run-organizations-are-drowning-in-fragmented-admin)
  - [Problem B: Household and family memberships are hard to model well](#problem-b-household-and-family-memberships-are-hard-to-model-well)
  - [Problem C: Renewals and payments are table stakes but still painful](#problem-c-renewals-and-payments-are-table-stakes-but-still-painful)
  - [Problem D: Member communication is unreliable or disconnected](#problem-d-member-communication-is-unreliable-or-disconnected)
  - [Problem E: Outdoor clubs need activity/trip workflows beyond generic events](#problem-e-outdoor-clubs-need-activitytrip-workflows-beyond-generic-events)
  - [Problem F: Boards fear lock-in, price hikes, and vendor instability](#problem-f-boards-fear-lock-in-price-hikes-and-vendor-instability)
- [2. Solution](#solution)
  - [MVP: membership operations for volunteer-run clubs](#mvp-membership-operations-for-volunteer-run-clubs)
  - [Phase 2: lightweight activity/trip management](#phase-2-lightweight-activitytrip-management)
  - [Trust architecture](#trust-architecture)
  - [Defer by default](#defer-by-default)
- [3. Unique Value Proposition](#unique-value-proposition)
  - [Primary UVP](#primary-uvp)
  - [Beachhead message](#beachhead-message)
  - [Supporting messages](#supporting-messages)
  - [Positioning against key alternatives](#positioning-against-key-alternatives)
  - [Avoid positioning as](#avoid-positioning-as)
- [4. Unfair Advantage](#unfair-advantage)
  - [Current advantage: founder/domain fit and KMC pilot access](#current-advantage-founderdomain-fit-and-kmc-pilot-access)
  - [Potential durable advantages](#potential-durable-advantages)
  - [Not currently an unfair advantage](#not-currently-an-unfair-advantage)
- [5. Customer Segments](#customer-segments)
  - [Long-term market](#long-term-market)
  - [Primary initial segment](#primary-initial-segment)
  - [Secondary segment](#secondary-segment)
  - [Future segments](#future-segments)
  - [Personas](#personas)
- [6. Channels](#channels)
  - [1. KMC pilot and case study](#kmc-pilot-and-case-study)
  - [2. Direct outreach to club admins](#direct-outreach-to-club-admins)
  - [3. Switcher and comparison content](#switcher-and-comparison-content)
  - [4. Outdoor club networks and federations](#outdoor-club-networks-and-federations)
  - [5. SEO and problem-aware pages](#seo-and-problem-aware-pages)
  - [6. Integration-led adoption](#integration-led-adoption)
- [7. Revenue Streams](#revenue-streams)
  - [Recommended pricing principle](#recommended-pricing-principle)
  - [Updated pricing stance](#updated-pricing-stance)
  - [Pricing hypotheses](#pricing-hypotheses)
  - [Setup / migration revenue](#setup-migration-revenue)
  - [Revenue risks](#revenue-risks)
- [8. Cost Structure](#cost-structure)
  - [Fixed costs](#fixed-costs)
  - [Variable costs](#variable-costs)
  - [Biggest cost drivers](#biggest-cost-drivers)
- [9. Key Metrics](#key-metrics)
  - [North Star metric](#north-star-metric)
  - [Activation metrics](#activation-metrics)
  - [Retention metrics](#retention-metrics)
  - [Revenue metrics](#revenue-metrics)
  - [Product quality metrics](#product-quality-metrics)
  - [Activity/trip metrics, once launched](#activitytrip-metrics-once-launched)
- [Key assumptions and risks](#key-assumptions-and-risks)
  - [Assumption 1: clubs will pay enough](#assumption-1-clubs-will-pay-enough)
  - [Assumption 2: households are a strong enough wedge](#assumption-2-households-are-a-strong-enough-wedge)
  - [Assumption 3: waivers and activities are needed earlier than expected](#assumption-3-waivers-and-activities-are-needed-earlier-than-expected)
  - [Assumption 4: volunteer handoff is a real buying trigger](#assumption-4-volunteer-handoff-is-a-real-buying-trigger)
  - [Assumption 5: migration can be made easy](#assumption-5-migration-can-be-made-easy)
  - [Assumption 6: independence is valued if made credible](#assumption-6-independence-is-valued-if-made-credible)
  - [Assumption 7: AT Protocol is not needed for MVP](#assumption-7-at-protocol-is-not-needed-for-mvp)
- [Validation experiments](#validation-experiments)
  - [1. Customer interviews](#customer-interviews)
  - [2. Landing page test](#landing-page-test)
  - [3. Pricing test](#pricing-test)
  - [4. Concierge MVP](#concierge-mvp)
  - [5. Migration spike](#migration-spike)
  - [6. Waiver + Sheets pilot](#waiver-sheets-pilot)
  - [7. Competitive trials](#competitive-trials)
- [Open strategic questions from the whole picture](#open-strategic-questions-from-the-whole-picture)
- [Strategic recommendation](#strategic-recommendation)
- [Startup Canvas Detail](#startup-canvas-detail)
- [Vision](#vision)
  - [Long-term aspiration](#long-term-aspiration)
  - [North-star user outcome](#north-star-user-outcome)
  - [What the world looks like if Memba wins](#what-the-world-looks-like-if-memba-wins)
  - [Smallest version of success we would still be proud of](#smallest-version-of-success-we-would-still-be-proud-of)
  - [Why now](#why-now)
  - [Statement of stance](#statement-of-stance)
  - [White-label club websites](#white-label-club-websites)
  - [What Memba explicitly will not become](#what-memba-explicitly-will-not-become)
  - [Identity and form](#identity-and-form)
  - [Open questions / assumptions to test](#open-questions-assumptions-to-test)
- [Market Segments](#market-segments)
  - [0. Why segmentation is unusually hard here](#why-segmentation-is-unusually-hard-here)
  - [1. Primary axis: Job-to-Be-Done clusters](#primary-axis-job-to-be-done-clusters)
  - [2. Primary beachhead: KMC-archetype clubs](#primary-beachhead-kmc-archetype-clubs)
  - [3. Secondary segment: mid-sized regional clubs (300–1,000 members)](#secondary-segment-mid-sized-regional-clubs-3001000-members)
  - [4. Future segments](#future-segments-1)
  - [5. Segments to EXCLUDE explicitly](#segments-to-exclude-explicitly)
  - [6. Personas (within the beachhead)](#personas-within-the-beachhead)
  - [7. Market sizing (best-available estimates)](#market-sizing-best-available-estimates)
  - [8. JTBD-aligned segment summary](#jtbd-aligned-segment-summary)
  - [9. Assumptions, risks, and segmentation-specific validation](#assumptions-risks-and-segmentation-specific-validation)
- [Value Proposition](#value-proposition)
  - [1. Segment-anchored framing](#segment-anchored-framing)
  - [2. What Before — current customer problems and unmet needs](#what-before-current-customer-problems-and-unmet-needs)
  - [3. Value Proposition Canvas mapping](#value-proposition-canvas-mapping)
  - [4. What After — induced state we are claiming](#what-after-induced-state-we-are-claiming)
  - [5. Alternatives — competitive positioning (Value Curve)](#alternatives-competitive-positioning-value-curve)
  - [6. Primary UVP (refined) and alternative framings to test](#primary-uvp-refined-and-alternative-framings-to-test)
  - [7. What Memba is NOT](#what-memba-is-not)
  - [8. Messaging hierarchy](#messaging-hierarchy)
  - [9. Messaging hypotheses to A/B test](#messaging-hypotheses-to-ab-test)
- [Capabilities](#capabilities)
  - [1. The irreducible core](#the-irreducible-core)
  - [2. Discipline map (build / partner / buy)](#discipline-map-build-partner-buy)
  - [3. Key activities](#key-activities)
  - [4. Key resources](#key-resources)
  - [5. Differentiating vs table-stakes](#differentiating-vs-table-stakes)
  - [6. The not acquiring list (deliberate exclusions)](#the-not-acquiring-list-deliberate-exclusions)
  - [7. Capability gaps and closure plans](#capability-gaps-and-closure-plans)
  - [8. Single-point-of-failure dependencies (per §6 pitfall #6)](#single-point-of-failure-dependencies-per-6-pitfall-6)
  - [9. Capability risks and mitigations](#capability-risks-and-mitigations)
- [Trade-offs](#trade-offs)
  - [1. Spinal trade-off](#spinal-trade-off)
  - [2. Structural trade-offs (derived from S1)](#structural-trade-offs-derived-from-s1)
  - [3. Tactical deferrals (the explicit not now list)](#tactical-deferrals-the-explicit-not-now-list)
  - [4. Open trade-off decisions (need a call)](#open-trade-off-decisions-need-a-call)
  - [5. The sharpest commitments, restated](#the-sharpest-commitments-restated)
- [Can’t / Won’t](#cant-wont)
  - [Won’t (deliberate trade-offs)](#wont-deliberate-trade-offs)
  - [Can’t (structural limits today)](#cant-structural-limits-today)
  - [Revisit triggers](#revisit-triggers)
- [Growth](#growth)
  - [Growth posture](#growth-posture)
  - [Trust-sensitive growth guardrails](#trust-sensitive-growth-guardrails)
  - [Beachhead sequence](#beachhead-sequence)
  - [KMC pilot and reference loop](#kmc-pilot-and-reference-loop)
  - [Acquisition channels](#acquisition-channels)
  - [Activation milestones](#activation-milestones)
  - [Retention, expansion, and referral loops](#retention-expansion-and-referral-loops)
  - [Channel risks](#channel-risks)
  - [90-day growth experiments](#day-growth-experiments)
- [Key Metrics](#key-metrics-1)
  - [Measurement dangers for volunteer-club SaaS](#measurement-dangers-for-volunteer-club-saas)
  - [North Star metric](#north-star-metric-1)
  - [OMTM: pilot and next quarter](#omtm-pilot-and-next-quarter)
  - [AARRR adapted for Memba](#aarrr-adapted-for-memba)
  - [Core metric set](#core-metric-set)
  - [Guardrails and counter-metrics](#guardrails-and-counter-metrics)
  - [Stage targets](#stage-targets)
  - [Anti-Goodhart risks](#anti-goodhart-risks)
  - [Instrumentation needed](#instrumentation-needed)
- [Relative Costs](#relative-costs)
  - [Customer cost versus the alternatives](#customer-cost-versus-the-alternatives)
  - [Memba’s own cost-to-serve implications](#membas-own-cost-to-serve-implications)
  - [Decision and tripwires](#decision-and-tripwires)
  - [Customer-facing cost narrative](#customer-facing-cost-narrative)
- [Cost Structure](#cost-structure-1)
  - [Unit of value and gross-margin frame](#unit-of-value-and-gross-margin-frame)
  - [Fixed operating costs](#fixed-operating-costs)
  - [Variable costs](#variable-costs-1)
  - [GTM costs](#gtm-costs)
  - [Trust and continuity commitments](#trust-and-continuity-commitments)
  - [Scenario estimates](#scenario-estimates)
  - [Gross-margin risks and reduction levers](#gross-margin-risks-and-reduction-levers)
- [Revenue Streams](#revenue-streams-1)
  - [Revenue architecture options](#revenue-architecture-options)
  - [Recommended model](#recommended-model)
  - [Pricing hypotheses](#pricing-hypotheses-1)
  - [Why not free](#why-not-free)
  - [Annual billing](#annual-billing)
  - [Setup and migration revenue](#setup-and-migration-revenue)
  - [Payment-processing stance](#payment-processing-stance)
  - [Trust covenant and pricing pledge implications](#trust-covenant-and-pricing-pledge-implications)
  - [ARR scenarios](#arr-scenarios)
  - [Competitive pricing risks](#competitive-pricing-risks)
  - [Experiments to validate willingness to pay](#experiments-to-validate-willingness-to-pay)

## Lean Canvas Summary

This Lean Canvas synthesizes the original product idea, the first research round, the second competitor-gap notes in `docs/strategy/research/round2-competitor-analysis/`, and the May 2026 `Competitor Gap Pass for Memba` report in `docs/strategy/research/extracted-text/`.

## Core thesis

Memba has a credible opportunity if it starts narrow but thinks broader: build membership operations software for volunteer-run membership organizations, using outdoor/activity clubs as the beachhead.

The long-term market is not only outdoor clubs. It is any member-based organization run by rotating volunteers: outdoor clubs, sport and recreation clubs, community associations, hobby groups, cultural groups, alumni groups, faith/community groups, and similar organizations that need members, dues, renewals, roles, communications, private content, and continuity.

The initial wedge should remain volunteer-run outdoor/activity clubs because their needs are concentrated and painful: households, renewals, waivers, emergency contacts, member-only activities, trip leaders, participant lists, privacy, and volunteer handoff. KMC is the design partner and proof point.

Second-round research changes the strategy in three important ways:

1. **Fair pricing is not enough.** Zeffy, HelloAsso, Givebutter, Spond Club, Heylo, membermojo, Clubforce, Yapla, and TidyHQ prove that clubs can find free, cheap, or transparent tools. Memba should still be fair and non-extractive, but “fair pricing” is table stakes, not the moat.
2. **The moat is the integrated domain model.** The strongest combination is households + individual people + membership status + waivers + activities/trips + emergency contacts + privacy + volunteer handoff. Competitors solve pieces, but not the whole volunteer-club operating model.
3. **Trust and independence matter, but must be made concrete.** “Bootstrapped and won’t sell out” is useful as a reason to believe, especially against PE/VC-backed incumbents, but it is not credible unless backed by data portability, a public pricing pledge, continuity planning, and possibly steward-ownership or B-Corp commitments.

## 1. Problem

### Problem A: Volunteer-run organizations are drowning in fragmented admin

Small and mid-sized clubs often run on spreadsheets, old websites, PayPal/Stripe buttons, Mailchimp, Google Groups, waiver PDFs, Meetup/Eventbrite, and manual treasurer work.

Research signals:

- Many clubs have low annual dues, often around $20–$50 per individual and $50–$200 per family.
- A 100-member club charging $25/year only grosses $2,500/year, so software must justify itself against a low budget.
- Volunteer administrators spend recurring time on roster cleanup, renewal chasing, payment reconciliation, communication lists, and handoff.
- The next volunteer secretary or treasurer often inherits undocumented workflows and fragile spreadsheets.

Current unsatisfactory solutions:

- Google Sheets / Excel: familiar but manual, insecure, and disconnected from payments and access control.
- Google Groups / Mailchimp: useful communication tools but not membership systems.
- WordPress plugins: flexible but create maintenance, security, and volunteer-burnout risk.
- Legacy AMS tools: broad but often expensive, clunky, staff-oriented, or acquisition-damaged.
- Free fundraising tools such as Zeffy: excellent for donations/forms/payments, but not a complete membership operating system.

### Problem B: Household and family memberships are hard to model well

Many volunteer organizations sell household/family memberships, but “family membership” often means only a bundle price or a shared transaction.

The real need is more subtle:

- One payer or household billing relationship.
- Multiple individual people.
- Shared address and billing details.
- Individual logins, permissions, waivers, emergency contacts, activity participation, privacy choices, and renewal status.
- Children aging into adult memberships.
- Partners, dependents, blended households, and mixed membership types.

Second-round research nuance:

- TidyHQ and Amilia have credible family/household support, so Memba cannot treat households as wholly unserved.
- Zeffy and Heylo appear weaker on true household modeling: they may support family payments or individual recurring memberships, but not the full “one household, many people, individual records” model Memba envisions.
- The wedge is not merely “family memberships exist”; it is **households done correctly for volunteer-admin workflows**.

### Problem C: Renewals and payments are table stakes but still painful

Membership revenue is small but essential. Clubs need to know who is active, lapsed, paid, unpaid, expired, pending, and eligible for member-only benefits.

Common pains:

- Manual renewal chasing.
- One-off invoices or reminders.
- Failed payment follow-up.
- Calendar-year vs anniversary renewal confusion.
- Offline payment recording.
- Mistake correction and refunds.
- Platform fees, processor lock-in, and percentage surcharges.

Second-round research nuance:

- Renewal/payment automation is not a differentiator by itself; Zeffy, Heylo, TidyHQ, Amilia, Wild Apricot, and others all solve parts of it.
- Memba must win by connecting renewals to households, roles, waivers, access, directories, and activities.

### Problem D: Member communication is unreliable or disconnected

Clubs need official announcements, renewal reminders, member-only updates, and sometimes activity-specific communication.

Current tools solve pieces:

- Google Groups handles mailing-list conversations but has no membership lifecycle.
- Mailchimp handles newsletters but creates a separate contact database.
- Discourse handles discussion but not dues, renewals, households, or access control.
- Heylo handles community/social communication, but may be more leader/social-first than secretary/back-office-first.

### Problem E: Outdoor clubs need activity/trip workflows beyond generic events

For the outdoor-club beachhead, activities are central to member value. Generic events often fail to model:

- Trip leader and co-leader roles.
- Capacity and waitlists.
- Expressions of interest and leader approval.
- Waivers and waiver expiry.
- Emergency contacts.
- Skill/qualification checks.
- Member-only visibility.
- Participant communication.
- Carpool and logistics notes.

Second-round research nuance:

- Heylo contests part of this: it has events, capacity/waitlists, payments, and paid native waivers.
- TidyHQ has events and strong family membership support, but limited native waiver/trip depth.
- Amilia has strong activity registration for facilities and programs, but not volunteer-led outdoor trip workflows.
- Memba’s opportunity is **not** generic event management; it is membership-aware activity operations for volunteer-run organizations.

### Problem F: Boards fear lock-in, price hikes, and vendor instability

Research into Wild Apricot and ClubExpress validates a real consolidation-pain story: acquired platforms can bring price increases, payment-processor pressure, support decline, and roadmap stagnation.

But small clubs may also fear the opposite: a tiny bootstrapped vendor with founder bus-factor risk. Memba must solve both trust problems:

- Not extractive or acquisition-driven.
- Not fragile, opaque, or hard to leave.

## 2. Solution

### MVP: membership operations for volunteer-run clubs

The MVP should focus on the core admin loop: members, households, renewals, payments, access, directory, announcements, waivers, export/sync, and roles.

#### 1. Member and household database

- Current, expired, prospective, and past members.
- Individual profiles.
- Household/family relationships.
- Shared billing account with individual member records.
- Date of birth.
- Address.
- Phone number.
- Emergency contact.
- Membership status.
- Renewal and expiry dates.
- Waiver status.
- Optional club-specific fields such as certifications, skill tier, leader status, equipment qualifications, or background checks.

#### 2. Renewal and payment engine

- Stripe payments initially.
- Calendar-fixed and rolling anniversary renewals.
- Automated reminders before expiry.
- Grace periods.
- Failed-payment handling.
- Offline payment recording.
- One-click renewal links.
- Easy admin corrections, refunds, and manual adjustments.

#### 3. Households done properly

- One bill, multiple people.
- Individual profiles and logins.
- Shared address and household contact details.
- Per-person waiver, participation, and directory visibility.
- Adult/child/dependent distinctions.
- Child aging-up flows.
- Admin tools for edge cases, imports, merges, separations, and transfers.

#### 4. Native waiver and risk workflows

- Waiver templates and versioning.
- Per-person acceptance status.
- Expiry and renewal tracking.
- Exportable evidence of acceptance.
- Emergency contacts tied to the person and surfaced on activity rosters.
- Clear distinction between lightweight checkbox consent and stronger e-signature options if legally required.

#### 5. Club website, privacy-aware member directory, and private content

- A hosted club website that can replace the fragile WordPress/static/custom site many clubs already maintain.
- Public pages for the club's outward-facing presence.
- Member-only pages and files.
- Searchable member directory.
- Member-controlled visibility for email, phone, address, and profile details.
- Access tied directly to active membership status.
- Club branding: logo upload, colors, and later custom domain support.

#### 6. Volunteer-friendly admin and handoff tools

- Clean admin dashboard.
- Bulk actions.
- Audit trails.
- Simple CSV import/export.
- Google Sheets export or sync as a trust bridge.
- Granular roles: owner/treasurer, registrar, communications admin, trip/activity leader.
- Handoff mode: checklist, key workflows, permission transfer, “what the next volunteer needs to know.”

#### 7. Announcements

- Reliable official club email announcements.
- Simple templates.
- Sender permissions.
- Delivery and bounce visibility.
- Later: member-to-member list bridge or activity-specific messaging.

### Phase 2: lightweight activity/trip management

Soon after the MVP, add activity/trip workflows for the beachhead:

- Activities/trips.
- Leader/co-leader.
- Date/time/location.
- Capacity.
- Waitlist.
- Expression of interest.
- Leader approval.
- Member-only visibility.
- Attendee lists.
- Emergency contacts.
- Waiver status.
- Activity-specific messages.

Avoid overbuilding into full course management, gear reservation, cabin booking, trail-status systems, public discovery, or municipal recreation management until validated.

### Trust architecture

Memba should ship trust as product, not just marketing:

- Full self-serve export in standard formats.
- “Leave anytime” portability.
- Public pricing pledge.
- No forced proprietary payment processor.
- Clear continuity plan if the business shuts down or changes hands.
- Consider B-Corp or steward-ownership if “won’t sell out” becomes central messaging.

### Defer by default

- AT Protocol/federation.
- Native mobile app.
- Full forum/discussion product.
- Generic, open-ended website builder unrelated to club operations.
- LMS/courses.
- Deep donation management.
- Marketplace/public discovery.
- Complex branded mobile apps.
- Facility scheduling / Parks & Rec management.

## 3. Unique Value Proposition

### Primary UVP

> Memba is membership software for volunteer-run clubs: households, renewals, waivers, directories, announcements, and activities in one simple system the next volunteer can actually inherit.

### Beachhead message

> Built for outdoor clubs that have outgrown spreadsheets but do not want Wild Apricot bloat, Zeffy workarounds, or a social app pretending to be club operations.

### Supporting messages

- Designed for rotating volunteer admins, not professional association staff.
- Real households: one renewal, multiple people, individual profiles, waivers, privacy, and emergency contacts.
- Membership-aware waivers and activities, not generic event forms.
- Transparent, non-extractive pricing: no payment surcharge, no contact-count punishment, no tip-tax on members.
- Works with the spreadsheet reality clubs already have.
- Leave anytime: clean exports and portability by design.
- Founder-led and independent, with concrete commitments that reduce lock-in and bus-factor risk.

### Positioning against key alternatives

- **TidyHQ:** strongest like-for-like volunteer-club benchmark, especially in Commonwealth markets; Memba must beat it on waivers, outdoor activity depth, UX, and volunteer handoff.
- **Amilia:** powerful Canadian recreation/facility system with credible family, waivers, waitlists, and permissions; too expensive and complex for the initial volunteer-club beachhead, but a very serious Canada benchmark.
- **Heylo:** strong community app with memberships, events, waitlists, exports, permissions, and paid waivers; dangerous for hiking/running/cycling groups that think of themselves as event communities before they think of themselves as associations.
- **Zeffy / Givebutter / Donorbox:** great free or low-cost fundraising, forms, CRM, and payments; weak for full club operations, true households, member portals, privacy, waivers, and activity workflows.
- **Spond Club / Clubforce / SportLoMo:** strong in grassroots or governed sport, with free/low-cost expectations and parent/guardian patterns; less perfect for informal outdoor associations, but highly relevant if the club behaves like a sport body.
- **membermojo / Yapla / HelloAsso:** prove that free or very-low-cost membership administration is a real expectation in some regions; HelloAsso is France-only, while membermojo and Yapla are practical price anchors in the UK and Canada respectively.
- **Communal:** direct-convergence watchlist competitor because it frames itself around community/member organizations, bookings, programs, payments, and active-member pricing.
- **Wild Apricot / ClubExpress:** broad incumbents; vulnerable on UX, family modeling, support, pricing, and acquisition/consolidation pain.
- **DIY stack:** cheap and familiar, but fragile, manual, insecure, and hard to hand off.

### Avoid positioning as

- A generic association management platform.
- A creator/community platform.
- A WordPress replacement.
- A full social network.
- A municipal recreation/facility platform.
- An AI-powered community product.
- The cheapest/free option.

## 4. Unfair Advantage

### Current advantage: founder/domain fit and KMC pilot access

The strongest immediate advantage is direct domain access through KMC: real users, real member data, real renewal processes, real privacy concerns, real volunteer handoff, and a credible pilot/reference case.

### Potential durable advantages

#### 1. Integrated volunteer-club domain model

The durable advantage is not any one feature. It is the combination:

- People.
- Households.
- Active/lapsed membership periods.
- Payments.
- Waivers.
- Emergency contacts.
- Roles and permissions.
- Privacy.
- Member-only content.
- Activities/trips.
- Volunteer handoff.

Competitors can copy individual features, but a coherent model tuned to volunteer-run organizations is harder to retrofit.

#### 2. Secretary-first simplicity and handoff

Most tools are built either for professional staff, fundraisers, social group leaders, or broad association administrators. Memba can own the “new volunteer inherits the system and understands it in one evening” outcome.

#### 3. Trust through independence, portability, and non-extractive pricing

Research found real frustration with acquired platforms, price increases, support decline, payment-processor pressure, and data lock-in. Memba can differentiate with:

- Active-member pricing.
- Unlimited archived contacts.
- No Memba surcharge on top of standard payment processing.
- No mandatory tip prompt to members.
- Clean exports.
- Google Sheets sync.
- Public pricing pledge.
- Clear continuity plan.

This is a supporting advantage, not the whole moat.

#### 4. Activity/trip integration

Once Memba ties membership status, waivers, emergency contacts, leader roles, directories, announcements, and trips together, it becomes more than a member database.

#### 5. Human support and migration friendliness

Early customers are likely to need reassurance and migration help. Founder-led, responsive support can win early trust if support load is kept under control.

### Not currently an unfair advantage

- **Fair pricing alone:** weakened by Zeffy, HelloAsso, Spond Club, Heylo, TidyHQ, membermojo, Clubforce, Yapla, and donation-tip-funded tools.
- **Payments/renewals alone:** table stakes.
- **Events alone:** already well served.
- **Waivers alone:** Heylo contests this.
- **AT Protocol:** strategic curiosity, not MVP advantage.

## 5. Customer Segments

### Long-term market

Volunteer-run membership organizations: groups with members, dues/renewals, communications, roles, private content, and frequent admin turnover.

Possible verticals include outdoor clubs, sport/recreation clubs, hobby groups, cultural associations, alumni groups, community associations, faith/community groups, and other membership organizations run by volunteers.

### Primary initial segment

Volunteer-run outdoor/activity clubs with approximately 30–300 members.

These clubs are often:

- Too organized for spreadsheets alone.
- Too budget-constrained for heavy AMS or recreation-management tools.
- Run by rotating volunteers.
- Likely to have household memberships.
- Likely to run trips, events, or activities.
- Likely to need waivers, emergency contacts, member-only rosters, communications, and directories.

KMC is the initial pilot and design partner.

### Secondary segment

Mid-sized outdoor/activity clubs with approximately 300–1,000 members.

These clubs may already use Wild Apricot, ClubExpress, TidyHQ, Join It, MemberPlanet, Heylo, Zeffy, or a custom stack. They are more likely to pay, but migration friction and board approval cycles are higher.

### Future segments

- Other volunteer-run clubs with household memberships and recurring activities.
- Larger regional clubs.
- Umbrella organizations and federations.
- Volunteer-heavy organizations that need continuity, privacy, payments, and member-only access but not facility-management software.

These should not define the MVP until the beachhead is validated.

### Personas

#### Membership Secretary / Registrar

The primary operational buyer/influencer.

Needs: accurate roster, renewal tracking, imports/exports, family membership handling, minimal manual work, and easy handoff.

#### Treasurer

Needs: payment visibility, reconciliation, offline payment recording, refunds/corrections, predictable cost, and no surprise surcharges.

#### Communications Admin

Needs: official announcements, sender permissions, reliable delivery, and clean member lists.

#### Board / Executive

Needs: risk reduction, continuity, privacy, data protection, credible business case, and avoidance of volunteer burnout.

#### Trip / Activity Leader

Needs: participant list, emergency contacts, waiver status, capacity/waitlist, attendee communication, and confidence participants are active members.

#### Regular Member

Needs: easy join/renew, clear status, profile updates, directory access, member-only content, privacy controls, and activity signup.

## 6. Channels

### 1. KMC pilot and case study

Use KMC as design partner, MVP proving ground, and first public reference.

### 2. Direct outreach to club admins

Target membership secretaries, treasurers, webmasters, trip coordinators, and presidents.

Trigger moments:

- Renewal season.
- Board turnover.
- Volunteer handoff crisis.
- Website redesign.
- Mailing-list failure.
- Waiver/liability concern.
- Wild Apricot/ClubExpress renewal or price increase.
- Failed attempt to use Zeffy/Heylo/TidyHQ/DIY for full club operations.

### 3. Switcher and comparison content

Create practical guides:

- Switch from Wild Apricot without losing your data.
- Zeffy vs Memba for membership clubs.
- Heylo vs Memba for outdoor clubs.
- TidyHQ vs Memba for volunteer-run clubs.
- How to model family memberships properly.
- How to stop running renewals in a spreadsheet.
- How to hand off club admin without chaos.

### 4. Outdoor club networks and federations

Possible channels:

- Mountaineering federations.
- Hiking club directories.
- Paddling associations.
- Cycling clubs and regional bodies.
- Trail associations.
- Ski touring clubs.

### 5. SEO and problem-aware pages

Search targets:

- Membership software for volunteer clubs.
- Membership software for hiking/outdoor clubs.
- Family membership software.
- Club waiver software.
- Club renewal software.
- Wild Apricot alternative.
- TidyHQ alternative.
- Zeffy alternative for clubs.
- Google Groups alternative for clubs.

### 6. Integration-led adoption

Lead with low-risk wedges if full migration feels too scary:

- Waiver collection + roster sync.
- Google Sheets sync.
- Renewal reminders.
- Directory/member portal.
- Household cleanup/import tool.

## 7. Revenue Streams

### Recommended pricing principle

Price by active members, not total contacts.

This counters contact-count frustration and lets clubs keep lapsed members, prospects, alumni, and history without being punished.

### Updated pricing stance

Memba should not try to be free. Zeffy and Heylo create a low-cost anchor, but Memba’s paid model should be justified by operational depth, trust, and reduced volunteer burden.

Principles:

- Transparent subscription.
- No Memba transaction surcharge.
- No mandatory payment-processor lock-in.
- No member tip prompts.
- Clean export included.
- Annual billing option aligned with club budget cycles.

### Pricing hypotheses

#### Starter: $29–$49/month

For small clubs up to roughly 100–150 active members.

Includes: member database, households, renewals, Stripe checkout, basic reminders, CSV import/export, Google Sheets export/sync, basic directory.

#### Club: $59–$99/month

For clubs up to roughly 300–750 active members.

Adds: waivers, member directory, private content, granular roles, announcements, activity basics, reporting.

#### Pro: $129–$199/month

For larger clubs up to roughly 1,500–2,000 active members.

Adds: advanced activity/trip workflows, custom domain, advanced communication tools, priority support, migration assistance, advanced reporting.

These prices need validation. The old $19–$29 starter may attract high-support, low-margin customers and may not be meaningfully better than free alternatives.

### Setup / migration revenue

Concierge migration may be a key differentiator and cost-control lever:

- Free/discounted migration for design partners.
- Paid migration for larger clubs.
- Import templates for Wild Apricot, ClubExpress, TidyHQ, Zeffy, Heylo, CSV, and Google Sheets.
- Household cleanup service as a paid add-on.

### Revenue risks

- Small clubs may be too price-sensitive for meaningful ARPU.
- Free tools may be “good enough” for simple clubs.
- Larger clubs may require complex migration and support.
- A low entry price can create a high-support, low-margin customer base.
- If waivers/activity workflows are required to justify price, MVP scope may need to expand earlier.

## 8. Cost Structure

### Fixed costs

- Product development.
- Hosting/infrastructure.
- Database backups and monitoring.
- Email deliverability infrastructure.
- Stripe/payment integration.
- Security and privacy work.
- Documentation.
- Customer support systems.
- Migration tooling.
- Legal review for waiver workflows and liability wording.

### Variable costs

- Email sending.
- File storage for waivers/files.
- Support time per club.
- Migration/onboarding time.
- Payment processor fees passed through.
- Possible SMS costs later.

### Biggest cost drivers

#### 1. Support and onboarding

Volunteer admins need reassurance. Poor onboarding could consume the business.

#### 2. Migration complexity

Rosters, households, lapsed members, duplicates, historic spreadsheets, and waiver data will be messy.

#### 3. Email deliverability

Reliable club email requires DNS setup, bounce handling, unsubscribe rules, reputation monitoring, and user education.

#### 4. Household edge cases

The wedge is valuable because it is messy. It must be modeled carefully without overbuilding.

#### 5. Waiver and liability workflow

Native waivers are a differentiator but create product, legal, storage, export, and support obligations.

#### 6. Activity/trip scope creep

Outdoor clubs may ask for qualifications, gear, cabins, maps, courses, permits, fleet, incident reporting, and public discovery. The product must stay disciplined.

#### 7. Trust/continuity commitments

If Memba promises portability, continuity, and independence, those commitments require engineering, documentation, legal structure, and operational discipline.

## 9. Key Metrics

### North Star metric

Monthly active clubs successfully running membership operations through Memba.

A club counts only if it is using Memba for at least two of: renewals, households, waivers, directory/member access, announcements, or activities.

Secondary North Star:

Active members managed by Memba.

### Activation metrics

- Club imports first roster.
- Club configures membership types and households.
- Club enables payments.
- First member renews successfully.
- First household renews successfully.
- First waiver accepted.
- First admin sends renewal reminders.
- First member logs in and updates profile.
- First Google Sheet sync/export completed.
- First volunteer handoff checklist completed.

### Retention metrics

- Club annual renewal rate.
- Percentage of members renewed through Memba.
- Monthly admin activity.
- Number of active admins per club.
- Support tickets per club per month.
- Number of manual workarounds still required.
- Whether a second volunteer can successfully administer the system.

### Revenue metrics

- ARR.
- Revenue per club.
- Gross margin after support/migration.
- Paid pilot conversion.
- CAC payback.
- Expansion from Starter to Club/Pro tiers.

### Product quality metrics

- Payment success rate.
- Renewal reminder conversion.
- Email delivery rate.
- Import error rate.
- Time to migrate a club.
- Time for a new volunteer admin to complete common tasks.
- Household renewal error rate.
- Waiver completion and retrieval success.

### Activity/trip metrics, once launched

- Activities created.
- Percentage of activities with participant list in Memba.
- Waiver completion rate.
- Waitlist usage.
- Trip/activity leader repeat usage.
- Emergency contact access rate before trips.

## Key assumptions and risks

### Assumption 1: clubs will pay enough

Zeffy and Heylo raise the bar by offering credible free/low-cost alternatives. Memba must prove it saves enough time, reduces enough risk, and improves enough continuity to justify paid subscription pricing.

Validation:

- Ask for paid pilots.
- Test pricing pages against Zeffy/Heylo/TidyHQ alternatives.
- Use board proposal tools.
- Measure admin hours saved in KMC.

### Assumption 2: households are a strong enough wedge

TidyHQ and Amilia weaken the claim that households are unserved. Memba must validate that its household model is meaningfully better for the beachhead.

Validation:

- Prototype household flows before locking schema.
- Test messy KMC-like household edge cases.
- Compare directly with TidyHQ and Amilia household workflows.
- Interview clubs with family memberships.

### Assumption 3: waivers and activities are needed earlier than expected

Heylo already offers paid waivers and strong event tooling. If waivers/activities are what justify payment over Zeffy, they may need to move closer to MVP.

Validation:

- Test “membership + households” vs “membership + waivers + activities” willingness to pay.
- Run a waiver + roster pilot.
- Interview trip/activity leaders.

### Assumption 4: volunteer handoff is a real buying trigger

Research suggests it is under-addressed, but it may be more of a retention/value proof than an initial purchase trigger.

Validation:

- Ask recent/current club officers about handoff failures.
- Prototype a handoff checklist/workflow.
- Test “the next volunteer can run it” messaging.

### Assumption 5: migration can be made easy

Even a better tool may lose if migration feels scary.

Validation:

- Build import templates.
- Run a real migration from KMC data.
- Measure time-to-live.
- Build a TidyHQ/Wild Apricot/Zeffy/CSV migration map.

### Assumption 6: independence is valued if made credible

“Bootstrapped, independent, won’t sell out” resonates against acquired incumbents, but can trigger bus-factor fear.

Validation:

- Test independence as a supporting message, not headline.
- Offer data portability and pricing pledge in interviews.
- Ask boards whether founder-led vendor risk worries them.

### Assumption 7: AT Protocol is not needed for MVP

Research found no buyer evidence that federation/social identity matters more than renewals, households, migration, waivers, and volunteer handoff.

Validation:

- Keep AT Protocol as a separate research spike.
- Do not let it block the Phoenix-first MVP.

## Validation experiments

### 1. Customer interviews

Interview 15–25 volunteer admins across clubs of 50, 200, 500, and 1,500 members.

Success signal:

- At least 10 cite two or more of households, renewals, waivers, activities, migration, email, or volunteer handoff as top pains.
- At least 5 indicate willingness to pay $50+/month for the integrated solution.

### 2. Landing page test

Message: “Membership software for volunteer-run clubs.”

Test variants:

- Households + renewals.
- Membership + waivers + activities.
- The next volunteer can run it.
- Transparent alternative to Wild Apricot.
- Better club operations than Zeffy + spreadsheets.

### 3. Pricing test

Compare pricing ladders:

- $29 / $59 / $129.
- $39 / $79 / $149.
- $49 / $99 / $199.

Test against explicit alternatives: Zeffy free, Heylo Pro at $59/mo plus fees, TidyHQ around $50–$65/mo, Amilia $99/mo plus setup and invoice fees.

### 4. Concierge MVP

Recruit 3–5 clubs for a design-partner program using a partially manual backend.

Success signal:

- Clubs run real renewals through Memba.
- At least one converts to a paid retail rate.
- Admins report time saved.
- A second volunteer can take over without founder help.

### 5. Migration spike

Build “switch from spreadsheet/Wild Apricot/TidyHQ/Zeffy/Heylo” importers or checklists.

Success signal:

- Median migration under two hours for a simple club.
- Household mapping is understandable.
- Data export/import builds trust.

### 6. Waiver + Sheets pilot

If full migration is too scary, offer a standalone waiver + roster sync tool.

Success signal:

- Clubs adopt it without replacing their whole stack.
- It creates a path to full Memba adoption.
- It validates whether waivers are a strong beachhead wedge.

### 7. Competitive trials

Hands-on trial Zeffy, Heylo, TidyHQ, and Amilia against KMC-like scenarios.

Scenarios:

- Import members and households.
- Create family renewal.
- Record waiver for each person.
- Create member-only activity with capacity/waitlist.
- Export everything.
- Hand admin role to a new volunteer.

## Open strategic questions from the whole picture

1. **Beachhead vs vision:** How broad should the public positioning be? “Volunteer-run clubs” may fit the long-term ambition, while “outdoor clubs” may be sharper for the first 10 customers.
2. **MVP scope:** Can Memba launch with membership + households + renewals only, or do waivers/activities need to be in v1 to justify paid adoption over Zeffy/Heylo?
3. **Household depth:** What exact household edge cases must Memba solve on day one to beat TidyHQ rather than merely match it?
4. **Waiver standard:** Is checkbox acceptance enough, or do target clubs need stronger e-signature, versioning, legal review, and audit trails?
5. **Pricing floor:** What is the minimum viable ARPU that avoids a high-support, low-margin customer base, and will 30–100 member clubs pay it?
6. **Free tier:** Should Memba offer a free tier for very small clubs, or would that attract the wrong customers and compete with Zeffy on unfavorable terms?
7. **Independence promise:** What concrete mechanism will make “we won’t sell out / leave anytime” credible: pricing pledge, data escrow, open-source core, B-Corp, steward ownership, or something else?
8. **Bus-factor risk:** How will Memba convince boards that a bootstrapped founder-led product is safer than a PE-backed incumbent?
9. **Secretary vs leader buyer:** Is the real buyer the membership secretary, treasurer, trip coordinator, president, or the person suffering most during handoff?
10. **Channel wedge:** Are the first customers more likely to arrive through Wild Apricot/TidyHQ switcher pain, Zeffy workaround frustration, outdoor-federation networks, or KMC referrals?
11. **Competitive watch:** How quickly could Heylo add households, or Zeffy add waivers/member portals, and what must Memba ship before that happens?
12. **Expansion path:** After outdoor clubs, which adjacent volunteer-run segment has the same household + renewal + activity + handoff pain without requiring a totally different product?
13. **Legal exposure:** How much liability does Memba assume by storing waivers and emergency contacts, and what legal/insurance posture is needed?
14. **Data model commitment:** Which concepts must be foundational from day one — clubs, people, households, memberships, waivers, roles, activities — so the product does not paint itself into a corner?
15. **Trust as product:** What must be visible in the UI from day one to make Memba feel portable, safe, and non-extractive rather than just another SaaS promise?

## Strategic recommendation

Build a Phoenix-first responsive web MVP for KMC and similar volunteer-run outdoor/activity clubs, but frame the long-term company as serving volunteer-run membership organizations.

Do not make AT Protocol, native mobile, full social networking, public discovery, or facility-management features a dependency for the first release.

Design the core model around:

- Clubs/organizations.
- People.
- Households.
- Membership periods.
- Payments.
- Waivers.
- Emergency contacts.
- Roles.
- Privacy.
- Activities.
- Data portability.
- Volunteer handoff.

This keeps the MVP focused while preserving the path toward the strongest differentiated product: a trusted membership operating system for volunteer-run organizations, proven first with outdoor clubs.


---

## Startup Canvas Detail



## Vision

### Long-term aspiration

**Memba exists so that volunteer-run outdoor clubs outlive the volunteers who run them.**

A healthy mountaineering, paddling, ski touring, or cycling club is a multi-generational piece of community infrastructure. It teaches skills, manages risk, holds local knowledge, and gets people outside together. Most of these clubs run on the unpaid evening hours of a membership secretary, a treasurer, and a webmaster — and they are quietly dying not because nobody wants to climb or paddle, but because the administrative load of keeping a club legible to itself (who is a member, who has paid, who has signed a waiver, who is leading Saturday's trip) is too high for the next volunteer to pick up.

Memba's ten-year aspiration is that the volunteer handoff — from one membership secretary to the next, from one board to the next — becomes a one-evening exercise rather than a six-month crisis. If we succeed, the small and mid-sized outdoor club becomes structurally easier to sustain, and a class of community institution that has been quietly atrophying recovers room to grow.

### North-star user outcome

The user we are designing around is the **incoming volunteer membership secretary** of a 50–500 person outdoor club. The moment of success is the moment they open Memba for the first time, look at the roster their predecessor left them, and think *"I can run this."*

Everything downstream — household billing, renewal automation, directory privacy, trip signups, waivers — is in service of that single felt experience. The emotional valence we are after is **relief and confidence**, not delight, not power. A volunteer doesn't want to be a power user; they want to not have to be.

### What the world looks like if Memba wins

- A 200-member club in the Kootenays, the Lake District, the Adirondacks, or the South Island runs its full administrative loop — joins, renewals, household billing, waivers, member directory, official announcements, trip signups — in one tool that costs less than 5% of annual dues revenue.
- "Powered by Wild Apricot" footers and the *Mailchimp + Google Sheet + Google Group + PDF waiver* stack have been replaced, in the small-and-mid-club tier, by something the next volunteer can actually inherit.
- Pricing is predictable. Clubs are charged by **active** members, not by lifetime contacts. There are no payment-processor surcharges layered on top of Stripe — a direct repudiation of the Wild Apricot / Personify 20% PSSF model that the research found to be the single most-resented grievance among Canadian and international users.
- Memba is independent and founder-led, not a portfolio company in a private-equity rollup. After the Personify → Momentive / TA Associates consolidation wave (and Bending Spoons' acquisitions of Meetup and Eventbrite), this is itself a vision-level commitment, not just a positioning angle.

### Smallest version of success we would still be proud of

A few hundred outdoor clubs — Kootenay Mountaineering Club and its peers — running their entire membership operation on Memba, sustainably, for a decade. Volunteers handing off to volunteers without disaster. Not a unicorn outcome; a craft-business outcome. The vision must remain coherent at that scale, because that is the most probable outcome.

### Why now

Three independent forces converge:

1. **The legacy AMS tier is collapsing in trust.** Wild Apricot's Trustpilot rating is 1.7/5; ClubExpress reviews on Capterra describe a UI that "made [an employee] cry"; support has degraded post-acquisition; price increases are routine. Research found a documented Wild Apricot wishlist thread on family memberships open and unaddressed since **2018**.
2. **PE consolidation is producing a flight-to-independence preference.** Buyers are now explicitly looking for vendors who will *not* be acquired and re-priced. Raklet has begun marketing on this dimension; it resonates.
3. **The volunteer pipeline is thinning.** Outdoor clubs increasingly report that recruiting younger volunteer admins is failing. The cost of administrative friction has gone from "annoying" to "existential."

### Statement of stance

Memba is **for** volunteer-run outdoor clubs as a distinct institutional form — household-shaped, activity-shaped, risk-shaped, and small. We are **against** the assumption that these clubs are merely undersized versions of professional associations, sports leagues, or creator communities, to be served by retrofitted tools from those categories.

Concrete commitments that follow:

- **Households are first-class, not a "bundle" workaround.** Two adults plus dependents, individual logins, shared billing, per-person waivers and emergency contacts. This is the single largest documented gap in the incumbent tier, and Memba is unwilling to ship the same fudge.
- **Active-member pricing, no platform surcharge.** Lifetime contacts are free to retain. Payment processing is Stripe at Stripe's price. Memba does not tax the club's payment rails.
- **The data belongs to the club.** Clean exports, Google Sheets sync as a first-class feature, a documented "leave anytime" promise.
- **The next volunteer is a user, not an edge case.** Onboarding, audit trails, granular roles, and admin clarity are designed against the handoff scenario, not the power-user scenario.

### White-label club websites

Memba should become white-labelable enough that each club can use it as its own website, not merely as a back-office database behind an existing site. The product should get out of the club's way: to members and the public it should feel like the club's site, powered by Memba rather than branded as Memba.

Implications:

- **Multi-tenant club identity.** Each club needs its own web presence, initially likely on a Memba-hosted subdomain, with custom domains as a paid or advanced capability.
- **Club branding.** Clubs should be able to upload a logo, set basic brand details, and get a sensible generated color scheme from the logo that admins can then tweak.
- **Opinionated site builder, not Wix clone.** Memba should offer only the pages and blocks membership clubs need: home/about, join/renew, member-only content, directory, announcements, files, trips/activities, leadership/contact, and policy/waiver pages.
- **Memba recedes.** The interface should be simpler than general-purpose builders because clubs are not trying to design arbitrary websites; they are trying to run a club and present it clearly.
- **Access control as the differentiator.** The website layer is valuable because it is tied directly to membership status, roles, privacy settings, waivers, and activities.

This changes the earlier “not a website builder” stance: Memba should not become a general Wix/Squarespace competitor, but it may become a focused Wix/Squarespace-style website product specifically for membership clubs.

### What Memba explicitly will not become

- A general-purpose association management system for professional associations or trade bodies.
- A creator-economy / community platform (Mighty Networks, Memberful adjacent).
- A youth-sports league app (Spond, TeamSnap adjacent).
- A booking, permitting, or commercial-trip system (FareHarbor adjacent).
- A learning management system, donation CRM, or general-purpose full-fat website builder.
- An AT Protocol or federation showcase. Federation may be useful infrastructure later; it is not the vision.

Each of these is an adjacent business model that would be easy to drift into and corrosive to what makes Memba defensible — namely, fit to a specific institutional form.

### Identity and form

Memba claims the tradition of **community infrastructure software**, not the tradition of growth-stage SaaS. The closest analogue from outside the category is something like Consumer Reports or a credit union: a small, durable, trust-led business serving a specific kind of organization for a long time. The implication is that Memba should be operated, and capitalized, in a way that makes a PE exit unattractive — because the moment the company optimizes for exit, the trust commitments above become uncredible.

### Open questions / assumptions to test

- **Heroic-user selection.** Centering the incoming membership secretary is a deliberate choice over the treasurer, the trip leader, or the regular member. Worth pressure-testing in customer discovery — does the emotional drama actually live with the registrar, or with the treasurer at renewal season?
- **Households as the primary wedge.** Research strongly suggests it is underserved, but switching is rare; clubs may need *households + trip management* combined to clear the inertia bar.
- **"Independent forever" as a vision-level commitment.** Credible only if matched by a capital structure (bootstrapped, steward-owned, B-corp, or capped-return) that makes the commitment enforceable. This is a real founder decision, not a tagline.
- **Geographic scope.** Canadian / UK / AU / NZ clubs are disproportionately punished by the Wild Apricot PSSF surcharge. Is Memba a North American product that ships internationally, or a Commonwealth-outdoor-club product that happens to start in BC?
- **The five named crises** Memba must have pre-decided answers to before launch: (1) a member's data is exposed through a directory privacy misconfiguration; (2) a participant is injured on a trip where waiver status was misrepresented in Memba; (3) Stripe deplatforms or freezes a club; (4) a board faction tries to use Memba's directory for a contested club election; (5) an acquisition offer arrives that would breach the independence commitment. None of these have doctrinal answers yet.



## Market Segments

> This section expands Lean Canvas §5. It applies the JTBD-primary, layered-cut methodology from `RESEARCH-MARKET-SEGMENTS-PROMPT.md` to Memba. Citations refer to research in `research/extracted-text/`.

### 0. Why segmentation is unusually hard here

Two clubs identical on size, geography, and activity can have opposite relationships with Memba. A 200-member hiking club run by a retired IT manager who built a custom WordPress stack has no pull; a 200-member club whose registrar just quit citing burnout has acute pull. The axis that predicts adoption is **the volunteer-admin pain trajectory**, not the club's demographics.

**Non-demographic axes that actually vary behavior:**

1. **Volunteer-admin pain trajectory** — stable, escalating, or crisis (registrar resigning, treasurer threatening to). Crisis = buying trigger.
2. **Household-membership share** — clubs where >30% of memberships are family/household are structurally underserved by current tools (SaaS Market Research, §Family-membership pain).
3. **Trip/activity centrality** — is the club's value proposition "we hike together" (high) or "we share information" (low)? High = waiver, leader, capacity workflows matter.
4. **Tech-incumbent inertia** — Google Sheets only, Wild Apricot legacy, ClubExpress legacy, WordPress+plugins, or custom-built. Each has different switching forces.
5. **Governance maturity** — board cycles, formal approval needed, signing authority. Determines sales cycle and who must be sold.
6. **Insurance/regulatory exposure** — clubs whose insurer or federation mandates waivers and background checks have non-negotiable software needs (SaaS Market Research, §Legal Liabilities).

**Third-rail axis: sport vertical.** Tempting to segment as "mountaineering clubs vs. cycling clubs vs. paddling clubs" because the research literature does. We refuse this cut for v1 because (a) the JTBD is identical across sports, (b) it would force vertical-specific feature work that the wedge does not need, and (c) it would foreclose horizontal scale. Sport is descriptive overlay only.

**Antithesis (what a bad segmentation looks like):** "Outdoor enthusiasts aged 35–65 in North America who like the outdoors." This describes members, not buyers, and predicts nothing about adoption.

### 1. Primary axis: Job-to-Be-Done clusters

Three distinct JTBDs surfaced in the research; the lead segment cluster shares the first.

- **JTBD-1 (Admin Survival):** *"When our membership renewal cycle approaches and I'm staring at a spreadsheet of 200 households, I want a system that just handles the dues, reminders, and roster, so I can stop dreading this job and hand it off cleanly to the next volunteer."* (Evidence: GAA Registrar Analysis — "5–8 hours per week during registration season"; Sports Club Admin Report — "volunteer burnout is the single biggest threat".)
- **JTBD-2 (Safe Trips):** *"When I'm leading a backcountry trip, I want to know everyone on this list is a paid member, has a current waiver, and I have their emergency contact, so my club and I aren't exposed."* (Evidence: North Shore Hikers bylaws — "$14.00 Liability Insurance... signed at the trailhead before each trip"; multiple ClubExpress/Wild Apricot users requesting integrated waivers.)
- **JTBD-3 (Trust handoff):** *"When I take over as registrar, I want the previous person's system to make sense in one evening, so I'm not the bottleneck and I don't quit in year one."* (Evidence: Capterra ski club director — "considerable computer experience is necessary... puts the system at risk of unintended damage".)

JTBD-1 is the wedge. JTBD-2 follows quickly (Phase 2). JTBD-3 is a constraint that shapes UX, not a separate segment.

### 2. Primary beachhead: KMC-archetype clubs

**Sharp ICP:**

The May 2026 competitor gap pass tightens this ICP: the best prospects are clubs whose pain is deeper than “we need cheap dues collection.” They should need the integrated household + renewal + waiver + activity + handoff model. If a prospect is already happy with TidyHQ, Amilia, Heylo, Spond Club, membermojo, Clubforce, SportLoMo, Zeffy, or Yapla, Memba needs a specific gap-based reason to compete.

- Volunteer-run outdoor/activity club, **80–300 active members** (tight band; KMC sits at the upper end).
- Annual dues **$25–$80 per individual; $50–$200 per household**, payable by Stripe-supported card.
- **≥25% of memberships are household/family** (the wedge bites).
- Runs **≥10 member-only trips/year with waivers** (Phase-2 hook).
- Currently on **Wild Apricot, ClubExpress, a custom WordPress site, Zeffy/forms workaround, or Google Sheets + Mailchimp + PayPal** — *not happily served by TidyHQ, Amilia, Heylo, Spond Club, membermojo, Clubforce, SportLoMo, or Yapla*.
- Has an **identifiable registrar or membership secretary** (named volunteer role) and a board that meets monthly or quarterly.
- Sits in a jurisdiction with **mandatory liability insurance** for outdoor activities (BC, AB, ON, WA, OR, CO, UT, BC, Scotland, England, NZ, etc.).
- **Pain trigger present in last 12 months:** registrar resigned/threatened to, Wild Apricot price increase, contact-limit overage, board complaint about renewal chaos, or website migration looming.

**Concrete archetypes (real clubs that fit):** Kootenay Mountaineering Club, North Shore Hikers, Mountain West Outdoor Club (Boise), Washington Alpine Club, Trails Club of Oregon, regional Alpine Club of Canada sections, mid-size IMBA chapters, regional ACA paddling clubs (Personal — Memba research, §Outdoor-club segment shape, tier 3 + lower tier 2).

**Why this beachhead:**

1. JTBD-1 severity is highest here — single volunteer often does both registrar and treasurer.
2. Household share is highest in family-oriented outdoor sports (Personal — Memba, §Family-focused clubs).
3. Software budget tolerance is $80–$200/month (Personal — Memba, §Typical software budget for 300–800 members; at 80–300 it's $30–$80) — matches Memba's Starter/Club tiers.
4. Accessibility: clubs are discoverable via federations (FMCBC, ACC, IMBA, ACA), regional directories, and r/hiking, r/mountaineering, r/cycling.
5. Trust intermediaries exist: federation officers, "switch from Wild Apricot" content channels, KMC reference case.

### 3. Secondary segment: mid-sized regional clubs (300–1,000 members)

ACC sections, regional ski-touring clubs, mid-sized paddling and cycling clubs already on Wild Apricot or ClubExpress, paying $200–$500/month and complaining (Capterra ClubExpress reviews; Personal — Memba, §Mid-size regional clubs). They have higher WTP but slower board cycles, more migration risk, and may already have custom integrations. **Defer to post-beachhead** because the sales cycle would starve cash; revisit when KMC reference case exists.

### 4. Future segments

- **Large national/regional clubs (1,000–10,000 members):** Alpine Club of Canada (national), The Mountaineers, Sierra Club chapters. Require multi-chapter, federated reporting, custom domains, SSO. Out of scope for v1; reachable only via reference + sales motion that doesn't exist yet.
- **Adjacent activity clubs (non-outdoor):** model railroad clubs, astronomy clubs, sailing clubs, dog-agility clubs. Same admin JTBD; no waiver/trip-leader needs. Validates whether wedge generalizes.
- **Sports-league federations:** youth sport governing bodies. High value but Spond owns this (Personal — Memba, §Spond captured significant share).
- **Outdoor-adjacent commercial operators:** guided-trip companies, hut systems, climbing gyms. Different buyer (paid staff), different JTBD (revenue, not admin survival). Do not pursue from this codebase.

### 5. Segments to EXCLUDE explicitly

- **Sub-50-member informal clubs / Meetup groups.** No willingness to pay; Google Sheets and Meetup are sufficient. Recruiting them inflates churn and support load.
- **Youth sports leagues / grassroots team sports.** Spond Club, Clubforce, and SportLoMo create strong free/low-cost or governed-sport alternatives; the buying pattern is structurally different (parents, teams, fixtures, federation compliance). Personal — Memba, §Spond; Competitor Gap Pass.
- **National associations / professional associations with paid staff.** They are Wild Apricot's defensible heartland and require RBAC, accreditation, CE credits, etc. **This is the mission-aligned-but-dangerous segment** (cf. methodology pitfall: "media-literacy educator mirage"): structurally appealing, mission-aligned, but procurement cycles will starve the company.
- **Creator-economy / paid-content communities.** Memberful and Mighty Networks own this; the JTBD is monetization, not volunteer admin.
- **HOAs, condo boards, religious congregations.** Adjacent in pain but very different in tone, governance, and regulatory regime.

### 6. Personas (within the beachhead)

| Persona | Role in buying | Core JTBD | Decisive concern |
|---|---|---|---|
| **Membership Secretary / Registrar** | Champion + primary user | JTBD-1, JTBD-3 | "Does this end my Sunday-night renewal spreadsheet hell?" |
| **Treasurer** | Co-champion; signs the cheque | JTBD-1 (financial slice) | Reconciliation, offline payments, no surprise fees. |
| **Communications Admin / Webmaster** | Influencer; sometimes blocker | "Stop the email database from drifting" | Reliable delivery; doesn't break the existing website. |
| **Board / President** | Approver | Risk reduction, continuity | "Will the next volunteer cope? Does this protect us legally?" |
| **Trip Leader** | Day-of user (Phase 2) | JTBD-2 | "On the trailhead with cell service flaky, can I see who's covered?" |
| **Regular Member** | End user | "Renew without phoning anyone" | One-click renew; doesn't accidentally pay twice. |

Founders should optimize the demo and onboarding for the **registrar + treasurer pair** — that's where the deal is made.

### 7. Market sizing (best-available estimates)

Sources are sparse; numbers are order-of-magnitude.

- **TAM (global volunteer-run clubs with admin pain ≥ Memba threshold):** ~200,000–400,000 clubs worldwide (extrapolated from Wild Apricot's claimed ~20,000 customers, ClubRunner's ~10,000, ClubExpress' several thousand, plus the much larger long tail on spreadsheets — Personal — Memba, §competitors and tier breakdown). At median $60/mo ARPU → **$140M–$290M ARR TAM**.
- **SAM (English-speaking volunteer-run outdoor/activity clubs, 50–1,000 members):** ~15,000–30,000 clubs across CA, US, UK, IE, AU, NZ. At $50–$90/mo ARPU → **$9M–$32M ARR SAM**.
- **SOM (3-year reachable: KMC archetype, 80–300 members, English-speaking, in pain trigger window):** ~3,000–6,000 clubs realistically reachable via federation channels, SEO, and direct outreach. At 5–10% penetration in 3 years and $50–$70/mo → **$0.9M–$2.5M ARR**.

These are wide because the underlying counts are not in any single dataset. Validation experiment 1 below tightens them.

### 8. JTBD-aligned segment summary

| Segment | Lead JTBD | Pain severity (1–10) | Est. WTP/mo | Tier in roadmap |
|---|---|---|---|---|
| KMC archetype (80–300) | JTBD-1 + JTBD-3 | 8 | $30–$80 | **Beachhead** |
| Mid-size regional (300–1,000) | JTBD-1 + JTBD-2 | 7 | $80–$200 | Secondary |
| Large national/federation | Multi-chapter ops | 6 | $300+ | Future |
| Adjacent indoor hobby (50–300) | JTBD-1 only | 7 | $30–$60 | Future |
| Youth sport league | Team logistics | 8 | $0–low (Spond Club / Clubforce / SportLoMo) | **Exclude** |
| Creator community | Monetization | n/a | n/a | **Exclude** |

### 9. Assumptions, risks, and segmentation-specific validation

#### Key segmentation assumptions

1. **The 80–300-member band is coherent.** Clubs at 80 and at 300 have the same JTBD intensity and tolerate similar prices. *Risk: at 80, dues × members may not clear a $30/mo line item; at 300, they may already have moved to Wild Apricot and Memba is a switching sale not a greenfield one.*
2. **Household-share ≥25% predicts switching.** *Risk: families may be a feature ask, not a switching trigger; admin survival may dominate.*
3. **Outdoor-specific framing pulls clubs we want without scaring off the indoor-hobby clubs we'd take later.** *Risk: "outdoor" branding may need to widen to "activity" before reaching SAM target.*
4. **Sport vertical is descriptive, not segmentation-relevant.** *Risk: paddling/cycling clubs have insurance regimes or federation requirements that fragment the product.*
5. **Pain-trigger events are frequent enough to drive a viable inbound funnel.** *Risk: triggers (registrar resignation, price hike) are episodic; we may need outbound to fill gaps.*

#### Pre-mortem (12 months out, what could go wrong)

- We close 5 KMC-archetype clubs, all of which discover they need Phase-2 trip workflows immediately. The wedge holds but engineering is consumed before pricing validates. *Detection signal:* design-partner clubs report >50% of post-MVP feature requests are trip-related (matches SaaS Market Research Risk 3 validation experiment).
- We close 5 clubs but household-membership turns out to be a "nice to have," not a switching driver. The product becomes a Wild Apricot clone with no wedge. *Detection signal:* in onboarding, fewer than half configure households in the first 30 days.
- Mid-size clubs (300–1,000) are easier to close than KMC-archetype because they have budget and explicit pain — we drift up-market and starve on procurement cycles. *Detection signal:* sales conversations skew >40% to 300+ member clubs by month 6.

#### Validation experiments (segmentation-specific)

1. **Beachhead recruitment test (week 1–4).** Cold-outreach 50 KMC-archetype clubs across BC, WA, OR, ID, CO, UT, AB, ON. Target ≥10 willingness-to-talk responses and ≥3 paid pilot conversions. *Falsification:* <3 conversions → archetype is wrong OR channel is wrong; diagnose which before iterating.
2. **Household-share probe (during the 15 admin interviews).** For each interviewee, ask: "When did your club last debate how family memberships should work?" *Falsification:* fewer than 8/15 have an active complaint → household wedge is weaker than research suggests.
3. **Pain-trigger taxonomy (during interviews).** Tag every interview with the trigger that made them respond. *Falsification:* no recurring trigger appears across 4+ interviewees → segment lacks acquisition moment.
4. **Competitive-displacement probe (during interviews).** Ask every prospect which of TidyHQ, Amilia, Heylo, Spond Club, membermojo, Clubforce, SportLoMo, Zeffy, and Yapla they considered or tried. *Falsification:* prospects cannot name a specific gap Memba would solve beyond price.
5. **Mid-size segment falsifier (week 8).** Take two warm 500-member-club leads and explicitly *defer them* in writing, citing this document. If you can't, you've already drifted; reset.
6. **Sport-vertical concentration check (week 12).** Tally first 10 pilot clubs by sport. *Falsification:* if 8+ are one sport, segmentation should narrow to that sport explicitly (lower TAM, higher density). Don't pretend horizontal coverage you don't have.
7. **Federation-channel accessibility test.** Pitch one regional federation (FMCBC, an ACC section umbrella, a state IMBA chapter) on a Memba briefing. *Falsification:* zero federation interest in 90 days → segment lacks trust intermediaries; need direct-to-club motion only.

#### Pitfalls being actively guarded against

- **Conflating Wild Apricot's TAM with Memba's.** Wild Apricot lumps small associations, nonprofits, and clubs. Memba's wedge is a slice of the slice — don't quote Wild Apricot's customer count as our SAM.
- **Founder projection (KMC is the founder's home club).** Recruit interviewees from clubs the founder has *no relationship with*; explicitly disqualify KMC from validation-stage interviews.
- **Channel-as-segment confusion.** r/hiking is a channel, not a segment. The clubs we'd reach there must still match the JTBD/household/trigger profile.
- **The "media-literacy mirage" equivalent here is large national associations.** They look ideal (budget, mission, formal procurement); they will starve the company. Named, so we don't fall for it.



## Value Proposition

This section of the Startup Canvas applies the Value Proposition research methodology to Memba — a SaaS membership platform for volunteer-run outdoor and activity clubs, starting with Kootenay Mountaineering Club (KMC). It synthesizes the Lean Canvas's Problem (§1), UVP (§3), and Unfair Advantage (§4) with the deep-research briefs and the May 2026 competitor gap pass in `docs/strategy/research/extracted-text/`.

### 1. Segment-anchored framing

The Value Proposition is written for the **primary VP segment**: a volunteer-run outdoor/activity club of roughly 30–300 members (hiking, mountaineering, ski touring, cycling, paddling) whose buyer/influencer is a **rotating Membership Secretary or Treasurer**, with the **board** as the budget approver. Buyer ≠ user: the regular member is a separate user whose VP is "join, renew, see the directory, sign up for the trip" with zero friction. (See Lean Canvas §5 personas.)

Critical contextual segments — not VP targets, but who shape viability:

- **The silent majority** of clubs running on Google Sheets + Mailchimp + Google Groups + Meetup. Many say they have the problem but never switch; do not treat them as TAM.
- **The board / credibility-audience.** A volunteer treasurer's reputational risk on choosing software is real; a single failed renewal cycle can torch trust. The Capterra ClubExpress review describing the platform causing an ex-employee "to cry" is the brand-destruction case study.

### 2. What Before — current customer problems and unmet needs

Evidence-grounded "before" state, per the Lean Canvas problems and the two research briefs:

#### Pain 1: Fragmented admin stack and volunteer overload
Clubs juggle spreadsheets, PayPal/Stripe buttons, Mailchimp, Google Groups, Meetup, Eventbrite, and a WordPress site. Potomac Mountain Club explicitly documents using "a google email group … and Mailchimp"; Wintergreen Sporting Club uses Mailchimp + Google Sheets + volunteer role assignments. Volunteer admins absorb the cost of stitching these together — and the cost is largest at handoff, when a new secretary inherits an opaque system. ("run exclusively by volunteers" — Hoosier Hikers Council.)

#### Pain 2: Household/family memberships are usually shallow or awkward
The single most-cited unmet need across the research, but not wholly unserved. Wild Apricot's Wishlist thread on family/child memberships has been open since 2018: "Bundle memberships don't really relate to Family memberships. I see this as the biggest hole in your software." A sports club admin reports "I end up having to create a unique account for those families." TidyHQ and Amilia have credible family/household support, and membermojo is good enough for many small UK clubs, so the claim cannot be “nobody has families.” The real shape Memba must own is deeper: one payer, multiple individuals, shared address, individual logins, per-person waiver/visibility/emergency contacts, child-to-adult transitions, and clean volunteer-admin workflows.

#### Pain 3: Renewals and payments are manual, error-prone, and easy to get wrong
"it does not allow group invoicing… I have to go into each account and manually create" (Wild Apricot, Capterra). ClubExpress users report renewals are "difficult to correct if mistakes are made." Failed-payment follow-up, grace periods, lapsed-member reactivation, calendar vs. anniversary cycles, and the basic "who has actually paid?" question consume disproportionate volunteer time.

#### Pain 4: Pricing is either opaque, punitive, or brutally anchored by free/cheap alternatives
Wild Apricot's contact-cliff pricing ("pricing structure is horrible jumping from a limit of 500 to 2000"), the 20% Payment System Servicing Fee on non-Personify processors (unavoidable outside the US), Meetup's ~2× organizer price hike since June 2024, Eventbrite's 3.7% + $1.79 per ticket + 2.9% processing. A 100-member club at $25/year dues grosses $2,500 — Wild Apricot's annual 100-contact plan consumes ~29% of that before payment fees. But the gap pass adds the opposite pressure: Zeffy and HelloAsso prove “free to the organization” can work at scale, while Spond Club, Givebutter, membermojo, Clubforce, Ticket Tailor, Teamup, and Yapla push expectations downward. Resentment is documented; willingness to pay must be earned with domain fit, not a “fair pricing” claim alone.

#### Pain 5: Support and product decay since PE consolidation
Wild Apricot Trustpilot: 1.7/5 across 153 reviews. "Since purchased by Personify, the support is HORRIBLE." "When Personify acquired WA in 2017 that turned around. Development ground to a halt." MemberClicks, YourMembership, Wild Apricot all sit under Momentive Software (TA Associates, Jan 2026). The credibility-audience (boards) is now actively suspicious of acquisition-driven platforms.

#### Pain 6: Outdoor-club-specific workflows aren't modeled
Trip leader/co-leader roles, qualification checks, participant caps, waitlists, expressions of interest, waivers, emergency contacts, member-only visibility, carpool coordination. The Mountaineers (15,000 members) built a custom Plone + Salesforce stack because nothing fit. Sierra Club Angeles Chapter runs ~2,000 trips/year on an internal Campfire system + PDF waivers + Meetup. The most sophisticated clubs build custom because off-the-shelf fails them.

#### Negative-space pain (what clubs avoid doing because they don't trust their tools)
Clubs avoid sending bulk reminders because they can't undo mistakes. Avoid offering true family memberships because the workaround is too messy. Avoid switching tools because migration is terrifying. Avoid bringing in a new volunteer because the handoff is too costly. These are the largest pools of latent demand.

### 3. Value Proposition Canvas mapping

#### Customer Jobs (functional / emotional / social)

| Job | Type |
|---|---|
| Keep an accurate roster of who is a paid-up member | Functional |
| Renew members on time without manual chasing | Functional |
| Charge the right amount for households | Functional |
| Hand the system to the next volunteer without weeks of training | Functional |
| Run trips with confidence that participants are members with valid waivers | Functional |
| Feel like a competent treasurer/secretary | Emotional |
| Avoid being "the volunteer who broke renewals" | Emotional/Social |
| Justify the choice to the board | Social |

#### Pains → Pain Relievers

| Pain (evidence) | Memba pain reliever |
|---|---|
| Fragmented stack across 4–6 tools | Members, households, renewals, payments, directory, announcements, trips in one home |
| Family memberships modeled as "bundles" (WA Wishlist 2018) | Households as a first-class object: one bill, multiple individuals, individual logins/profiles/waivers |
| Renewal mistakes are hard to fix (ClubExpress) | First-class admin "fix a renewal" workflow; clean audit trails |
| Contact-cliff pricing + 20% PSSF surcharge | Active-member pricing, no Memba surcharge over Stripe, unlimited archived contacts |
| Volunteer handoff burns weeks | Designed so the next volunteer understands the system in one evening |
| PE acquisition risk / support collapse | Independent, founder-led, migration-friendly, "leave anytime" data portability |
| Outdoor trip workflows unsupported | Lightweight trip module post-MVP: leader, cap, waitlist, waiver, member-only |
| Sheets are the source of truth and clubs are scared to leave them | Google Sheets export/sync as a trust bridge, not a checkbox feature |

#### Gains → Gain Creators

| Gain | Memba gain creator |
|---|---|
| Volunteer time back (hours/month) | Automation of reminders, renewals, household billing |
| Confidence that no one is missed | Single dashboard of expiring/lapsed/active members |
| Confidence at trip head | Trip leader sees active membership + waiver + emergency contact in one view |
| Predictable budget for the board | Flat tier pricing by active members, no surprise surcharges |
| Pride in modernizing the club without burnout | Migration concierge + onboarding designed for non-technical volunteers |

### 4. What After — induced state we are claiming

After 90 days on Memba, a volunteer-run outdoor club should be able to say:

- "Our renewals run themselves. I spend an hour a month, not an evening a week."
- "Families pay once. Each person has their own profile and waiver."
- "We finally know who has paid."
- "When I hand this to the next secretary, I'll hand them a login, not a binder."
- "Our trip leaders see who's coming, who's a member, and who's signed the waiver — on their phone."

These are the behavioral deltas Memba's research plan must validate (concierge MVP and design-partner program — see Lean Canvas validation experiments).

### 5. Alternatives — competitive positioning (Value Curve)

Per-segment value-curve axes drawn from coded complaint corpora and switch-interview material in the research briefs. Score 0–5 (higher = stronger). Scores are directional; the cells without a numeric anchor in the research are conservatively rated.

| Axis | Memba | Wild Apricot | ClubExpress | Memberful | Mighty Networks | Sheets+Stripe+Mailchimp | WordPress (MemberPress/PMPro) |
|---|---|---|---|---|---|---|---|
| Household / family model | **5** | 2 | 3 | 0 | 0 | 1 | 2 |
| Renewal automation correctness | 4 | 4 | 3 | 4 | 3 | 1 | 3 |
| Volunteer-admin simplicity / handoff | **5** | 2 | 1 | 3 | 3 | 3 | 1 |
| Outdoor-trip workflow (Phase 2) | **4** | 2 | 2 | 0 | 1 | 1 | 1 |
| Pricing fairness (no cliffs/surcharges) | 4 | 1 | 2 | 2 | 2 | 5 | 4 |
| Data portability / "leave anytime" | **5** | 2 | 3 | 3 | 2 | 5 | 4 |
| Sheets/CSV bridge | **5** | 2 | 2 | 1 | 1 | 5 | 1 |
| Private member directory + content | 4 | 4 | 4 | 3 | 4 | 1 | 3 |
| Independent operator durability | **5** | 1 | 3 | 2 | 3 | n/a | n/a |
| Mobile-first member experience | 4 | 2 | 1 | 3 | 4 | 3 | 2 |
| Time-to-onboard a volunteer | **5** | 2 | 1 | 3 | 3 | 4 | 1 |
| Modern community / social features | 1 | 2 | 2 | 2 | **5** | 1 | 2 |

Gap-pass correction: the old value curve understates modern club-native and free alternatives. The highest beachhead threats now are **TidyHQ, Amilia, Heylo, Zeffy, Spond Club, membermojo, SportLoMo, and Clubforce**; the highest broader-market threats include **TidyHQ, Amilia, Givebutter, Donorbox, Zeffy, Yapla, Wild Apricot, Raklet, and Join It**. Therefore pricing fairness is a qualifier. The primary differentiation must be the integrated club model: first-class households, renewal edge cases, waivers, emergency contacts, member-only activity workflows, privacy, and volunteer handoff.

#### ERRC commitments

- **Eliminate**: contact-count cliff pricing; payment-processor surcharges layered on Stripe; site-builder competition with WordPress; AI-powered "community" marketing.
- **Reduce**: feature breadth (no LMS, no full forum, no donation suite, no public event discovery, no native mobile app at launch); admin training overhead.
- **Raise**: household correctness; volunteer-handoff design; pricing transparency; data portability; migration concierge quality.
- **Create**: a single domain model that unifies households + memberships + waivers + trips + leader permissions + privacy — built specifically for outdoor clubs. Google Sheets sync as a first-class promise. An explicit "we will not sell to PE" operator commitment.

### 6. Primary UVP (refined) and alternative framings to test

#### Primary UVP

> **Memba is the membership platform built for volunteer-run outdoor clubs — real family memberships, one-click renewals, and the trips you actually run, without the bloat of an association suite or the hacks of a DIY stack.**

#### Alternative framings (A/B test candidates)

1. **Household-led**: "Real family memberships. Two adults, three kids, one renewal, one bill — and individual profiles for each person."
2. **Switch-from-WA**: "The Wild Apricot alternative for outdoor clubs. No contact cliffs. No 20% surcharge. Same renewals; better households."
3. **Volunteer-led**: "Membership software your treasurer can hand to the next treasurer in one evening."
4. **Trips-led**: "Dues, households, and the trips you actually run — in one place."
5. **Sheets-bridge-led**: "All your club data in one place — and we still sync to your Google Sheet."
6. **Independence-led**: "Founder-run. Migration-friendly. Won't sell to private equity. Built for clubs, not portfolios."

### 7. What Memba is NOT

- Not a generic association management platform (Wild Apricot/ClubExpress).
- Not a creator/community/monetization platform (Memberful, Mighty Networks).
- Not a WordPress site builder or plugin replacement.
- Not a public event-discovery marketplace (Meetup, Eventbrite).
- Not a discussion forum / social network (Discourse, Mighty).
- Not an LMS, donation CRM, gear-reservation, cabin-booking, or permit system.
- Not (yet) a federated / AT Protocol social club identity layer.
- Not "all things to all clubs" — initial wedge is outdoor/activity clubs only.

### 8. Messaging hierarchy

#### Primary message (above the fold)
"Memba is the membership platform built for volunteer-run outdoor clubs."

#### Supporting proof points (ranked by research-evidence strength)
1. **Real family memberships** — addresses the most-documented competitor failure (Wild Apricot Wishlist open since 2018).
2. **Built for the next volunteer** — handoff as a feature, addressing the documented ClubExpress and WA admin-complexity pain and an under-served theme in the gap pass.
3. **Trips, not just events** (Phase 2 onward) — leader, cap, waitlist, waiver, emergency contact, member-only.
4. **Renewals that don't break** — admin "fix a renewal" workflow as a category-leading promise.
5. **Predictable pricing, no surcharges** — a trust qualifier, not the lead hook, because free/low-cost alternatives now set the visible price anchor.
6. **Works with your spreadsheet** — Google Sheets sync as a trust bridge.
7. **Independent, founder-led, migration-friendly** — addresses the PE-consolidation anxiety surfaced repeatedly in reviews.

### 9. Messaging hypotheses to A/B test

These are the candidate hypotheses to drive Lean Canvas validation experiment #2 (landing page) and #3 (pricing). Each is testable as a paid-ad headline + landing-page variant; each has a falsification condition.

| ID | Hypothesis | Test | Kill condition |
|---|---|---|---|
| H1 | "Households done properly" is the strongest single hook for outdoor clubs | LP variant A vs. control | CTR within 0.5× of control across 1,000 visits |
| H2 | "Dues + trips in one place" beats "households + renewals" for clubs with active trip programs | LP variant B vs. H1 winner | H1 wins by 2× on mountaineering/paddling subsegment |
| H3 | "Wild Apricot alternative — no contact cliffs, no surcharge" converts Canadian/international WA users at 3× US baseline | Geo-segmented LP test | <1.5× lift on non-US traffic |
| H4 | "Built for the next volunteer" outperforms feature-list messaging with board/treasurer ICP | Targeted LinkedIn ads to club treasurers | <2% CTR vs. feature-list at >2% |
| H5 | "We will not sell to PE" as a trust hook materially lifts signups post-Trustpilot proof points | Adds proof block to LP | <10% lift in email capture |
| H6 | Active-member pricing ($19/$39/$79) beats contact-based pricing comprehension test 4:1 | Pricing-page comprehension survey | <2:1 preference |
| H7 | "Switch from Wild Apricot in a weekend" webinar funnel converts ≥3 paid pilots per session | Run 2 webinars | <1 paid pilot per session across 2 runs |
| H8 | Sheets-sync demo in onboarding lifts activation (first roster imported) by ≥30% | Onboarding A/B | <10% lift |

These hypotheses must be tested *after* the concierge MVP has produced the behavioral-delta evidence the research-prompt quality bar requires; landing-page CTR alone is not sufficient to ship the VP without the paid-pilot signal.

---

**Evidence index (key sources):** Wild Apricot Wishlist family-memberships thread (open 2018); Capterra Wild Apricot reviews (Walt B., ski club director, "made someone cry"); Trustpilot WA 1.7/5 (153 reviews, May 2026); Wild Apricot 20% PSSF (FatLab); Meetup organizer price hike (June 2024 blog + Medium analysis); Memberful G2 family-pass requests; ClubExpress G2 admin-complexity reviews; Potomac Mountain Club join page (Google Groups + Mailchimp stack); Hoosier Hikers Council "run exclusively by volunteers"; Lambton Outdoor Club $25/year dues; The Mountaineers custom Plone+Salesforce stack; Sierra Club Campfire+PDF+Meetup stack. Full citations in `docs/strategy/research/extracted-text/`.



## Capabilities

This section maps the activities, resources, and partnerships Memba needs to deliver its value proposition: a simpler, fairer, outdoor-club-native membership platform for volunteer-run clubs. It follows the Paweł Huryn Startup Canvas framing of "Capabilities" as the union of Key Activities, Key Resources, and Unfair Advantage, and applies the methodology from the CAPABILITIES research template (RESEARCH-CAPABILITIES-PROMPT.md) — including the build/partner/buy lenses, the irreducible-core test, and the explicit "not-acquiring" list.

The grounding documents are this canvas, `docs/strategy/research-plan.md`, the extracted competitor research in `docs/strategy/research/extracted-text/` including `Competitor Gap Pass for Memba.txt`, and the repo-level `AGENTS.md` confirming a Phoenix-first stack.

### 1. The irreducible core

Applying §1b of the template: what does the customer actually buy from Memba, and which capability — if absent or weak — causes the product to fail regardless of how strong the rest is?

The Lean Canvas summary is explicit: the wedge is "membership operations for volunteer-run outdoor clubs," with household/family handling, activity/waiver workflows, and volunteer-admin handoff as the differentiating axes (§Core thesis, §Unfair Advantage). The competitor research confirms that the gap is not feature breadth — Wild Apricot and ClubExpress already out-feature any plausible MVP, while TidyHQ, Amilia, Heylo, Spond Club, membermojo, Clubforce, SportLoMo, Zeffy, and Yapla compress the “cheap enough” space — but **a coherent domain model + volunteer-friendly UX + trustable pricing/portability**, executed without the contact-count cliffs, bundle hacks, tip prompts, and fee stacking that drive churn or discomfort.

Memba's irreducible core is therefore a **rare cross**: deep outdoor-club domain modelling (households, dependents, waivers, leader roles, trip lifecycle, lapsed-vs-active state) fused with volunteer-admin UX design (handoff in one evening, no jargon, no Salesforce-shaped onboarding). This is judgment-led at the domain layer and execution-led at the engineering layer; neither alone is sufficient.

Diagnostic per the template: roughly 60% of customer value depends on judgment quality (does the household model match how *our* club actually works?), and 40% on execution quality (does Stripe billing, email deliverability, and the import tool just work?). That puts Memba slightly on the judgment-led side — meaning the **domain/UX leader should sit at parity with or above the engineering leader**, not below. Today, that role is held by the founder.

The minimum viable team for the core at MVP stage is one founder/PM with embedded domain access (Matt + KMC) plus one to two Phoenix engineers. The v0 artifacts the core team must produce are: the household/membership data model (ERD + invariants), the volunteer-admin task taxonomy, the renewal state machine, and the migration playbook for Wild Apricot / ClubExpress / spreadsheet starting states.

### 2. Discipline map (build / partner / buy)

Per §1a and §1c, every non-trivial capability needs a position, not a survey. The table below uses MVP as the staging horizon; 10× and 100× revisits are flagged where the answer flips.

| Capability | MVP position | Differentiating? | Trigger to revisit |
|---|---|---|---|
| Household/family data model | **Build** (core) | Yes — moat | Never outsource |
| Volunteer-admin UX | **Build** (core) | Yes — moat | Never outsource |
| Phoenix/Elixir engineering | **Build** in-house | Table stakes | — |
| Postgres multi-tenancy | **Build** on managed Postgres | Table stakes | Re-evaluate at 100+ clubs |
| Payments | **Buy** Stripe; pass through fees | Table stakes | Add GoCardless / PayPal when international clubs ask |
| Subscription billing logic | **Build** (thin layer on Stripe) | Differentiating (no Memba surcharge) | — |
| Email transactional + announcements | **Partner** (Postmark or AWS SES + Swoosh/Oban) | Table stakes; deliverability is a hidden cost | Switch providers if reputation degrades |
| Migration tooling (Wild Apricot, ClubExpress, CSV, Sheets) | **Build** + concierge service | Differentiating | Productise once 5+ clubs migrated |
| Google Sheets sync | **Build** thin integration | Differentiating (trust bridge) | — |
| Waivers / e-signature | **Build** lightweight first; **partner** (DocuSign/HelloSign) only if regulated clubs demand | Differentiating in context, not generally | When a club asks for legally-binding signatures |
| Hosting / infra | **Buy** (Fly.io or Render; managed Postgres) | Context | Re-evaluate at scale |
| Observability | **Buy** (AppSignal or Sentry + log drain) | Context | — |
| Customer support | **Build** founder-led; **partner** (Plain or Help Scout) for tooling | Differentiating early — founder-led trust | Hire dedicated support at ~30 paying clubs |
| Content / SEO | **Build** founder-led | Differentiating (comparison content against TidyHQ, Amilia, Heylo, Zeffy, Spond Club, membermojo, Yapla, and incumbents) | — |
| Legal / privacy | **Partner** fractional counsel; UK + Canada coverage | Table stakes; non-deferrable | Add EU counsel only if EU clubs sign |
| Accessibility / WCAG | **Build** to AA from day one | Table stakes for clubs with grant funding | — |
| AT Protocol / federation | **Defer** as research spike only | Not a moat today | Revisit only if a federation buyer surfaces |
| Native mobile app | **Defer** | Not core | Revisit when trip-leaders ask in volume |
| Club website and white-label tenant branding | **Build** narrowly | Differentiating when tied to membership/access control | Start simple; expand only for club-specific website needs |

This list, generated from first principles per the template's warning against copying the source brief's discipline list, deliberately omits things that incumbents over-acquire (general-purpose website builder, LMS, donation engine, marketplace, branded mobile apps) — see §6 "Not acquiring."

### 3. Key activities

The activities Memba must execute well, in priority order:

1. **Product development** on the Phoenix/LiveView stack — household model, renewals engine, Stripe integration, member directory, announcements, role-based admin (`AGENTS.md`; §Solution).
2. **Migration concierge** — hand-running imports for the first 5–10 clubs to build playbooks, schemas, and trust. The Lean Canvas flags migration as a top-five validation experiment and a key cost driver; doing it as a *service* before automating it as a *feature* is the standard concierge-MVP move.
3. **Customer success and support** — founder-led at MVP, designed for volunteer admins who need reassurance, not just docs. Identified as one of the two biggest cost drivers (§Cost Structure).
4. **Email deliverability operations** — DNS, DKIM/SPF/DMARC, bounce handling, suppression lists, reputation monitoring. Explicitly called out in cost drivers; a club whose announcements don't land will churn fast.
5. **Content/SEO and comparison marketing** — "Wild Apricot alternative", "ClubExpress alternative", "membership software for hiking clubs" (§Channels). Cheap, durable, founder-writable.
6. **Community and federation outreach** — mountaineering federations, paddling associations, trail-club umbrellas as channel partnerships, not advisor decoration. Per the template's §1e warning, each must have a named contact and a concrete deliverable structure.
7. **KMC pilot operations** — running the design-partner relationship as a *capability*, not as a favour. KMC is both reference customer and methodology validator.

### 4. Key resources

- **Founder/domain fit**: Matt as founding builder with direct KMC access — real users, real data, real renewal cycles (§Unfair Advantage). This is the single largest capability asset and the closest analogue to a "rare-cross hire" being available from day one.
- **KMC pilot relationship**: Doubles as design partner, data source, reference case, and methodology stress-test.
- **Tech stack**: Phoenix 1.8 / Elixir / LiveView / Postgres / Tailwind, with Stripe, Swoosh, Oban as standard libraries (`AGENTS.md`, `docs/reference/`). The stack is mature, debuggable, and hires-into a small-but-real Elixir labour market; talent-market fit is acceptable for a small team and excellent for retention.
- **Data assets (latent)**: Anonymised renewal cohort patterns, household structures across clubs, migration mappings from Wild Apricot/ClubExpress exports. None of these are moats individually; their *aggregate* over 20+ clubs becomes one.
- **Strategy archive**: The research workstreams already executed (`docs/strategy/research/`) constitute a knowledge resource that competitors entering this niche would need to redo.

### 5. Differentiating vs table-stakes

**Differentiating (worth in-housing even when buying would be cheaper, per §4c learning-curve lens):**

- Household/family domain model.
- Volunteer-admin UX and handoff design.
- Migration concierge.
- Active-member pricing model as a trust covenant (not a standalone moat): no contact-count cliff, no Memba surcharge, no mandatory tip prompt.
- Trip/activity workflow integration (Phase 2).
- Founder-led, independent, migration-friendly support posture.

**Table stakes (buy or partner; differentiation lives elsewhere):**

- Payments rails, hosting, observability, transactional email infrastructure, base CRUD, generic auth, Google Sheets API plumbing, accessibility compliance.

The §4a Wardley test confirms this split: the household/UX/migration capabilities are *strategic and not-yet-commodity*; the payments/email/hosting capabilities are *context and commodity*; nothing on the MVP roadmap belongs in the "strategic but commodity" quadrant that would force a partnership.

### 6. The "not acquiring" list (deliberate exclusions)

Per the template's quality bar §5.7 — the most important deliverable. Memba will explicitly *not* acquire:

- **AT Protocol / federation engineering** beyond a time-boxed research spike. Risk accepted: a federated competitor could emerge; mitigated by the assessment that no buyer evidence supports federation as a switching trigger (§Assumption 5).
- **Native mobile app development**. Risk accepted: trip-leaders may want mobile; mitigated by responsive LiveView + push-as-email until evidence forces a revisit.
- **Full forum/discussion product**, **LMS**, **general-purpose website builder**, **donation engine**, **marketplace**. Risk accepted: clubs may stitch in other tools; that's preferred to scope-creep into incumbents' bloat. The exception is a narrow white-label club website surface where pages, branding, custom domains, and access control are directly tied to membership operations.
- **In-house payments processing**. Risk accepted: Stripe rate hikes; mitigated by clean abstraction allowing GoCardless/PayPal addition.
- **Enterprise sales motion** (large federations, multi-chapter umbrellas). Risk accepted: revenue ceiling at the small-club tier; mitigated by deliberate sequencing — federations are a *future* segment.
- **Internationalisation/localisation** beyond English (with currency-agnostic billing). Risk accepted: EU/LATAM markets stay closed; revisit trigger is a credible federation lead from a non-English market.

### 7. Capability gaps and closure plans

1. **Email deliverability expertise**. Gap: founder-level. Close by: engaging a fractional deliverability consultant for a one-week DNS/warm-up engagement before the first 10-club send; using Postmark (which embeds the expertise) rather than rolling on SES initially.
2. **Volunteer-admin UX research depth beyond KMC**. Gap: single design-partner risk. Close by: structured discovery interviews with 5+ non-KMC clubs (the customer discovery plan in `research-plan.md` already specifies this); avoid over-fitting to KMC idiosyncrasies.
3. **Migration tooling at scale**. Gap: each migration today is bespoke. Close by: concierge-first for the first 5 clubs; productise patterns after that — explicitly *not* before, to avoid building the wrong importer.
4. **Specialty counsel** on Canadian and UK privacy/waiver law, plus payment-related liability. Gap: no counsel on retainer. Close by: scope memos from one Canadian (PIPEDA + provincial) and one UK (UK GDPR + Defamation Act for member directories) firm before the first non-KMC club signs.
5. **Senior engineering bandwidth**. Gap: solo / small team. Close by: one senior Phoenix hire when paid-pilot count reaches 5, recruited through ElixirForum / Code BEAM / Elixir Slack networks (the §1f equivalent for this stack).
6. **Domain-credibility partnerships**. Gap: no federation logos yet. Close by: structured outreach to one mountaineering federation, one paddling association, and one trail-club umbrella in months 4–6, with concrete deliverables per the template's anti-advisor-decoration rule.

### 8. Single-point-of-failure dependencies (per §6 pitfall #6)

- **Stripe**: Critical. Mitigation — design billing abstraction layer from day one; GoCardless and PayPal as named fallbacks; budget reserve for a 90-day rewrite if Stripe terminates the account.
- **Postmark/SES**: Important. Mitigation — Swoosh's adapter pattern makes swapping providers a one-day job; maintain a warm secondary domain.
- **KMC as design partner**: Reputational. Mitigation — recruit a second design-partner club by month 4 so methodology is not single-club-derived.
- **Fly.io / Render**: Low coupling. Mitigation — standard Docker + Postgres dump portability.

### 9. Capability risks and mitigations

1. **Engineering substituting for the real core** (template pitfall #1). Risk: a Phoenix-fluent founder over-invests in engineering elegance at the expense of household/UX research. Mitigation: track a *domain-artefact-to-code-commit ratio* — for every fortnight of build, one fortnight of customer-discovery output (interview notes, model revisions, UX flows).
2. **Concierge migration becomes the business**. Risk: low-ARPU clubs consume founder time on bespoke migrations. Mitigation: cap concierge to the first 5 clubs; convert learnings into self-serve importer; price migration explicitly above cost for Pro tier.
3. **Email deliverability incident**. Risk: a misconfigured send tanks domain reputation across all tenants. Mitigation: per-tenant subdomain strategy, suppression-list discipline, monitoring dashboards from day one.
4. **Stripe account suspension**. Mitigation as above; plus diversified merchant-of-record consideration (Paddle) if exposure grows.
5. **Volunteer-admin churn at customer clubs**. Risk: handoff failures look like Memba failures. Mitigation: handoff-oriented design as a first-class product requirement; "new-treasurer onboarding mode."
6. **Scope creep into trips, courses, gear, cabins, permits** (§Cost Structure #5). Mitigation: the "not acquiring" list is the contract; revisits require evidence, not enthusiasm.
7. **AT Protocol distraction**. Mitigation: time-box to a documented spike with a kill-switch criterion (does any pilot club ask for federation? if no, ship.).
8. **Legal exposure on private member directories** (defamation, data subject requests, minors' data in family memberships). Mitigation: scope memos commissioned before the second club ships; DPA template ready; minimal data collection by default.
9. **Solo-founder bus factor**. Mitigation: documented architecture decisions (ADRs already configured via `adrgen.config.yml`), public runbooks, an early senior engineering hire as the team scales past one paying cohort.

---

**Summary for the canvas:** Memba's distinctive capability stack is a rare cross of outdoor-club domain modelling and volunteer-admin UX design, executed on a Phoenix/Postgres/Stripe stack with founder-led migration concierge and fair-pricing discipline; the biggest capability gap is migration-tooling-at-scale beyond the founder's hands, and the closure plan is to run concierge migrations for the first five clubs deliberately, then productise the patterns rather than the other way around.



## Trade-offs

> *"The essence of strategy is choosing what not to do."* — Michael Porter

This document names the deliberate strategic choices Memba is making. Each trade-off is framed as a **commitment** (verb-and-object refusal), tagged with what is **gained**, what is **given up**, why **incumbents cannot easily mirror it without breaking their own strategy**, a **reversibility tier** (A: irreversible / B: high cost / C: moderate / D: tactical), and a **trigger** that would force re-litigation.

This is a Porter-style activity-system trade-off list, not a feature list. The point is to surface the choices that make Memba *coherent* — and to name what we will **not** do.

---

### 1. Spinal trade-off

#### S1. Volunteer-run outdoor/activity clubs only — not horizontal AMS

**Commitment:** Memba will only serve volunteer-run outdoor and activity clubs (hiking, mountaineering, paddling, cycling, ski-touring, climbing). We will not pursue professional associations, chambers of commerce, alumni networks, faith groups, HOAs, or general non-profits — even when they ask.

**Gained:**
- Domain-specific model (household + waiver + trip + leader + emergency contact + skill tier) becomes the product, not a configuration of a generic AMS.
- Messaging, onboarding, migration content, channels (federations, paddling associations, FMCBC) all compound on one ICP.
- Lean Canvas §4 "Outdoor-club-specific domain model" only becomes a durable advantage if we refuse adjacent verticals that would water it down.

**Given up:**
- ~90% of the addressable AMS TAM. Research notes Wild Apricot's TAM spans nonprofits, chambers, professional bodies — Memba refuses all of it.
- Easy expansion revenue from professional associations who would pay 3–5x the ARPU of a $25/yr hiking club.

**Why incumbents can't mirror:**
- Wild Apricot (now Personify) and ClubExpress are *generalist* by strategy. Their pricing, sales motion, marketing, and codebase are organized around horizontal AMS. Re-orienting to "outdoor clubs only" would mean shrinking their TAM by an order of magnitude — a board-level impossibility for an acquired/PE-backed product.
- Memberful and Mighty Networks are creator/community platforms; outdoor-club operations (waivers, households, trips, volunteer handoff) are *off-strategy* for them.
- The competitor matrix in `Memba Market and Competitor Research.txt` confirms none of the 13 incumbents are vertical-specialised for outdoor clubs.

**Reversibility:** **Type A** — reversing means renaming the company and rebuilding the brand and domain model.
**Re-litigation trigger:** Two consecutive years of <$300k ARR with strong inbound from adjacent verticals (e.g. cycling racing leagues, scouting groups) whose data model is ~80% shared.

---

### 2. Structural trade-offs (derived from S1)

#### S2. First-class household/family as a core data model — not as a "bundle" feature

**Commitment:** Households, individuals, and household memberships will be modelled as first-class entities from day one. We will not ship an "individuals-only" MVP and bolt on family/bundle support later.

**Gained:**
- Directly attacks Wild Apricot's longest-running public complaint thread (bundle memberships, family-event registration; see Wild Apricot forums, refs 3, 30, 43, 51 in the research). Mt Baker Bicycle Club, AMC, ADK all publish family dues — this is *the* underserved primitive.
- Encodes household + waiver + per-person trip participation in one schema — hard to bolt onto a flat "contacts" table later.

**Given up:**
- Several months of additional schema design, migration complexity, and edge-case handling (children aging into adult; mixed households; one-payer-multiple-people). The Lean Canvas explicitly flags household edge cases as a top cost driver.
- A faster, simpler MVP that could ship in 6 weeks if we shipped individual-only.

**Why incumbents can't mirror:**
- Wild Apricot's "bundle membership" is a 10+ year old design layer on a flat contact schema. Their forum threads show they cannot fix per-family-member event selection without breaking their event/registration code.
- Memberful and Mighty Networks have no household concept and their target buyer (creators monetising content) doesn't need one — building it is off-strategy.

**Reversibility:** **Type A** — schema is the foundation; ripping it out means rewriting the product.
**Trigger:** Discovery during KMC pilot that households are <30% of memberships *and* admins don't list household pain in their top three.

#### S3. Active-member pricing with no Memba payment surcharge — not maximum revenue per club

**Commitment:** We will price by *active* members (not stored contacts) and we will not add a Memba surcharge on top of Stripe processing fees. Lapsed members, prospects, and archived records are free. This is a trust covenant and board-approval aid, not the primary wedge.

**Gained:**
- Directly counters the most-cited Wild Apricot grievance: contact-count pricing cliffs (research refs 28, 42, 52). A 100-member club at $25/yr cannot tolerate paying ~29% of gross dues to its software vendor.
- Avoids the discomfort of mandatory member tip prompts or hidden payment spread while keeping the software bill legible to treasurers.
- Creates a "fair to small clubs" qualifier that pairs with the volunteer-run ICP, while acknowledging the gap-pass finding that Zeffy, HelloAsso, Spond Club, membermojo, Clubforce, and Yapla already make low/free pricing a market expectation.

**Given up:**
- Higher ARPU per club, especially from large clubs with long archives.
- Float/skim revenue from payment surcharges, which competitors like Memberful (4.9%), Mighty (2%), and Eventbrite (3.7% + $1.79/ticket) all rely on.

**Why competitors can't all mirror:**
- Wild Apricot's contact-based pricing is its revenue model. Switching to active-member pricing would require re-quoting every existing customer downward — a material revenue hit a PE-owned product cannot absorb.
- Memberful's transaction-fee model is core to their pricing page; removing it would force a list-price increase that breaks their creator positioning.
- Free/donor-funded and ultra-low-cost competitors can beat this on sticker price, so Memba must pair the pricing stance with the deeper household, waiver, activity, privacy, and handoff model.

**Reversibility:** **Type B** — reversible but only with public announcement and customer trust damage. Trip-wire: any internal proposal to add a Memba surcharge requires founder + advisory veto.

#### S4. Volunteer-admin ergonomics over feature-completeness for professional staff

**Commitment:** Every feature is designed so that a rotating volunteer can take over the system in one evening. We will not ship features that require staff training, certification, or a multi-day onboarding.

**Gained:**
- "Handoff in one evening" becomes a testable product feature (per research ref 21: clubs run "exclusively by volunteers"). ClubExpress's own help docs recommend staff-assisted loading for all but the smallest clubs — Memba refuses that posture.
- Reduces support burden, which the Lean Canvas identifies as the #1 cost driver.

**Given up:**
- The "power user" segment (large associations with paid staff) who would pay for advanced workflow customisation, complex approval chains, deep reporting.
- Feature parity with ClubExpress on the long tail of admin-configuration depth.

**Why incumbents can't mirror:**
- ClubExpress's market position *is* feature depth for staff-run clubs; simplifying would alienate their installed base.
- Wild Apricot has accumulated 15+ years of features serving paid administrators — pruning is politically impossible.

**Reversibility:** **Type B** — reversible but would require re-positioning.

#### S5. Web-first responsive — no native mobile app at launch

**Commitment:** Memba ships responsive web only. We will not build native iOS/Android apps for the first 18 months.

**Gained:**
- One codebase, one deploy pipeline (Phoenix monolith). Faster iteration. Lower hosting/maintenance cost — critical given the support-heavy customer base.
- Avoids App Store / Play Store platform risk (review delays, 15-30% fees, policy changes).

**Given up:**
- "Branded mobile app" expectations set by Mighty Networks and some Wild Apricot tiers.
- Push notifications and offline trip-leader workflows (e.g. on a trail with no signal).

**Why incumbents can't mirror cheaply:**
- Mighty Networks' value prop is the branded mobile community experience; they cannot drop it. Wild Apricot Pro has a mobile app and cannot deprecate it without churn.

**Reversibility:** **Type C** — re-evaluate when ≥3 design-partner clubs cite mobile as the reason for not switching.

#### S6. Founder-led human support — not scalable self-serve at launch

**Commitment:** Through the first ~50 clubs, the founders run support and migration personally. We will not build out a tiered support team, knowledge-base-only support, or AI chatbots until we have direct line-of-sight on every failure mode.

**Gained:**
- Tight feedback loop with the design partners (KMC + 3–5 pilots). Every support ticket is product insight.
- Trust signal in a market burned by Wild Apricot acquisition / Personify support decline (Lean Canvas §4.5).

**Given up:**
- Scalability beyond ~50–100 clubs without hiring. Caps growth rate.
- Investor narrative around "self-serve viral product" — Memba is not that.

**Why incumbents can't mirror:**
- Wild Apricot (Personify-owned) and ClubExpress are at scale; "founder-led" is not an option. The acquisition-driven price/support trajectory is exactly what Memba's positioning exploits.

**Reversibility:** **Type C** — scales out as customer base grows, by design.

#### S7. Phoenix monolith — not a WordPress-style plugin ecosystem

**Commitment:** Memba is a single integrated Phoenix application. We will not build a plugin marketplace, public extension API, or a WordPress-style ecosystem in the first 2 years.

**Gained:**
- Coherent UX, no plugin-compatibility hell, no security surface from third-party code (the MemberPress/WooCommerce failure mode flagged in research ref 11).
- One product to support, one schema to migrate, one place to fix bugs.

**Given up:**
- Long-tail customisation that WordPress-stack clubs love.
- Third-party developer leverage and the SEO benefits of an ecosystem.

**Why incumbents can't mirror in reverse:**
- WordPress/MemberPress's *strategy* is the plugin ecosystem — they cannot become a closed monolith without destroying their value prop. Memba's integrated coherence is a direct counter to their assembly burden.

**Reversibility:** **Type B**.

---

### 3. Tactical deferrals (the explicit "not now" list)

| Deferred | Why now | Reversibility | Re-evaluation trigger |
|---|---|---|---|
| AT Protocol / federation | Zero buyer evidence (Lean Canvas Assumption 5). Strategic curiosity, not advantage. | D | Federation becomes a buyer-stated requirement, or a federated competitor emerges in outdoor-club space |
| LMS / courses | Crowded; off the membership-ops wedge | D | Three+ pilot clubs cite course management as a top-3 pain |
| Public discovery / marketplace | Competing with Meetup is suicide; not the wedge | C | Member acquisition becomes a stated club pain over admin pain |
| Branded mobile apps | See S5 | C | See S5 |
| Donation management / fundraising | Adjacent to membership but a distinct product (Givebutter, etc.) | D | Pilot clubs report >20% revenue from donations and ask for integration |
| Cabin / gear / fleet booking | Higher-ARPU sub-market (Rideau, Washington Canoe, UBC Sailing) but very different product | C | A specific large-club pilot makes it the wedge for that tier |
| General-purpose website builder | Wild Apricot/ClubExpress play this; we don't | B | Never — this is structural |
| White-label club website surface | Lets clubs replace fragile public/private sites without becoming Wix | B | Build only as opinionated club pages, branding, subdomains/custom domains, and membership-aware access control |
| Forum / discussion product | Discourse exists; off-wedge | D | Member-to-member comms emerges as a top-3 retention driver |
| Advanced email marketing | Mailchimp exists; we ship announcements, not campaigns | D | Email becomes the #1 cited pain in retention interviews |

---

### 4. Open trade-off decisions (need a call)

These are axes where the strategy is **not yet committed** and a deliberate choice is required:

1. **Trip management timing.** The Lean Canvas notes trips should be "soon after launch" — but exactly when? Shipping at MVP slows time-to-pilot; deferring risks "incomplete" perception (research ref 47). **Open: lock a calendar trigger.**

2. **Canadian vs US-first launch.** KMC is BC-based; FMCBC has 54 clubs / 5,000+ members. Canadian payment surcharge sensitivity is high (research). US TAM is bigger but more crowded. **Open: which country gets the SEO and migration-guide investment first?**

3. **Self-serve signup vs sales-assisted only.** S6 (founder-led support) is committed for the first ~50 clubs, but does the website allow self-signup at all, or is every customer a hand-held migration? **Open.**

4. **Pricing-floor: do we serve <30-member clubs?** Lean Canvas ICP is 30–300. Sub-30 clubs are price-sensitive and high-touch; they may damage unit economics. A "free tier for <30 members" could be a wedge — or a tar pit. **Open.**

5. **KMC equity / pilot terms.** Is KMC a paying customer, a design-partner with reduced fees, or an equity-style stakeholder? This determines how reference-able the case study is. **Open.**

6. **Open-source posture.** Phoenix monolith could be open-sourced (à la Discourse, Mastodon) which would help trust for volunteer-run clubs but complicates pricing. **Open — currently undecided.**

7. **Data residency.** GDPR (research ref 16 in SaaS Market Research) and Canadian PIPEDA exposure suggests Canadian/EU hosting may become a buying criterion. **Open: where do we host?**

---

### 5. The sharpest commitments, restated

If a future Memba employee, advisor, or investor reads only one paragraph, it should be this:

> Memba is the membership platform for volunteer-run outdoor and activity clubs. We model households as first-class. We price by active members and charge no payment surcharge. We optimise for the volunteer who inherits the job, not the paid administrator. We ship web-first, founder-supported, as a Phoenix monolith. We may provide each club with a white-label website, but only as an opinionated club-specific surface for membership, content, announcements, and activities. We are not a horizontal AMS, a creator platform, a community network, a course platform, a general-purpose website builder, or a public events marketplace — and we will turn down customers and features that would pull us toward any of those.

Each "not" in that paragraph is a refusal Wild Apricot, ClubExpress, Memberful, and Mighty Networks structurally cannot match without breaking their own strategy. That asymmetry — not feature parity — is the source of Memba's defensibility.



## Can't / Won't

This section names the explicit boundaries of Memba's strategy: what we deliberately refuse to do, and what we are structurally unable to do today. Following the deep-research methodology, every "won't" is paired with an *until-when* condition, and every "can't" is paired with the conditions under which it might shift. The goal is to make trade-offs crisp so the integrated strategy is harder to copy and easier to execute.

### Won't (deliberate trade-offs)

These are choices, not limits. Each protects the integrated strategy described in the lean canvas: a narrow, opinionated product for volunteer-run outdoor/activity clubs.

#### 1. Won't be a generic Association Management System (AMS)

- **Boundary:** Memba will not pursue feature breadth comparable to Wild Apricot, ClubExpress, or MemberPlanet (donation pipelines, committee management, accounting integrations, CME tracking, certifications-at-scale, complex membership-tier matrices, fundraising campaigns, sponsor management).
- **Reason:** Breadth is what makes those products unloved by volunteer admins (lean canvas §1, §3 "Avoid positioning as"). Our wedge is the *opposite* posture: opinionated, narrow, learnable in an evening.
- **Risk of violating:** We dilute the volunteer-handoff value proposition, end up competing on professional-AMS terms, and lose the structural reason large incumbents "won't" copy us.
- **Revisit when:** We have 500+ paying clubs and a clear, validated request pattern for a specific adjacency from existing customers — not from prospect wish-lists.

#### 2. Won't be a creator / community / social platform

- **Boundary:** No creator monetization (Memberful, Patreon, Substack), no community feeds (Mighty Networks, Circle, Discord), no AI-powered community features.
- **Reason:** Outdoor clubs are *not* communities-of-content-consumers; they are operational organizations with rosters, dues, waivers, and trips. Positioning here erodes trust with our buyer (the membership secretary) and pulls scope toward feeds, posts, and engagement metrics.
- **Risk:** Feature drift toward engagement KPIs that volunteer admins don't care about; brand confusion; competing against well-funded category leaders on their turf.
- **Revisit when:** Never as the core; possibly as a thin integration if Discourse/Slack/forum bridges become a top-3 churn driver.

#### 3. Won't be a general-purpose WordPress / Wix / Squarespace replacement

- **Boundary:** No full CMS, page builder, theme marketplace, or arbitrary marketing-site tooling. Yes to a focused club website surface: public club pages, member-only pages/files, directory, announcements, activities, logo, generated/tweakable colors, Memba-hosted subdomains, and later custom domains.
- **Reason:** CMS is a bottomless scope sink (lean canvas §8 "Cost drivers"), but many clubs need Memba to become their simple website rather than another back-office tool behind a fragile site. The safe path is an opinionated club-site product, not a generic builder.
- **Risk:** Becomes a maintenance and support tarpit; volunteer admins inherit a CMS they didn't ask for.
- **Revisit when:** Clubs ask for arbitrary layout/theme/plugin features rather than membership-aware club pages; say no unless the feature clearly serves the core club operating model.

#### 4. Won't run a public Meetup-style discovery network

- **Boundary:** No public trip directory, no cross-club social graph, no "find a club near you" marketplace.
- **Reason:** Our buyers want a *private* digital home (lean canvas §3). Public discovery introduces moderation, safety, and brand-risk costs we are too small to absorb, and competes with Meetup's distribution.
- **Risk:** Diverts engineering into two-sided-marketplace dynamics; exposes private club data to discovery pressure; alienates privacy-sensitive boards.
- **Revisit when:** A federation or umbrella body commissions it and funds it, and our top-tier clubs vote to opt-in.

#### 5. Won't add a Memba transaction surcharge

- **Boundary:** Stripe (and later GoCardless/PayPal) fees pass through at cost. No Memba percentage skim on dues, donations, or trip fees.
- **Reason:** Surcharges are the single most-cited frustration with incumbents (lean canvas §1, §7). Pricing on *active members* is the load-bearing trust signal.
- **Risk of violating:** We poison the "fair pricing" differentiator that Unfair Advantage §3 depends on, and hand Wild Apricot's critics back to Wild Apricot.
- **Revisit when:** Only for an explicitly optional service (e.g., concierge migration, hardware, SMS) — never on core dues flow.

#### 6. Won't lock data in

- **Boundary:** Clean CSV export, Google Sheets sync, documented schema, and a "leave anytime" covenant. No proprietary export formats, no data-egress fees, no contract clauses that retain member data on exit.
- **Reason:** Volunteer boards rotate; trust requires reversibility (lean canvas §4.3). Data portability is a structural commitment a vertically-integrated incumbent would have to cannibalize lock-in to match.
- **Risk:** None to us — high to violators. Violating this collapses the brand.
- **Revisit:** Never.

#### 7. Won't build an LMS / courses / certification engine

- **Boundary:** No course authoring, quizzes, certification issuance, or CE-credit tracking. We can *record* that a member holds an external certification; we will not become the certification system.
- **Reason:** LMS is a separate category with mature competitors (Thinkific, Teachable, LearnDash). Outdoor-club skill workflows can be modelled as flags/attributes without a learning platform.
- **Revisit when:** A federation requires it as a procurement gate AND we have the resources to ship it as a separate product line.

#### 8. Won't ship native branded mobile apps for MVP

- **Boundary:** Responsive web only at launch. No iOS/Android app, no white-labelled native client per club.
- **Reason:** Native shipping multiplies build cost ~3× and ongoing maintenance ~5× (Apple/Google review, push infra, per-tenant signing). Volunteer admins use desktop; members tolerate web for once-yearly renewal.
- **Risk of violating:** Burns runway on the wrong surface before product-market fit.
- **Revisit when:** Trip-day workflows (check-in, emergency contacts, offline waivers) are validated as the top retention driver AND we have the ARR to fund native properly.

#### 9. Won't chase enterprise federations / umbrella bodies as ICP

- **Boundary:** Federations (Alpine Club of Canada, BMC, national paddling associations) are *channels*, not initial customers. We will not configure the product around their procurement, SSO, branded-portal, or multi-chapter governance requirements first.
- **Reason:** Federation sales cycles are 9–18 months and product demands distort the volunteer-club UX (lean canvas §5 "Future segment").
- **Revisit when:** We have 200+ independent club customers and a federation deal can be served by configuration, not bespoke build.

#### 10. Won't make AT Protocol a dependency

- **Boundary:** AT Protocol stays a research spike. The MVP domain model does not require it; the data model does not assume PDS hosting; the product does not market federation.
- **Reason:** Research found no buyer evidence for federation/social-identity demand (lean canvas Assumption 5). Coupling a small-club ops tool to a young protocol multiplies risk on both sides.
- **Risk of violating:** Architectural rework, founder distraction, positioning confusion ("is this a Bluesky thing?").
- **Revisit when:** A paying customer explicitly requires it, or a federation channel partner funds the integration.

### Can't (structural limits today)

These are honest acknowledgements of constraints. They shape what we won't promise and where we won't compete.

#### 1. Can't out-feature Wild Apricot on professional-AMS breadth

- **Constraint:** Wild Apricot has 20+ years of feature accretion, a Personify acquisition behind it, and thousands of edge cases baked in (chapters, accounting exports, complex committees).
- **Reason:** We are a small team with no shot at parity, and parity is the wrong goal anyway.
- **Risk if pretended otherwise:** RFP losses, support cost explosions, brand confusion.
- **Revisit when:** Never — this is a permanent strategic concession that *enables* the wedge.

#### 2. Can't outspend incumbents on paid acquisition

- **Constraint:** Wild Apricot/Personify, ClubExpress, and Mighty Networks have orders-of-magnitude more marketing budget. We cannot win on Google Ads, retargeting, or trade-show presence.
- **Implication:** Growth must come from KMC reference, SEO comparison content, federation channels, and direct outreach (lean canvas §6).
- **Revisit when:** ARR and unit economics support paid channels with payback under 12 months — likely post-Series A, if ever.

#### 3. Can't offer in-person training or onboarding at scale

- **Constraint:** No field sales, no on-site implementation team. One founder cannot fly to every club.
- **Implication:** Onboarding must be self-serve or remote-concierge; documentation, importers, and templates carry the load.
- **Revisit when:** Concierge migration becomes a revenue line that funds dedicated implementation staff.

#### 4. Can't serve clubs needing SOC2 / HIPAA / heavy compliance day one

- **Constraint:** No audit reports, no BAA, no SSO/SAML, no data-residency guarantees beyond hosting region defaults.
- **Implication:** University-affiliated clubs, healthcare-adjacent groups, and government-contracted federations are out of scope at launch.
- **Revisit when:** A clearly-priced enterprise tier justifies the ~$50–150K/year compliance overhead.

#### 5. Can't deliver native mobile at launch

- See "Won't #8" — this is also a *can't* given current team size. Building native correctly requires capacity we do not have.

#### 6. Can't guarantee email deliverability at the level of dedicated ESPs

- **Constraint:** Email deliverability is a deep specialty (lean canvas §8). We will use a reputable provider (e.g., Postmark/SendGrid) but cannot promise inbox placement parity with Mailchimp or a dedicated marketing-ops setup.
- **Implication:** Position announcements as *transactional and operational*, not as marketing newsletters.
- **Revisit when:** Deliverability becomes a top-3 churn driver and warrants a dedicated investment.

#### 7. Can't model every outdoor-club edge case at launch

- **Constraint:** Cabin booking, gear libraries, permits, trail-status, fleet management, multi-day expeditions with shuttle logistics — these exist in real clubs but each is a product unto itself.
- **Implication:** MVP and Phase 2 cover the 80% (members, households, renewals, trips, waivers). The long tail waits.
- **Revisit when:** A specific edge case is requested by ≥20% of paying clubs.

### Revisit triggers

The boundaries above are not permanent dogma. The following signals would warrant reopening one or more items:

- **Concentrated customer demand:** ≥20–30% of paying clubs request the same deferred capability, with willingness to pay, and the request originates from existing customers (not prospects shopping a feature list).
- **Channel-funded build:** A federation, insurer, or umbrella body commissions a capability and funds the build (relevant to AT Protocol, LMS, multi-chapter, compliance).
- **Validated retention driver:** Post-launch data shows a deferred capability (e.g., native mobile for trip-day, deliverability investment) is the top-3 churn or activation blocker.
- **Competitive shift:** An incumbent acquisition, price hike, or product retreat opens a positioning lane we deliberately ceded (e.g., creator-platform-style features become non-negotiable for our ICP).
- **Capacity step-change:** ARR or fundraising materially changes our ability to absorb compliance, enterprise sales, or native-mobile overhead.
- **Disconfirmation of an assumption:** Specifically, Assumption 5 (AT Protocol not needed) flips only if a paying customer or channel partner requires it, not because the founder finds it interesting.

Any flip must be a deliberate strategy revision — documented, dated, and reviewed against the integrated-strategy reinforcement matrix — not a creeping concession made in a sales call.



## Growth

Memba’s growth strategy should be trust-sensitive, not growth-at-all-costs. The product asks volunteer boards to move member records, payments, waivers, emergency contacts, and institutional memory into a new system. A bad first renewal cycle, a privacy mistake, or a visible “tiny vendor disappeared” scare would travel faster than a paid ad win. Growth therefore has to optimize for survivable trust, referenceability, and channel quality before raw lead volume. This follows directly from the Vision’s stance that Memba is community infrastructure software, not venture-scale SaaS, and from the Value Proposition’s emphasis on board confidence, portability, and volunteer handoff.

### Growth posture

Memba should use a hybrid motion: product-led activation inside each club, founder-led sales into each account. It is not pure PLG because a club is a governed buyer with data migration, payments, privacy, and sometimes board approval. It is not classic sales-led SaaS either: expected ACV for the beachhead is likely too low to support SDR-led outbound. The right early motion is “concierge PLG”: direct founder outreach, a guided migration, a live pilot, then self-serve member/admin activation once the club is inside.

Outdoor clubs are the beachhead. The long-term market is broader volunteer-run membership organizations, but the first growth loops must concentrate on outdoor/activity clubs with households, waivers, trips, renewals, and volunteer turnover. That focus sharpens messaging and avoids becoming a generic association management vendor too early.

### Trust-sensitive growth guardrails

Growth channels should be ranked by trust durability, reversibility, concentration risk, and fit to the volunteer-admin buying moment. Memba should avoid channels that create volume without confidence: broad paid social, generic “community app” influencer pushes, or free-tier virality that attracts sub-50-member informal groups. These would inflate support, distort the roadmap, and increase churn.

Specific early guardrails:

- No scaling paid acquisition until KMC and at least two non-founder-affiliated pilots have completed real renewals or waiver/activity workflows.
- No broad free tier for clubs below the beachhead threshold; use trials or design-partner discounts instead.
- Cap any one referral source, federation, or club network so Memba is not captured by a single geography, sport, or gatekeeper.
- Treat trust promises as product commitments: export, Google Sheets sync, pricing pledge, continuity plan, and no forced payment surcharge. The vendor-independence research is clear that independence is useful only when backed by mechanisms, and bus-factor fear must be neutralized.

### Beachhead sequence

The growth sequence should move from proof to density to adjacency.

1. **KMC design partner.** Use KMC to prove the domain model with real data: households, renewal states, roles, privacy, waivers, and the “next volunteer can run it” outcome. KMC is not validation by itself, because founder proximity can bias the signal, but it is the essential product-quality proving ground.
2. **3–5 non-affiliated outdoor club pilots.** Recruit KMC-archetype clubs: roughly 80–300 active members, at least 25% household/family memberships, recurring trips or activities, and a live pain trigger such as renewal season, registrar turnover, waiver concern, website migration, or Wild Apricot/TidyHQ/Zeffy workaround fatigue.
3. **Regional outdoor-club density.** Concentrate first in BC/Alberta/Pacific Northwest and comparable Commonwealth outdoor-club ecosystems where Wild Apricot surcharge frustration, household memberships, and waiver/trip needs are salient.
4. **Switcher segment.** Target larger outdoor/activity clubs already on Wild Apricot, ClubExpress, TidyHQ, Heylo, Zeffy, or DIY stacks. These have higher willingness to pay but need stronger migration proof.
5. **Adjacent volunteer-run membership orgs.** Only after repeatable activation in outdoor clubs should Memba widen to other clubs with the same operating model: sailing, astronomy, model railway, alumni, cultural, hobby, and community associations.

### KMC pilot and reference loop

KMC should become a reference loop, not just a case study. The loop is:

1. Build with KMC’s messy realities.
2. Measure before/after outcomes: admin hours saved, import time, household errors, renewal completion, waiver completion, number of admins who can operate the system, and support required.
3. Convert outcomes into assets: board-ready case study, migration checklist, demo data, “renewal season after Memba” narrative, and quotes from registrar/treasurer/trip leaders.
4. Use those assets in direct outreach to similar clubs.
5. Feed objections from outreach back into product and onboarding.

The first public proof should not be “KMC likes it.” It should be: “A volunteer-run outdoor club migrated its roster, renewed members, handled households, and handed admin access to another volunteer without chaos.”

### Acquisition channels

#### 1. Direct outreach

Direct outreach is the primary early channel. The target is not “outdoor enthusiasts”; it is named club officers: membership secretary, treasurer, president, webmaster, communications admin, and trip/activity coordinator.

Outreach should be trigger-based. Best trigger moments:

- Renewal season approaching.
- Registrar or treasurer handoff.
- Board complaint about spreadsheet chaos.
- Website redesign or WordPress maintenance failure.
- Waiver/liability review.
- Insurance or federation requirement changes.
- Wild Apricot/ClubExpress renewal or price increase.
- Failed attempt to use Zeffy, Heylo, TidyHQ, Amilia, Spond Club, membermojo, Clubforce, SportLoMo, Yapla, Meetup, Eventbrite, Mailchimp, Google Groups, or spreadsheets as a complete system.

Cold outreach should lead with a narrow offer: “We help outdoor clubs move from spreadsheets/Wild Apricot/Zeffy workarounds to one membership system with households, renewals, waivers, and handoff.” Avoid abstract “club management platform” language.

#### 2. Comparison and SEO content

SEO is not a launch channel, but it can become the compounding channel for switchers and problem-aware buyers. Memba should publish comparison and problem pages that map to real search intent:

- Wild Apricot alternative for outdoor clubs.
- Zeffy vs Memba for membership clubs.
- Heylo vs Memba for outdoor clubs.
- TidyHQ alternative for hiking and mountaineering clubs.
- Spond Club alternative for outdoor clubs that are not team sports.
- membermojo alternative for clubs that need waivers and true households.
- Yapla alternative for Canadian outdoor clubs.
- Family membership software for clubs.
- Club waiver software with membership status.
- How to stop running club renewals in a spreadsheet.
- How to hand off membership secretary duties.

The competitor research makes this comparison strategy necessary: Zeffy erodes the pricing wedge, TidyHQ contests family memberships, Heylo already offers memberships/events/paid waivers, Spond Club, Clubforce, SportLoMo, membermojo, and Yapla push price expectations down, and Amilia is strong but overbuilt for the beachhead (`round2-competitor-analysis/`, `extracted-text/Competitor Gap Pass for Memba.txt`, and `zeffy.md`). Content should not pretend competitors are weak. It should explain the specific trade: Memba is for clubs that need the combination of households, waivers, activity workflows, portability, and volunteer handoff.

#### 3. Federation and regional networks

Federations and regional networks are trust intermediaries. They may include mountaineering federations, hiking club directories, Alpine Club sections, paddling associations, cycling bodies, trail associations, ski touring clubs, and regional outdoor councils. The goal is not immediate reseller scale; it is credibility, introductions, and pattern recognition.

The first ask should be educational, not commercial: a webinar or checklist on “how volunteer clubs can survive renewal season and admin handoff.” Over time, federation relationships may produce group discounts, recommended-vendor status, shared waiver templates, or multi-club reference clusters. The risk is gatekeeper concentration: one federation can define Memba too narrowly or demand bespoke features. Keep federation work lightweight until the core club motion is repeatable.

#### 4. Integration-led wedge

Full migration is scary. Memba should offer low-risk wedges that create trust before replacement:

- Waiver collection plus roster sync.
- Google Sheets export/sync.
- Household cleanup/import tool.
- Renewal reminder tool.
- Member directory/member portal.
- Wild Apricot/TidyHQ/Zeffy/Heylo/Yapla/membermojo/CSV migration assessment.

The best wedge is the one that preserves the path to full membership operations. Waiver + roster sync is especially promising because Zeffy and TidyHQ appear weaker on native outdoor-club waiver depth, while Heylo’s waivers are paid and not tied to true households (`extracted-text/Competitor Gap Pass for Memba.txt`).

### Activation milestones

A club is not activated when it signs up. It is activated when it trusts Memba with a real operating loop. Activation milestones should be sequenced and visible:

1. Club imports first roster.
2. Admin resolves duplicate people and households.
3. Membership types and renewal rules are configured.
4. Payments are enabled.
5. First test renewal succeeds.
6. First household renewal succeeds.
7. First waiver is accepted and retrievable.
8. First renewal reminder is sent.
9. First member logs in and updates profile/privacy.
10. First export or Google Sheets sync runs successfully.
11. A second volunteer admin is invited and completes a core task.
12. First handoff checklist is completed.

The “second volunteer can run it” milestone matters as much as payment activation. It is the product proof behind the whole vision.

### Retention, expansion, and referral loops

Retention should come from recurring administrative rhythm, not daily engagement. Clubs renew annually; Memba must become part of the club’s calendar: pre-renewal prep, renewal campaign, waiver refresh, AGM/board turnover, trip season opening, and end-of-year reporting.

Expansion paths:

- Starter to Club when waivers, announcements, directory, and roles become necessary.
- Club to Pro when activity/trip workflows, migration support, advanced reporting, or priority support are needed.
- One club to peer clubs through secretary/treasurer references.
- One federation conversation to several local clubs, without becoming federation-dependent.

Referral mechanics should be status- and trust-based, not cash-based. Cash referrals can feel grubby in a trust-sensitive volunteer market. Better loops: “recommended by KMC,” board-ready case studies, migration templates, federation webinars, and a small credit donated to the referring club’s outdoor access/trail fund if needed.

### Channel risks

- **Free competitors.** Zeffy and Heylo make “cheap” a losing headline. Memba must sell operational depth and trust, not price alone.
- **TidyHQ parity.** TidyHQ is strong on family memberships; Memba must prove better household onboarding, waiver integration, emergency contacts, and outdoor trip fit.
- **Support overload.** Small clubs can be high-touch and low-ARPU. Onboarding must be templated quickly.
- **Migration fear.** Switchers will stall unless imports, exports, and rollback confidence are excellent.
- **Geographic overfitting.** KMC/BC proof is valuable but not universal. Validate outside the founder’s network early.
- **Independence skepticism.** “Founder-led” helps only if paired with continuity and data-portability commitments.

### 90-day growth experiments

1. **KMC reference package.** Produce a quantified KMC before/after narrative and one board-ready slide deck. Success: at least five cold prospects agree to calls after seeing it.
2. **50-club direct outreach test.** Target KMC-archetype clubs across BC, AB, WA, OR, CO, and ON. Success: 10 conversations, 3 serious pilot candidates, at least 1 paid or deposit-backed pilot.
3. **Trigger-message test.** Test four hooks: households, waivers/trips, handoff, and Wild Apricot/Zeffy workaround. Success: one hook produces 2× reply rate.
4. **Switcher content test.** Publish three comparison pages and track qualified demo requests, not raw traffic. Success: 3 qualified inbound conversations in 90 days.
5. **Waiver + roster wedge.** Offer a limited pilot to clubs unwilling to migrate fully. Success: 2 clubs use it with real members and one requests full membership migration.
6. **Federation briefing.** Run one educational session for a regional outdoor network. Success: 10 attendees, 3 follow-up club conversations.
7. **Activation audit.** Time every pilot from import to first renewal/waiver/export/second-admin task. Success: median simple-club migration under two hours of admin effort, excluding founder cleanup.

The decision after 90 days is not “did we get traffic?” It is whether Memba can repeatedly turn a trust-sensitive club from curiosity into an operating reference without exhausting founder support.



## Key Metrics

Metrics are unusually dangerous for Memba because the product serves low-budget, volunteer-run organizations where the buyer, admin user, activity leader, board, and regular member all experience value differently. The product can look healthy in analytics while failing the mission: an admin logs in often because the workflow is confusing; a club renews because migration is painful; members pay successfully but households, waivers, or privacy are wrong; a board is satisfied while the next volunteer still cannot inherit the system.

The metrics system must therefore measure not only growth and usage, but administrative confidence, handoff quality, data correctness, and operational risk. No single metric should become an OKR target alone. Every growth metric needs a quality or trust counter-metric, and for the first stage quality should dominate growth when they conflict.

### Measurement dangers for volunteer-club SaaS

1. **Admin engagement can be inverse value.** A membership secretary logging in every night during renewal season may mean Memba is saving the club, or it may mean Memba has recreated spreadsheet hell in a browser. Admin activity must be paired with task completion time, error rate, and self-reported confidence.
2. **Buyer satisfaction can hide user failure.** The board may like pricing and reporting while regular members struggle to renew or trip leaders cannot access emergency contacts. Measure each persona separately.
3. **Retention can reflect lock-in, not love.** A club may stay because switching is scary. Renewal must be paired with export usage, NPS-style removal impact, and evidence that a second volunteer can run the system.
4. **Payment success can hide household failure.** A family may pay once while individual profiles, waivers, children, directory settings, and membership status are wrong.
5. **Low support volume can mean silence, not success.** Volunteer admins may avoid asking for help or route around Memba in Sheets. Pair tickets with workaround counts and onboarding check-ins.
6. **Activity metrics can incentivize unsafe growth.** More trips in Memba is good only if waiver, membership, capacity, leader, and emergency-contact data are correct.
7. **Competitive comparison can Goodhart scope.** Chasing Heylo’s event/social metrics or Zeffy’s payment volume would pull Memba away from secretary-first club operations.

The 18-month silent-drift failure mode is clear: Memba becomes a decent renewal/payment tool with many dashboards, but clubs still rely on side spreadsheets for households, waivers, trip lists, and handoff. The analytics say “active clubs”; the next volunteer still says, “I can’t run this.”

### North Star metric

**North Star: Monthly Sustained Club Operations.**

A club counts as a Monthly Sustained Club only if, in the last 30 days, it has used Memba for at least three core operational jobs and passed basic quality gates:

- roster or household management;
- renewals or payment reconciliation;
- member self-service, directory, or privacy updates;
- official announcements;
- waiver collection or retrieval;
- activity/trip participant management;
- export, sync, or handoff workflow.

Quality gates: no unresolved critical data-integrity issue, payment success above threshold, email delivery above threshold, and at least one non-founder admin able to complete a core task without direct founder help.

This North Star is better than “monthly active clubs” because it rejects superficial login activity. It is better than “active members managed” because member count alone would push Memba up-market too early. It is better than ARR because the first existential question is whether clubs can actually run through Memba.

Secondary North Star: **Active Members Under Correct Management** — active members whose status, household, renewal, waiver/privacy basics, and exportability are represented correctly. Use this for scale reporting, not as the primary OMTM during the pilot.

### OMTM: pilot and next quarter

For the KMC pilot and next quarter, the One Metric That Matters should be quality-anchored:

**OMTM: Percentage of KMC’s real renewal workflow completed in Memba without founder intervention, with no critical data errors.**

This includes import, household setup, membership types, renewal reminders, member renewal, payment recording, admin correction, export/sync, and board-visible reporting. The transition condition to a growth OMTM is: two consecutive renewal cycles or equivalent pilot milestones with ≥90% of targeted workflow completed in Memba, zero critical membership/payment/privacy errors, and a second volunteer completing the handoff checklist successfully.

After that threshold, the OMTM can become: **number of clubs reaching first successful renewal cycle within 45 days of onboarding**, paired with onboarding support hours and data-error rate.

### AARRR adapted for Memba

#### Acquisition

For club admins: qualified club conversations, board demos booked, and design-partner applications from KMC-archetype clubs. Counter-metric: percentage matching ICP, so outreach does not fill the funnel with sub-50-member clubs or large associations.

For members: invitations sent and accepted after a club goes live. Counter-metric: member support requests per 100 invited members.

For activity leaders: leaders invited to manage trips/activities. Counter-metric: percentage who can access the information they need without becoming full admins.

#### Activation

A club is activated when it imports a roster, configures memberships and households, enables renewal/payment flow or offline payment tracking, sends its first renewal or invitation, and has at least one member successfully renew or update their profile.

Member activation: logs in, confirms contact details, privacy settings, and membership status; renews or verifies renewal if due.

Activity-leader activation: creates or manages an activity, views participant list, sees waiver/membership status, and can access emergency contacts in the expected context.

#### Retention

Club retention is annual renewal plus continued operational depth: the club still uses Memba for multiple core jobs, not just as a dead database. Member retention is successful renewal without duplicate accounts or payment confusion. Activity-leader retention is repeat use for trips without reverting to side spreadsheets.

#### Revenue

Track MRR/ARR, revenue per club, paid pilot conversion, gross margin after support and migration, support-adjusted ARPU, and expansion from Starter to Club/Pro. Pair revenue with ICP fit and support load to avoid building a low-margin custom-services business.

#### Referral

Measure warm introductions to other clubs, federation mentions, public case-study consent, and “switcher” webinar referrals. Counter-metric: referral quality; a flood of tiny free-tool clubs is not success.

### Core metric set

#### Activation metrics

- Time from signed pilot to clean roster import.
- Percentage of households mapped without manual rework.
- First successful individual renewal.
- First successful household renewal.
- First admin correction completed without founder help.
- First export or Google Sheets sync completed.
- First announcement sent with acceptable delivery rate.
- First handoff checklist completed by a second volunteer.

#### Retention metrics

- Club annual renewal rate.
- Clubs still using ≥3 core workflows after 90 and 180 days.
- Percentage of renewals processed through Memba rather than side channels.
- Number of active admins per club.
- Second-volunteer task completion rate.
- Manual workaround count per club per month.
- “If Memba disappeared tomorrow, how disrupted would your club be?” segmented by registrar, treasurer, board, member, and activity leader.

#### Revenue metrics

- ARR and MRR.
- Paid pilot conversion rate.
- Revenue per active club.
- Gross margin after infrastructure, email, support, and migration time.
- Onboarding hours per club and payback period.
- Discount dependence.
- Win/loss by named alternative: Zeffy, TidyHQ, Amilia, Heylo, Spond Club, membermojo, Clubforce, SportLoMo, Yapla, Wild Apricot, DIY.
- Percentage of deals won for domain-model reasons rather than price.
- Expansion to higher tiers when waivers/activity workflows launch.

#### Quality metrics

- Critical data error rate: wrong member status, wrong household billing, duplicate paid member, incorrect waiver state, privacy exposure.
- Payment success and reconciliation accuracy.
- Renewal reminder conversion and false-reminder rate.
- Email delivery, bounce, complaint, and unsubscribe rates.
- Import error rate and time to clean import.
- Household edge-case resolution rate.
- Waiver completion, versioning, and retrieval success.
- Time for a new volunteer to complete common tasks.
- Support requests per 100 members and per admin, classified by severity.

### Guardrails and counter-metrics

- **Growth guardrail:** New clubs added is valid only if median onboarding support hours and critical data errors stay below threshold.
- **Engagement guardrail:** Admin sessions are positive only when task completion time falls and workaround count falls.
- **Revenue guardrail:** ARR growth is valid only when support-adjusted gross margin remains healthy.
- **Competitive guardrail:** “Fair pricing” messaging is valid only if win/loss notes show prospects chose Memba for households, waivers, activity workflows, privacy, or handoff — not because they thought no cheap/free alternatives existed.
- **Household guardrail:** Household renewals count only when individual profiles, member statuses, waivers, and privacy settings are correct.
- **Activity guardrail:** Activities created count only when participant list, waiver status, membership status, and emergency contact access are complete.
- **Handoff guardrail:** A club is not “healthy” until a second volunteer can perform core workflows without founder intervention.
- **Trust guardrail:** Export/sync usage is not churn risk by default; it is evidence of portability. Do not punish it.

### Stage targets

#### KMC pilot

- 100% of relevant member records imported and reconciled.
- ≥90% of household cases modeled correctly.
- First real renewal/payment cycle completed with zero critical payment or status errors.
- ≥60% of invited members activate accounts if member portal is in scope.
- Median admin core-task completion under 10 minutes for routine tasks.
- A second volunteer completes handoff checklist without founder help.
- Fewer than 5 severe support issues per 100 members during launch.

#### First 10 clubs

- ≥7 of 10 reach activation within 45 days.
- ≥6 of 10 use Memba for at least three core workflows by day 90.
- Median clean import under two hours for simple clubs after tooling improves.
- Critical data error rate below 1% of active members.
- Median founder/onboarding support below a defined sustainable threshold.
- At least 3 clubs agree to reference calls or case-study quotes.
- At least 5 pay retail or near-retail pricing.

#### Year 1

- 25–50 paying clubs, depending on support load and scope.
- ≥80% logo retention among ICP-fit clubs.
- ≥70% of clubs using three or more workflows.
- Support-adjusted gross margin trending toward SaaS viability, not services dependency.
- Documented repeatable migration path from CSV/Sheets and at least one incumbent.
- At least one federation or trusted network channel producing qualified leads.
- No unresolved systemic privacy, waiver, or payment integrity incidents.

### Anti-Goodhart risks

- Optimizing “clubs onboarded” attracts tiny clubs with no budget or large clubs with procurement drag.
- Optimizing “members managed” pulls Memba up-market before the handoff product is excellent.
- Optimizing “admin activity” rewards confusion.
- Optimizing “low support” rewards silent failure and hidden spreadsheets.
- Optimizing “payment volume” turns Memba into Zeffy-lite.
- Optimizing “events created” turns Memba into Heylo-lite.
- Optimizing “retention” can tolerate lock-in.

Mitigation: every OKR must be paired. Growth targets require quality gates. Revenue targets require support-margin gates. Usage targets require task-success gates. The dominance rule for the first year: data correctness, privacy, and volunteer handoff beat growth.

### Instrumentation needed

Memba should instrument events and state changes from day one: imports, household merges/splits, membership status changes, renewals, failed payments, reminders, email delivery, waiver acceptance/version retrieval, privacy changes, exports/syncs, role changes, activity participant changes, and admin corrections. Each event should include club, user role, object type, source, timestamp, and whether founder/support intervention occurred.

Add structured support tagging for persona, workflow, severity, root cause, and workaround. Add onboarding checklists per club. Add periodic in-product task-success prompts for admins and members. Maintain a “what users can’t see” dashboard: data-integrity anomalies, duplicate households, stale waivers, privacy-risk changes, failed reminders, email deliverability, export health, and clubs with declining operational depth.

The framework is working when it catches a problem the founder would otherwise have missed — and reverses a product or growth decision because the quality counter-metric says no.



## Relative Costs

Memba should choose a **differentiated focus** position: not cost leadership, not broad differentiation, and not a muddled hybrid. The focused segment is volunteer-run outdoor/activity clubs that need households, renewals, waivers, directories, announcements, activity workflows, and volunteer handoff in one system. The differentiation is not polish or feature breadth for its own sake; it is the lower *true cost of club administration* for a narrow customer whose explicit budget is small but whose hidden volunteer-time and risk costs are high.

This distinction matters because Memba cannot be the cheapest visible option. Zeffy can be free. HelloAsso proves the free/donor-funded model at French scale. Spond Club normalizes free or low-cost club administration in grassroots sport. Heylo has a free tier and paid waivers at a price that overlaps Memba’s likely Club tier. TidyHQ is mature, club-native, and roughly in the $50–$80/month band. membermojo is dramatically cheaper in the UK. Clubforce and SportLoMo create low-cost governed-sport expectations. Yapla adds a Canadian free-membership-management anchor. DIY is “free” except for payment processing and the volunteers’ evenings. Competing as the lowest subscription price would pull Memba into the worst part of the market: small, highly price-sensitive clubs with messy data, low ARPU, and high support needs. That is not Southwest-style cost leadership; it is underpriced services work disguised as SaaS.

The customer-facing cost comparison must therefore use total cost of ownership, not subscription price alone. For a volunteer club, true cost includes software subscription, payment fees, setup and migration, payment reconciliation, renewal mistakes, duplicate data entry, support responsiveness, waiver retrieval, privacy risk, role handoff, lock-in, and the cost of the next volunteer failing to understand the system. Memba wins only if it makes those costs visibly lower than the alternatives.

### Customer cost versus the alternatives

**Zeffy** sets the hardest price anchor: $0 subscription and absorbed payment processing funded by optional donor tips. For donation-heavy nonprofits this is compelling. For membership clubs, the cost is shifted rather than eliminated. Members may see tip prompts in a context that feels odd for annual dues; the club becomes dependent on a model optimized for fundraising economics, not membership operations. Zeffy’s membership forms, recurring payments, events, CRM, and exports make it a credible low-cost workaround. But the hidden costs are household compromise, waiver workarounds, limited member portal semantics, no club-specific activity model, and volunteer time spent adapting a fundraising tool to a club operating system. For simple clubs, Zeffy may be “good enough.” Memba should not chase them. For clubs with families, trips, waivers, emergency contacts, and handoff risk, Zeffy’s zero price is offset by recurring workaround cost.

**Heylo** is closer functionally than Zeffy. It has memberships, payments, events with capacity and waitlists, web and mobile access, Canadian support, and native waivers on its Pro plan. Its visible cost can be low: free for basic use, $19/month for Plus, $59/month for Pro, plus payment service fees. That makes it dangerous because it contests payments, events, and waivers simultaneously. Memba’s cost case against Heylo is narrower: true household membership and secretary-first administration. Heylo’s center of gravity is community leaders and member engagement; Memba’s must be the boring back-office job of keeping club records, renewals, waivers, permissions, emergency contacts, and handoff clean. If Memba cannot prove that administrative depth, Heylo will look cheaper and good enough. If Memba does prove it, the incremental subscription cost becomes the price of avoiding household hacks and back-office drift.

**TidyHQ** is the most serious like-for-like cost benchmark. It is transparent, mature, international, volunteer-club-native, and strong on family memberships. Its pricing around the $50–$80/month range means Memba cannot ask clubs to pay much more unless it delivers clear domain superiority. The TidyHQ comparison forces discipline: Memba’s household model must be easier in practice, not merely more theoretically correct. Its waiver, emergency contact, and outdoor activity workflows must be meaningfully better than generic events and custom fields. Its volunteer handoff must be a real product workflow, not a marketing phrase. Against TidyHQ, Memba is not cheaper on subscription; it must be cheaper in implementation friction, trip/waiver risk, and the cost of the next committee inheriting the system.

**Amilia / SmartRec** is not a beachhead price competitor but is useful as an upper-bound contrast and a serious Canadian benchmark. At $99/month entry, implementation from $899, higher tiers at $499/month and beyond, plus a 1% service fee on invoices and card processing, Amilia is too costly and complex for a 30–300 member volunteer outdoor club. Its true cost includes onboarding, configuration, staff learning curve, and a facility/recreation model that is overbuilt for club secretaries. Memba’s cost advantage here is straightforward: right-sized software. It should not compete with Amilia on power; it should say, in effect, “you do not need Parks & Rec infrastructure to run a mountaineering club.”

**Wild Apricot** and similar broad AMS incumbents are the clearest examples of high true cost despite familiar category fit. Their visible subscription ranges are broad, but the customer pain is contact-count cliffs, payment-processor pressure, support decline, acquisition uncertainty, weak family modeling, and administrative complexity. A small club can end up paying a large share of dues revenue before it counts payment fees or volunteer time. The switching cost away from Wild Apricot is also part of its cost: data export, cleanup, retraining, and fear of breaking renewals. Memba’s cost position is not merely “less expensive than Wild Apricot.” It is “lower-risk to operate and lower-risk to leave.” Clean exports, active-member pricing, no Memba payment surcharge, and migration help are essential cost features, not nice trust copy.

**Spond Club, Clubforce, SportLoMo, membermojo, and Yapla** create regional low-cost anchors. Spond, Clubforce, and SportLoMo are strongest where the club behaves like a grassroots sport body or governing-body participant. membermojo is an excellent tiny-club price benchmark in the UK. Yapla matters because it is Canadian and uses free-membership-management language. Memba should not try to win these comparisons on sticker price. It should qualify out prospects whose main job is team fixtures, federation compliance, or cheapest possible member records; pursue only those with the household + outdoor-activity + volunteer-handoff gap.

**DIY** — Google Sheets, Stripe or PayPal buttons, Mailchimp, Google Groups, WordPress plugins, PDFs, Meetup/Eventbrite — will remain Memba’s most common competitor. Its subscription cost is often near zero, and volunteers already know the tools. But DIY’s true cost is paid in repeated manual work: reconciling payments, chasing renewals, copying emails between systems, keeping rosters current, storing waivers, maintaining access lists, debugging WordPress, explaining the setup to a successor, and recovering from mistakes. DIY is rational for tiny or very simple clubs. Memba should not shame it. The strategic opening is the point where DIY’s volunteer-time cost exceeds the board’s tolerance, especially after a failed renewal season, waiver scare, website problem, or officer handoff.

### Memba’s own cost-to-serve implications

A differentiated focus strategy raises Memba’s cost to serve. The expensive inputs are not infrastructure or payment processing; they are support, migration, household edge cases, waiver/legal posture, email deliverability, and product design discipline. The dominant value driver — making complex volunteer-club operations feel simple enough for rotating non-specialists — is expensive to produce well. It requires founder-led support early, careful onboarding, import tools, documentation, and opinionated refusal of feature sprawl.

This cost structure rules out a broad low-price strategy. A free tier for very small clubs would likely attract the customers least able to pay and most likely to need hand-holding. A $19/month tier could create high-support, low-margin accounts before the product has scale. Memba may choose a narrow free trial or design-partner discount, but not a permanent lowest-price posture. The healthy model is paid, predictable, and honest: enough ARPU to fund responsive support and migration, while avoiding the extractive mechanics customers resent — contact-count punishment, proprietary payment surcharge, mandatory tip prompts, and paid hostage-taking around data export.

The key cost-management move is productized simplicity. Every workflow that reduces support also strengthens the positioning: clean household import, guided renewal setup, waiver templates with clear legal caveats, Google Sheets export/sync, role transfer, handoff checklist, and obvious admin dashboards. Memba’s internal cost advantage over broader incumbents is focus: it can make fewer workflows excellent for one segment instead of supporting the long tail of association, facility, donor, course, and website-builder use cases.

### Decision and tripwires

The decision sentence is: **Memba should pursue differentiated focus because the market already contains free and low-cost general tools, while the costly unmet need is the integrated outdoor-club operating model that lowers volunteer time, handoff risk, waiver risk, and lock-in for a narrow segment.**

This decision should be revisited if four conditions emerge: clubs refuse to pay at least roughly $50–$100/month for the integrated workflow; TidyHQ, Amilia, Heylo, Spond Club, Clubforce, SportLoMo, membermojo, Yapla, or Communal ships true household plus waiver plus outdoor trip-depth for the same segment at a lower effective price; migration and support time remain too high after productization; or the beachhead proves that households/waivers/trips are not top-three pains.

### Customer-facing cost narrative

Memba is not the free option. It is the option that makes club administration cost less in the ways that matter: fewer renewal mistakes, fewer spreadsheet nights, fewer waiver workarounds, fewer payment surprises, fewer handoff disasters, and no fear that your data is trapped. Pay a clear subscription for the members you actually serve. Use standard payment processing without a Memba surcharge. Export your data whenever you want. Keep families, waivers, trips, and volunteer roles in one place. The promise is not “cheapest software.” The promise is: **your club gets its evenings back, and the next volunteer can keep it running.**



## Cost Structure

Memba is not an AI-heavy product whose main cost risk is inference. Its hard cost problem is a low-ARPU, high-trust, high-support SaaS business for volunteer-run clubs. A naive model would assume that once the Phoenix app is built, each additional club costs almost nothing. The reality is that the expensive work sits around the software: migration from messy spreadsheets or incumbents, support for rotating volunteers, reliable email delivery, waiver/privacy/legal assurance, and the trust commitments needed to make a small independent vendor credible.

All numbers below are estimates until replaced by vendor quotes, pilot actuals, and a driver-based FP&A model.

### Unit of value and gross-margin frame

The most useful unit of value is one active club-month, with a secondary unit of one active member-month. Memba's pricing hypotheses are roughly $29–$49/month for Starter, $59–$99/month for Club, and $129–$199/month for Pro. That implies low annual contract values: perhaps $500–$1,200/year for many early clubs and $1,500–$2,500/year for larger ones. This makes support and migration discipline existential.

The target long-run software gross margin should be 80%+ before migration services, but early gross margin may be much lower because founder time is doing support, onboarding, and custom import work. A realistic early target is to prove that steady-state variable cost per club can stay below 10–20% of subscription revenue, while one-time migration is either paid, capped, or treated as deliberate learning for the first design partners.

### Fixed operating costs

#### Product and engineering

The largest fixed cost is founder and engineering time. Even if founder salary is initially deferred, the model should not pretend it is free. Estimate founder compensation at $120k–$180k/year pre-seed/pre-Series A equivalent, rising to $180k–$250k if investor-funded or once revenue supports it. A first senior Phoenix engineer would likely cost $140k–$220k base, or roughly $180k–$285k fully loaded. Contractors may be cheaper in calendar terms but risk knowledge loss in the domain model.

The engineering fixed-cost base includes Phoenix/LiveView development, Postgres schema evolution, Stripe integration, imports/exports, Google Sheets sync, admin UX, accessibility, tests, security fixes, and documentation. The most expensive product choices are not hosting choices; they are schema commitments around households, children, waivers, membership periods, roles, and activities.

#### Infrastructure and SaaS tooling

Memba should start with a boring managed stack: Phoenix app hosting, managed Postgres, object storage, transactional email provider, observability, error tracking, uptime monitoring, CI, backups, and security tooling. Estimated MVP infrastructure and tooling: $200–$800/month. At 10 clubs: $300–$1,500/month. At 50 clubs: $800–$4,000/month, depending on email volume, file storage, observability retention, and database size. These are estimates; actuals should be instrumented by club, member count, email volume, and stored files.

Likely rows in the model: app hosting, managed Postgres, backup storage, object storage for waiver evidence/files, CDN if needed, Postmark or equivalent email, Sentry/AppSignal, log drain, uptime monitoring, analytics, domain/DNS, CI minutes, staging environment, secrets management, and support/helpdesk software.

#### Legal, privacy, security, and insurance

Waivers and emergency contacts make Memba trust-sensitive even if it is not giving legal advice. Memba will store personal information, possibly minors' information, emergency contacts, waiver attestations, and payment-related metadata. Estimate an initial legal/privacy review at $5k–$20k for Canada/UK/US templates, terms, privacy policy, DPA, waiver-product posture, and data retention guidance. Annual legal reserve should not be zero; estimate $5k–$25k/year early, rising with revenue and geography.

Insurance should include Tech E&O and Cyber from the first meaningful external customers. Estimated early premium: $2k–$8k/year; with higher revenue, larger limits, or waiver-related concerns, $10k–$30k/year is plausible. D&O becomes relevant if outside capital or a formal board is added. Security costs include password/auth hardening, vulnerability management, periodic penetration tests, and eventually SOC 2 readiness if larger clubs or federations demand it. Estimate a lightweight annual pen test at $5k–$15k once the product manages several clubs' real data.

### Variable costs

#### Payments

Stripe processing fees should be passed through transparently where possible. The strategic commitment is no Memba surcharge. The cost model still needs to track payment fees because refunds, disputes, failed payments, and international cards create support and operational costs. Payment-related variable cost is mostly not margin cost if passed through, but it is still a driver of support time.

#### Email deliverability

Email is a core product function, not a commodity afterthought. Costs include transactional renewal reminders, login emails, announcements, bounce processing, suppression lists, DMARC/SPF/DKIM setup, reputation monitoring, and customer education. Estimated direct email vendor cost may be low at first: perhaps $10–$100/month for KMC-scale usage and $100–$1,000/month at 50 clubs. The larger cost is operational: diagnosing why a member did not receive an announcement, helping clubs configure sender domains, and preventing one tenant from damaging shared reputation.

A deliverability consultant before the first 10-club expansion is prudent. Estimate $2k–$8k one-time for setup review, domain strategy, warm-up guidance, and monitoring design.

#### Storage and documents

Waiver evidence, exports, private files, and audit logs create storage and retention obligations. Direct storage cost is likely small initially, but retention, retrieval, backups, and evidence integrity matter. Estimate pennies to a few dollars per club-month early; the risk is not raw S3 cost but the support and legal burden of proving what was accepted, by whom, when, and under which waiver version.

#### Support and customer success

Support is the largest variable-cost risk. Volunteer admins need reassurance, and their roles rotate. If one club pays $79/month but consumes two hours/month of founder support, the account is underwater. The model should track support minutes per club-month, tickets per 100 members, and support reason codes.

Estimated steady-state target: under 20–30 minutes per club-month after onboarding. Danger zone: more than one hour per club-month for Starter/Club tiers. Dedicated support becomes necessary around 30–50 paying clubs unless the product and docs reduce the load. A support/customer-success hire may cost $60k–$100k base, $80k–$130k fully loaded.

#### Migration and onboarding

Migration is both differentiator and cost trap. Early migrations from KMC, spreadsheets, Wild Apricot, ClubExpress, TidyHQ, Zeffy, Heylo, or custom databases will expose edge cases in households, lapsed members, duplicates, waiver status, payments, and roles. For the first 5 clubs, concierge migration should be treated as research and product development. After that, it must be priced or capped.

Estimated migration effort: simple CSV club, 2–6 hours; messy household club, 8–25 hours; incumbent migration with historical data, 20–60+ hours. At an internal loaded cost of $75–$150/hour, an unpriced complex migration can wipe out one to three years of subscription margin. Cost-control levers: import templates, migration checklists, paid migration packages, do-not-import defaults for stale history, and a clear boundary between data cleanup and software setup.

### GTM costs

Memba's early GTM should be founder-led and content-heavy: KMC case study, direct outreach, switcher pages, comparison guides, and outdoor-club networks. Estimated cash spend can be low: $100–$1,000/month for tools, hosting, design, directories, and small experiments. The real cost is founder time.

Paid acquisition is risky because ARPU is low. A $300 CAC can work for a $1,200/year club with strong retention; it does not work for a $348/year Starter club with heavy support. Channel-level CAC should be modeled separately: KMC referrals, federation outreach, SEO/comparison content, direct email, and partner webinars. Do not blend CAC until each channel has enough data.

### Trust and continuity commitments

The independence promise has costs. "Leave anytime" requires clean exports, documentation, schema stability, and support for offboarding. A public pricing pledge reduces future pricing flexibility. Continuity commitments may require source-code escrow, open-source posture, steward-ownership/B-Corp work, or a shutdown runway policy. Estimate $2k–$15k one-time legal/structural work for serious continuity commitments, plus ongoing documentation and engineering maintenance. These costs are part of the product, not marketing overhead.

### Scenario estimates

#### KMC pilot

Estimated cash operating cost: $300–$1,500/month excluding founder salary; $1k–$5k/month if part-time contractors or specialist consultants are included. One-time costs may include $5k–$20k legal/privacy review, $2k–$8k email deliverability setup, and substantial founder migration time. Gross margin is not meaningful yet; the goal is measured unit economics and support/migration baselines.

#### First 10 clubs

Estimated recurring cash cost: $1k–$5k/month excluding full-time salaries; $10k–$30k/month including founder salary and contractor/engineering capacity. One-time migration effort could total 80–250 hours if not constrained. At $700 average ARR, 10 clubs produce only $7k ARR; at $1,500 average ARR, they produce $15k ARR. This stage is still learning-heavy and will likely be cash-negative.

#### 50 clubs

At 50 clubs, estimated ARR might range from $35k to $100k depending on tier mix. Recurring infrastructure and tooling may be $1k–$4k/month. Support may require a part-time or full-time hire. Founder/engineering salary dominates the P&L. If average support is 20 minutes per club-month, support load is manageable; if it is 90 minutes, it becomes a 75-hour/month function before migrations. This is the stage where Memba must prove that onboarding is repeatable, migration is priced, and gross margin can trend toward SaaS norms.

### Gross-margin risks and reduction levers

The top margin risks are high-touch support, unpriced migrations, email deliverability incidents, waiver/legal escalation, household edge-case complexity, and scope creep into trips, courses, cabins, gear, donations, or general-purpose website building. Heylo already covers memberships, events, and paid waivers; competing by adding every adjacent feature would raise costs without preserving differentiation.

Cost-reduction levers are clear: build household and import workflows carefully; cap concierge migration; charge for complex migration; use Postmark-like managed email before optimizing for raw SES cost; design self-serve exports from day one; keep payments pass-through; maintain a narrow outdoor-club ICP; defer native mobile and full community features; invest in docs and handoff mode; instrument support time by feature; and review actuals monthly against a driver-based model.

The cost thesis is therefore: Memba can be capital-efficient only if it treats support, migration, and trust operations as first-class cost lines. Hosting will not kill the business. Volunteer complexity might.



## Revenue Streams

Memba should be a paid subscription business from the start. The revenue model must match the market's two truths: volunteer-run clubs have small budgets, and the clubs that most need Memba are not buying a generic database. They are buying fewer renewal mistakes, cleaner household records, waiver confidence, board-level predictability, and an easier handoff to the next volunteer.

The beachhead is outdoor clubs, especially 80–300 member organizations with family memberships, trip/activity programs, waivers, and a recent admin pain trigger. The long-term market is broader: volunteer-run membership organizations that need membership operations but cannot tolerate professional-association bloat. Revenue design should therefore avoid both extremes: not a free/donation-funded tool like Zeffy or HelloAsso, not a free/low-cost sports-club default like Spond Club, and not a high-setup, staff-oriented recreation platform like Amilia.

### Revenue architecture options

#### Option 1: Active-member SaaS subscription

Charge clubs a monthly or annual subscription based on active members, not total contacts. Archived members, prospects, lapsed members, and historical records do not count.

This is the strongest default architecture. It aligns price with current club scale, avoids Wild Apricot-style contact cliffs, and lets Memba promise that clubs can keep history without being punished. It is also simple enough for boards to approve and treasurers to explain.

#### Option 2: Low base subscription plus paid modules

A lower core plan could cover members, households, renewals, and payments, with waivers, announcements, activity workflows, or advanced reporting sold as add-ons.

This may improve entry conversion but risks recreating the complexity Memba is trying to escape. Worse, if waivers and activities are the features that justify switching from Zeffy, Heylo, or TidyHQ, hiding them behind add-ons weakens the value proposition. Use modules sparingly, if at all.

#### Option 3: Transaction-fee or payment take-rate model

Memba could charge a percentage on dues or event payments. This is common in adjacent tools: Heylo combines subscriptions with payment fees; Amilia charges a 1% service fee on invoices plus processing; Eventbrite-style products take event fees.

Memba should reject this as a primary model. It conflicts with the trust promise and with treasurer psychology. Clubs already resent platforms that skim member money, especially when dues are low. Payment processing should be pass-through, not a hidden revenue stream.

#### Option 4: Freemium

A free tier for small clubs could improve adoption and counter Zeffy, Heylo, Spond Club, Givebutter, Yapla, and membermojo. It could also poison the customer base with high-support, low-WTP clubs.

Memba should not launch with a broad free tier. Sub-50-member informal groups are explicitly outside the ICP; attracting them would inflate support and churn. If a free product exists, it should be a narrow wedge such as a migration assessment, roster cleanup preview, or waiver-and-Sheets pilot, not full membership operations.

#### Option 5: Setup, migration, and cleanup services

Concierge migration is likely both a revenue source and a conversion lever. Clubs fear switching because their data is messy: households, duplicates, old members, waiver history, custom fields, and spreadsheet conventions. Paid migration turns that fear into a productized service.

This should supplement recurring SaaS, not replace it. It also protects margins by charging for the highest-touch work rather than burying unlimited migration inside cheap plans.

### Recommended model

Use a transparent active-member subscription with annual billing encouraged, no Memba payment surcharge, and optional paid migration/setup.

Recommended initial package:

- Price by active members only.
- Unlimited archived/lapsed contacts.
- Standard export included on every plan.
- Stripe or other standard processor fees passed through transparently.
- No Memba surcharge on payments.
- No mandatory tip prompt to members.
- Annual billing discount or annual-only default for most clubs.
- Paid migration for larger or messy clubs.

This model supports the positioning: Memba earns money from software that reduces volunteer burden, not from skimming dues, trapping data, or exploiting member payments.

### Pricing hypotheses

These are hypotheses, not launch doctrine. They should be tested against actual paid pilots and comparison pages naming Zeffy, Heylo, TidyHQ, Wild Apricot, Amilia, Spond Club, membermojo, Clubforce, SportLoMo, and Yapla.

#### Starter: $39–$49/month, or $390–$490/year

For clubs up to roughly 100–150 active members. Includes member database, households, membership types, renewals, payment links, reminders, basic directory, CSV import/export, Google Sheets export/sync, and standard email notices.

This should not be too cheap. A $19/month plan risks attracting clubs that cannot sustain support costs and do not value the product over spreadsheets.

#### Club: $79–$99/month, or $790–$990/year

For clubs up to roughly 300–750 active members. Adds waiver versioning, member directory controls, announcements, granular roles, private content, reporting, and lightweight activity workflows.

This should be the target beachhead plan. A 200-member club charging $50/year grosses $10,000 in dues. A $900 annual software line item is meaningful but defensible if it saves renewal labor, reduces errors, and improves risk handling.

#### Pro: $149–$199/month, or $1,490–$1,990/year

For larger clubs up to roughly 1,500–2,000 active members. Adds advanced trip/activity workflows, priority support, advanced reporting, custom domain, deeper migration assistance, and possibly federation/chapter tools later.

The Pro tier should avoid becoming a custom-enterprise trap. If clubs require multi-chapter governance, SSO, facility scheduling, or complex approvals, they may be outside the current strategy.

### Why not free

Free is strategically tempting because Zeffy and Heylo create a harsh anchor. But Memba should not compete on being free.

Zeffy can be free because its donation-tip model works at fundraising scale. HelloAsso proves a similar voluntary-contribution model can operate at large scale, although it is France-only for the beachhead. That model is less natural for membership renewals, where members may resent being nudged to tip a software vendor while paying club dues. Heylo's free tier is real, but its waiver feature sits on a paid plan and its model includes payment service fees. Spond Club, Clubforce, SportLoMo, membermojo, Yapla, and TidyHQ show that clubs can find free, very cheap, or modest subscriptions when the product fits.

Memba's promise is operational depth, not zero cost: households, waivers, renewals, emergency contacts, activities, privacy, and volunteer handoff in one coherent system. Free would also weaken trust. A board can understand a transparent annual software bill; it may distrust a vendor whose revenue depends on tips, future monetization, data, ads, or payment spread.

### Annual billing

Annual billing should be the default presentation, with monthly available for pilots or early adopters. Clubs budget annually, collect dues annually, and approve line items through boards. Annual prepay improves Memba's cash flow and reduces churn caused by short-term hesitation.

A practical offer: “Pay annually, get two months free,” or simply list annual prices first. For design partners, offer a first-year founding-club discount in exchange for feedback and a reference, but avoid permanent underpricing that corrupts WTP data.

### Setup and migration revenue

Migration should be productized:

- Simple CSV or Google Sheets import: included.
- Standard migration from Wild Apricot, ClubExpress, TidyHQ, Zeffy, Heylo, or spreadsheets: $300–$750.
- Household cleanup, duplicate merging, historical records, waiver import, and custom fields: $750–$2,500.
- Large club migration or board-supported launch package: custom, but capped and scoped.

The goal is not services revenue for its own sake. The goal is to make switching feel safe while ensuring high-touch onboarding does not destroy SaaS margins. Early design partners may receive discounted migration, but the list price should be visible so the value is not hidden.

### Payment-processing stance

Memba should integrate with Stripe first and pass through processor fees. It should not add a Memba percentage fee, should not force a proprietary processor, and should not make payment revenue a hidden margin center.

This stance is expensive in the short term because it leaves money on the table. It is strategically important because treasurers are fee-sensitive and because payment independence is part of the trust covenant. If Memba later supports additional processors, that should be framed as portability and choice, not monetization.

### Trust covenant and pricing pledge implications

Revenue choices must be constrained by a public trust covenant. At minimum, Memba should pledge:

- No Memba surcharge on dues or member payments.
- No contact-count pricing cliffs.
- No charging for access to standard exports.
- No mandatory member tip prompts.
- No selling member data.
- No forced migration to a proprietary payment processor.
- Price changes announced with at least six months' notice.
- Existing customers grandfathered for a defined period, ideally 12–24 months.

This pledge reduces future monetization optionality. That is the point. It turns “independent and fair” from sentiment into a board-visible commitment. Because indie/vendor risk cuts both ways, the covenant should sit beside continuity promises: self-serve export, documented shutdown plan, and perhaps steward ownership, B-Corp, source escrow, or an open-source posture later.

### ARR scenarios

Illustrative scenarios:

| Scenario | Clubs | Avg ARR/club | Subscription ARR | Setup/migration revenue |
|---|---:|---:|---:|---:|
| Bear, year 1 | 10 | $600 | $6,000 | $5,000–$10,000 |
| Base, year 2 | 75 | $900 | $67,500 | $25,000–$50,000 |
| Strong beachhead, year 3 | 300 | $1,000 | $300,000 | $75,000–$150,000 |
| Expansion, year 5 | 1,000 | $1,200 | $1.2M | $150,000–$300,000 |

The business only works if support and migration time fall as the product matures. A $600–$1,200 ARR customer cannot absorb unlimited founder support. Therefore the revenue model and product strategy are linked: better imports, clearer handoff flows, and simpler admin UX are margin infrastructure.

### Competitive pricing risks

- **Zeffy:** Free will beat Memba for simple clubs. Memba must win where family memberships, waivers, member portals, private content, and activity operations matter.
- **Heylo:** Strong threat because $59/month Pro includes waivers and events. Memba must beat it on true households, secretary-first back office, and outdoor trip depth.
- **TidyHQ:** The sharpest paid club-native competitor. Its family support, volunteer-governance language, integrations, and $50–$79/month pricing pressure Memba's Club plan. Memba must prove waiver/activity/handoff superiority, not merely claim it.
- **Amilia:** Serious Canadian benchmark: $99/month minimum, setup from $899, 1% invoice service fee, strong households/waivers/waitlists/permissions, and facility-oriented complexity. Memba should not drift into Amilia's market.
- **Spond Club / Clubforce / SportLoMo:** Strong free/low-cost threats when the club is sports-, parent-, team-, or federation-oriented. Memba should qualify these prospects carefully rather than discounting into that market.
- **membermojo / Yapla / HelloAsso:** Regional price anchors. membermojo pressures UK tiny-club economics; Yapla pressures Canadian nonprofit pricing; HelloAsso is not a Canadian beachhead replacement but proves the voluntary-contribution model.
- **Communal:** Watchlist threat because its active-member pricing and community/member-organization framing converge on Memba’s long-term story.

### Experiments to validate willingness to pay

1. Run paid pilots with 3–5 KMC-archetype clubs. At least one should pay the target retail annual price, not only a token fee.
2. Test pricing ladders: $39/$79/$149, $49/$99/$199, and a lower TidyHQ-matching ladder. Measure board approval, not just signup intent.
3. In interviews, show explicit alternatives: Zeffy free, Heylo Pro at $59/month plus payment fees, TidyHQ around $50–$79/month, Amilia at $99/month plus setup and invoice fees, Spond Club free/low-cost, membermojo very-low-cost UK pricing, and Yapla free-membership-management positioning.
4. Test annual prepay vs monthly billing. Success is not preference; success is signed annual commitments.
5. Offer paid migration quotes during pilots. If clubs accept migration fees, switching fear is monetizable; if not, migration must be simpler or bundled.
6. Measure admin hours saved in KMC and convert that into a board-facing ROI calculator.
7. Run landing-page smoke tests with price visible and a “request board proposal” CTA.
8. Conduct conjoint or structured pricing research once enough qualified clubs are reachable, separating 80–150, 150–300, and 300–1,000 member clubs.

The kill criterion is simple: if KMC-archetype clubs will not pay at least $600–$1,000/year for the integrated product after seeing real households, renewals, waivers, and handoff, Memba should narrow the product, move upmarket, or reconsider the beachhead. It should not respond by becoming free.
