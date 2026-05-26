# Value Proposition

This section of the Startup Canvas applies the Value Proposition research methodology to Memba — a SaaS membership platform for volunteer-run outdoor and activity clubs, starting with Kootenay Mountaineering Club (KMC). It synthesizes the Lean Canvas's Problem (§1), UVP (§3), and Unfair Advantage (§4) with the two deep-research briefs in `docs/strategy/research/extracted-text/`.

## 1. Segment-anchored framing

The Value Proposition is written for the **primary VP segment**: a volunteer-run outdoor/activity club of roughly 30–300 members (hiking, mountaineering, ski touring, cycling, paddling) whose buyer/influencer is a **rotating Membership Secretary or Treasurer**, with the **board** as the budget approver. Buyer ≠ user: the regular member is a separate user whose VP is "join, renew, see the directory, sign up for the trip" with zero friction. (See Lean Canvas §5 personas.)

Critical contextual segments — not VP targets, but who shape viability:

- **The silent majority** of clubs running on Google Sheets + Mailchimp + Google Groups + Meetup. Many say they have the problem but never switch; do not treat them as TAM.
- **The board / credibility-audience.** A volunteer treasurer's reputational risk on choosing software is real; a single failed renewal cycle can torch trust. The Capterra ClubExpress review describing the platform causing an ex-employee "to cry" is the brand-destruction case study.

## 2. What Before — current customer problems and unmet needs

Evidence-grounded "before" state, per the Lean Canvas problems and the two research briefs:

### Pain 1: Fragmented admin stack and volunteer overload
Clubs juggle spreadsheets, PayPal/Stripe buttons, Mailchimp, Google Groups, Meetup, Eventbrite, and a WordPress site. Potomac Mountain Club explicitly documents using "a google email group … and Mailchimp"; Wintergreen Sporting Club uses Mailchimp + Google Sheets + volunteer role assignments. Volunteer admins absorb the cost of stitching these together — and the cost is largest at handoff, when a new secretary inherits an opaque system. ("run exclusively by volunteers" — Hoosier Hikers Council.)

### Pain 2: Household/family memberships are universally broken
The single most-cited unmet need across the research. Wild Apricot's Wishlist thread on family/child memberships has been open since 2018: "Bundle memberships don't really relate to Family memberships. I see this as the biggest hole in your software." A sports club admin reports "I end up having to create a unique account for those families." Memberful, Mighty Networks, and most creator-tier products don't model households at all. The real shape — one bill, multiple individuals, shared address, individual logins, per-person waiver/visibility, children aging into adult memberships — is modeled by no incumbent cleanly.

### Pain 3: Renewals and payments are manual, error-prone, and easy to get wrong
"it does not allow group invoicing… I have to go into each account and manually create" (Wild Apricot, Capterra). ClubExpress users report renewals are "difficult to correct if mistakes are made." Failed-payment follow-up, grace periods, lapsed-member reactivation, calendar vs. anniversary cycles, and the basic "who has actually paid?" question consume disproportionate volunteer time.

### Pain 4: Pricing is opaque and feels punitive
Wild Apricot's contact-cliff pricing ("pricing structure is horrible jumping from a limit of 500 to 2000"), the 20% Payment System Servicing Fee on non-Personify processors (unavoidable outside the US), Meetup's ~2× organizer price hike since June 2024, Eventbrite's 3.7% + $1.79 per ticket + 2.9% processing. A 100-member club at $25/year dues grosses $2,500 — Wild Apricot's annual 100-contact plan consumes ~29% of that before payment fees. Resentment is documented; patience for surprise costs is not.

### Pain 5: Support and product decay since PE consolidation
Wild Apricot Trustpilot: 1.7/5 across 153 reviews. "Since purchased by Personify, the support is HORRIBLE." "When Personify acquired WA in 2017 that turned around. Development ground to a halt." MemberClicks, YourMembership, Wild Apricot all sit under Momentive Software (TA Associates, Jan 2026). The credibility-audience (boards) is now actively suspicious of acquisition-driven platforms.

### Pain 6: Outdoor-club-specific workflows aren't modeled
Trip leader/co-leader roles, qualification checks, participant caps, waitlists, expressions of interest, waivers, emergency contacts, member-only visibility, carpool coordination. The Mountaineers (15,000 members) built a custom Plone + Salesforce stack because nothing fit. Sierra Club Angeles Chapter runs ~2,000 trips/year on an internal Campfire system + PDF waivers + Meetup. The most sophisticated clubs build custom because off-the-shelf fails them.

### Negative-space pain (what clubs avoid doing because they don't trust their tools)
Clubs avoid sending bulk reminders because they can't undo mistakes. Avoid offering true family memberships because the workaround is too messy. Avoid switching tools because migration is terrifying. Avoid bringing in a new volunteer because the handoff is too costly. These are the largest pools of latent demand.

## 3. Value Proposition Canvas mapping

### Customer Jobs (functional / emotional / social)

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

### Pains → Pain Relievers

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

### Gains → Gain Creators

| Gain | Memba gain creator |
|---|---|
| Volunteer time back (hours/month) | Automation of reminders, renewals, household billing |
| Confidence that no one is missed | Single dashboard of expiring/lapsed/active members |
| Confidence at trip head | Trip leader sees active membership + waiver + emergency contact in one view |
| Predictable budget for the board | Flat tier pricing by active members, no surprise surcharges |
| Pride in modernizing the club without burnout | Migration concierge + onboarding designed for non-technical volunteers |

