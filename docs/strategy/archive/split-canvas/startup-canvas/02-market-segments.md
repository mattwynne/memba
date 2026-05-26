# Market Segments

> Companion to `../lean-canvas.md` §5. This document applies the JTBD-primary, layered-cut methodology from `RESEARCH-MARKET-SEGMENTS-PROMPT.md` to Memba. Citations refer to research in `../research/extracted-text/`.

## 0. Why segmentation is unusually hard here

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

## 1. Primary axis: Job-to-Be-Done clusters

Three distinct JTBDs surfaced in the research; the lead segment cluster shares the first.

- **JTBD-1 (Admin Survival):** *"When our membership renewal cycle approaches and I'm staring at a spreadsheet of 200 households, I want a system that just handles the dues, reminders, and roster, so I can stop dreading this job and hand it off cleanly to the next volunteer."* (Evidence: GAA Registrar Analysis — "5–8 hours per week during registration season"; Sports Club Admin Report — "volunteer burnout is the single biggest threat".)
- **JTBD-2 (Safe Trips):** *"When I'm leading a backcountry trip, I want to know everyone on this list is a paid member, has a current waiver, and I have their emergency contact, so my club and I aren't exposed."* (Evidence: North Shore Hikers bylaws — "$14.00 Liability Insurance... signed at the trailhead before each trip"; multiple ClubExpress/Wild Apricot users requesting integrated waivers.)
- **JTBD-3 (Trust handoff):** *"When I take over as registrar, I want the previous person's system to make sense in one evening, so I'm not the bottleneck and I don't quit in year one."* (Evidence: Capterra ski club director — "considerable computer experience is necessary... puts the system at risk of unintended damage".)

JTBD-1 is the wedge. JTBD-2 follows quickly (Phase 2). JTBD-3 is a constraint that shapes UX, not a separate segment.

## 2. Primary beachhead: KMC-archetype clubs

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

## 3. Secondary segment: mid-sized regional clubs (300–1,000 members)

ACC sections, regional ski-touring clubs, mid-sized paddling and cycling clubs already on Wild Apricot or ClubExpress, paying $200–$500/month and complaining (Capterra ClubExpress reviews; Personal — Memba, §Mid-size regional clubs). They have higher WTP but slower board cycles, more migration risk, and may already have custom integrations. **Defer to post-beachhead** because the sales cycle would starve cash; revisit when KMC reference case exists.

## 4. Future segments

- **Large national/regional clubs (1,000–10,000 members):** Alpine Club of Canada (national), The Mountaineers, Sierra Club chapters. Require multi-chapter, federated reporting, custom domains, SSO. Out of scope for v1; reachable only via reference + sales motion that doesn't exist yet.
- **Adjacent activity clubs (non-outdoor):** model railroad clubs, astronomy clubs, sailing clubs, dog-agility clubs. Same admin JTBD; no waiver/trip-leader needs. Validates whether wedge generalizes.
- **Sports-league federations:** youth sport governing bodies. High value but Spond owns this (Personal — Memba, §Spond captured significant share).
- **Outdoor-adjacent commercial operators:** guided-trip companies, hut systems, climbing gyms. Different buyer (paid staff), different JTBD (revenue, not admin survival). Do not pursue from this codebase.

## 5. Segments to EXCLUDE explicitly

- **Sub-50-member informal clubs / Meetup groups.** No willingness to pay; Google Sheets and Meetup are sufficient. Recruiting them inflates churn and support load.
- **Youth sports leagues / grassroots team sports.** Spond Club, Clubforce, and SportLoMo create strong free/low-cost or governed-sport alternatives; the buying pattern is structurally different (parents, teams, fixtures, federation compliance). Personal — Memba, §Spond; Competitor Gap Pass.
- **National associations / professional associations with paid staff.** They are Wild Apricot's defensible heartland and require RBAC, accreditation, CE credits, etc. **This is the mission-aligned-but-dangerous segment** (cf. methodology pitfall: "media-literacy educator mirage"): structurally appealing, mission-aligned, but procurement cycles will starve the company.
- **Creator-economy / paid-content communities.** Memberful and Mighty Networks own this; the JTBD is monetization, not volunteer admin.
- **HOAs, condo boards, religious congregations.** Adjacent in pain but very different in tone, governance, and regulatory regime.

