# Problems

## Club email arrives without surrounding context or useful links

Observed: 2026-06-01

Status: In progress / partially addressed by [iteration 024: Transactional email template redesign](../iterations/024-email-template-designs/plan.md). That plan covers group-led member-message email context, reply guidance, and a Memba-as-carrier footer, but it is still implementing and does not appear to cover all requested links or optional slugged subjects.

When a member receives an email from a club, the message arrives without enough surrounding context to understand where it came from or what to do next.

The email should be designed as a club communication, not just raw message content. It should include helpful context such as:

- which club sent the message;
- an option for club moderators to include the club slug in the subject line, for example `[kmc] Trip planning night`;
- a link to the club's website;
- a link to the online forum or message page where the message appears;
- any other navigation that helps the recipient orient themselves and continue the conversation.

Expected:

- A recipient can tell at a glance which club the email is from.
- Club moderators can choose whether outgoing club-message email subjects include the club slug, for example `[kmc]`.
- The email provides clear links back to the club and to the relevant online context.
- The email template supports club-specific context instead of sending an isolated message body.
