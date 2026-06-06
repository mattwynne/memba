# Copy audit: public-facing pages for an 80-year-old community member with an iPad

Date: 2026-06-06

## Persona lens

Core reader: an 80-year-old mountaineer using an iPad. They may be competent, experienced, and impatient with fuss, but they may also have reduced eyesight, finger accuracy, memory for unfamiliar UI terms, and tolerance for ambiguous digital workflows. They want to know: "Is this for my group? Can I trust it? What happens if I tap this? Will I accidentally email everyone?"

Broader audience: Memba should feel applicable to any small non-profit community organizing group, including incorporated societies and less formal groups such as a school parents association. Copy can use clubs as a concrete example, but should not make Memba feel only for outdoor clubs.

Copy principles for this iteration:

- Use Canadian English: Canadian spellings where relevant, with common Canadian `-ize` forms such as "organize", "organizer", "organization", and "organizing".
- Use plain, concrete words.
- Prefer human group terms such as "members", "committee", "organizers", and "your group" over software terms.
- Explain consequences before action, especially before sending messages.
- Use reassuring microcopy near forms and buttons.
- Avoid vague or cute lines when a user is trying to complete a task.
- Make CTAs say what happens next.
- Keep sentences short enough to scan on iPad.

## Pages reviewed

- Logged-out homepage: `/`
- Signed-in memberships homepage: `/`
- About: `/about`
- Get started request page and acknowledgement: `/get-started`
- Sign in and check-email: `/auth`, `/auth/check-email`
- Public club page: club root by `club_id` or club subdomain
- Member club home/dashboard
- Member compose message page, success state, and error state: `/messages/new`
- Member message detail and receipt status page: `/messages/:message_id`
- Terms and privacy: `/terms`, `/privacy`
- Shared public/club layout navigation and flash reconnect copy

Admin/staff pages were not treated as core public-facing copy, although some wording there may also need a later operations-copy pass.

## Overall diagnosis

The current copy is warm and calm, but it was written for a confident early adopter more than for an older club member on an iPad. The biggest gaps are not grammar; they are clarity, trust, and consequence-setting.

What works:

- The voice is friendly and low-pressure.
- The homepage understands volunteer fatigue.
- The member messaging surfaces already try to explain who will receive a message.
- The get-started flow makes the staff-review boundary clear.

What needs work:

- The homepage is too club-specific in places and promises future capabilities (events and renewals) that may not be live yet. This risks a trust break.
- Several CTAs are generic: "Get started", "See it in action", "Sign in to continue".
- Some lines are clever but not concrete enough for a task-focused older reader: "Three things, done quietly", "What the club's been saying, and who's around right now".
- Message delivery language uses terms such as "receipt", "delivery problems", "addressed members", and "projected" that may not match the reader's vocabulary.
- Error and acknowledgement copy often tells the truth but does not say what to do next in human terms.
- Legal pages are short and readable, but could better reassure clubs about member data, email sending, and contact details.

## Page-by-page findings

### Logged-out homepage `/`

Current hero:

- "Volunteering shouldn’t feel like work."
- "Membership software for clubs and societies run by volunteers. Renewals, events, and messages — in one place."

Findings:

- Strong emotional idea, but the subheadline overclaims if renewals/events are not production-ready.
- "Membership software" may be abstract for a club committee member. "A simple private website for your club members" may be clearer for the current product.
- "See it in action →" jumps to feature cards rather than a real demo; for an iPad user, this may feel misleading.
- Feature cards should match today's product, not the future roadmap.

Recommended direction:

- Lead with the vision: help volunteer-run community groups keep members informed and organized without heavy administration.
- Use examples that are true today, such as private member messages and member-only spaces, rather than presenting future renewals/events as already available.
- Replace generic CTA with "Ask about using Memba" or "Request access for your group".
- Use a secondary CTA such as "See what members can do".
- Make feature cards concrete: private club page, send one message to all current members, see who received it.

Example hero alternatives:

1. "A simpler way to keep your group members informed" — clear, current, member-message focused.
2. "Member messages without the mailing-list mess" — stronger pain-led version.
3. "A private member website for volunteer-run groups" — broad, concrete category.

### Signed-in memberships homepage `/`

Findings:

- "Your memberships" and "Your clubs" are clear.
- "We did not find any active club memberships for this email address" is accurate but stiff.
- Empty state should explain what to do: check a different email, ask a club organizer, or contact Memba/support.
- Staff access card repeats "Memba staff" three times.

Recommended direction:

- Rewrite the empty state as: "We can't find any current club memberships for this email address. If you expected to see a group here, try the email address your group uses for you, or ask an organizer to check your membership."

### About `/about`

Findings:

- Clear and trustworthy.
- Use Canadian English consistently: prefer "small organizations", "organizers", and "organizing" for this product copy.
- The page would be stronger if it connected the mission to older volunteer committees and community groups: less admin, fewer missed notices, member data treated carefully.

Recommended direction:

- Keep it concise, but add a concrete line about private club communication and careful member records.

### Get started `/get-started`

