# Key Metrics

Metrics are unusually dangerous for Memba because the product serves low-budget, volunteer-run organizations where the buyer, admin user, activity leader, board, and regular member all experience value differently. The product can look healthy in analytics while failing the mission: an admin logs in often because the workflow is confusing; a club renews because migration is painful; members pay successfully but households, waivers, or privacy are wrong; a board is satisfied while the next volunteer still cannot inherit the system.

The metrics system must therefore measure not only growth and usage, but administrative confidence, handoff quality, data correctness, and operational risk. No single metric should become an OKR target alone. Every growth metric needs a quality or trust counter-metric, and for the first stage quality should dominate growth when they conflict.

## Measurement dangers for volunteer-club SaaS

1. **Admin engagement can be inverse value.** A membership secretary logging in every night during renewal season may mean Memba is saving the club, or it may mean Memba has recreated spreadsheet hell in a browser. Admin activity must be paired with task completion time, error rate, and self-reported confidence.
2. **Buyer satisfaction can hide user failure.** The board may like pricing and reporting while regular members struggle to renew or trip leaders cannot access emergency contacts. Measure each persona separately.
3. **Retention can reflect lock-in, not love.** A club may stay because switching is scary. Renewal must be paired with export usage, NPS-style removal impact, and evidence that a second volunteer can run the system.
4. **Payment success can hide household failure.** A family may pay once while individual profiles, waivers, children, directory settings, and membership status are wrong.
5. **Low support volume can mean silence, not success.** Volunteer admins may avoid asking for help or route around Memba in Sheets. Pair tickets with workaround counts and onboarding check-ins.
6. **Activity metrics can incentivize unsafe growth.** More trips in Memba is good only if waiver, membership, capacity, leader, and emergency-contact data are correct.
7. **Competitive comparison can Goodhart scope.** Chasing Heylo’s event/social metrics or Zeffy’s payment volume would pull Memba away from secretary-first club operations.

The 18-month silent-drift failure mode is clear: Memba becomes a decent renewal/payment tool with many dashboards, but clubs still rely on side spreadsheets for households, waivers, trip lists, and handoff. The analytics say “active clubs”; the next volunteer still says, “I can’t run this.”

## North Star metric

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

## OMTM: pilot and next quarter

For the KMC pilot and next quarter, the One Metric That Matters should be quality-anchored:

**OMTM: Percentage of KMC’s real renewal workflow completed in Memba without founder intervention, with no critical data errors.**

This includes import, household setup, membership types, renewal reminders, member renewal, payment recording, admin correction, export/sync, and board-visible reporting. The transition condition to a growth OMTM is: two consecutive renewal cycles or equivalent pilot milestones with ≥90% of targeted workflow completed in Memba, zero critical membership/payment/privacy errors, and a second volunteer completing the handoff checklist successfully.

After that threshold, the OMTM can become: **number of clubs reaching first successful renewal cycle within 45 days of onboarding**, paired with onboarding support hours and data-error rate.

## AARRR adapted for Memba

### Acquisition

For club admins: qualified club conversations, board demos booked, and design-partner applications from KMC-archetype clubs. Counter-metric: percentage matching ICP, so outreach does not fill the funnel with sub-50-member clubs or large associations.

For members: invitations sent and accepted after a club goes live. Counter-metric: member support requests per 100 invited members.

For activity leaders: leaders invited to manage trips/activities. Counter-metric: percentage who can access the information they need without becoming full admins.

### Activation

A club is activated when it imports a roster, configures memberships and households, enables renewal/payment flow or offline payment tracking, sends its first renewal or invitation, and has at least one member successfully renew or update their profile.

Member activation: logs in, confirms contact details, privacy settings, and membership status; renews or verifies renewal if due.

Activity-leader activation: creates or manages an activity, views participant list, sees waiver/membership status, and can access emergency contacts in the expected context.

### Retention

Club retention is annual renewal plus continued operational depth: the club still uses Memba for multiple core jobs, not just as a dead database. Member retention is successful renewal without duplicate accounts or payment confusion. Activity-leader retention is repeat use for trips without reverting to side spreadsheets.

### Revenue

Track MRR/ARR, revenue per club, paid pilot conversion, gross margin after support and migration, support-adjusted ARPU, and expansion from Starter to Club/Pro. Pair revenue with ICP fit and support load to avoid building a low-margin custom-services business.

### Referral

Measure warm introductions to other clubs, federation mentions, public case-study consent, and “switcher” webinar referrals. Counter-metric: referral quality; a flood of tiny free-tool clubs is not success.

## Core metric set

### Activation metrics

- Time from signed pilot to clean roster import.
- Percentage of households mapped without manual rework.
- First successful individual renewal.
- First successful household renewal.
- First admin correction completed without founder help.
- First export or Google Sheets sync completed.
- First announcement sent with acceptable delivery rate.
- First handoff checklist completed by a second volunteer.

### Retention metrics

- Club annual renewal rate.
- Clubs still using ≥3 core workflows after 90 and 180 days.
- Percentage of renewals processed through Memba rather than side channels.
- Number of active admins per club.
- Second-volunteer task completion rate.
- Manual workaround count per club per month.
- “If Memba disappeared tomorrow, how disrupted would your club be?” segmented by registrar, treasurer, board, member, and activity leader.

