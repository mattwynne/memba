# Revenue Streams

Memba should be a paid subscription business from the start. The revenue model must match the market's two truths: volunteer-run clubs have small budgets, and the clubs that most need Memba are not buying a generic database. They are buying fewer renewal mistakes, cleaner household records, waiver confidence, board-level predictability, and an easier handoff to the next volunteer.

The beachhead is outdoor clubs, especially 80–300 member organizations with family memberships, trip/activity programs, waivers, and a recent admin pain trigger. The long-term market is broader: volunteer-run membership organizations that need membership operations but cannot tolerate professional-association bloat. Revenue design should therefore avoid both extremes: not a free/donation-funded tool like Zeffy, and not a high-setup, staff-oriented recreation platform like Amilia.

## Revenue architecture options

### Option 1: Active-member SaaS subscription

Charge clubs a monthly or annual subscription based on active members, not total contacts. Archived members, prospects, lapsed members, and historical records do not count.

This is the strongest default architecture. It aligns price with current club scale, avoids Wild Apricot-style contact cliffs, and lets Memba promise that clubs can keep history without being punished. It is also simple enough for boards to approve and treasurers to explain.

### Option 2: Low base subscription plus paid modules

A lower core plan could cover members, households, renewals, and payments, with waivers, announcements, activity workflows, or advanced reporting sold as add-ons.

This may improve entry conversion but risks recreating the complexity Memba is trying to escape. Worse, if waivers and activities are the features that justify switching from Zeffy, Heylo, or TidyHQ, hiding them behind add-ons weakens the value proposition. Use modules sparingly, if at all.

### Option 3: Transaction-fee or payment take-rate model

Memba could charge a percentage on dues or event payments. This is common in adjacent tools: Heylo combines subscriptions with payment fees; Amilia charges a 1% service fee on invoices plus processing; Eventbrite-style products take event fees.

Memba should reject this as a primary model. It conflicts with the trust promise and with treasurer psychology. Clubs already resent platforms that skim member money, especially when dues are low. Payment processing should be pass-through, not a hidden revenue stream.

### Option 4: Freemium

A free tier for small clubs could improve adoption and counter Zeffy, Heylo, Spond, and membermojo. It could also poison the customer base with high-support, low-WTP clubs.

Memba should not launch with a broad free tier. Sub-50-member informal groups are explicitly outside the ICP; attracting them would inflate support and churn. If a free product exists, it should be a narrow wedge such as a migration assessment, roster cleanup preview, or waiver-and-Sheets pilot, not full membership operations.

### Option 5: Setup, migration, and cleanup services

Concierge migration is likely both a revenue source and a conversion lever. Clubs fear switching because their data is messy: households, duplicates, old members, waiver history, custom fields, and spreadsheet conventions. Paid migration turns that fear into a productized service.

This should supplement recurring SaaS, not replace it. It also protects margins by charging for the highest-touch work rather than burying unlimited migration inside cheap plans.

## Recommended model

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

## Pricing hypotheses

These are hypotheses, not launch doctrine. They should be tested against actual paid pilots and comparison pages naming Zeffy, Heylo, TidyHQ, Wild Apricot, and Amilia.

### Starter: $39–$49/month, or $390–$490/year

For clubs up to roughly 100–150 active members. Includes member database, households, membership types, renewals, payment links, reminders, basic directory, CSV import/export, Google Sheets export/sync, and standard email notices.

This should not be too cheap. A $19/month plan risks attracting clubs that cannot sustain support costs and do not value the product over spreadsheets.

### Club: $79–$99/month, or $790–$990/year

For clubs up to roughly 300–750 active members. Adds waiver versioning, member directory controls, announcements, granular roles, private content, reporting, and lightweight activity workflows.

This should be the target beachhead plan. A 200-member club charging $50/year grosses $10,000 in dues. A $900 annual software line item is meaningful but defensible if it saves renewal labor, reduces errors, and improves risk handling.

### Pro: $149–$199/month, or $1,490–$1,990/year

For larger clubs up to roughly 1,500–2,000 active members. Adds advanced trip/activity workflows, priority support, advanced reporting, custom domain, deeper migration assistance, and possibly federation/chapter tools later.

The Pro tier should avoid becoming a custom-enterprise trap. If clubs require multi-chapter governance, SSO, facility scheduling, or complex approvals, they may be outside the current strategy.

## Why not free

Free is strategically tempting because Zeffy and Heylo create a harsh anchor. But Memba should not compete on being free.

Zeffy can be free because its donation-tip model works at fundraising scale. That model is less natural for membership renewals, where members may resent being nudged to tip a software vendor while paying club dues. Heylo's free tier is real, but its waiver feature sits on a paid plan and its model includes payment service fees. TidyHQ and membermojo show that clubs will pay modest subscriptions when the product fits.

