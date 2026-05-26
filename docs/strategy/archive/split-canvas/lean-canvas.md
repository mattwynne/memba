# Lean Canvas: Memba

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

#### 5. Privacy-aware member directory and private content

- Searchable member directory.
- Member-controlled visibility for email, phone, address, and profile details.
- Member-only pages and files.
- Access tied directly to active membership status.

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
- Full website builder.
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
