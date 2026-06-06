# Replacement copy draft

Task 003 draft copy for the public and member-facing pages reviewed in `copy-audit.md`.

This is a code-ready editorial draft only. It does not change routes, permissions, layouts, or behaviour. Later tasks should apply these strings in the existing source of truth and update tests that assert changed visible copy.

## Copy rules used

- Canadian English, with common Canadian `-ize` forms: organize, organizer, organization, organizing.
- Plain words and short sentences that scan on an iPad.
- Concrete next steps near every button and form.
- Clear consequences before sending a message to all current members.
- Inclusive group language: group, club, society, association, parent group, organizers.
- No unsupported customer claims, statistics, testimonials, or finished-product claims for unfinished workflows.
- No internal member-facing terms such as receipt groups, addressed members, or projected.

## Logged-out homepage `/`

Keep the route and layout structure. Replace the marketing claims about renewals and events with product copy that is true today.

| Surface | Draft replacement copy |
| --- | --- |
| Page title | `A simpler way to keep your group members informed` |
| Top nav CTA | `Request access` |
| Hero eyebrow | `Private member websites for volunteer-run groups` |
| Hero heading | `A simpler way to keep your group members informed.` |
| Hero body | `Memba helps small non-profit groups, clubs, societies, and associations share member messages in one private place.` |
| Primary CTA | `Request access for your group` |
| Secondary CTA | `See what members can do` |
| Support line | `Built for volunteer organizers, not full-time administrators.` |
| Mock club label | `Kootenay Mountaineering Club` |
| Mock club sublabel | `Private member space` |
| Mock badge | `Members only` |
| Mock note label | `Latest member message` |
| Mock note subject | `Saturday trail day` |
| Mock note body | `Meet at the trailhead at 9am. Bring gloves, lunch, and a thermos.` |
| Feature eyebrow | `Product` |
| Feature heading | `What Memba can help with today.` |
| Feature 1 heading | `A private place for members` |
| Feature 1 body | `Members sign in to read group messages and see member-only information away from the public internet.` |
| Feature 2 heading | `One message to current members` |
| Feature 2 body | `Write a note once. Memba sends it to everyone with a current membership in the group.` |
| Feature 3 heading | `Clear delivery details` |
| Feature 3 body | `After sending, check whether each member’s email is delivered, still sending, or not delivered.` |

Notes for implementation:

- Avoid "renewals" and "events" on the homepage until those workflows are visible product capabilities.
- Keep the Kootenay example because it is concrete, but the surrounding copy should make societies, associations, parent groups, and other small community groups feel included.

## Signed-in memberships homepage `/`

Keep `Your memberships` and `Your clubs`; they are plain and useful. Make the empty state more helpful.

| Surface | Draft replacement copy |
| --- | --- |
| Eyebrow | `Your memberships` |
| Heading | `Your clubs` |
| Body when memberships exist | `You’re a member of {club_count} {club_noun}. Choose a club below to open its member website.` |
| Club card label | `Current member` |
| Club card CTA | `Open club website` |
| Empty heading | `No clubs found for this email` |
| Empty body | `We can’t find any current club memberships for this email address. If you expected to see a group here, try the email address your group uses for you, or ask an organizer to check your membership.` |
| Staff card eyebrow | `Staff tools` |
| Staff card heading | `Memba staff area` |
| Staff card body | `Open the staff area for Memba operations.` |
| Staff card CTA | `Open staff area` |

## About `/about`

The page is already calm and trustworthy. Use broader community-group language and keep the company/contact wording substantively unchanged.

| Surface | Draft replacement copy |
| --- | --- |
| Eyebrow | `About Memba` |
| Heading | `Simple software for volunteer-run groups.` |
| Intro | `Memba helps small clubs, societies, and community groups keep member records clear and send important messages with confidence.` |
| Paragraph 1 | `Volunteer groups depend on people who give their time freely. Memba is designed to make their work calmer: fewer spreadsheets, fewer missed messages, and a private place for member information.` |
| Paragraph 2 | `The product is built by Red Donkey Technology Corp. We focus on simple, reliable tools for small organizations that need clarity more than clutter.` |
| Paragraph 3 | `If you would like to learn more about the company, visit donkey.red.` |

