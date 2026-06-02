# Problem domain terms

This glossary records Memba’s problem-domain terms: the words we use when talking to or about people using Memba. It is not a specification; rules and examples belong in the acceptance tests.

## Principles

- Use terms a person using Memba would understand.
- Use one term for one concept.
- Keep problem-domain language distinct from solution-domain language.
- Avoid solution-domain terms here unless they are also meaningful to people using Memba.
- Prefer precise role names over generic words like “admin”, “staff”, or “user”.

## Preferred terms

| Term | Meaning |
| --- | --- |
| Person | A human known to Memba. |
| Club | An organisation using Memba. |
| Club member | A person who belongs to a club. Use “member” when the club context is clear. |
| Memba staff | A person acting on behalf of Memba. This is the term for everyone currently using the Memba staff area. |
| Visitor | Someone who is not signed in. |
| Public | Available without signing in. |
| Public club page | The page visitors see for a club. Prefer this over “club marketing page”. |
| Member club home | The home page a club member sees after signing in. |
| Memba staff home | The home page Memba staff see after signing in. |
| Memba staff area | The part of Memba used by Memba staff. |
| Sign-in form | The form where someone asks Memba to email them a sign-in link. |
| Sign-in link | The emailed link someone uses to sign in. |
| Primary email address | The address Memba normally uses to email a person. |
| Alternate email address | Another address Memba knows for the same person. |
| Club slug | The short name used in a club’s web address. |
| Message | Something one person sends to other people. |
| Club message | A message sent to members of a club. |
| Sender | The person who sends a message. |
| Email delivery | The sending of a message by email to one person. An email delivery has details such as who it is for and whether there is a delivery problem. |

## Terms to avoid or replace

| Avoid | Use instead |
| --- | --- |
| admin | Memba staff, Memba staff area |
| staff | Memba staff |
| operator | Memba staff |
| user | Person, visitor, club member, or Memba staff |
| magic link | Sign-in link |
| login / log in | Sign in |
| club marketing page | Public club page |
| staff-only homepage | Memba staff home |
