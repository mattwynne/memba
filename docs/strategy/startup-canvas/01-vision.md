# Vision

## Long-term aspiration

**Memba exists so that volunteer-run outdoor clubs outlive the volunteers who run them.**

A healthy mountaineering, paddling, ski touring, or cycling club is a multi-generational piece of community infrastructure. It teaches skills, manages risk, holds local knowledge, and gets people outside together. Most of these clubs run on the unpaid evening hours of a membership secretary, a treasurer, and a webmaster — and they are quietly dying not because nobody wants to climb or paddle, but because the administrative load of keeping a club legible to itself (who is a member, who has paid, who has signed a waiver, who is leading Saturday's trip) is too high for the next volunteer to pick up.

Memba's ten-year aspiration is that the volunteer handoff — from one membership secretary to the next, from one board to the next — becomes a one-evening exercise rather than a six-month crisis. If we succeed, the small and mid-sized outdoor club becomes structurally easier to sustain, and a class of community institution that has been quietly atrophying recovers room to grow.

## North-star user outcome

The user we are designing around is the **incoming volunteer membership secretary** of a 50–500 person outdoor club. The moment of success is the moment they open Memba for the first time, look at the roster their predecessor left them, and think *"I can run this."*

Everything downstream — household billing, renewal automation, directory privacy, trip signups, waivers — is in service of that single felt experience. The emotional valence we are after is **relief and confidence**, not delight, not power. A volunteer doesn't want to be a power user; they want to not have to be.

## What the world looks like if Memba wins

- A 200-member club in the Kootenays, the Lake District, the Adirondacks, or the South Island runs its full administrative loop — joins, renewals, household billing, waivers, member directory, official announcements, trip signups — in one tool that costs less than 5% of annual dues revenue.
- "Powered by Wild Apricot" footers and the *Mailchimp + Google Sheet + Google Group + PDF waiver* stack have been replaced, in the small-and-mid-club tier, by something the next volunteer can actually inherit.
- Pricing is predictable. Clubs are charged by **active** members, not by lifetime contacts. There are no payment-processor surcharges layered on top of Stripe — a direct repudiation of the Wild Apricot / Personify 20% PSSF model that the research found to be the single most-resented grievance among Canadian and international users.
- Memba is independent and founder-led, not a portfolio company in a private-equity rollup. After the Personify → Momentive / TA Associates consolidation wave (and Bending Spoons' acquisitions of Meetup and Eventbrite), this is itself a vision-level commitment, not just a positioning angle.

## Smallest version of success we would still be proud of

A few hundred outdoor clubs — Kootenay Mountaineering Club and its peers — running their entire membership operation on Memba, sustainably, for a decade. Volunteers handing off to volunteers without disaster. Not a unicorn outcome; a craft-business outcome. The vision must remain coherent at that scale, because that is the most probable outcome.

## Why now

Three independent forces converge:

1. **The legacy AMS tier is collapsing in trust.** Wild Apricot's Trustpilot rating is 1.7/5; ClubExpress reviews on Capterra describe a UI that "made [an employee] cry"; support has degraded post-acquisition; price increases are routine. Research found a documented Wild Apricot wishlist thread on family memberships open and unaddressed since **2018**.
2. **PE consolidation is producing a flight-to-independence preference.** Buyers are now explicitly looking for vendors who will *not* be acquired and re-priced. Raklet has begun marketing on this dimension; it resonates.
3. **The volunteer pipeline is thinning.** Outdoor clubs increasingly report that recruiting younger volunteer admins is failing. The cost of administrative friction has gone from "annoying" to "existential."

## Statement of stance

Memba is **for** volunteer-run outdoor clubs as a distinct institutional form — household-shaped, activity-shaped, risk-shaped, and small. We are **against** the assumption that these clubs are merely undersized versions of professional associations, sports leagues, or creator communities, to be served by retrofitted tools from those categories.

Concrete commitments that follow:

- **Households are first-class, not a "bundle" workaround.** Two adults plus dependents, individual logins, shared billing, per-person waivers and emergency contacts. This is the single largest documented gap in the incumbent tier, and Memba is unwilling to ship the same fudge.
- **Active-member pricing, no platform surcharge.** Lifetime contacts are free to retain. Payment processing is Stripe at Stripe's price. Memba does not tax the club's payment rails.
- **The data belongs to the club.** Clean exports, Google Sheets sync as a first-class feature, a documented "leave anytime" promise.
- **The next volunteer is a user, not an edge case.** Onboarding, audit trails, granular roles, and admin clarity are designed against the handoff scenario, not the power-user scenario.

## What Memba explicitly will not become

- A general-purpose association management system for professional associations or trade bodies.
- A creator-economy / community platform (Mighty Networks, Memberful adjacent).
- A youth-sports league app (Spond, TeamSnap adjacent).
- A booking, permitting, or commercial-trip system (FareHarbor adjacent).
- A learning management system, donation CRM, or full-fat website builder.
- An AT Protocol or federation showcase. Federation may be useful infrastructure later; it is not the vision.

Each of these is an adjacent business model that would be easy to drift into and corrosive to what makes Memba defensible — namely, fit to a specific institutional form.

## Identity and form

Memba claims the tradition of **community infrastructure software**, not the tradition of growth-stage SaaS. The closest analogue from outside the category is something like Consumer Reports or a credit union: a small, durable, trust-led business serving a specific kind of organization for a long time. The implication is that Memba should be operated, and capitalized, in a way that makes a PE exit unattractive — because the moment the company optimizes for exit, the trust commitments above become uncredible.

## Open questions / assumptions to test

- **Heroic-user selection.** Centering the incoming membership secretary is a deliberate choice over the treasurer, the trip leader, or the regular member. Worth pressure-testing in customer discovery — does the emotional drama actually live with the registrar, or with the treasurer at renewal season?
- **Households as the primary wedge.** Research strongly suggests it is underserved, but switching is rare; clubs may need *households + trip management* combined to clear the inertia bar.
- **"Independent forever" as a vision-level commitment.** Credible only if matched by a capital structure (bootstrapped, steward-owned, B-corp, or capped-return) that makes the commitment enforceable. This is a real founder decision, not a tagline.
- **Geographic scope.** Canadian / UK / AU / NZ clubs are disproportionately punished by the Wild Apricot PSSF surcharge. Is Memba a North American product that ships internationally, or a Commonwealth-outdoor-club product that happens to start in BC?
- **The five named crises** Memba must have pre-decided answers to before launch: (1) a member's data is exposed through a directory privacy misconfiguration; (2) a participant is injured on a trip where waiver status was misrepresented in Memba; (3) Stripe deplatforms or freezes a club; (4) a board faction tries to use Memba's directory for a contested club election; (5) an acquisition offer arrives that would breach the independence commitment. None of these have doctrinal answers yet.
