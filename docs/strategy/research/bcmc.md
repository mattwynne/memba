# BC Mountaineering Club (bcmc.ca) — DIY / prior-art note

Not a SaaS competitor. BCMC is a volunteer-run outdoor club (founded 1907, 1,300+
active member accounts) running a custom-built member platform stitched together
with several third-party tools. It is most useful as **prior art** and as
**evidence of the core problem**: a club this size has had to build and integrate
bespoke software to handle membership, trips, courses, forum, and huts — exactly
the work Memba aims to make unnecessary.

## Source

- https://bcmc.ca and sub-pages — checked on 2026-05-29 via automated fetch of
  public pages (member-only areas not inspected). Detail below is a read of public
  content, not a verified audit.

## Site map (public nav)

- Who We Are `/about`, Membership `/membership`, Volunteers `/volunteers`,
  Discounts `/discounts`, **Trip List `/events`**, Courses `/courses`,
  Mentorship `/mentorship`, Forum `/forum`, **Huts `/huts`**,
  Publications `/publications`, Member Directory `/members`, Contact `/contact`.
- Top actions: Become a Member `/register`, Sign In `/login`.
- Merch is offloaded to Spreadshop (`bcmcswag.myspreadshop.ca`).

## The stack is fragmented (this is the key insight)

BCMC did **not** build one tidy product. It runs:

- A custom membership / trips / courses / forum / directory site.
- **Hut booking outsourced to rezexpert.com** (third-party reservation system),
  with per-hut "Book Now" links.
- **Kees & Claire hut booked via a partner** (Spearhead Huts Society) on a
  separate site, giving BCMC members "additional booking privileges."
- Merchandise on Spreadshop.

The seams show: a forum thread asks for "the promo code to take advantage of the
90 day window" for the Kees & Claire hut — i.e. the hut benefit is glued on, not
natively integrated with membership. This is the DIY-stack pain Memba targets,
embodied in one club.

## Membership

- **Guest Member** — free, 30-day trial. Access to trips, forum, newsletters, but
  some activities restricted and lower registration priority.
- **Adult Member** — $40/year. Full benefits; voting rights after one year.
- Minimum age 19. **No household/family option** mentioned — a clear gap and a
  direct match to Memba's household wedge.
- Renewal: members log in and visit the memberships page.
- Includes: 550+ trips/courses per year, priority on 20+ instructional courses, an
  800-book library, discounted cabin bookings, monthly socials (Sep–Jun), forum,
  newsletter, optional biennial *B.C. Mountaineer* journal ($10).
- No public detail on waivers, emergency contacts, or cancellation policy.

## Trips & courses (unified under `/events`)

Trips and courses live in one chronological "Trips & Courses List." Each trip shows:

- Date, day of week, and duration (hours/days).
- **Difficulty rating**: two-character system — letter A–D for strenuousness,
  number 1–5 for technical difficulty (e.g. "B2"). Separate scales for
  hiking/climbing vs. ski/snowshoe; a reference table is shown on the page.
- Activity type (icon + category): hiking, scrambling, rock/mixed climbing,
  mountaineering, etc.
- **Named organizer/leader** with a profile link.
- **Capacity**: max participants, confirmed registrations, and waitlist count.
- **Status**: OPEN / FULL / Cancelled.
- **Flags**: some trips marked "Screening" or "Members Only" → approval workflows
  exist, though the screening procedure isn't public.
- Signup requires login. **Cost is not shown** in the public listing.

Courses split into volunteer-led in-house offerings ("beginner friendly",
"Practice"/"Training", "Instructional Programs") and professional partner courses
(Canada West Mountain School, Mountain Skills Academy) with fees and member
discounts. In-house courses carry a "minimal charge" funding club projects;
refunds are handled by transferring a place to a replacement current member.

## Forum

Five sections, activity-typed and member-aware:

1. Get Informed & Share Ideas — per activity (ice/rock/mountaineering/ski), each
   with "Basic Info" and "Issues" sub-forums.
2. Trail Updates & Trip Reports — BC + international, with photo galleries.
3. Looking for Beta or Partners — partner-finding.
4. General Club Discussions — announcements, conservation, gear, events.
5. **Member-Only Forums** — restricted, for volunteer coordination.

Requires login; gates content by membership. Cross-references club services (e.g.
the hut promo-code question above).

## Huts / facilities

Six properties: Watersprite Lake Cabin, Mountain Lake Hut, Plummer Hut, North
Creek Hut, Norm Deacon Cabin, Kees & Claire Hut. "Drop-in visitors are not
permitted" — bookings are member-gated. Watersprite has a **90-day advance window**.
Booking is via rezexpert.com (third party); Kees & Claire via the Spearhead Huts
Society partner site. Nightly rates, capacities, and amenities aren't on the public
page.

(Earlier I noted "live cameras" from a first-pass fetch; I could not confirm this on
re-check, so treat it as unverified.)

## Requirements / features this surfaces for Memba

Reinforced (already on radar):

- Trip model with difficulty grading, leader roles, capacity + waitlist counts,
  status, and screening/members-only approval flags.
- Membership-gated content (forum sections, directory, benefits).
- Member directory and profiles (with leader profile links from trips).

Worth considering:

- **Difficulty rating as a structured, club-configurable taxonomy** (two-axis,
  multiple scales per activity family) rather than free text.
- **Unified trips + courses** in one schedule, with course-specific concepts
  (in-house vs. professional/partner, fees, prerequisites, replacement-member
  refund handling).
- **Facility/resource booking** (huts/cabins) with advance-booking windows and
  member-only access — a strong stickiness feature for asset-owning clubs. BCMC
  outsources this; a native, membership-aware version would remove a painful seam.
- Publications / journal archive as a member benefit.
- Guest/trial membership tier with restricted access and lower priority.

## Corroborating primary source

See `kmc-thread.md` — a private KMC email thread (2026-05-29) in which a former BCMC
exec member confirms the BCMC site is **fully custom, built ~2012, and still needs a
volunteer team to maintain**, and in which KMC members cite the BCMC events page as
the model they wish they had. Direct, unprompted validation of the points below.

## Strategic implication

BCMC is a case study, not a competitor to beat. Use it as:

- **Proof of the problem** — even a capable 1,300-member club ends up running a
  custom site + rezexpert + a partner society + Spreadshop, with visible seams.
- **A requirements source** — especially trips/courses and facility booking.
- **A "graduated DIY" prospect profile** — but note high switching costs; clubs
  that have already built and integrated their stack are likely late adopters.
