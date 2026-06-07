# Problems

## Club email announcement behaviour is unclear

Observed: 2026-06-05

Status: In progress / partially addressed by [iteration 024: Transactional email template redesign](../iterations/024-email-template-designs/plan.md). That plan preserves the current rule that replies go to the sender, not the group, and adds reply guidance to HTML member-message email; it is still implementing.

The current club email wording describes sending a message, but does not make clear that this email behaves like an announcement. Recipients can reply to the email, but the reply goes directly to the sender rather than back into Memba or out to other members.

This leaves room for confusion between one-way announcements and possible future discussion-style messages, where replies might be visible in Memba or notify subscribed members, a club, or a group.

Expected:

- The copy makes plain that the current club email is an announcement.
- Users understand that replies go to the sender, not to all members or an in-app discussion.
- The product language leaves room to distinguish announcements from discussion messages with different reply behaviour.

## Candidate resolution

Iteration 024 should address this by redesigning member-message emails around the v2 transactional email system.

Relevant acceptance criteria in [iteration 024](../iterations/024-email-template-designs/plan.md):

- Member-message HTML uses the v2 member-message pattern: group-led header, sender-to-members line, readable message body, reply guidance, and Memba-as-carrier footer.
- Member-message From, Reply-To, subject, provider metadata, and local-delivery fact recording continue to work.
- Member-message plain text remains exactly the sender's original body; the clarification is added in the HTML part for this iteration.

This should close the copy/expectation problem for outgoing club-message email once iteration 024 is delivered: the email should make clear that replies go to the sender, not to the whole group or to an in-app discussion.
