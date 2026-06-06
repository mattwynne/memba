# Notes: white-labelling — branding surfaces and dials

Date: 2026-06-06

How much should a club member see "Memba" versus just "their club"? This note
records the heuristics we use to decide, surface by surface.

## The governing principle

> **Memba is ambient inside a club, and steps forward only between clubs.**

Memba is never *hidden* — the `memba.io` domain is in every web address and email
address, and the brand shows up on sign-in screens and in footers. Trying to
conceal that is a losing game, and a consistent quiet presence actually builds
trust (it's the same name on the login screen, the email footer, and the URL).

But inside a club's experience, Memba stays in the **background**: a footer line,
a domain, a trust mark — not a thing the member is asked to think about. It only
steps into the **foreground** in the connective tissue that is *inherently*
cross-club: their account, "your clubs", their identity that spans more than one
club. This keeps the white-label instinct ("it's basically our club's website")
from cannibalising the social/network vision ("I'm in this club and that club"),
and vice versa.

It mirrors how Substack works: every newsletter carries a quiet Substack footer
and a `.substack.com` domain, but you read *the newsletter* — until you open your
account and find you're subscribed to six newsletters *on* Substack.

When unsure how prominent Memba should be on a new surface, ask: **is this
experience about being in one club, or about belonging across clubs?** Within →
club-dominant, Memba in the background. Across → Memba in the foreground.

## The dial, surface by surface

From *most club / least Memba* to *most Memba*:

| Surface | Who sees it | Dial | Why |
| --- | --- | --- | --- |
| Public club page | Visitors | Club-dominant; quiet Memba footer | The club's shop window. Someone googling the club must feel they found the club. |
| Member club home | Signed-in members | Club-dominant chrome; Memba footer + account corner | Their day-to-day homepage. Should feel like the club. |
| Sign-in screen | Anyone signing in | Club-led, but Memba visibly present as the trust mark | Lives on a `memba.io` URL; the consistent Memba mark is what reassures "this is the real sign-in". |
| Onboarding / approval emails | New / joining members | Club-dominant, warm; Memba in footer | They're being welcomed *to the club*, not to Memba. |
| Sign-in link emails | Members signing in | From the club; Memba in the trust footer | Transactional. Confusion here reads as "is this phishing?" — a consistent Memba footer helps. |
| Announcement & list/channel emails | All members | Club name, "via Memba"; Memba in footer | Club is unmistakably the author; Memba is unmistakably just the postal service. |
| Account / social / "my clubs" layer | Members, deliberately | Memba in the foreground | The only place the cross-club identity can live. Memba *should* lead here. |

The Memba footer / domain / sign-in mark are the *ambient* presence — present on
every surface, asking for no attention. The "dial" is really how far Memba is
allowed to move *forward* of that baseline on a given surface.

## Email "via" pattern

For club emails, the From reads:

```
From: Kootenay Mountaineering Club via Memba <kmc@memba.io>
Subject: July trips schedule
```

The member's eye lands on the club — no confusion. Memba is named quietly as the
carrier. This is the standard mailing-list dual-brand (Google Groups, Mailman,
Substack), and it *reduces* confusion and spam-flagging rather than causing it.

### Why the address domain is `memba.io`, not the club's domain

The `From` address domain must be one Memba controls, so Memba can DKIM-sign and
DMARC-align cleanly. The moment a club's own domain (`news@theclub.org`) goes in
the `From` address, Memba inherits that club's DNS and DMARC problems — the exact
deliverability pain we want to avoid.

So:

- **Display name** carries the club ("Kootenay Mountaineering Club via Memba").
- **Address** carries Memba (`kmc@memba.io`).
- A club's own domain in `From` is a **premium upgrade** (per-club DKIM setup),
  never the default.

## Worked examples

- *A visitor lands on the public page* → club logo, club colours, club copy, with
  a quiet "powered by Memba" footer. The club leads; Memba is the watermark.
  (Background.)
- *A member signs in and reads an announcement* → the page and the email both
  read as the club, each carrying a small Memba footer. The email is
  `Club via Memba`. (Background.)
- *A member opens their account menu* → "Your clubs", profile, identity. Memba
  steps forward; this is expected and reassuring here. (Foreground.)
- *A member discovers they belong to two clubs* → this is a Memba experience by
  definition; lean into it. (Foreground.)

## Related

- `idea.md` — the original tension: "just their club's homepage" vs the
  AT-Protocol social/network vision.
- `docs/problem-domain-terms.md` — "Public club page", "Member club home",
  "Club slug", and the email-delivery terms.
