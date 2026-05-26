# Zeffy Deep-Dive (verification)

*Research date: 2026-05-25. Every factual claim below carries a source link or an explicit "unverified" flag with a confidence level.*

## TL;DR correction

The two prior reports that called Zeffy "bootstrapped / funding undisclosed" are **wrong**. Zeffy is **VC-backed** — it has raised disclosed venture rounds from named investors. However, the rounds are modest and *early-stage* (seed-era, 2019–2021); there is **no evidence of a large recent (2022+) round**. So "bootstrapped" is false, but "they raised a significant [late-stage] round" is also not supported by public records.

## 1. Funding & ownership

Zeffy (originally **Simplyk**, Montréal) has raised at least two disclosed venture rounds:

- **Pre-seed (Dec 2019)**: ~CA$720K (~US$560K). Investors include Real Ventures, FounderFuel, Anges Québec. ([Clay funding dossier](https://www.clay.com/dossier/zeffy-funding))
- **Seed (8 Nov 2021)**: ~CA$3.7M (~US$2.97M), **led by Ring Capital**, with Real Ventures, Panache Ventures, Sand Hill North, Frenchfounders, and Dispatch Ventures. Purpose: US expansion. ([Clay](https://www.clay.com/dossier/zeffy-funding), [Tracxn](https://tracxn.com/d/companies/zeffy/__jEFikKpQ33iDXbAO-2Q5uJAHp7SbabbXeFXypi6UEWM/funding-and-investors))

**Total disclosed: ~US$3.7M–$4.5M** (sources vary — PitchBook ~$3.71M, Clay "at least $4.5M"). ([PitchBook](https://pitchbook.com/profiles/company/168644-89), [Crunchbase](https://www.crunchbase.com/organization/zeffy)). The Future of Good profile independently confirms the 2019 (~$750K) and 2021 ($3.7M) rounds. ([Future of Good](https://futureofgood.co/the-delicate-economics-of-a-no-fee-fundraising-platform-meet-zeffy/))

**No 2024/2025/2026 round is publicly recorded** — latest funding date across all trackers is Nov 8 2021. *Confidence: high that nothing large was announced; moderate that none occurred (a quiet raise is possible).*

**B Corp: YES.** Certified B Corporation since June 2022. ([Zeffy B Corp announcement](https://www.zeffy.com/blog/zeffy-certified-b-corporation), [B Lab listing](https://www.bcorporation.net/en-us/find-a-b-corp/company/simplyk/))

## 2. Business model sustainability

Revenue comes **solely** from optional "voluntary contributions" (tips) donors leave at checkout — Zeffy charges nonprofits nothing and absorbs payment-processing fees. ([Zeffy](https://www.zeffy.com/blog/how-does-zeffy-make-money))

Hard numbers from journalism (Future of Good, citing the founders):

- **Opt-in rate: ~50%+** of donors leave a tip. (Marketing pages elsewhere claim 60–80% — treat the higher figures as *unverified self-reported*.)
- **Effective take-rate: ~3.2% per transaction** initially, "negotiated down ~30%" as volume grew.
- **Suggested tip default**: algorithmic, ~15–17% of donation, scaling down as amount rises. ([Zeffy support](https://support.zeffy.com/can-i-change-or-customize-the-voluntary-contribution-to-zeffy-7x8ei))
- At the time of the profile: ~US$15M annual revenue on ~$600M processed. ([Future of Good](https://futureofgood.co/the-delicate-economics-of-a-no-fee-fundraising-platform-meet-zeffy/))

**Sustainability read:** The founders openly describe it as "delicate economics" — each tip must out-earn processing costs. With volume now ~$100M+/month and a take-rate near processing-plus, the model appears workable *at scale* but margin-thin and dependent on sustained tip behaviour. *Confidence: moderate — no audited financials; revenue figure is a single 2023-era source.*

## 3. Scale

Figures have grown over time, which explains the 50k-vs-100k disagreement in prior reports:

- **May 2025 (official milestone)**: **50,000+ nonprofits**, **$1B+ processed cumulatively since 2017**, $50M+ fees saved, 200% YoY growth, $100M+/month. ([Zeffy](https://www.zeffy.com/blog/zeffy-surpasses-1-billion-donations), [Newswire/PR](https://www.newswire.ca/news-releases/zeffy-reaches-new-milestone-over-1-billion-in-donations-processed-on-zero-fee-fundraising-platform-865930746.html))
- **100,000 nonprofits / $2B** appears in newer marketing copy — *plausibly current (late 2025/2026) but treat as unverified self-reported* until a dated press release confirms.
- Stated goal: **400,000 orgs / $4B by Dec 2026** (aspirational target, not actuals). ([Stripe case study](https://stripe.com/customers/zeffy))

**Most current firmly-cited figure: 50,000+ orgs, $1B+ cumulative (May 2025).** Note $1B is *cumulative*, not annual — the "~$1B/yr" in prior reports likely conflates the two; annual run-rate is ~$1.2B+ implied by $100M/month.

## 4. Membership vs fundraising

Zeffy is **fundraising-first but already ships membership features**, not just donations:

- Membership forms, **auto-renewals (monthly/yearly)**, membership cards, tax receipts, member CRM with tags/filters, 30-day renewal reminders. ([Membership product page](https://www.zeffy.com/home/membership-application-form-nonprofits-associations), [renewals help](https://support.zeffy.com/automatic-membership-renewals))
- Also: event ticketing, peer-to-peer, auctions, raffles, online stores. ([$1B post](https://www.zeffy.com/blog/zeffy-surpasses-1-billion-donations))
- **No evidence of waivers / liability forms or a member-facing portal/app** aimed at clubs. *Confidence: moderate — searches surfaced none.* Positioning is "nonprofits & associations," not sports/volunteer clubs specifically.

## 5. Geography

**Canada + US confirmed** — "every state and province." Rebranded Simplyk→Zeffy on US entry (Apr 2022). Second office in **Paris**, framed as global-expansion intent (not yet a live market). ([About us](https://www.zeffy.com/home/about-us), [Choose Paris Region](https://www.chooseparisregion.org/success-stories/moving-canada-paris-region-zeffys-global-expansion))

## 6. Strategic implication for Memba

- **"They're VC-backed, we're independent" is a fair and now-verifiable framing** — Zeffy *is* venture-funded (Ring Capital et al.). But the differentiator is weaker than it would be against a heavily-funded growth-stage player: Zeffy's raise is small/old, and as a **B Corp** with a genuinely free, fee-absorbing model, the usual "VCs will force a price hike / enshittification" narrative is harder to land cleanly. Use it carefully, not as a knockout.
- **The stronger, more honest wedge** is *focus*: Zeffy is donation/association-centric with thin club-specific features (no waivers, no member portal evident). Memba's volunteer-run-club specialisation and member experience is the defensible gap — not the funding story.
- **Watch item:** Zeffy's model economics are tip-dependent and margin-thin; a future raise or a tip-rate change is a plausible disruption Memba should monitor (set an alert on Zeffy funding news).
