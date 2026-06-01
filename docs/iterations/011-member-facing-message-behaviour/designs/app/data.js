// Memba — Kootenay Mountaineering Club sample data
// Avatar tints drawn from the forest scale only.
const AV = ["#a6c0b1", "#7aa08c", "#c4d3c9", "#d2e0d7", "#b3b9b4", "#9bb6a6"];

const ME = { id: 1, name: "Lou Thirgood", first: "Lou", initials: "LT", sub: "Member since 1974", role: "Honorary life member", committee: true };

const MEMBERS = [
  { id: 1,  first: "Lou",     last: "Thirgood",  initials: "LT", role: "Honorary life", since: 1974, status: "active",   email: "lou@kootenay-alpine.org",   phone: "250 555 0184", town: "Nelson" },
  { id: 2,  first: "Eira",    last: "Sandhu",    initials: "ES", role: "President",      since: 1998, status: "active",   email: "eira@kootenay-alpine.org",  phone: "250 555 0110", town: "Nelson" },
  { id: 3,  first: "Priya",   last: "Dholakia",  initials: "PD", role: "Secretary",      since: 2005, status: "active",   email: "priya.d@gmail.com",         phone: "250 555 0143", town: "Castlegar" },
  { id: 4,  first: "Jamie",   last: "Mott",      initials: "JM", role: "Treasurer",      since: 2011, status: "active",   email: "jmott@telus.net",           phone: "250 555 0172", town: "Rossland" },
  { id: 5,  first: "Hannah",  last: "Sørensen",  initials: "HS", role: "Trip leader",    since: 2009, status: "active",   email: "h.sorensen@hotmail.com",    phone: "250 555 0199", town: "Nelson" },
  { id: 6,  first: "Ravi",    last: "Rai",       initials: "RR", role: "Trip leader",    since: 2014, status: "due-soon", email: "ravi.rai@outlook.com",      phone: "250 555 0128", town: "Trail" },
  { id: 7,  first: "Birgit",  last: "Lund",      initials: "BL", role: "Member",         since: 2019, status: "active",   email: "birgit.lund@gmail.com",     phone: "250 555 0163", town: "Nelson" },
  { id: 8,  first: "Tomas",   last: "Okonkwo",   initials: "TO", role: "Member",         since: 2021, status: "active",   email: "tomas.o@proton.me",         phone: "250 555 0117", town: "Castlegar" },
  { id: 9,  first: "Maggie",  last: "Friesen",   initials: "MF", role: "Member",         since: 1987, status: "active",   email: "mfriesen@shaw.ca",          phone: "250 555 0151", town: "Kaslo" },
  { id: 10, first: "Dewi",    last: "Pugh",      initials: "DP", role: "Member",         since: 2022, status: "due-soon", email: "dewi.pugh@hotmail.com",     phone: "250 555 0188", town: "Nelson" },
  { id: 11, first: "Sam",     last: "Achterberg",initials: "SA", role: "Member",         since: 2016, status: "active",   email: "sam.a@telus.net",           phone: "250 555 0134", town: "Rossland" },
  { id: 12, first: "Noor",    last: "Haddad",    initials: "NH", role: "Member",         since: 2020, status: "active",   email: "noor.haddad@gmail.com",     phone: "250 555 0109", town: "Nelson" },
  { id: 13, first: "Glen",    last: "Petrov",    initials: "GP", role: "Member",         since: 2003, status: "lapsed",   email: "gpetrov@hotmail.com",       phone: "250 555 0192", town: "Salmo" },
  { id: 14, first: "Aroha",   last: "Wikaira",   initials: "AW", role: "Member",         since: 2023, status: "active",   email: "aroha.w@gmail.com",         phone: "250 555 0175", town: "Nelson" },
  { id: 15, first: "Connor",  last: "Quayle",    initials: "CQ", role: "Member",         since: 2018, status: "active",   email: "connor.q@shaw.ca",          phone: "250 555 0146", town: "Trail" },
  { id: 16, first: "Yuki",    last: "Tan",       initials: "YT", role: "Member",         since: 2024, status: "active",   email: "yuki.tan@outlook.com",      phone: "250 555 0121", town: "Castlegar" },
  { id: 17, first: "Marta",   last: "Basa",      initials: "MB", role: "Member",         since: 2012, status: "active",   email: "marta.basa@gmail.com",      phone: "250 555 0158", town: "Nelson" },
  { id: 18, first: "Errol",   last: "Vance",     initials: "EV", role: "Member",         since: 1995, status: "due-soon", email: "evance@telus.net",          phone: "250 555 0137", town: "Kaslo" },
];
MEMBERS.forEach((m, i) => { m.av = AV[i % AV.length]; m.name = m.first + " " + m.last; });