Memba's promise is operational depth, not zero cost: households, waivers, renewals, emergency contacts, activities, privacy, and volunteer handoff in one coherent system. Free would also weaken trust. A board can understand a transparent annual software bill; it may distrust a vendor whose revenue depends on tips, future monetization, data, ads, or payment spread.

## Annual billing

Annual billing should be the default presentation, with monthly available for pilots or early adopters. Clubs budget annually, collect dues annually, and approve line items through boards. Annual prepay improves Memba's cash flow and reduces churn caused by short-term hesitation.

A practical offer: “Pay annually, get two months free,” or simply list annual prices first. For design partners, offer a first-year founding-club discount in exchange for feedback and a reference, but avoid permanent underpricing that corrupts WTP data.

## Setup and migration revenue

Migration should be productized:

- Simple CSV or Google Sheets import: included.
- Standard migration from Wild Apricot, ClubExpress, TidyHQ, Zeffy, Heylo, or spreadsheets: $300–$750.
- Household cleanup, duplicate merging, historical records, waiver import, and custom fields: $750–$2,500.
- Large club migration or board-supported launch package: custom, but capped and scoped.

The goal is not services revenue for its own sake. The goal is to make switching feel safe while ensuring high-touch onboarding does not destroy SaaS margins. Early design partners may receive discounted migration, but the list price should be visible so the value is not hidden.

## Payment-processing stance

Memba should integrate with Stripe first and pass through processor fees. It should not add a Memba percentage fee, should not force a proprietary processor, and should not make payment revenue a hidden margin center.

This stance is expensive in the short term because it leaves money on the table. It is strategically important because treasurers are fee-sensitive and because payment independence is part of the trust covenant. If Memba later supports additional processors, that should be framed as portability and choice, not monetization.

## Trust covenant and pricing pledge implications

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

## ARR scenarios

Illustrative scenarios:

| Scenario | Clubs | Avg ARR/club | Subscription ARR | Setup/migration revenue |
|---|---:|---:|---:|---:|
| Bear, year 1 | 10 | $600 | $6,000 | $5,000–$10,000 |
| Base, year 2 | 75 | $900 | $67,500 | $25,000–$50,000 |
| Strong beachhead, year 3 | 300 | $1,000 | $300,000 | $75,000–$150,000 |
| Expansion, year 5 | 1,000 | $1,200 | $1.2M | $150,000–$300,000 |

The business only works if support and migration time fall as the product matures. A $600–$1,200 ARR customer cannot absorb unlimited founder support. Therefore the revenue model and product strategy are linked: better imports, clearer handoff flows, and simpler admin UX are margin infrastructure.

## Competitive pricing risks

- **Zeffy:** Free will beat Memba for simple clubs. Memba must win where family memberships, waivers, member portals, private content, and activity operations matter.
- **Heylo:** Strong threat because $59/month Pro includes waivers and events. Memba must beat it on true households, secretary-first back office, and outdoor trip depth.
- **TidyHQ:** The sharpest paid competitor. Its family support and $50–$79/month pricing pressure Memba's Club plan. Memba must prove waiver/activity/handoff superiority, not merely claim it.
- **Amilia:** Not a beachhead price threat, but useful as contrast: $99/month minimum, setup from $899, 1% invoice service fee, and facility-oriented complexity. Memba should not drift into Amilia's market.
- **membermojo/TidyHQ low-price anchors:** In UK/Commonwealth contexts, Memba cannot win on price. It must win on outdoor-specific workflows and trust.

## Experiments to validate willingness to pay

1. Run paid pilots with 3–5 KMC-archetype clubs. At least one should pay the target retail annual price, not only a token fee.
2. Test pricing ladders: $39/$79/$149, $49/$99/$199, and a lower TidyHQ-matching ladder. Measure board approval, not just signup intent.
3. In interviews, show explicit alternatives: Zeffy free, Heylo Pro at $59/month plus payment fees, TidyHQ around $50–$79/month, Amilia at $99/month plus setup and invoice fees.
4. Test annual prepay vs monthly billing. Success is not preference; success is signed annual commitments.
5. Offer paid migration quotes during pilots. If clubs accept migration fees, switching fear is monetizable; if not, migration must be simpler or bundled.
6. Measure admin hours saved in KMC and convert that into a board-facing ROI calculator.
7. Run landing-page smoke tests with price visible and a “request board proposal” CTA.
8. Conduct conjoint or structured pricing research once enough qualified clubs are reachable, separating 80–150, 150–300, and 300–1,000 member clubs.

The kill criterion is simple: if KMC-archetype clubs will not pay at least $600–$1,000/year for the integrated product after seeing real households, renewals, waivers, and handoff, Memba should narrow the product, move upmarket, or reconsider the beachhead. It should not respond by becoming free.