## Get started `/get-started`

Make the staff-review boundary feel safe rather than exclusive. Use "group" as the broad label, with "club" still acceptable in examples.

| Surface | Draft replacement copy |
| --- | --- |
| Eyebrow | `Request access` |
| Heading | `Ask us to set up Memba for your group.` |
| Intro | `We review each request before creating a group space, so Memba stays safe for members.` |
| Info card heading | `Want to use Memba with your club or group?` |
| Info card body | `Tell us a little about your group. Memba staff will review your request before any group, membership, or sign-in access is created.` |
| Bullet 1 | `Tell us who should be the first organizer.` |
| Bullet 2 | `Name the club, society, association, or group you want to bring onto Memba.` |
| Bullet 3 | `Share what you want Memba to help with.` |
| Signed-in requester note | `You’re signed in, so we’ll use these details for your request.` |
| Name label | `Your name` |
| Email label | `Email address` |
| Group name label | `Group or club name` |
| Note label | `What would you like Memba to help with?` |
| Note placeholder | `Example: We want one reliable way to email all current members.` |
| Submit button | `Request access` |
| Form privacy note | `We’ll use these details only to review your Memba request.` |

### Get-started acknowledgement

| Surface | Draft replacement copy |
| --- | --- |
| Eyebrow | `Request received` |
| Heading | `Thanks — we’ll read your request.` |
| Body | `We’ll email you if Memba looks like a good fit for your group. Nothing has been created yet: no group space, membership, or sign-in access.` |

## Sign in `/auth`

Explain magic-link sign-in without using the term "magic link" in member-facing copy.

| Surface | Draft replacement copy |
| --- | --- |
| Eyebrow | `Sign in` |
| Heading | `Sign in with your email.` |
| Intro | `Use the email address your club or group has for you. We’ll email you a private sign-in link.` |
| Email label | `Email address` |
| Email placeholder | `you@example.com` |
| Submit button | `Email me a sign-in link` |
| Privacy microcopy | `To protect member privacy, this page does not say whether that email address is on a club list.` |
| Invalid/expired link flash | `That sign-in link is no longer valid. Please ask for a new sign-in link.` |

## Check email `/auth/check-email`

Keep the neutral response, but make the next step concrete.

| Surface | Draft replacement copy |
| --- | --- |
| Eyebrow | `Check your email` |
| Heading | `Check your email for the sign-in link.` |
| Neutral notice | `If that email address can sign in to Memba, the sign-in email is on its way.` |
| Instruction card body | `Open the email on this iPad and tap the sign-in button. The link works once and expires in 15 minutes. If it does not arrive, check your junk mail or ask for another link.` |
| Retry link | `Ask for another sign-in link` |

## Public club page

Keep `Welcome to {club_name}`. Make the sign-in requirement and privacy boundary explicit.

| Surface | Draft replacement copy |
| --- | --- |
| Eyebrow | `Member space` |
| Heading | `Welcome to {club_name}` |
| Body | `Sign in with the email address {club_name} has for you to read member messages and see the current member list. Member-only details stay private.` |
| Primary CTA | `Email me a sign-in link` |
| Secondary CTA | `Back to Memba` |
| Side card heading | `For members` |
| Side item 1 | `Read messages from your group in one shared place.` |
| Side item 2 | `See the current member list.` |
| Side item 3 | `Member-only details stay behind sign-in.` |

## Member club home / dashboard

Keep the existing jobs on one page: read messages, send a message, and see current members. Be careful not to imply guaranteed email delivery.

| Surface | Draft replacement copy |
| --- | --- |
| Hero body | `Read recent club messages, send a note to all current members, and see who is on the member list.` |
| Send-message card heading | `Send a message to the club?` |
| Send-message card body | `Messages go to all current members.` |
| Send-message CTA | `Send club message` |
| Inbound email eyebrow | `Prefer email?` |
| Inbound email body | `You can also send a club-wide message to {inbound_email_address}.` |
| Messages heading | `Recent club messages` |
| Empty messages heading | `No club messages yet` |
| Empty messages body | `When a member sends a message, it will appear here.` |
| Empty messages CTA | `Send the first message` |
| Members heading | `Current members` |
| First-member heading | `You’re the first member listed` |
| First-member body | `As members are added, you’ll see them here.` |
| Active-member count | `{count} current {member_noun}` |
| Active-member body | `Memba sends club-wide messages to everyone with a current membership.` |

