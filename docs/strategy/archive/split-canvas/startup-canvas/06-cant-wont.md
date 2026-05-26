# Can't / Won't

This section names the explicit boundaries of Memba's strategy: what we deliberately refuse to do, and what we are structurally unable to do today. Following the deep-research methodology, every "won't" is paired with an *until-when* condition, and every "can't" is paired with the conditions under which it might shift. The goal is to make trade-offs crisp so the integrated strategy is harder to copy and easier to execute.

## Won't (deliberate trade-offs)

These are choices, not limits. Each protects the integrated strategy described in the lean canvas: a narrow, opinionated product for volunteer-run outdoor/activity clubs.

### 1. Won't be a generic Association Management System (AMS)

- **Boundary:** Memba will not pursue feature breadth comparable to Wild Apricot, ClubExpress, or MemberPlanet (donation pipelines, committee management, accounting integrations, CME tracking, certifications-at-scale, complex membership-tier matrices, fundraising campaigns, sponsor management).
- **Reason:** Breadth is what makes those products unloved by volunteer admins (lean canvas §1, §3 "Avoid positioning as"). Our wedge is the *opposite* posture: opinionated, narrow, learnable in an evening.
- **Risk of violating:** We dilute the volunteer-handoff value proposition, end up competing on professional-AMS terms, and lose the structural reason large incumbents "won't" copy us.
- **Revisit when:** We have 500+ paying clubs and a clear, validated request pattern for a specific adjacency from existing customers — not from prospect wish-lists.

### 2. Won't be a creator / community / social platform

- **Boundary:** No creator monetization (Memberful, Patreon, Substack), no community feeds (Mighty Networks, Circle, Discord), no AI-powered community features.
- **Reason:** Outdoor clubs are *not* communities-of-content-consumers; they are operational organizations with rosters, dues, waivers, and trips. Positioning here erodes trust with our buyer (the membership secretary) and pulls scope toward feeds, posts, and engagement metrics.
- **Risk:** Feature drift toward engagement KPIs that volunteer admins don't care about; brand confusion; competing against well-funded category leaders on their turf.
- **Revisit when:** Never as the core; possibly as a thin integration if Discourse/Slack/forum bridges become a top-3 churn driver.

### 3. Won't be a WordPress / website builder replacement

- **Boundary:** No full CMS, page builder, theme marketplace, or general-purpose website tooling. Member-only pages and a simple directory yes; arbitrary marketing-site authoring no.
- **Reason:** CMS is a bottomless scope sink (lean canvas §8 "Cost drivers"). Most clubs already have a public website; what they lack is the *private* operational layer behind it.
- **Risk:** Becomes a maintenance and support tarpit; volunteer admins inherit a CMS they didn't ask for.
- **Revisit when:** A clear "club homepage in a box" SKU is demanded by ≥30% of paying clubs and we can ship it without compromising the admin surface.

### 4. Won't run a public Meetup-style discovery network

- **Boundary:** No public trip directory, no cross-club social graph, no "find a club near you" marketplace.
- **Reason:** Our buyers want a *private* digital home (lean canvas §3). Public discovery introduces moderation, safety, and brand-risk costs we are too small to absorb, and competes with Meetup's distribution.
- **Risk:** Diverts engineering into two-sided-marketplace dynamics; exposes private club data to discovery pressure; alienates privacy-sensitive boards.
- **Revisit when:** A federation or umbrella body commissions it and funds it, and our top-tier clubs vote to opt-in.

### 5. Won't add a Memba transaction surcharge

- **Boundary:** Stripe (and later GoCardless/PayPal) fees pass through at cost. No Memba percentage skim on dues, donations, or trip fees.
- **Reason:** Surcharges are the single most-cited frustration with incumbents (lean canvas §1, §7). Pricing on *active members* is the load-bearing trust signal.
- **Risk of violating:** We poison the "fair pricing" differentiator that Unfair Advantage §3 depends on, and hand Wild Apricot's critics back to Wild Apricot.
- **Revisit when:** Only for an explicitly optional service (e.g., concierge migration, hardware, SMS) — never on core dues flow.

### 6. Won't lock data in

- **Boundary:** Clean CSV export, Google Sheets sync, documented schema, and a "leave anytime" covenant. No proprietary export formats, no data-egress fees, no contract clauses that retain member data on exit.
- **Reason:** Volunteer boards rotate; trust requires reversibility (lean canvas §4.3). Data portability is a structural commitment a vertically-integrated incumbent would have to cannibalize lock-in to match.
- **Risk:** None to us — high to violators. Violating this collapses the brand.
- **Revisit:** Never.

### 7. Won't build an LMS / courses / certification engine

- **Boundary:** No course authoring, quizzes, certification issuance, or CE-credit tracking. We can *record* that a member holds an external certification; we will not become the certification system.
- **Reason:** LMS is a separate category with mature competitors (Thinkific, Teachable, LearnDash). Outdoor-club skill workflows can be modelled as flags/attributes without a learning platform.
- **Revisit when:** A federation requires it as a procurement gate AND we have the resources to ship it as a separate product line.

### 8. Won't ship native branded mobile apps for MVP

- **Boundary:** Responsive web only at launch. No iOS/Android app, no white-labelled native client per club.
- **Reason:** Native shipping multiplies build cost ~3× and ongoing maintenance ~5× (Apple/Google review, push infra, per-tenant signing). Volunteer admins use desktop; members tolerate web for once-yearly renewal.
- **Risk of violating:** Burns runway on the wrong surface before product-market fit.
- **Revisit when:** Trip-day workflows (check-in, emergency contacts, offline waivers) are validated as the top retention driver AND we have the ARR to fund native properly.