Findings:

- The staff-review boundary is good and important for trust/anti-abuse.
- "Memba is invite-only right now" may sound exclusive or startup-ish. Older club volunteers may prefer "We review each club before setting it up."
- "Short note" is vague. Use a label that asks a real question.
- The acknowledgement says what does not happen, which is good, but it could say what happens next.

Recommended direction:

- Headline: "Ask us to set up Memba for your group"
- Subheadline: "We review each request before creating a group space, so Memba stays safe for members."
- Field label: "What would you like Memba to help with?"
- Acknowledgement: "We’ll read your request and email you if Memba looks like a good fit. Nothing has been created yet."

### Sign in `/auth` and `/auth/check-email`

Findings:

- Magic-link auth is simple but older users may not understand "link expires soon and can only be used once" without a next step.
- "For your privacy, the response is the same whether or not we recognize the email address" is accurate but may raise concern.
- "Sign in to your club" can be confusing if they belong to multiple clubs.

Recommended direction:

- Use "Email me a sign-in link" consistently.
- Add reassurance: "Use the email address your club has for you."
- Explain the privacy line more gently: "To protect member privacy, we won't say on this page whether that email is on a club list."
- Check-email page should say: "Open the email on this iPad and tap the sign-in button."

### Public club page

Findings:

- Good privacy signal: "Member-only details stay behind sign-in."
- "keep track of who belongs" is slightly odd for a regular member and may imply surveillance/admin.
- "Sign in to continue" is generic.

Recommended direction:

- Headline can stay: "Welcome to {club}"
- Body: "Sign in with the email address your club has for you to read member messages and see the current member list."
- CTA: "Email me a sign-in link" or "Sign in with email".

### Member club home/dashboard

Findings:

- "What the club's been saying, and who's around right now" is friendly but a little vague.
- "Got something to share?" is good.
- "Write once — every active member gets it" is strong and clear.
- "They'll all receive your messages" near active members is clear but should be careful: delivery can fail; better "Memba will send your messages to them".

Recommended direction:

- Hero body: "Read recent club messages, send a note to all current members, and see who is on the member list."
- Empty state: "No club messages yet" / "When a member sends a message, it will appear here."
- Consider adding a simple warning near send-message CTA: "Messages go to all current members."

### Member compose `/messages/new`

Findings:

- This page is the highest-risk copy because one tap can email everyone.
- Recipient summary is good: "There’s no list to pick — everyone with a current membership gets it."
- Button "Send to all members" is clear.
- Placeholder "What's this about?" is casual; older users may expect "Subject line".
- Error copy says contact support but gives no contact route.
- Success copy "watch it land" is metaphorical; delivery may be asynchronous and partial.

Recommended direction:

- Strengthen pre-send reassurance: "Before you send: this message will be emailed to all current members of {club}."
- Subject placeholder: "Example: Saturday trail day"
- Message placeholder: "Write the message members should receive."
- Success: "Memba is sending your message to all current members. You can check delivery on the message page."
- Error: "Your message was not sent. Please try again. If it still fails, contact one of your group's organizers."

### Member message detail `/messages/:message_id`

Findings:

- "Who got this" is excellent plain-English copy.
- The page then switches into technical/reporting language: "Everyone, by status", "Receipt groups are ordered by delivered, sending, then delivery problems", "No addressed members are projected".
- "Receipt" may sound like payment. Use "delivery" or "message delivery".
- Status labels and descriptions should be reviewed in the presentation layer too, not only the template.

Recommended direction:

- Rename section to "Delivery details" or "Message delivery".
- Replace "Everyone, by status" with "Members by delivery status".
- Replace ordering explanation with "Delivered messages are shown first. Messages still sending or not delivered are grouped below."
- Replace empty state with "Memba has not prepared the delivery list for this message yet. Check again in a moment."

### Terms and privacy

Findings:

- These pages are concise and readable.
- They may be too thin for trust during early customer review.
- Contact through `donkey.red` is indirect; if `hello@memba.io` is available, direct contact would reassure visitors.

Recommended direction:

- Leave privacy/terms policy wording substantively unchanged for this iteration.
- Do not add a broadly published public Memba email address as part of this copy pass; keep `/get-started` as the primary request/contact path.

## Prioritised iteration scope

High priority for one focused iteration:

1. Align homepage claims with the broader vision for small non-profit community organizing groups while keeping examples honest about what Memba can do today.
2. Rewrite primary public CTAs around the next concrete action.
3. Make get-started request copy warmer and clearer.
4. Add older-reader reassurance to sign-in/check-email.
5. Clarify member compose and delivery-status copy, especially consequences and next steps.
6. Replace technical terms in member-facing receipt/status copy.
7. Add a manual iPad copy review pass.

Leave for later:

- Full brand positioning exercise.
- Customer testimonials or proof, because none are currently present in the repository.
- Legal-policy expansion beyond small plain-language improvements unless Matt wants legal review.
- Staff/admin operations copy.
- Accessibility/layout changes beyond copy-driven button labels and help text.