## 4. What After — induced state we are claiming

After 90 days on Memba, a volunteer-run outdoor club should be able to say:

- "Our renewals run themselves. I spend an hour a month, not an evening a week."
- "Families pay once. Each person has their own profile and waiver."
- "We finally know who has paid."
- "When I hand this to the next secretary, I'll hand them a login, not a binder."
- "Our trip leaders see who's coming, who's a member, and who's signed the waiver — on their phone."

These are the behavioral deltas Memba's research plan must validate (concierge MVP and design-partner program — see Lean Canvas validation experiments).

## 5. Alternatives — competitive positioning (Value Curve)

Per-segment value-curve axes drawn from coded complaint corpora and switch-interview material in the research briefs. Score 0–5 (higher = stronger). Scores are directional; the cells without a numeric anchor in the research are conservatively rated.

| Axis | Memba | Wild Apricot | ClubExpress | Memberful | Mighty Networks | Sheets+Stripe+Mailchimp | WordPress (MemberPress/PMPro) |
|---|---|---|---|---|---|---|---|
| Household / family model | **5** | 2 | 3 | 0 | 0 | 1 | 2 |
| Renewal automation correctness | 4 | 4 | 3 | 4 | 3 | 1 | 3 |
| Volunteer-admin simplicity / handoff | **5** | 2 | 1 | 3 | 3 | 3 | 1 |
| Outdoor-trip workflow (Phase 2) | **4** | 2 | 2 | 0 | 1 | 1 | 1 |
| Pricing fairness (no cliffs/surcharges) | **5** | 1 | 2 | 2 | 2 | 5 | 4 |
| Data portability / "leave anytime" | **5** | 2 | 3 | 3 | 2 | 5 | 4 |
| Sheets/CSV bridge | **5** | 2 | 2 | 1 | 1 | 5 | 1 |
| Private member directory + content | 4 | 4 | 4 | 3 | 4 | 1 | 3 |
| Independent operator durability | **5** | 1 | 3 | 2 | 3 | n/a | n/a |
| Mobile-first member experience | 4 | 2 | 1 | 3 | 4 | 3 | 2 |
| Time-to-onboard a volunteer | **5** | 2 | 1 | 3 | 3 | 4 | 1 |
| Modern community / social features | 1 | 2 | 2 | 2 | **5** | 1 | 2 |

### ERRC commitments

- **Eliminate**: contact-count cliff pricing; payment-processor surcharges layered on Stripe; site-builder competition with WordPress; AI-powered "community" marketing.
- **Reduce**: feature breadth (no LMS, no full forum, no donation suite, no public event discovery, no native mobile app at launch); admin training overhead.
- **Raise**: household correctness; volunteer-handoff design; pricing transparency; data portability; migration concierge quality.
- **Create**: a single domain model that unifies households + memberships + waivers + trips + leader permissions + privacy — built specifically for outdoor clubs. Google Sheets sync as a first-class promise. An explicit "we will not sell to PE" operator commitment.

## 6. Primary UVP (refined) and alternative framings to test

### Primary UVP

> **Memba is the membership platform built for volunteer-run outdoor clubs — real family memberships, one-click renewals, and the trips you actually run, without the bloat of an association suite or the hacks of a DIY stack.**

### Alternative framings (A/B test candidates)

1. **Household-led**: "Real family memberships. Two adults, three kids, one renewal, one bill — and individual profiles for each person."
2. **Switch-from-WA**: "The Wild Apricot alternative for outdoor clubs. No contact cliffs. No 20% surcharge. Same renewals; better households."
3. **Volunteer-led**: "Membership software your treasurer can hand to the next treasurer in one evening."
4. **Trips-led**: "Dues, households, and the trips you actually run — in one place."
5. **Sheets-bridge-led**: "All your club data in one place — and we still sync to your Google Sheet."
6. **Independence-led**: "Founder-run. Migration-friendly. Won't sell to private equity. Built for clubs, not portfolios."

## 7. What Memba is NOT

- Not a generic association management platform (Wild Apricot/ClubExpress).
- Not a creator/community/monetization platform (Memberful, Mighty Networks).
- Not a WordPress site builder or plugin replacement.
- Not a public event-discovery marketplace (Meetup, Eventbrite).
- Not a discussion forum / social network (Discourse, Mighty).
- Not an LMS, donation CRM, gear-reservation, cabin-booking, or permit system.
- Not (yet) a federated / AT Protocol social club identity layer.
- Not "all things to all clubs" — initial wedge is outdoor/activity clubs only.

## 8. Messaging hierarchy

### Primary message (above the fold)
"Memba is the membership platform built for volunteer-run outdoor clubs."

### Supporting proof points (ranked by research-evidence strength)
1. **Real family memberships** — addresses the most-documented competitor failure (Wild Apricot Wishlist open since 2018).
2. **Predictable pricing, no surcharges** — directly contrasts WA's PSSF and contact cliffs, which generated the loudest grievances.
3. **Built for the next volunteer** — handoff as a feature, addressing the documented ClubExpress and WA admin-complexity pain.
4. **Renewals that don't break** — admin "fix a renewal" workflow as a category-leading promise.
5. **Trips, not just events** (Phase 2 onward) — leader, cap, waitlist, waiver, member-only.
6. **Works with your spreadsheet** — Google Sheets sync as a trust bridge.
7. **Independent, founder-led, migration-friendly** — addresses the PE-consolidation anxiety surfaced repeatedly in reviews.

## 9. Messaging hypotheses to A/B test

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
