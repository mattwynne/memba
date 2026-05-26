# Heylo Deep-Dive (product threat)

**Bottom line up front:** Heylo is a real, well-built, VC-backed community platform that genuinely ships waivers, recurring memberships, events with capacity/waitlists, and payments — and it works in Canada. But two of its headline overlaps with Memba are softer than feared: waivers are a **paid** ($59/mo) feature (not free), and there is **no evidence of true household/family memberships** (multiple individual profiles/logins under one payer). The threat is real on payments+memberships+events; the household/trip "whitespace" is largely intact.

## 1. Company

- **Who:** Heylo is built by **Piccup, Inc.** Founded **2019** by ex-Googlers **Eric Winters** (CEO) and **Brandon Pearcy**, who met at Google and built community groups (running, beach volleyball) on the side. ([TechCrunch, Nov 2022](https://techcrunch.com/2022/11/01/heylo-fundraise/), [Heylo About](https://www.heylo.com/about))
- **Funding:** Bootstrapped to profitability, then raised a **$1.5M round (announced Nov 2022) led by Worklife Ventures** (Brianne Kimmel), with **Precursor Ventures** (Charles Hudson) participating. ([TechCrunch](https://techcrunch.com/2022/11/01/heylo-fundraise/), [Crunchbase](https://www.crunchbase.com/organization/heylo-a6ce)) So: VC-backed but lightly capitalized — a seed-stage company, not a giant.
- **Traction:** Google Play listing reports **~140K downloads** and **~2K ratings averaging 4.80** ([AppBrain](https://www.appbrain.com/app/heylo-|-build-community-groups/com.piccup), [Google Play](https://play.google.com/store/apps/details?id=com.piccup&hl=en_US)). At the 2022 raise they cited only **$500K collected** for leaders ([TechCrunch](https://techcrunch.com/2022/11/01/heylo-fundraise/)) — modest. Reviews are positive (favorable Meetup comparisons), with some Android performance complaints.

## 2. Monetization

The "100% free, no ads" framing from earlier research is **outdated/incomplete.** Heylo now runs a **tiered SaaS model plus payment take-rate** ([Pricing](https://www.heylo.com/pricing)):

- **Base $0/mo** — unlimited members/events, chat, payment collection, 500 emails/mo, **5% + $0.59** payment fee.
- **Plus $19/mo** — advanced events, analytics, 4% + $0.49.
- **Pro $59/mo** — **waiver collection**, website-embedded events, 2% + $0.29.
- **Business $199/mo** — API, onboarding, 1% + $0.10.
- **Organization** — custom, multi-chapter discounts.

So they make money two ways: subscriptions and a **payment service fee** (~3.7% + $0.59 platform fee on top of Stripe per their help docs, [Platform & processing fees](https://www.heylo.com/help/platform-and-processing-fees)). This is a **sustainable, disclosed model** — lower shutdown risk than a pure free play, but the free tier is real and competitive for small groups.

## 3. Feature verification

**(a) Waivers — YES, but paid.** Genuinely native: upload waiver once, members prompted to sign during onboarding/event registration, access blocked until accepted, **timestamped + versioned, logged to member profile, exportable, recoverable** ([Waiver signatures](https://www.heylo.com/help/waiver-signatures-collection), [blog](https://www.heylo.com/blog/waivers-collected)). Caveat: it's a checkbox "I have read, understand, and agree…" attestation, **not a drawn/typed e-signature**, and it's gated behind **Pro ($59/mo)** ([Pricing](https://www.heylo.com/pricing)). Real and competent, but not free and not a full e-sign artifact.

**(b) Household/family memberships — NO evidence.** Membership-plan docs describe only **individual** plans (name, price, initiation fee, frequency, visibility, admin approval) with **no family/household bundling, no "multiple profiles under one payer," no dependents** ([Membership plans](https://www.heylo.com/help/membership-plans)). "Multiple profiles" in their materials means multiple *photos* per profile and belonging to multiple *groups* — not family accounts. **This is Memba's strongest remaining differentiator.** (Flagged: absence of a feature in docs is suggestive, not definitive, but the silence across pricing, membership, and profile docs is strong.)

**(c) Recurring dues & renewals — YES.** Recurring monthly/quarterly/annual plans, initiation fees, free trials, and **30-day renewal reminders** ([Membership plans](https://www.heylo.com/help/membership-plans), homepage).

**(d) Trip/activity management — PARTIAL, "events" not "trips."** They have events with RSVPs, **capacity caps, waitlists**, attendance tracking, per-event chats, and member-only visibility ([homepage](https://www.heylo.com/), [hiking-club](https://www.heylo.com/hiking-club)). The hiking page adds route/trailhead/difficulty/packing-list fields and "cap group size for safety." But this is **event configuration, not a true outdoor-trip workflow** — no clear evidence of dedicated **trip-leader roles**, multi-day trips, equipment/sign-out, or trip-specific approvals beyond generic admin roles. Distinguish: Heylo has *events with hiking metadata*, not a *trips module*.

## 4. Platform

**Both web and mobile** — "Heylo works in any browser. iOS and Android apps are also available" ([homepage](https://www.heylo.com/)). This **neutralizes** the assumption that Heylo is mobile/consumer-only: a volunteer membership secretary **can** do admin on a laptop. That said, the product's center of gravity (app store presence, 140K downloads, social profiles/icebreakers, "build your social circle" positioning) is **consumer/social-first**; the admin web tooling exists but the marketing voice targets group *leaders building community*, not back-office club secretaries.

## 5. Geography

**Works in Canada.** Heylo supports **CAD and 20+ currencies**, uses Stripe, lets members pay by card/Apple Pay, and handles international payments with currency conversion (~2% Stripe charge on mismatch) ([Currencies](https://www.heylo.com/help/currencies), [International Heylo](https://www.heylo.com/blog/international-heylo)). A Canadian App Store listing exists ([apps.apple.com/ca](https://apps.apple.com/ca/app/heylo-build-community-groups/id1445966180)). **Not a US-only escape hatch for Memba.**

## 6. Verdict

Heylo contests a **meaningful slice** of Memba's claimed whitespace today: recurring memberships, payments, native waivers, capacity/waitlist events, web admin, and Canadian support all exist and are production-grade. The earlier research's "free + waivers" alarm is **half-right**: waivers are real but cost $59/mo, and "free" is a small-group tier, not the whole product.

**What Heylo does NOT have (Memba's defensible ground):**
- **True household/family memberships** — multiple individual profiles/logins under one paying account/dependents. No evidence anywhere. *(Memba's #1 differentiator.)*
- **A genuine outdoor-trip workflow** (trip-leader roles, multi-day/equipment/waitlist-by-trip logic) beyond events-with-metadata.
- **Secretary-first / back-office admin positioning** — Heylo is leader/consumer-social-first; Memba can own the "boring club admin done right" niche.

**Timeline/risk:** Heylo is a focused, profitable, ~seed-stage team that ships steadily — adding household plans or a richer trip module is **plausible within 6–18 months if a customer pushes for it**, since they already have the payments/membership/waiver substrate. The risk is **medium-high on overlap, but Memba retains a real, currently-uncontested wedge** in households + true trips + secretary-grade admin. Differentiate hard and fast on those, because the surrounding moat (payments, events, waivers) is already gone.
