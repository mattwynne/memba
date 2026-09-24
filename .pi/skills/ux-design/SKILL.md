---
name: ux-design
description: Decide, locate, create, and review UX design coverage for visible behaviour before implementation, using Memba's design sources and Matt's decisions.
---

# UX Design

Use this skill when work adds or changes a screen, page, component, email, interaction, content journey, or visible state. It can stand alone or be composed into planning.

## Sources and Environment

The design system at `claude.ai/design` is the source of truth and is intended to mirror the running app; see `CLAUDE.md`.

- In Claude Code, use `DesignSync` when it is available: inspect with `list_files` and `get_file` before proposing new work.
- Outside Claude Code, do not call or pretend to have checked `DesignSync`. Inspect checked-in sources such as `design-system/` and `docs/specs/*` and state that live design-system access was unavailable.
- When `DesignSync` is available in Claude Code, use it to inspect and continue the design work; no handoff is needed merely because checked-in sources are insufficient.
- When new or changed design is required, `DesignSync` is unavailable, and checked-in sources are insufficient, return a blocking handoff to a Claude Code session with the behaviour, surfaces, constraints, and restart prompt. A calling planning workflow must stop before drafting, publishing, or validating its plan. Do not fake, skip, or downgrade missing design coverage to a fast-follow.

## Design Decision

Work with Matt to decide:

1. **Is a design needed?** Identify every affected visible surface and state, including empty, first-run, loading, error, success, narrow-screen, and email states. Record `No design needed` with a reason only when nothing visible changes.
2. **What already covers it?** Link the exact design-system card or checked-in sketch. A close design can be the base, but name what it lacks.
3. **What must change?** Describe the final intended experience, information hierarchy, actions, content, states, accessibility constraints, and which parts this slice deliberately omits.
4. **Who produces it?** During planning, normally record the design or the explicit reminder/handoff. Create or revise a mock only when Matt asks and the environment supports it.

For a new or changed design in Claude Code, make a self-contained design-system preview, render-verify it, and push it through `DesignSync`. For a feature split across iterations, design the final experience once and identify what earlier slices omit rather than creating incompatible per-slice destinations.

## Review Brief

When a design is created or materially changed, call `ensemble-review` with:

- **Subject:** whether the design expresses the agreed behaviour clearly and safely.
- **Artifact:** agreed examples, vocabulary, design paths/renders, existing design patterns, and scope boundaries.
- **Focus:** (1) user journey and simplicity, (2) states, errors and accessibility, (3) content, visual-pattern and behaviour coherence.
- **Rubric:** Can the intended user complete the outcome? Are important states and transitions represented? Is content expressed in agreed problem-domain language? Does the design reuse established patterns and remain coherent across screen sizes and email/web boundaries where relevant? Does it add policy not present in the agreed behaviour?
- **Known questions:** unresolved UX questions, or `None`.
- **Constraints:** read-only review; no new product policy, scope, vocabulary, or architecture; Matt owns UX decisions.
- **Feedback route:** this skill for design issues; product, vocabulary, or scenario findings return to their owning skill.

Synthesize evidence and disagreement, revise with Matt, and repeat review only when a material design decision changes.

## Output

Return a plan-ready `## Designs` record containing:

- each affected surface and visible state;
- exact existing or new design paths;
- Matt-agreed design decisions;
- final-experience coverage and omissions for this slice;
- accessibility and responsive considerations;
- required handoff or fast-follow, with owner;
- unresolved UX questions.

Do not implement the application UI in this skill.
