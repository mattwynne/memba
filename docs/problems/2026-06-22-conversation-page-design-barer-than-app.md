# Problems

## The conversation-page design is barer than the app it is meant to mirror

Observed: 2026-06-22

Status: Being addressed. [Iteration 044](../iterations/044-conversation-page-alignment/plan.md) keeps the app's richer treatment and updates the design to match (fast-follow).

The design system is meant to mirror the running app (see `CLAUDE.md`). While aligning the
member conversation/message-detail page to `wireframes/member-conversation.html`, the
wireframe turned out to be **barer than the app** in places where the app is actually
better:

- The reply **composer** in the wireframe is a bare textarea; the app also shows who the
  reply is posted as ("Replying as \<name\>"), which is a useful affordance worth keeping.
- The original message and replies are **inline rows** in the wireframe, but **boxed cards**
  in the app — the card treatment is clearer and visually consistent.

If the design were treated as the literal target, aligning the app to it would *remove*
these good elements. Instead the decision (iteration 044) is to keep the app's richer
treatment and **update the wireframe** to match.

Expected:

- The design system reflects the app's richer composer ("Replying as") and card-based
  original/reply treatment, not a barer earlier sketch.
- Where the app is better than a wireframe, the reconciliation updates the wireframe rather
  than degrading the app — and the divergence is captured rather than silently resolved.

Impact:

- Without updating it, the design system would understate the real UI, and a future
  "align app to design" pass could regress the composer and card treatment.
