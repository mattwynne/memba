---
name: domain-vocabulary
description: Consult and maintain Memba's canonical problem-domain vocabulary when naming behaviour, scenarios, commands, events, invariants, or domain concepts.
---

# Memba Domain Vocabulary

Use this skill whenever behaviour formulation or domain modelling introduces, changes, or questions a business noun or verb. The canonical lexicon is [`docs/problem-domain-terms.md`](../../../docs/problem-domain-terms.md).

## Purpose

Keep stakeholder language, Gherkin, domain models, and later code aligned without turning the lexicon into a specification. Rules and examples remain in acceptance artifacts; this skill owns names and meanings.

## Boundary

- **Problem-domain language** names people, organisations, things, actions, outcomes, and distinctions that people using or discussing Memba recognize.
- **Solution-domain language** names implementation mechanisms such as modules, schemas, tables, processes, adapters, projections, aggregates, storage, and delivery machinery.
- Keep solution-domain terms out of the problem-domain lexicon unless Matt confirms that people using Memba also use that term with the proposed meaning.
- Matt owns vocabulary decisions. Do not add, rename, deprecate, or redefine a canonical term without his explicit agreement.
- A reviewer or modeller may propose language; it may not silently normalize the Gherkin, model, code vocabulary, or lexicon.

## Consultation

1. Read `docs/problem-domain-terms.md` before choosing names.
2. Extract the important nouns and verbs from the behaviour examples or model.
3. Reuse the canonical term when it expresses the same concept.
4. Flag synonyms, overloaded words, generic roles, unexplained jargon, and problem/solution-domain mixing.
5. For a missing or awkward term, bring Matt:
   - the concrete examples that need a name;
   - the existing term, if any;
   - the proposed preferred term and plain-language meaning;
   - alternatives and consequences for existing scenarios/model language;
   - whether the term is problem-domain or solution-domain.
6. Record Matt's decision. If accepted, update the lexicon's preferred or avoid/replace table and then update affected planning artifacts consistently. If deferred or rejected, preserve the decision as an open question or explicit deferral; do not drift independently.

## Feedback from Modelling

Commands, events, and invariants often expose a more natural business noun or verb. When that happens:

1. stop treating the model term as settled;
2. return the evidence to `bdd-formulation` and this skill;
3. ask Matt whether the behaviour wording and lexicon should change;
4. if agreed, update the lexicon and formulated scenarios first;
5. repeat the caller-defined formulation review and Matt-agreement checkpoint;
6. then revise and review the model.

Do not preserve an awkward scenario term merely because it appeared first, and do not let the model invent a competing synonym.

## Output

Return a short vocabulary record containing:

- canonical terms reused;
- proposed additions, changes, or replacements;
- problem-domain versus solution-domain classification;
- Matt's decision for each proposal;
- lexicon and planning artifacts changed;
- unresolved naming questions and their owner.
