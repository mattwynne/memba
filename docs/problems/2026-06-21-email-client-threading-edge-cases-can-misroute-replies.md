# Problems

## Some email-client threading edge cases can keep replies out of the right conversation

Observed: 2026-06-21

Iteration 041 routes email replies by matching inbound `In-Reply-To` and `References` headers to Memba-stored outbound `Message-ID` values. That covers the normal email-client path, but review surfaced that real mail clients and providers can produce messy header variants that are not yet well evidenced with real-world samples.

Examples include folded headers, duplicate `References` headers, malformed or bare message ids, very long reference chains, provider-specific header shapes, comments or unusual whitespace, clients that omit `In-Reply-To`, and clients that rewrite or drop threading headers.

When Memba cannot recognize a same-club header match, it deliberately falls back to creating a new club-wide message rather than guessing by subject. That is safe, but from a member's point of view a valid reply from their email client could appear as a new message or fail to join the conversation they expected.

Expected:

- Replies from common mail clients reliably land in the conversation the member replied to.
- Header parsing is tolerant of ordinary real-world email formatting variations.
- If a reply cannot be matched safely, Memba avoids cross-conversation mistakes and gives members enough feedback to understand what happened.
