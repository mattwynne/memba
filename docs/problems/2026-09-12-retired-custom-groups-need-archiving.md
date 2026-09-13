# Problems

## Retired custom groups need an archive lifecycle

Observed: 2026-09-12

Status: Deferred during discovery for custom club groups. No implementation iteration assigned.

A committee or working group may finish its work. The first custom-group slice has no way to retire that group, so it will remain in the club's group list even when it is no longer used.

Why it matters:

- Obsolete groups can clutter the list and confuse members about where to send messages.
- Deleting a group would risk losing useful conversation history and context.

Expected:

- Prefer archiving over deleting a custom group when it is no longer needed.
- Decide archive permissions, list visibility, historical access, inbound email handling, and restoration behaviour before planning delivery. None of these details is agreed yet.

Scope boundary:

- Archiving and deletion are out of scope for the first custom-group slice.
- The earlier suggestion to archive automatically when the last member leaves was dropped. For this slice, an empty group remains unchanged and visible to club admins, who can add themselves or another active club member. It follows the agreed all-club-member group-discovery rule too.
- Empty groups are not implicitly archived.
- Everyone and Admin retain their existing system-group rules.