const TRIPS = [
  { id: 1, month: "Jun", day: 14, year: 2026, title: "Kokanee Glacier — Gibson Lake loop", when: "Sat 14 Jun, 06:30", leader: "Hannah Sørensen", duration: "7 hours", grade: "Moderate", dist: "14 km · 600 m gain",
    summary: "An alpine loop past the old cabins to the glacier toe. Boots, layers, lunch.",
    detail: "Meet at the clubroom for 06:30 — we'll convoy up the Kokanee Glacier road. Easy-to-moderate pace, well-known to most regulars and a good first big day of the season. Snow lingers on the upper traverse, so bring poles. Back at the cars by mid-afternoon.",
    attending: 6, capacity: 8, roster: [1, 5, 7, 12, 14, 16] },
  { id: 2, month: "Jun", day: 21, year: 2026, title: "Gimli Ridge scramble — Valhallas", when: "Sun 21 Jun, 05:30", leader: "Ravi Rai", duration: "9 hours", grade: "Hard", dist: "11 km · 900 m gain",
    summary: "Classic granite ridge in the Valhallas. Scrambling experience needed.",
    detail: "A long day on superb rock. This is a proper scramble — comfort on exposed third-class ground is essential, and a helmet is required. We'll cap numbers low and pair newer members with leaders. Early start to beat afternoon weather.",
    attending: 5, capacity: 6, roster: [2, 6, 11, 15, 17] },
  { id: 3, month: "Jun", day: 28, year: 2026, title: "Idaho Peak wildflowers — family day", when: "Sat 28 Jun, 09:00", leader: "Maggie Friesen", duration: "4 hours", grade: "Easy", dist: "6 km · 250 m gain",
    summary: "A gentle walk through the meadows above Sandon. Children welcome.",
    detail: "One of the great easy days in the Slocan. The old lookout road climbs gently through some of the best wildflower meadows in the province. Suitable for families and newer members. Tea at the top if the weather holds.",
    attending: 11, capacity: 20, roster: [3, 4, 8, 9, 10, 13, 14, 16, 17, 18, 7] },
  { id: 4, month: "Jul", day: 5,  year: 2026, title: "Mount Brennan — Lyle Creek approach", when: "Sat 5 Jul, 05:00", leader: "Eira Sandhu", duration: "10 hours", grade: "Hard", dist: "16 km · 1,400 m gain",
    summary: "A big summit day above Retallack. Strong hikers only.",
    detail: "The full Brennan day — a long approach, a sustained climb, and a summit with one of the finest views in the Kootenays. Strong, fit hikers only; we'll move steadily all day. Bring two litres minimum and an early night beforehand.",
    attending: 4, capacity: 6, roster: [2, 5, 11, 15] },
  { id: 5, month: "Jul", day: 12, year: 2026, title: "Pulpit Rock evening — after-work walk", when: "Wed 12 Jul, 18:00", leader: "Tomas Okonkwo", duration: "2 hours", grade: "Easy", dist: "5 km · 350 m gain",
    summary: "A quick climb above town for the sunset over the lake.",
    detail: "Our regular midweek leg-stretcher. Up to the bench at Pulpit Rock for the light on Kootenay Lake, then down before dark. No sign-up needed for regulars — just turn up at the trailhead.",
    attending: 9, capacity: 25, roster: [1, 8, 10, 12, 14, 16, 17, 7, 4] },
];

// Two sent broadcasts with delivery tracking, then ordinary thread messages.
const MESSAGES = [
  { id: 101, kind: "broadcast", who: "Eira Sandhu", initials: "ES", colour: AV[1], when: "2 days ago",
    subject: "AGM is on Sat 12 July — tea provided",
    body: "A reminder that this year's AGM is at the clubroom from 14:00. We'll vote on next year's trip programme and the membership-fee review. Tea, biscuits, the usual. Do come — quorum matters.",
    audience: "All members", stats: { sent: 198, delivered: 191, opened: 142, bounced: 4, spam: 1 },
    recipients: [
      { id: 5,  status: "opened",    when: "opened 2h ago" },
      { id: 12, status: "opened",    when: "opened 5h ago" },
      { id: 9,  status: "delivered", when: "delivered" },
      { id: 13, status: "bounced",   when: "mailbox full" },
      { id: 6,  status: "delivered", when: "delivered" },
      { id: 18, status: "opened",    when: "opened 1d ago" },
      { id: 8,  status: "spam",      when: "marked spam" },
      { id: 16, status: "delivered", when: "delivered" },
    ] },
  { id: 102, kind: "broadcast", who: "Jamie Mott", initials: "JM", colour: AV[3], when: "3 weeks ago",
    subject: "Renewals are open — £40 for 2026–27",
    body: "Membership renewals for the coming year are open. It's £40 for the full year, £20 concession, and family rates as before. You can renew from your membership page in a couple of taps. Thank you for keeping the club running.",
    audience: "Renewing soon (24)", stats: { sent: 24, delivered: 24, opened: 19, bounced: 0, spam: 0 },
    recipients: [
      { id: 6,  status: "opened",    when: "opened 3w ago" },
      { id: 10, status: "opened",    when: "opened 3w ago" },
      { id: 18, status: "delivered", when: "delivered" },
    ] },
  { id: 103, kind: "thread", who: "Priya Dholakia", initials: "PD", colour: AV[2], when: "1 week ago",
    subject: "Gimli Ridge — helmets and a low cap this year",
    body: "For everyone signed up to Gimli: it's a scramble, not a hike. Helmets are required and we're keeping numbers to six. If you're newer, have a word with Ravi first and we'll pair you up." },
  { id: 104, kind: "thread", who: "Memba", initials: "M", colour: AV[4], when: "3 weeks ago",
    subject: "Your renewal receipt",
    body: "Thanks, Lou. £40 received for the 2026–27 year. Your waiver is on file through 31 March 2027." },
];

Object.assign(window, { AV, ME, MEMBERS, TRIPS, MESSAGES });
