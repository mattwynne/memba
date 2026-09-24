---
name: interview-me
description: Conduct a thorough, adaptive interview about any topic. Use when the user asks to be interviewed, questioned, grilled, or helped to clarify their thinking through dialogue.
---

# Interview Me

Interview the user until the purpose of the interview is fulfilled and both sides share a clear understanding. This can be used for decisions, plans, requirements, reflection, research, preparation, or any other topic.

## Set the Frame

Infer the interview's subject and purpose from the conversation. If either is unclear, begin by asking what the user wants to explore and what a useful outcome would be. Do not force the interview toward a plan, artifact, or decision unless that is the user's goal.

Respect any format, tone, pace, role, or question limit the user requests. Otherwise, use the process below.

## Build the Question Tree

Map the subject as a **question tree**: broad areas branch into the questions needed to understand them, and answers may reveal new branches.

### Maintain a private temporary known-unknowns ledger

At the start of the interview, create a temporary ledger file outside the repository. Prefer a thread-scoped private storage directory when the environment provides one; otherwise create a uniquely named file in the operating system's temporary directory with permissions restricted to the current user. Never place the ledger in tracked project paths.

The ledger is working state, not a transcript. Keep only:

- the number of answered questions;
- each specific unresolved question;
- a brief note about why it matters;
- its expected value, risk, branch leverage, and dependencies;
- whether it is ready to ask; and
- a compact list of working assumptions chosen instead of asking.

Do not store the user's answers unless a minimal fact is necessary to understand an unresolved question. Do not print, read aloud, or otherwise expose the ledger's contents unless the user asks to see it.

Maintain it continuously:

- Consider a new entry whenever the opening frame, an answer, an inconsistency, or a new branch reveals something that might be worth asking. Apply the admission test below before adding it.
- Rank open entries by expected value, risk, and branch leverage while respecting dependencies. Interest may break a tie between useful questions, but curiosity alone is not a reason to ask.
- Merge duplicates and remove entries that become irrelevant or fall below the value threshold.
- Remove an entry as soon as it is answered, assumed, or explicitly left open. If an answer creates follow-up unknowns, evaluate those as new candidates before reprioritizing.
- After every answer, update the file before asking the next question.
- Delete the ledger when the interview ends unless the user explicitly asks to preserve it. If deletion fails, tell the user where the file remains.

### Control the long tail

Treat each question as an investment of the user's attention. Add or retain it only when its **expected value of information** clearly justifies that cost.

A question deserves a ledger entry when at least one plausible answer would materially change the conclusion, recommendation, scope, or next questions, and the answer cannot be safely researched or inferred. Its value rises with:

- the consequence of being wrong;
- the likelihood that different answers lead somewhere meaningfully different;
- the number of downstream branches it resolves;
- irreversibility, safety, trust, money, or substantial effort; and
- dependence on the user's private knowledge, intent, preferences, or values.

Do not add or retain a question merely because it is related or interesting. Prefer an assumption when the issue is low-impact, reversible, conventional, already strongly implied, or unlikely to alter the outcome. Drop questions whose answers would only add detail without changing understanding or action.

The threshold for asking should rise as the interview continues. After every answer, compare the likely improvement in understanding against the user's cognitive effort and visible fatigue. Prune the remaining tail aggressively when marginal value is declining.

The agent may accept its own recommendation as a working assumption only when the choice is low-risk, reversible, and supported by context or a clear default. Record the assumption for the closing summary rather than asking about it. Never assume the user's lived experience, personal values, material preferences, authorization, or a high-impact or hard-to-reverse decision.

When no remaining question clears this threshold, end the interview even if conceivable unknowns remain. If only optional exploration remains, finish the core interview, summarize the assumptions made, and offer the user the choice to explore further rather than continuing automatically.

### Ask one question at a time

The **frontier** is every useful ledger entry whose prerequisites are already settled. Select the highest-priority entry from the frontier and ask only that question. Wait for the answer before updating the ledger, recomputing the frontier, and asking another. Do not show the queue merely to prove that it exists.

Track the number of answered questions in the ledger. At every question, show progress as **current question / total questions currently known**, where the total is answered questions plus unresolved ledger entries. For example, `9/15` means this is the ninth question and fifteen questions are currently known. The denominator is provisional: explain once near the start that it may rise or fall as answers reveal or eliminate branches.

Use this format:

```markdown
❓ **9/15 — <short title>**

<one question, with context or options when useful>
```

For decision-oriented questions, add a recommendation only when it would genuinely help:

```markdown
➡️ **Recommendation:** <recommended answer and brief rationale>
```

Do not recommend answers to questions about the user's own experience, preferences, memories, feelings, or expertise.

## Interview Well

- Ask open questions to discover; use multiple choice to make a known decision easier.
- Follow the user's language and intended level of depth.
- Probe vague, contradictory, consequential, or surprising answers without becoming adversarial.
- Distinguish what the user said from your inference. Check important inferences explicitly.
- Ask for concrete examples when abstractions hide ambiguity.
- Accept “I don't know” as a real answer. Identify whether the unknown needs research, experimentation, reflection, or can remain open.
- Do not repeat settled questions unless a later answer creates a genuine conflict.
- Do not manufacture branches merely to prolong the interview.
- Notice signs of fatigue such as shorter answers, repetition, impatience, or an explicit desire to wrap up. Respond by raising the admission threshold and prioritizing only consequential unresolved questions.

Researchable facts are your responsibility: inspect available sources or tools instead of asking the user to retrieve information you can obtain yourself. Personal knowledge, intentions, experiences, and decisions belong to the user and must not be inferred as fact.

## Finish Deliberately

The interview is ready to close when its purpose has been met, the meaningful branches are settled or explicitly left open, and further questions would add little value.

Before ending:

1. Summarize the understanding reached, including important decisions, themes, tensions, and open questions as appropriate to the interview.
2. Clearly label uncertainty and your own inferences.
3. Ask the user to confirm or correct the summary.
4. Do not implement, publish, contact others, or otherwise act on the interview unless the user separately requests or has already authorized that action.

If the user asks to stop, wrap up immediately with the best available summary.

## Source

Adapted from the `grill-me` and `grilling` skills in [mattpocock/skills](https://github.com/mattpocock/skills).
