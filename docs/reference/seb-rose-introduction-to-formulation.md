# Seb Rose: Introduction to Formulation

Source: [“Introduction to Formulation” — Seb Rose, Cucumber blog](https://cucumber.io/blog/bdd/introduction-to-formulation/). These are Memba's paraphrased reading notes, not a copy of the article.

## Illustrative scenarios and journeys

Rose distinguishes **illustrative scenarios**, which show a focused example of a particular business rule, from **journey scenarios**, which cover a complete user interaction. The article's Q&A explicitly acknowledges a need for journeys; its webinar concentrates on illustrative scenarios and points to *The BDD Books: Formulation* for more on journeys.

Formulation should make the relevant rule and its concrete example clear to readers, rather than turn each rule example into a record of every interface action. A journey has a different purpose: following a user through connected behaviour. It is not a replacement for the examples that explain individual rules.

## Applying this in Memba

[ADR 0026](../adr/0026-keep-browser-journeys-distinct-from-domain-examples.md) uses that distinction: focused domain examples describe rules, while deliberately selected browser journeys may be longer and cross feature boundaries. The choice of how many journeys to keep, and their `@journey` tag and file location, is **Memba's decision**, not a claim that Rose prescribes our test configuration.
