# Problems

## Club email announcement behaviour is unclear

Observed: 2026-06-05

Status: Resolved for current outgoing member-message email by [iteration 024: Transactional email template redesign](../iterations/024-email-template-designs/plan.md). The implemented member-message HTML now uses the v2 pattern with group-led context and explicit reply guidance that replies go to the sender, not to the group or an in-app discussion. Evidence: [iteration 024 implementation notes](../iterations/024-email-template-designs/implementation-notes.md) and `web/test/memba_web/controllers/postmark_webhook_controller_test.exs`.

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

This closed the copy/expectation problem for current outgoing club-message email: the HTML email makes clear that replies go to the sender, not to the whole group or to an in-app discussion.
