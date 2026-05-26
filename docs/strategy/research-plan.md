# Memba Research Plan

This plan defines the research needed to validate Memba thoroughly before overcommitting to product scope, positioning, or architecture.

## Central research question

Is there a viable market for Memba: a simple membership, renewal, communication, and private-content platform for volunteer-run clubs, starting with outdoor/activity clubs?

## Workstream 1: Competitor Landscape

### Objective

Identify existing tools that solve part or all of the Memba problem, compare them, and find gaps.

### Competitors to research

Prioritize:

1. Wild Apricot
2. ClubExpress
3. MemberPlanet
4. Join It
5. Memberful
6. Raklet
7. Mighty Networks
8. WordPress membership plugins
9. Squarespace/Wix member areas
10. Google Groups + Sheets + Stripe/manual workflows
11. Mailchimp
12. Discourse
13. Meetup
14. Eventbrite

### Evaluation criteria

For each competitor, capture:

- Target customer
- Pricing
- Core features
- Member database support
- Renewals and recurring payments
- Family/group memberships
- Member directory
- Email broadcasts
- Member-to-member communication
- Private website/content
- Event/activity management
- Roles/permissions
- Data import/export
- Google Sheets integration
- Ease of use for volunteer admins
- Known complaints/reviews
- Strengths
- Weaknesses
- Why a club would choose it
- Why a club would churn or reject it

### Deliverable

Competitor matrix plus a summary of the top market gaps.

## Workstream 2: Outdoor Club / Activity Club Market

### Objective

Understand whether outdoor clubs are a strong beachhead market.

### Research questions

- How many hiking, mountaineering, climbing, skiing, cycling, paddling, trail-running, and outdoor recreation clubs exist in Canada, the US, UK, Australia, and New Zealand?
- What size are these clubs?
- How are they commonly managed?
- Do they charge membership dues?
- Do they run regular trips/events?
- Do they need liability waivers, participant tracking, or leader approval?
- What software do they currently use?
- Are there federations or umbrella organizations that could become channels?

### Sources to inspect

- Club websites
- Membership pages
- Renewal flows
- Public pricing
- Event/trip calendars
- Mailing list references
- Software/vendor mentions
- Complaints in forums or public docs
- Federation directories

### Deliverable

A beachhead-market report answering:

- Is “volunteer-run outdoor clubs” a coherent market?
- How large might it be?
- What are their shared pain points?
- What software patterns do they currently use?
- Are they willing and able to pay?

## Workstream 3: Customer Pain and Review Mining

### Objective

Find evidence of dissatisfaction with current solutions.

### Sources

- G2
- Capterra
- Trustpilot
- Reddit
- Hacker News
- WordPress plugin reviews
- Google Groups complaints
- Discourse/forum discussions
- Club admin forums
- Nonprofit technology forums
- Public club board minutes, if available

### Search themes

- “Wild Apricot alternative”
- “ClubExpress reviews”
- “membership software too expensive”
- “club membership software family membership”
- “membership renewal software nonprofit”
- “Google Groups email deliverability problems”
- “Mailchimp nonprofit member communication”
- “WordPress membership plugin problems”
- “membership software volunteer club”

### Extract

- Repeated complaints
- Switching triggers
- Pricing objections
- Missing features
- Admin complexity
- Email deliverability issues
- Migration pain
- Support complaints
- Praise: what competitors do well

### Deliverable

A ranked list of validated pains, with quotes and source links.

## Workstream 4: Pricing and Business Model

### Objective

Estimate what clubs already pay and what Memba could charge.

### Research questions

- What do competitors charge by member count?
- Do clubs prefer annual billing?
- Are there setup fees?
- Are payment-processing fees passed through?
- Do competitors charge transaction fees?
- What is the likely annual software budget for a 100, 500, 1,000, and 2,000-member club?
- Is website hosting included in competitor pricing?
- Are email/newsletter tools separate costs?

### Deliverable

Pricing benchmark with recommended Memba pricing hypotheses:

- Small club willingness-to-pay
- Medium club willingness-to-pay
- Large club willingness-to-pay
- Setup/migration fee viability
- Subscription vs transaction fee recommendation

## Workstream 5: Feature Gap / MVP Benchmark

### Objective

Decide which features are table stakes versus differentiators.

### Feature categories

Investigate:

- Membership records
- Renewal tracking
- Recurring payments
- Family memberships
- Member self-service
- Admin dashboard
- Member directory
- Private content
- Email announcements
- Member-to-member email/list
- Event/trip management
- Waivers/liability
- Roles/permissions
- Import/export
- Google Sheets sync
- Mobile friendliness
- Multi-club tenancy

### Deliverable

Feature matrix with each feature labelled as:

- Table stakes
- Nice-to-have
- Differentiator
- Dangerous distraction
- Post-MVP

## Workstream 6: Strategic Differentiation

### Objective

Answer: why would Memba win?

### Research questions

