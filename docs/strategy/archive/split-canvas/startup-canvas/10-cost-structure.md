# Cost Structure

Memba is not an AI-heavy product whose main cost risk is inference. Its hard cost problem is a low-ARPU, high-trust, high-support SaaS business for volunteer-run clubs. A naive model would assume that once the Phoenix app is built, each additional club costs almost nothing. The reality is that the expensive work sits around the software: migration from messy spreadsheets or incumbents, support for rotating volunteers, reliable email delivery, waiver/privacy/legal assurance, and the trust commitments needed to make a small independent vendor credible.

All numbers below are estimates until replaced by vendor quotes, pilot actuals, and a driver-based FP&A model.

## Unit of value and gross-margin frame

The most useful unit of value is one active club-month, with a secondary unit of one active member-month. Memba's pricing hypotheses are roughly $29–$49/month for Starter, $59–$99/month for Club, and $129–$199/month for Pro. That implies low annual contract values: perhaps $500–$1,200/year for many early clubs and $1,500–$2,500/year for larger ones. This makes support and migration discipline existential.

The target long-run software gross margin should be 80%+ before migration services, but early gross margin may be much lower because founder time is doing support, onboarding, and custom import work. A realistic early target is to prove that steady-state variable cost per club can stay below 10–20% of subscription revenue, while one-time migration is either paid, capped, or treated as deliberate learning for the first design partners.

## Fixed operating costs

### Product and engineering

The largest fixed cost is founder and engineering time. Even if founder salary is initially deferred, the model should not pretend it is free. Estimate founder compensation at $120k–$180k/year pre-seed/pre-Series A equivalent, rising to $180k–$250k if investor-funded or once revenue supports it. A first senior Phoenix engineer would likely cost $140k–$220k base, or roughly $180k–$285k fully loaded. Contractors may be cheaper in calendar terms but risk knowledge loss in the domain model.

The engineering fixed-cost base includes Phoenix/LiveView development, Postgres schema evolution, Stripe integration, imports/exports, Google Sheets sync, admin UX, accessibility, tests, security fixes, and documentation. The most expensive product choices are not hosting choices; they are schema commitments around households, children, waivers, membership periods, roles, and activities.

### Infrastructure and SaaS tooling

Memba should start with a boring managed stack: Phoenix app hosting, managed Postgres, object storage, transactional email provider, observability, error tracking, uptime monitoring, CI, backups, and security tooling. Estimated MVP infrastructure and tooling: $200–$800/month. At 10 clubs: $300–$1,500/month. At 50 clubs: $800–$4,000/month, depending on email volume, file storage, observability retention, and database size. These are estimates; actuals should be instrumented by club, member count, email volume, and stored files.

Likely rows in the model: app hosting, managed Postgres, backup storage, object storage for waiver evidence/files, CDN if needed, Postmark or equivalent email, Sentry/AppSignal, log drain, uptime monitoring, analytics, domain/DNS, CI minutes, staging environment, secrets management, and support/helpdesk software.

### Legal, privacy, security, and insurance

Waivers and emergency contacts make Memba trust-sensitive even if it is not giving legal advice. Memba will store personal information, possibly minors' information, emergency contacts, waiver attestations, and payment-related metadata. Estimate an initial legal/privacy review at $5k–$20k for Canada/UK/US templates, terms, privacy policy, DPA, waiver-product posture, and data retention guidance. Annual legal reserve should not be zero; estimate $5k–$25k/year early, rising with revenue and geography.

Insurance should include Tech E&O and Cyber from the first meaningful external customers. Estimated early premium: $2k–$8k/year; with higher revenue, larger limits, or waiver-related concerns, $10k–$30k/year is plausible. D&O becomes relevant if outside capital or a formal board is added. Security costs include password/auth hardening, vulnerability management, periodic penetration tests, and eventually SOC 2 readiness if larger clubs or federations demand it. Estimate a lightweight annual pen test at $5k–$15k once the product manages several clubs' real data.

## Variable costs

### Payments

Stripe processing fees should be passed through transparently where possible. The strategic commitment is no Memba surcharge. The cost model still needs to track payment fees because refunds, disputes, failed payments, and international cards create support and operational costs. Payment-related variable cost is mostly not margin cost if passed through, but it is still a driver of support time.

### Email deliverability

Email is a core product function, not a commodity afterthought. Costs include transactional renewal reminders, login emails, announcements, bounce processing, suppression lists, DMARC/SPF/DKIM setup, reputation monitoring, and customer education. Estimated direct email vendor cost may be low at first: perhaps $10–$100/month for KMC-scale usage and $100–$1,000/month at 50 clubs. The larger cost is operational: diagnosing why a member did not receive an announcement, helping clubs configure sender domains, and preventing one tenant from damaging shared reputation.

A deliverability consultant before the first 10-club expansion is prudent. Estimate $2k–$8k one-time for setup review, domain strategy, warm-up guidance, and monitoring design.

