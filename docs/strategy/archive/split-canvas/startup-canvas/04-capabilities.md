# Capabilities

This section maps the activities, resources, and partnerships Memba needs to deliver its value proposition: a simpler, fairer, outdoor-club-native membership platform for volunteer-run clubs. It follows the Paweł Huryn Startup Canvas framing of "Capabilities" as the union of Key Activities, Key Resources, and Unfair Advantage, and applies the methodology from the CAPABILITIES research template (RESEARCH-CAPABILITIES-PROMPT.md) — including the build/partner/buy lenses, the irreducible-core test, and the explicit "not-acquiring" list.

The grounding documents are `docs/strategy/lean-canvas.md`, `docs/strategy/research-plan.md`, the extracted competitor research in `docs/strategy/research/extracted-text/` including `Competitor Gap Pass for Memba.txt`, and the repo-level `AGENTS.md` confirming a Phoenix-first stack.

## 1. The irreducible core

Applying §1b of the template: what does the customer actually buy from Memba, and which capability — if absent or weak — causes the product to fail regardless of how strong the rest is?

The Lean Canvas is explicit: the wedge is "membership operations for volunteer-run outdoor clubs," with household/family handling, activity/waiver workflows, and volunteer-admin handoff as the differentiating axes (`lean-canvas.md` §Core thesis, §Unfair Advantage). The competitor research confirms that the gap is not feature breadth — Wild Apricot and ClubExpress already out-feature any plausible MVP, while TidyHQ, Amilia, Heylo, Spond Club, membermojo, Clubforce, SportLoMo, Zeffy, and Yapla compress the “cheap enough” space — but **a coherent domain model + volunteer-friendly UX + trustable pricing/portability**, executed without the contact-count cliffs, bundle hacks, tip prompts, and fee stacking that drive churn or discomfort.

Memba's irreducible core is therefore a **rare cross**: deep outdoor-club domain modelling (households, dependents, waivers, leader roles, trip lifecycle, lapsed-vs-active state) fused with volunteer-admin UX design (handoff in one evening, no jargon, no Salesforce-shaped onboarding). This is judgment-led at the domain layer and execution-led at the engineering layer; neither alone is sufficient.

Diagnostic per the template: roughly 60% of customer value depends on judgment quality (does the household model match how *our* club actually works?), and 40% on execution quality (does Stripe billing, email deliverability, and the import tool just work?). That puts Memba slightly on the judgment-led side — meaning the **domain/UX leader should sit at parity with or above the engineering leader**, not below. Today, that role is held by the founder.

The minimum viable team for the core at MVP stage is one founder/PM with embedded domain access (Matt + KMC) plus one to two Phoenix engineers. The v0 artifacts the core team must produce are: the household/membership data model (ERD + invariants), the volunteer-admin task taxonomy, the renewal state machine, and the migration playbook for Wild Apricot / ClubExpress / spreadsheet starting states.

## 2. Discipline map (build / partner / buy)

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

This list, generated from first principles per the template's warning against copying the source brief's discipline list, deliberately omits things that incumbents over-acquire (full website builder, LMS, donation engine, marketplace, branded mobile apps) — see §6 "Not acquiring."

## 3. Key activities

The activities Memba must execute well, in priority order:

1. **Product development** on the Phoenix/LiveView stack — household model, renewals engine, Stripe integration, member directory, announcements, role-based admin (`AGENTS.md`; `lean-canvas.md` §Solution).
2. **Migration concierge** — hand-running imports for the first 5–10 clubs to build playbooks, schemas, and trust. The Lean Canvas flags migration as a top-five validation experiment and a key cost driver; doing it as a *service* before automating it as a *feature* is the standard concierge-MVP move.
3. **Customer success and support** — founder-led at MVP, designed for volunteer admins who need reassurance, not just docs. Identified as one of the two biggest cost drivers (`lean-canvas.md` §Cost Structure).
4. **Email deliverability operations** — DNS, DKIM/SPF/DMARC, bounce handling, suppression lists, reputation monitoring. Explicitly called out in cost drivers; a club whose announcements don't land will churn fast.
5. **Content/SEO and comparison marketing** — "Wild Apricot alternative", "ClubExpress alternative", "membership software for hiking clubs" (`lean-canvas.md` §Channels). Cheap, durable, founder-writable.
6. **Community and federation outreach** — mountaineering federations, paddling associations, trail-club umbrellas as channel partnerships, not advisor decoration. Per the template's §1e warning, each must have a named contact and a concrete deliverable structure.
7. **KMC pilot operations** — running the design-partner relationship as a *capability*, not as a favour. KMC is both reference customer and methodology validator.

## 4. Key resources

- **Founder/domain fit**: Matt as founding builder with direct KMC access — real users, real data, real renewal cycles (`lean-canvas.md` §Unfair Advantage). This is the single largest capability asset and the closest analogue to a "rare-cross hire" being available from day one.
- **KMC pilot relationship**: Doubles as design partner, data source, reference case, and methodology stress-test.
- **Tech stack**: Phoenix 1.8 / Elixir / LiveView / Postgres / Tailwind, with Stripe, Swoosh, Oban as standard libraries (`AGENTS.md`, `docs/reference/`). The stack is mature, debuggable, and hires-into a small-but-real Elixir labour market; talent-market fit is acceptable for a small team and excellent for retention.
- **Data assets (latent)**: Anonymised renewal cohort patterns, household structures across clubs, migration mappings from Wild Apricot/ClubExpress exports. None of these are moats individually; their *aggregate* over 20+ clubs becomes one.
- **Strategy archive**: The research workstreams already executed (`docs/strategy/research/`) constitute a knowledge resource that competitors entering this niche would need to redo.