## 6. Personas (within the beachhead)

| Persona | Role in buying | Core JTBD | Decisive concern |
|---|---|---|---|
| **Membership Secretary / Registrar** | Champion + primary user | JTBD-1, JTBD-3 | "Does this end my Sunday-night renewal spreadsheet hell?" |
| **Treasurer** | Co-champion; signs the cheque | JTBD-1 (financial slice) | Reconciliation, offline payments, no surprise fees. |
| **Communications Admin / Webmaster** | Influencer; sometimes blocker | "Stop the email database from drifting" | Reliable delivery; doesn't break the existing website. |
| **Board / President** | Approver | Risk reduction, continuity | "Will the next volunteer cope? Does this protect us legally?" |
| **Trip Leader** | Day-of user (Phase 2) | JTBD-2 | "On the trailhead with cell service flaky, can I see who's covered?" |
| **Regular Member** | End user | "Renew without phoning anyone" | One-click renew; doesn't accidentally pay twice. |

Founders should optimize the demo and onboarding for the **registrar + treasurer pair** — that's where the deal is made.

## 7. Market sizing (best-available estimates)

Sources are sparse; numbers are order-of-magnitude.

- **TAM (global volunteer-run clubs with admin pain ≥ Memba threshold):** ~200,000–400,000 clubs worldwide (extrapolated from Wild Apricot's claimed ~20,000 customers, ClubRunner's ~10,000, ClubExpress' several thousand, plus the much larger long tail on spreadsheets — Personal — Memba, §competitors and tier breakdown). At median $60/mo ARPU → **$140M–$290M ARR TAM**.
- **SAM (English-speaking volunteer-run outdoor/activity clubs, 50–1,000 members):** ~15,000–30,000 clubs across CA, US, UK, IE, AU, NZ. At $50–$90/mo ARPU → **$9M–$32M ARR SAM**.
- **SOM (3-year reachable: KMC archetype, 80–300 members, English-speaking, in pain trigger window):** ~3,000–6,000 clubs realistically reachable via federation channels, SEO, and direct outreach. At 5–10% penetration in 3 years and $50–$70/mo → **$0.9M–$2.5M ARR**.

These are wide because the underlying counts are not in any single dataset. Validation experiment 1 below tightens them.

## 8. JTBD-aligned segment summary

| Segment | Lead JTBD | Pain severity (1–10) | Est. WTP/mo | Tier in roadmap |
|---|---|---|---|---|
| KMC archetype (80–300) | JTBD-1 + JTBD-3 | 8 | $30–$80 | **Beachhead** |
| Mid-size regional (300–1,000) | JTBD-1 + JTBD-2 | 7 | $80–$200 | Secondary |
| Large national/federation | Multi-chapter ops | 6 | $300+ | Future |
| Adjacent indoor hobby (50–300) | JTBD-1 only | 7 | $30–$60 | Future |
| Youth sport league | Team logistics | 8 | $0–low (Spond Club / Clubforce / SportLoMo) | **Exclude** |
| Creator community | Monetization | n/a | n/a | **Exclude** |

## 9. Assumptions, risks, and segmentation-specific validation

### Key segmentation assumptions

1. **The 80–300-member band is coherent.** Clubs at 80 and at 300 have the same JTBD intensity and tolerate similar prices. *Risk: at 80, dues × members may not clear a $30/mo line item; at 300, they may already have moved to Wild Apricot and Memba is a switching sale not a greenfield one.*
2. **Household-share ≥25% predicts switching.** *Risk: families may be a feature ask, not a switching trigger; admin survival may dominate.*
3. **Outdoor-specific framing pulls clubs we want without scaring off the indoor-hobby clubs we'd take later.** *Risk: "outdoor" branding may need to widen to "activity" before reaching SAM target.*
4. **Sport vertical is descriptive, not segmentation-relevant.** *Risk: paddling/cycling clubs have insurance regimes or federation requirements that fragment the product.*
5. **Pain-trigger events are frequent enough to drive a viable inbound funnel.** *Risk: triggers (registrar resignation, price hike) are episodic; we may need outbound to fill gaps.*

### Pre-mortem (12 months out, what could go wrong)

- We close 5 KMC-archetype clubs, all of which discover they need Phase-2 trip workflows immediately. The wedge holds but engineering is consumed before pricing validates. *Detection signal:* design-partner clubs report >50% of post-MVP feature requests are trip-related (matches SaaS Market Research Risk 3 validation experiment).
- We close 5 clubs but household-membership turns out to be a "nice to have," not a switching driver. The product becomes a Wild Apricot clone with no wedge. *Detection signal:* in onboarding, fewer than half configure households in the first 30 days.
- Mid-size clubs (300–1,000) are easier to close than KMC-archetype because they have budget and explicit pain — we drift up-market and starve on procurement cycles. *Detection signal:* sales conversations skew >40% to 300+ member clubs by month 6.

### Validation experiments (segmentation-specific)

1. **Beachhead recruitment test (week 1–4).** Cold-outreach 50 KMC-archetype clubs across BC, WA, OR, ID, CO, UT, AB, ON. Target ≥10 willingness-to-talk responses and ≥3 paid pilot conversions. *Falsification:* <3 conversions → archetype is wrong OR channel is wrong; diagnose which before iterating.
2. **Household-share probe (during the 15 admin interviews).** For each interviewee, ask: "When did your club last debate how family memberships should work?" *Falsification:* fewer than 8/15 have an active complaint → household wedge is weaker than research suggests.
3. **Pain-trigger taxonomy (during interviews).** Tag every interview with the trigger that made them respond. *Falsification:* no recurring trigger appears across 4+ interviewees → segment lacks acquisition moment.
4. **Competitive-displacement probe (during interviews).** Ask every prospect which of TidyHQ, Amilia, Heylo, Spond Club, membermojo, Clubforce, SportLoMo, Zeffy, and Yapla they considered or tried. *Falsification:* prospects cannot name a specific gap Memba would solve beyond price.
5. **Mid-size segment falsifier (week 8).** Take two warm 500-member-club leads and explicitly *defer them* in writing, citing this document. If you can't, you've already drifted; reset.
6. **Sport-vertical concentration check (week 12).** Tally first 10 pilot clubs by sport. *Falsification:* if 8+ are one sport, segmentation should narrow to that sport explicitly (lower TAM, higher density). Don't pretend horizontal coverage you don't have.
7. **Federation-channel accessibility test.** Pitch one regional federation (FMCBC, an ACC section umbrella, a state IMBA chapter) on a Memba briefing. *Falsification:* zero federation interest in 90 days → segment lacks trust intermediaries; need direct-to-club motion only.

### Pitfalls being actively guarded against

- **Conflating Wild Apricot's TAM with Memba's.** Wild Apricot lumps small associations, nonprofits, and clubs. Memba's wedge is a slice of the slice — don't quote Wild Apricot's customer count as our SAM.
- **Founder projection (KMC is the founder's home club).** Recruit interviewees from clubs the founder has *no relationship with*; explicitly disqualify KMC from validation-stage interviews.
- **Channel-as-segment confusion.** r/hiking is a channel, not a segment. The clubs we'd reach there must still match the JTBD/household/trigger profile.
- **The "media-literacy mirage" equivalent here is large national associations.** They look ideal (budget, mission, formal procurement); they will starve the company. Named, so we don't fall for it.