### Storage and documents

Waiver evidence, exports, private files, and audit logs create storage and retention obligations. Direct storage cost is likely small initially, but retention, retrieval, backups, and evidence integrity matter. Estimate pennies to a few dollars per club-month early; the risk is not raw S3 cost but the support and legal burden of proving what was accepted, by whom, when, and under which waiver version.

### Support and customer success

Support is the largest variable-cost risk. Volunteer admins need reassurance, and their roles rotate. If one club pays $79/month but consumes two hours/month of founder support, the account is underwater. The model should track support minutes per club-month, tickets per 100 members, and support reason codes.

Estimated steady-state target: under 20–30 minutes per club-month after onboarding. Danger zone: more than one hour per club-month for Starter/Club tiers. Dedicated support becomes necessary around 30–50 paying clubs unless the product and docs reduce the load. A support/customer-success hire may cost $60k–$100k base, $80k–$130k fully loaded.

### Migration and onboarding

Migration is both differentiator and cost trap. Early migrations from KMC, spreadsheets, Wild Apricot, ClubExpress, TidyHQ, Zeffy, Heylo, or custom databases will expose edge cases in households, lapsed members, duplicates, waiver status, payments, and roles. For the first 5 clubs, concierge migration should be treated as research and product development. After that, it must be priced or capped.

Estimated migration effort: simple CSV club, 2–6 hours; messy household club, 8–25 hours; incumbent migration with historical data, 20–60+ hours. At an internal loaded cost of $75–$150/hour, an unpriced complex migration can wipe out one to three years of subscription margin. Cost-control levers: import templates, migration checklists, paid migration packages, do-not-import defaults for stale history, and a clear boundary between data cleanup and software setup.

## GTM costs

Memba's early GTM should be founder-led and content-heavy: KMC case study, direct outreach, switcher pages, comparison guides, and outdoor-club networks. Estimated cash spend can be low: $100–$1,000/month for tools, hosting, design, directories, and small experiments. The real cost is founder time.

Paid acquisition is risky because ARPU is low. A $300 CAC can work for a $1,200/year club with strong retention; it does not work for a $348/year Starter club with heavy support. Channel-level CAC should be modeled separately: KMC referrals, federation outreach, SEO/comparison content, direct email, and partner webinars. Do not blend CAC until each channel has enough data.

## Trust and continuity commitments

The independence promise has costs. "Leave anytime" requires clean exports, documentation, schema stability, and support for offboarding. A public pricing pledge reduces future pricing flexibility. Continuity commitments may require source-code escrow, open-source posture, steward-ownership/B-Corp work, or a shutdown runway policy. Estimate $2k–$15k one-time legal/structural work for serious continuity commitments, plus ongoing documentation and engineering maintenance. These costs are part of the product, not marketing overhead.

## Scenario estimates

### KMC pilot

Estimated cash operating cost: $300–$1,500/month excluding founder salary; $1k–$5k/month if part-time contractors or specialist consultants are included. One-time costs may include $5k–$20k legal/privacy review, $2k–$8k email deliverability setup, and substantial founder migration time. Gross margin is not meaningful yet; the goal is measured unit economics and support/migration baselines.

### First 10 clubs

Estimated recurring cash cost: $1k–$5k/month excluding full-time salaries; $10k–$30k/month including founder salary and contractor/engineering capacity. One-time migration effort could total 80–250 hours if not constrained. At $700 average ARR, 10 clubs produce only $7k ARR; at $1,500 average ARR, they produce $15k ARR. This stage is still learning-heavy and will likely be cash-negative.

### 50 clubs

At 50 clubs, estimated ARR might range from $35k to $100k depending on tier mix. Recurring infrastructure and tooling may be $1k–$4k/month. Support may require a part-time or full-time hire. Founder/engineering salary dominates the P&L. If average support is 20 minutes per club-month, support load is manageable; if it is 90 minutes, it becomes a 75-hour/month function before migrations. This is the stage where Memba must prove that onboarding is repeatable, migration is priced, and gross margin can trend toward SaaS norms.

## Gross-margin risks and reduction levers

The top margin risks are high-touch support, unpriced migrations, email deliverability incidents, waiver/legal escalation, household edge-case complexity, and scope creep into trips, courses, cabins, gear, donations, or full website building. Heylo already covers memberships, events, and paid waivers; competing by adding every adjacent feature would raise costs without preserving differentiation.

Cost-reduction levers are clear: build household and import workflows carefully; cap concierge migration; charge for complex migration; use Postmark-like managed email before optimizing for raw SES cost; design self-serve exports from day one; keep payments pass-through; maintain a narrow outdoor-club ICP; defer native mobile and full community features; invest in docs and handoff mode; instrument support time by feature; and review actuals monthly against a driver-based model.

The cost thesis is therefore: Memba can be capital-efficient only if it treats support, migration, and trust operations as first-class cost lines. Hosting will not kill the business. Volunteer complexity might.