## 5. Differentiating vs table-stakes

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

## 6. The "not acquiring" list (deliberate exclusions)

Per the template's quality bar §5.7 — the most important deliverable. Memba will explicitly *not* acquire:

- **AT Protocol / federation engineering** beyond a time-boxed research spike. Risk accepted: a federated competitor could emerge; mitigated by the assessment that no buyer evidence supports federation as a switching trigger (`lean-canvas.md` §Assumption 5).
- **Native mobile app development**. Risk accepted: trip-leaders may want mobile; mitigated by responsive LiveView + push-as-email until evidence forces a revisit.
- **Full forum/discussion product**, **LMS**, **website builder**, **donation engine**, **marketplace**. Risk accepted: clubs may stitch in other tools; that's preferred to scope-creep into incumbents' bloat.
- **In-house payments processing**. Risk accepted: Stripe rate hikes; mitigated by clean abstraction allowing GoCardless/PayPal addition.
- **Enterprise sales motion** (large federations, multi-chapter umbrellas). Risk accepted: revenue ceiling at the small-club tier; mitigated by deliberate sequencing — federations are a *future* segment.
- **Internationalisation/localisation** beyond English (with currency-agnostic billing). Risk accepted: EU/LATAM markets stay closed; revisit trigger is a credible federation lead from a non-English market.

## 7. Capability gaps and closure plans

1. **Email deliverability expertise**. Gap: founder-level. Close by: engaging a fractional deliverability consultant for a one-week DNS/warm-up engagement before the first 10-club send; using Postmark (which embeds the expertise) rather than rolling on SES initially.
2. **Volunteer-admin UX research depth beyond KMC**. Gap: single design-partner risk. Close by: structured discovery interviews with 5+ non-KMC clubs (the customer discovery plan in `research-plan.md` already specifies this); avoid over-fitting to KMC idiosyncrasies.
3. **Migration tooling at scale**. Gap: each migration today is bespoke. Close by: concierge-first for the first 5 clubs; productise patterns after that — explicitly *not* before, to avoid building the wrong importer.
4. **Specialty counsel** on Canadian and UK privacy/waiver law, plus payment-related liability. Gap: no counsel on retainer. Close by: scope memos from one Canadian (PIPEDA + provincial) and one UK (UK GDPR + Defamation Act for member directories) firm before the first non-KMC club signs.
5. **Senior engineering bandwidth**. Gap: solo / small team. Close by: one senior Phoenix hire when paid-pilot count reaches 5, recruited through ElixirForum / Code BEAM / Elixir Slack networks (the §1f equivalent for this stack).
6. **Domain-credibility partnerships**. Gap: no federation logos yet. Close by: structured outreach to one mountaineering federation, one paddling association, and one trail-club umbrella in months 4–6, with concrete deliverables per the template's anti-advisor-decoration rule.

## 8. Single-point-of-failure dependencies (per §6 pitfall #6)

- **Stripe**: Critical. Mitigation — design billing abstraction layer from day one; GoCardless and PayPal as named fallbacks; budget reserve for a 90-day rewrite if Stripe terminates the account.
- **Postmark/SES**: Important. Mitigation — Swoosh's adapter pattern makes swapping providers a one-day job; maintain a warm secondary domain.
- **KMC as design partner**: Reputational. Mitigation — recruit a second design-partner club by month 4 so methodology is not single-club-derived.
- **Fly.io / Render**: Low coupling. Mitigation — standard Docker + Postgres dump portability.

## 9. Capability risks and mitigations

1. **Engineering substituting for the real core** (template pitfall #1). Risk: a Phoenix-fluent founder over-invests in engineering elegance at the expense of household/UX research. Mitigation: track a *domain-artefact-to-code-commit ratio* — for every fortnight of build, one fortnight of customer-discovery output (interview notes, model revisions, UX flows).
2. **Concierge migration becomes the business**. Risk: low-ARPU clubs consume founder time on bespoke migrations. Mitigation: cap concierge to the first 5 clubs; convert learnings into self-serve importer; price migration explicitly above cost for Pro tier.
3. **Email deliverability incident**. Risk: a misconfigured send tanks domain reputation across all tenants. Mitigation: per-tenant subdomain strategy, suppression-list discipline, monitoring dashboards from day one.
4. **Stripe account suspension**. Mitigation as above; plus diversified merchant-of-record consideration (Paddle) if exposure grows.
5. **Volunteer-admin churn at customer clubs**. Risk: handoff failures look like Memba failures. Mitigation: handoff-oriented design as a first-class product requirement; "new-treasurer onboarding mode."
6. **Scope creep into trips, courses, gear, cabins, permits** (`lean-canvas.md` §Cost Structure #5). Mitigation: the "not acquiring" list is the contract; revisits require evidence, not enthusiasm.
7. **AT Protocol distraction**. Mitigation: time-box to a documented spike with a kill-switch criterion (does any pilot club ask for federation? if no, ship.).
8. **Legal exposure on private member directories** (defamation, data subject requests, minors' data in family memberships). Mitigation: scope memos commissioned before the second club ships; DPA template ready; minimal data collection by default.
9. **Solo-founder bus factor**. Mitigation: documented architecture decisions (ADRs already configured via `adrgen.config.yml`), public runbooks, an early senior engineering hire as the team scales past one paying cohort.

---

**Summary for the canvas:** Memba's distinctive capability stack is a rare cross of outdoor-club domain modelling and volunteer-admin UX design, executed on a Phoenix/Postgres/Stripe stack with founder-led migration concierge and fair-pricing discipline; the biggest capability gap is migration-tooling-at-scale beyond the founder's hands, and the closure plan is to run concierge migrations for the first five clubs deliberately, then productise the patterns rather than the other way around.