- Are existing products too broad or generic?
- Is there room for a niche product focused on activity/outdoor clubs?
- Is trip/activity management a meaningful wedge?
- Is reliable member communication a meaningful wedge?
- Is “replace spreadsheet + mailing list + old website” compelling?
- Would AT Protocol/social identity matter to buyers, or is it founder-led curiosity?
- What positioning would be clearest?

### Positioning hypotheses

1. Simple membership software for volunteer-run outdoor clubs.
2. Replace your club spreadsheet, mailing list, and renewal process.
3. Membership, renewals, announcements, and trips in one place.
4. A private digital home for your club.
5. The modern alternative to Wild Apricot for activity clubs.

### Deliverable

A positioning memo with 3–5 recommended angles and evidence for or against each.

## Customer discovery plan

### Interview targets

Start with 10–15 interviews:

- 3–5 KMC board/admin people
- 2–3 KMC regular members
- 2–3 trip leaders/activity organizers
- 3–5 admins from other outdoor clubs

Roles to include:

- Membership secretary
- Treasurer
- Webmaster
- Communications person
- President/board member
- Regular member

### Questions for membership secretaries

- How do you manage the member list today?
- What tools are involved?
- What breaks most often?
- How much time do renewals take?
- How do you handle family memberships?
- How do you know who is active?
- What happens when someone’s membership expires?
- What reports do you need?
- Do you trust your current data?
- What would make you switch systems?
- What would prevent you from switching?
- How much would the club realistically pay per year?

### Questions for communications/admin people

- How do announcements go out today?
- Who can send them?
- What reliability problems have you had?
- Do members complain about missing emails?
- Do you need two-way member-to-member email?
- Would a web forum work, or must it be email?
- How important are deliverability, unsubscribe, archive, moderation, and privacy?

### Questions for members

- How do you renew today?
- Do you know when your membership expires?
- Would you use a member portal?
- Would you want a member directory?
- What contact information would you share?
- Would you want your club membership visible on a social profile?
- How do you prefer receiving club communications?
- Would you use a mobile app?

### Questions for trip leaders

- How are trips organized today?
- What is painful about participant management?
- Do you need to know whether participants are active members?
- Do you want expressions of interest, waitlists, approvals?
- How do you communicate with participants?

## MVP scope validation

### Proposed MVP

Must-have candidates:

- Club tenant/account
- Admin login
- Member database
- Member import
- Member profile
- Membership status
- Renewal/expiry dates
- Membership types
- Family/group relationships
- Stripe payments
- Renewal reminders
- Member self-service portal
- Member-only page/content access
- Member directory with privacy controls
- Roles/permissions
- Export/Google Sheets sync
- Basic announcements

Defer by default:

- Trip management
- AT Protocol federation
- Mobile app
- Full discussion forum
- Complex CMS
- Multi-club social graph
- Native mailing-list replacement, unless validated as essential

### Validation method

Create a clickable prototype or thin vertical slice and review with:

- KMC membership secretary
- KMC board
- 3–5 regular members
- 2 external club admins

Measure:

- Which features get immediate “we need this” reactions
- Which features are confusing
- Which existing workflows would still require separate tools
- Whether MVP is enough to replace the old website/membership system

## Technical research

### Phoenix-first architecture

Likely default:

- Phoenix web app
- PostgreSQL
- Stripe
- Swoosh/Oban for email jobs
- Tailwind
- Multi-tenant schema strategy
- Later API for mobile apps

Research:

- Best multi-tenancy pattern
- Email deliverability infrastructure
- Google Sheets sync
- Payment/subscription modeling
- Privacy/security model

### AT Protocol fit

Questions:

- What club concepts map naturally to AT Protocol records?
- Is membership private or public?
- Can private club membership be represented safely?
- Does each club need a PDS?
- Can one app-level PDS serve multiple clubs?
- Is AT Protocol useful without Bluesky visibility?
- What does it add for MVP users?
- What does it complicate?

Recommendation: treat AT Protocol as a research spike, not a core MVP dependency.

### Mobile app path

Research:

- Phoenix backend with JSON API
- LiveView Native possibilities
- React Native / Expo client
- iOS/Android authentication
- Push notifications
- Whether mobile is needed before trips

Likely assumption: web-first responsive app is enough for MVP.

## Pilot plan

### KMC pilot success criteria

- Import real member data
- Admins can manage members without developer help
- Members can log in and renew
- Family memberships work
- Payments work
- Member-only content access works
- Directory privacy is acceptable
- Admins trust the data
- The old website/process can be partially decommissioned

### Pilot metrics

- Number of imported members
- Percentage of members who activate accounts
- Percentage who renew successfully
- Support requests per 100 members
- Admin hours saved
- Payment failure rate
- Email delivery rate
- Board satisfaction
- Member complaints

## Recommended research sequence

1. Competitor matrix
2. Review/pain mining
3. Outdoor club market scan
4. Pricing benchmark
5. MVP/positioning synthesis
