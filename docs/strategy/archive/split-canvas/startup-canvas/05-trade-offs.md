# Trade-offs

> *"The essence of strategy is choosing what not to do."* — Michael Porter

This document names the deliberate strategic choices Memba is making. Each trade-off is framed as a **commitment** (verb-and-object refusal), tagged with what is **gained**, what is **given up**, why **incumbents cannot easily mirror it without breaking their own strategy**, a **reversibility tier** (A: irreversible / B: high cost / C: moderate / D: tactical), and a **trigger** that would force re-litigation.

This is a Porter-style activity-system trade-off list, not a feature list. The point is to surface the choices that make Memba *coherent* — and to name what we will **not** do.

---

## 1. Spinal trade-off

### S1. Volunteer-run outdoor/activity clubs only — not horizontal AMS

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

## 2. Structural trade-offs (derived from S1)

### S2. First-class household/family as a core data model — not as a "bundle" feature

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

### S3. Active-member pricing with no Memba payment surcharge — not maximum revenue per club

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

### S4. Volunteer-admin ergonomics over feature-completeness for professional staff

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

### S5. Web-first responsive — no native mobile app at launch

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

### S6. Founder-led human support — not scalable self-serve at launch

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

### S7. Phoenix monolith — not a WordPress-style plugin ecosystem

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

## 3. Tactical deferrals (the explicit "not now" list)

| Deferred | Why now | Reversibility | Re-evaluation trigger |
|---|---|---|---|
| AT Protocol / federation | Zero buyer evidence (Lean Canvas Assumption 5). Strategic curiosity, not advantage. | D | Federation becomes a buyer-stated requirement, or a federated competitor emerges in outdoor-club space |
| LMS / courses | Crowded; off the membership-ops wedge | D | Three+ pilot clubs cite course management as a top-3 pain |
| Public discovery / marketplace | Competing with Meetup is suicide; not the wedge | C | Member acquisition becomes a stated club pain over admin pain |
| Branded mobile apps | See S5 | C | See S5 |
| Donation management / fundraising | Adjacent to membership but a distinct product (Givebutter, etc.) | D | Pilot clubs report >20% revenue from donations and ask for integration |
| Cabin / gear / fleet booking | Higher-ARPU sub-market (Rideau, Washington Canoe, UBC Sailing) but very different product | C | A specific large-club pilot makes it the wedge for that tier |
| Full website builder | Wild Apricot/ClubExpress play this; we don't | B | Never — this is structural |
| Forum / discussion product | Discourse exists; off-wedge | D | Member-to-member comms emerges as a top-3 retention driver |
| Advanced email marketing | Mailchimp exists; we ship announcements, not campaigns | D | Email becomes the #1 cited pain in retention interviews |

---

## 4. Open trade-off decisions (need a call)

These are axes where the strategy is **not yet committed** and a deliberate choice is required:

1. **Trip management timing.** The Lean Canvas notes trips should be "soon after launch" — but exactly when? Shipping at MVP slows time-to-pilot; deferring risks "incomplete" perception (research ref 47). **Open: lock a calendar trigger.**

2. **Canadian vs US-first launch.** KMC is BC-based; FMCBC has 54 clubs / 5,000+ members. Canadian payment surcharge sensitivity is high (research). US TAM is bigger but more crowded. **Open: which country gets the SEO and migration-guide investment first?**

3. **Self-serve signup vs sales-assisted only.** S6 (founder-led support) is committed for the first ~50 clubs, but does the website allow self-signup at all, or is every customer a hand-held migration? **Open.**

4. **Pricing-floor: do we serve <30-member clubs?** Lean Canvas ICP is 30–300. Sub-30 clubs are price-sensitive and high-touch; they may damage unit economics. A "free tier for <30 members" could be a wedge — or a tar pit. **Open.**

5. **KMC equity / pilot terms.** Is KMC a paying customer, a design-partner with reduced fees, or an equity-style stakeholder? This determines how reference-able the case study is. **Open.**

6. **Open-source posture.** Phoenix monolith could be open-sourced (à la Discourse, Mastodon) which would help trust for volunteer-run clubs but complicates pricing. **Open — currently undecided.**

7. **Data residency.** GDPR (research ref 16 in SaaS Market Research) and Canadian PIPEDA exposure suggests Canadian/EU hosting may become a buying criterion. **Open: where do we host?**

---

## 5. The sharpest commitments, restated

If a future Memba employee, advisor, or investor reads only one paragraph, it should be this:

> Memba is the membership platform for volunteer-run outdoor and activity clubs. We model households as first-class. We price by active members and charge no payment surcharge. We optimise for the volunteer who inherits the job, not the paid administrator. We ship web-first, founder-supported, as a Phoenix monolith. We are not a horizontal AMS, a creator platform, a community network, a course platform, a website builder, or a public events marketplace — and we will turn down customers and features that would pull us toward any of those.

Each "not" in that paragraph is a refusal Wild Apricot, ClubExpress, Memberful, and Mighty Networks structurally cannot match without breaking their own strategy. That asymmetry — not feature parity — is the source of Memba's defensibility.
