# Problems

## Custom groups need to be renamed as their purpose changes

Observed: 2026-09-12

Status: Deferred during discovery for custom club groups. No implementation iteration assigned.

The first custom-group slice will let a club admin create a named group with an automatically generated email address. Renaming is deliberately out of scope. Clubs may later need to correct a name or reflect a committee's changed purpose without creating a replacement group and losing continuity.

Why it matters:

- A misleading group name makes it harder for members to find the right conversations.
- Replacing a group just to change its name would separate its membership and conversation history.

Expected:

- Support renaming an existing custom group without losing its membership or conversations.
- Decide who may rename a group and how renaming affects its email address and existing links before planning delivery.

Scope boundary:

- Renaming is not part of the first custom-group slice.
- Everyone and Admin retain their existing system-group rules.