## Member compose `/messages/new`

This is the highest-risk page because one submit sends email to all current members. Keep the warning close to the form and button.

| Surface | Draft replacement copy |
| --- | --- |
| Back link | `Club home` |
| Eyebrow | `New message` |
| Heading | `Send a message to all current members` |
| Selected club label | `{club_name}` |
| Recipient warning | `Before you send: this message will be emailed to all {active_member_count_summary} of {club_name}. There is no list to pick.` |
| Inbound email body | `Prefer email? You can also send a club-wide message to {inbound_email_address}.` |
| Sender label | `From` |
| Sender helper | `Sending as yourself` |
| Subject label | `Subject` |
| Subject placeholder | `Example: Saturday trail day` |
| Body label | `Message` |
| Body placeholder | `Write the message members should receive.` |
| Submit button | `Send to all current members` |
| Cancel link | `Cancel` |

### Compose success state

| Surface | Draft replacement copy |
| --- | --- |
| Eyebrow | `Club message` |
| Heading | `Your message is being sent.` |
| Summary | `Memba is sending your message to {active_member_count_summary}. You can check delivery on the message page.` |
| Primary link | `Check delivery` |
| Secondary link | `Send another message` |
| Back link | `Back to club home` |

### Compose error state

| Surface | Draft replacement copy |
| --- | --- |
| Eyebrow | `Club message` |
| Heading | `Your message was not sent.` |
| Summary | `No one received this message. Please try again. If it still fails, ask a group organizer to contact Memba.` |
| Retry button | `Try again` |
| Back link | `Back to club home` |

## Member message detail `/messages/:message_id`

Use "delivery" language throughout the visible UI. Internal names can stay as they are unless a later code task chooses to rename them deliberately.

| Surface | Draft replacement copy |
| --- | --- |
| Back link | `Club home` |
| Eyebrow | `Club message` |
| Meta line | `From {sender_name} · sent to {member_count} {member_noun}` |
| Summary section heading | `Message delivery` |
| Summary count pill | `{member_count} {member_noun}` |
| Detail section heading | `Members by delivery status` |
| Detail section helper | `Delivered messages are shown first. Messages still sending or not delivered are grouped below.` |
| Empty delivery state | `Memba has not prepared the delivery list for this message yet. Check again in a moment.` |

### Member-facing delivery status labels and descriptions

Keep the current simple member-facing labels that implement ADR 0006’s simplification intent, with clearer descriptions.

| Status | Label | Description |
| --- | --- | --- |
| `delivered` | `Delivered` | `Email delivered` |
| `sent` | `Sending` | `Email still sending` |
| `delivery problem` | `Delivery problem` | `Email not delivered` |

Do not show these terms to members:

- `receipt`
- `receipt groups`
- `addressed members`
- `projected`
- provider IDs, provider reasons, or provider delivery jargon
- `opened` / `not opened`

## Terms `/terms` and privacy `/privacy`

Leave the policy wording substantively unchanged for this iteration. The current headings and body copy are short and readable. Do not add a public Memba email address or new legal/privacy promises in this copy pass.

If shared navigation labels change, the terms and privacy pages may inherit those chrome changes only.

## Shared layout and connection copy

| Surface | Draft replacement copy |
| --- | --- |
| Public nav `Get started` label | `Request access` |
| Public nav `Sign in` label | `Sign in` |
| Club identity text | `Signed in as {email}` |
| Club sign-out button | `Sign out` |
| Club footer | `Powered by Memba` |
| Browser connection title | `We can’t connect right now` |
| Browser connection body | `Trying to reconnect` |
| Server connection title | `Something went wrong` |
| Server connection body | `Trying to reconnect` |

The connection-copy edits are optional. They are visible to LiveView users, but lower priority than the page and delivery-status copy above.
