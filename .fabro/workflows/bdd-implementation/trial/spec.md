# One-scenario historical rehearsal

Implement only the active example "Alice's older edit requires confirmation of the newer name" in acceptance-tests/features/member_profile.feature. Its rule and wording come from approved plan c5402f0bd8fc99587c8b220b51643ecd650377eb. Product source starts at delivered pre-068 commit 5645fb62d50892b763f419f4b08e5d22b9a0e4bd. The other historical examples remain pending; do not implement the whole iteration.

Use Memba's real Membership command preparation, dispatch, aggregate/events and projected queries. Step definitions must exercise those boundaries, not implement a fake Person/name store in the test context. Existing step discovery loads domain Elixir definitions; this is not a browser/JavaScript task. Add focused domain unit tests where useful.

A stale attempt must not replace the current name. Compare the expected name atomically on the write side. Rejection leaves the actual name unchanged; confirmation explicitly based on the latest displayed name can replace it. A later unseen change must still be rejected. An identical normalized target is an eventless no-op.

Preserve self-only authority: use the trusted Person actor; do not add staff/arbitrary-Person rename. Normalize whitespace, reject blank or more than 100 Unicode graphemes, and do not restrict scripts or punctuation. Preserve Person identity, email state, memberships, historic events and replay compatibility. Do not create migrations, new dependencies, a UI, email changes, photo support or a generic conflict framework for this rehearsal.

Keep the agreed feature/assertions and all other historical pending examples untouched. Refactor only where worthwhile using the project's CQRS/event-sourcing/responsibility and idiomatic-Elixir guidance. Finish with the actual selected scenario, relevant units, ordinary full dev check and one fresh whole-change review. No publishing, deployment or merging replay product changes into main.