### Revenue metrics

- ARR and MRR.
- Paid pilot conversion rate.
- Revenue per active club.
- Gross margin after infrastructure, email, support, and migration time.
- Onboarding hours per club and payback period.
- Discount dependence.
- Win/loss by named alternative: Zeffy, TidyHQ, Amilia, Heylo, Spond Club, membermojo, Clubforce, SportLoMo, Yapla, Wild Apricot, DIY.
- Percentage of deals won for domain-model reasons rather than price.
- Expansion to higher tiers when waivers/activity workflows launch.

### Quality metrics

- Critical data error rate: wrong member status, wrong household billing, duplicate paid member, incorrect waiver state, privacy exposure.
- Payment success and reconciliation accuracy.
- Renewal reminder conversion and false-reminder rate.
- Email delivery, bounce, complaint, and unsubscribe rates.
- Import error rate and time to clean import.
- Household edge-case resolution rate.
- Waiver completion, versioning, and retrieval success.
- Time for a new volunteer to complete common tasks.
- Support requests per 100 members and per admin, classified by severity.

## Guardrails and counter-metrics

- **Growth guardrail:** New clubs added is valid only if median onboarding support hours and critical data errors stay below threshold.
- **Engagement guardrail:** Admin sessions are positive only when task completion time falls and workaround count falls.
- **Revenue guardrail:** ARR growth is valid only when support-adjusted gross margin remains healthy.
- **Competitive guardrail:** “Fair pricing” messaging is valid only if win/loss notes show prospects chose Memba for households, waivers, activity workflows, privacy, or handoff — not because they thought no cheap/free alternatives existed.
- **Household guardrail:** Household renewals count only when individual profiles, member statuses, waivers, and privacy settings are correct.
- **Activity guardrail:** Activities created count only when participant list, waiver status, membership status, and emergency contact access are complete.
- **Handoff guardrail:** A club is not “healthy” until a second volunteer can perform core workflows without founder intervention.
- **Trust guardrail:** Export/sync usage is not churn risk by default; it is evidence of portability. Do not punish it.

## Stage targets

### KMC pilot

- 100% of relevant member records imported and reconciled.
- ≥90% of household cases modeled correctly.
- First real renewal/payment cycle completed with zero critical payment or status errors.
- ≥60% of invited members activate accounts if member portal is in scope.
- Median admin core-task completion under 10 minutes for routine tasks.
- A second volunteer completes handoff checklist without founder help.
- Fewer than 5 severe support issues per 100 members during launch.

### First 10 clubs

- ≥7 of 10 reach activation within 45 days.
- ≥6 of 10 use Memba for at least three core workflows by day 90.
- Median clean import under two hours for simple clubs after tooling improves.
- Critical data error rate below 1% of active members.
- Median founder/onboarding support below a defined sustainable threshold.
- At least 3 clubs agree to reference calls or case-study quotes.
- At least 5 pay retail or near-retail pricing.

### Year 1

- 25–50 paying clubs, depending on support load and scope.
- ≥80% logo retention among ICP-fit clubs.
- ≥70% of clubs using three or more workflows.
- Support-adjusted gross margin trending toward SaaS viability, not services dependency.
- Documented repeatable migration path from CSV/Sheets and at least one incumbent.
- At least one federation or trusted network channel producing qualified leads.
- No unresolved systemic privacy, waiver, or payment integrity incidents.

## Anti-Goodhart risks

- Optimizing “clubs onboarded” attracts tiny clubs with no budget or large clubs with procurement drag.
- Optimizing “members managed” pulls Memba up-market before the handoff product is excellent.
- Optimizing “admin activity” rewards confusion.
- Optimizing “low support” rewards silent failure and hidden spreadsheets.
- Optimizing “payment volume” turns Memba into Zeffy-lite.
- Optimizing “events created” turns Memba into Heylo-lite.
- Optimizing “retention” can tolerate lock-in.

Mitigation: every OKR must be paired. Growth targets require quality gates. Revenue targets require support-margin gates. Usage targets require task-success gates. The dominance rule for the first year: data correctness, privacy, and volunteer handoff beat growth.

## Instrumentation needed

Memba should instrument events and state changes from day one: imports, household merges/splits, membership status changes, renewals, failed payments, reminders, email delivery, waiver acceptance/version retrieval, privacy changes, exports/syncs, role changes, activity participant changes, and admin corrections. Each event should include club, user role, object type, source, timestamp, and whether founder/support intervention occurred.

Add structured support tagging for persona, workflow, severity, root cause, and workaround. Add onboarding checklists per club. Add periodic in-product task-success prompts for admins and members. Maintain a “what users can’t see” dashboard: data-integrity anomalies, duplicate households, stale waivers, privacy-risk changes, failed reminders, email deliverability, export health, and clubs with declining operational depth.

The framework is working when it catches a problem the founder would otherwise have missed — and reverses a product or growth decision because the quality counter-metric says no.