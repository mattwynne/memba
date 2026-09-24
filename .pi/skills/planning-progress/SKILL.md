---
name: planning-progress
description: Maintain a live HTML map of a long-running planning process, showing its full flow, current stage, completed checkpoints, rework loops, decisions, and artifact links.
---

# Planning Progress Map

Use this skill when a planning workflow has multiple specialist stages or human decision checkpoints. The map helps Matt see the whole journey and current position; it does not replace the source artifacts or make decisions.

## Location and Lifecycle

- In BB, create one stable file at `$BB_THREAD_STORAGE/reports/iteration-planning-progress.html` and update it in place.
- In another harness, use equivalent session/report storage outside the product repository and report the exact path.
- Create the map as soon as the planning route is known, before detailed discovery.
- Update it after every stage transition, Matt decision, material rework loop, blocker, publication, and validation result.
- Present the refreshed report after each update. In BB, emit `::inline-vis{source="thread-storage" file="reports/iteration-planning-progress.html"}` as its own message block after the file exists.

Do not commit the live report to the repository. Published plans and source artifacts remain the durable record.

## Required View

Produce a self-contained, readable HTML page with:

- iteration working title and intended outcome;
- route: behaviour-changing or technical/refactoring;
- the complete ordered workflow, not only completed steps;
- one status per stage: `pending`, `current`, `complete`, `rework`, `blocked`, or `not needed`;
- the current question or decision owner;
- completed Matt-agreement/acceptance checkpoints;
- rework arrows to the owning earlier stage;
- open questions and explicit deferrals;
- last-updated time and a short change note;
- links to artifacts that exist, using file paths or safe URLs.

At minimum, link or summarize artifacts as they appear: example maps, feature files/scenarios, vocabulary changes, UX designs/renders, domain models/diagrams, ADRs, the assembled plan, and validation evidence. Never fabricate a link or mark a stage complete merely because work started.

## Rendering

Use simple semantic HTML and embedded CSS with no external runtime dependency. Make the current stage visually dominant and completed versus blocked/rework states distinguishable without relying only on colour. Include a compact flow diagram using HTML/CSS or inline SVG; enhance it as real artifacts emerge rather than delaying planning for decorative work.

Escape artifact text before embedding it. Do not copy secrets, credentials, private URLs, or large source files into the report.

## Update Contract

The planning workflow owns status truth. A separate monitor may render supplied status, but it must not infer completion, run discovery, review artifacts, or decide whether a checkpoint passed.

On every update:

1. receive the full stage list and current statuses from the caller;
2. preserve completed history and record any return to rework;
3. add only verified artifact links and concise summaries;
4. write the updated page atomically;
5. return the path, current stage, blocker/decision if any, and links added.

The report is successful when Matt can answer “where are we, what is next, what did we agree, and where are the artifacts?” at a glance.
