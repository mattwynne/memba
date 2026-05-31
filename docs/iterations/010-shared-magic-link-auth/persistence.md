# Authentication persistence notes

Task: `002 Add persistence for authentication:`

## Tables

- `auth_magic_tokens` stores magic-link request state:
  - `email` for the normalized recipient address the later auth context will use,
  - `token_hash` as unique `bytea` storage for the server-side token digest,
  - `expires_at` for the 15-minute validity window,
  - `consumed_at` for single-use token consumption,
  - regular `inserted_at` and `updated_at` timestamps.

The table intentionally has no plaintext token column.

## Identity/session table decision

No separate identity or session-support table is added for this slice. Browser
sessions are already cookie-backed, and iteration 010 authorization can be
derived from the signed-in email plus Membership query APIs. If later audit or
explicit staff/user management needs arise, a dedicated identity table can be
added without changing the magic-token storage shape.