### 9. Won't chase enterprise federations / umbrella bodies as ICP

- **Boundary:** Federations (Alpine Club of Canada, BMC, national paddling associations) are *channels*, not initial customers. We will not configure the product around their procurement, SSO, branded-portal, or multi-chapter governance requirements first.
- **Reason:** Federation sales cycles are 9–18 months and product demands distort the volunteer-club UX (lean canvas §5 "Future segment").
- **Revisit when:** We have 200+ independent club customers and a federation deal can be served by configuration, not bespoke build.

### 10. Won't make AT Protocol a dependency

- **Boundary:** AT Protocol stays a research spike. The MVP domain model does not require it; the data model does not assume PDS hosting; the product does not market federation.
- **Reason:** Research found no buyer evidence for federation/social-identity demand (lean canvas Assumption 5). Coupling a small-club ops tool to a young protocol multiplies risk on both sides.
- **Risk of violating:** Architectural rework, founder distraction, positioning confusion ("is this a Bluesky thing?").
- **Revisit when:** A paying customer explicitly requires it, or a federation channel partner funds the integration.

## Can't (structural limits today)

These are honest acknowledgements of constraints. They shape what we won't promise and where we won't compete.

### 1. Can't out-feature Wild Apricot on professional-AMS breadth

- **Constraint:** Wild Apricot has 20+ years of feature accretion, a Personify acquisition behind it, and thousands of edge cases baked in (chapters, accounting exports, complex committees).
- **Reason:** We are a small team with no shot at parity, and parity is the wrong goal anyway.
- **Risk if pretended otherwise:** RFP losses, support cost explosions, brand confusion.
- **Revisit when:** Never — this is a permanent strategic concession that *enables* the wedge.

### 2. Can't outspend incumbents on paid acquisition

- **Constraint:** Wild Apricot/Personify, ClubExpress, and Mighty Networks have orders-of-magnitude more marketing budget. We cannot win on Google Ads, retargeting, or trade-show presence.
- **Implication:** Growth must come from KMC reference, SEO comparison content, federation channels, and direct outreach (lean canvas §6).
- **Revisit when:** ARR and unit economics support paid channels with payback under 12 months — likely post-Series A, if ever.

### 3. Can't offer in-person training or onboarding at scale

- **Constraint:** No field sales, no on-site implementation team. One founder cannot fly to every club.
- **Implication:** Onboarding must be self-serve or remote-concierge; documentation, importers, and templates carry the load.
- **Revisit when:** Concierge migration becomes a revenue line that funds dedicated implementation staff.

### 4. Can't serve clubs needing SOC2 / HIPAA / heavy compliance day one

- **Constraint:** No audit reports, no BAA, no SSO/SAML, no data-residency guarantees beyond hosting region defaults.
- **Implication:** University-affiliated clubs, healthcare-adjacent groups, and government-contracted federations are out of scope at launch.
- **Revisit when:** A clearly-priced enterprise tier justifies the ~$50–150K/year compliance overhead.

### 5. Can't deliver native mobile at launch

- See "Won't #8" — this is also a *can't* given current team size. Building native correctly requires capacity we do not have.

### 6. Can't guarantee email deliverability at the level of dedicated ESPs

- **Constraint:** Email deliverability is a deep specialty (lean canvas §8). We will use a reputable provider (e.g., Postmark/SendGrid) but cannot promise inbox placement parity with Mailchimp or a dedicated marketing-ops setup.
- **Implication:** Position announcements as *transactional and operational*, not as marketing newsletters.
- **Revisit when:** Deliverability becomes a top-3 churn driver and warrants a dedicated investment.

### 7. Can't model every outdoor-club edge case at launch

- **Constraint:** Cabin booking, gear libraries, permits, trail-status, fleet management, multi-day expeditions with shuttle logistics — these exist in real clubs but each is a product unto itself.
- **Implication:** MVP and Phase 2 cover the 80% (members, households, renewals, trips, waivers). The long tail waits.
- **Revisit when:** A specific edge case is requested by ≥20% of paying clubs.

## Revisit triggers

The boundaries above are not permanent dogma. The following signals would warrant reopening one or more items:

- **Concentrated customer demand:** ≥20–30% of paying clubs request the same deferred capability, with willingness to pay, and the request originates from existing customers (not prospects shopping a feature list).
- **Channel-funded build:** A federation, insurer, or umbrella body commissions a capability and funds the build (relevant to AT Protocol, LMS, multi-chapter, compliance).
- **Validated retention driver:** Post-launch data shows a deferred capability (e.g., native mobile for trip-day, deliverability investment) is the top-3 churn or activation blocker.
- **Competitive shift:** An incumbent acquisition, price hike, or product retreat opens a positioning lane we deliberately ceded (e.g., creator-platform-style features become non-negotiable for our ICP).
- **Capacity step-change:** ARR or fundraising materially changes our ability to absorb compliance, enterprise sales, or native-mobile overhead.
- **Disconfirmation of an assumption:** Specifically, Assumption 5 (AT Protocol not needed) flips only if a paying customer or channel partner requires it, not because the founder finds it interesting.

Any flip must be a deliberate strategy revision — documented, dated, and reviewed against the integrated-strategy reinforcement matrix — not a creeping concession made in a sales call.
