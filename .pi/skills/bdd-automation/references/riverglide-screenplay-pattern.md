# RiverGlide Screenplay: reading reference

## Primary sources and attribution

- **[Refactoring page objects — The Screenplay Pattern](https://www.slideshare.net/RiverGlide/refactoring-page-objects-the-screenplay-pattern)**: RiverGlide’s deck, presented under **Antony Marcano**’s name (slide 2); slide 48 explicitly credits materials to **Antony Marcano and Andy Palmer**. Slide 47 acknowledges Palmer, John Ferguson Smart and Jan Molak: acknowledgements are not an article co-author byline. Read slides 9–10, 26–39 and 44–48.
- **[RiverGlide’s TodoMVC example](https://github.com/RiverGlide/serenity-web-todomvc-journey/tree/1fe949c0ad598fc6bb89659393c8201c3c41e5de)**: the Serenity implementation linked by slide 47; inspected at this pinned revision. Evidence for concrete responsibilities, not a framework-independent specification.
- **[Page Objects Refactored](https://ideas.riverglide.com/page-objects-refactored-12ec3541990)**: the deck’s article link resolves to this Medium publication. Search indexing attributes it to the **RiverGlide account**; live access was blocked. Do not present Marcano, Palmer, Molak and Smart as four verified article co-authors.

## Maintainability and responsibilities

**RiverGlide’s argument:** page objects can couple locating elements with completing user tasks (slides 12, 26). Refactor by responsibility, applying Single Responsibility and Open/Closed principles: separate UI targets and task objects rather than continually enlarging a page class (slides 27–29). Model the problem rather than the technical solution (slide 32). The pattern is not restricted to browsers: slide 10 includes RESTful APIs and other interactions.

| Concept | Responsibility demonstrated by the deck/example |
| --- | --- |
| **Actor** | Named participant performing tasks and checking observations. `AddNewTodos` creates James and expresses the scenario through him. |
| **Ability** | Access to an interaction capability/resource: James receives `BrowseTheWeb.with(hisBrowser)`. Slide 35: “Actors have abilities.” |
| **Task** | Intentful activity, composable from actions: `AddATodoItem` implements `Task` and delegates to `Enter`. |
| **Interaction/action** | Lower-level operation such as entering text and pressing Return. The deck calls these **actions** (slide 37); do not impose later libraries’ exact `Interaction` API on this source. |
| **Question** | Observation answered for an actor: `DisplayedItems` implements `Question<List<String>>`, using `Text` and a target. `AddNewTodos` separately applies a matcher through `seeThat`. This distinction is visible in the example, not defined in the deck transcript. |

**Where UI mechanics belong:** the example’s `user_interface/ToDoList.java` holds named targets and selectors; task implementations sequence UI actions; questions read UI state. The scenario names intent and expected results. Importantly, `AddATodoItem` itself chooses the field and Return key: RiverGlide does **not** demonstrate that every task must be UI-independent. Stable scenario vocabulary is the goal; some support code necessarily knows the interface.

## Boundaries, tradeoffs and local policy

- **Explicit RiverGlide cautions:** more small classes replace fewer large ones (slide 39); do not refactor everything—experiment alongside existing support code (44). Ask whether too much is being tested (46); use key usage examples rather than exhaustive whole-product combinations (9). Cucumber is optional (40).
- **Engineering implications, not source promises:** added objects introduce navigation/indirection costs; naming and boundaries still require judgement. Separation can contain change but cannot guarantee stable selectors, correct synchronization, sufficient coverage or fast browser execution.
- **Draft-skill boundary:** no draft `SKILL.md` was available in this worktree. Any proposed mandatory transport-independent tasks, driver/adapter layer, selector convention or framework ban must be labelled **local policy**, not attributed to RiverGlide on this evidence.
- **[Nat Pryce’s variant: Having Our Cake and Eating It](https://speakerdeck.com/npryce/having-our-cake-and-eating-it-1)** is a separate primary source. Pryce combines domain-model tests with hexagonal architecture and test drivers, running the same tests quickly against the model or more slowly against deployment. His explicit challenges include unfamiliar TDD workflow, combinatorial mappings, multiple UI mappings and whether the effort is worthwhile. Millisecond execution is not a promise for browser end-to-end tests or a universal Screenplay requirement.

**Verification limits:** deck transcript, linked repository and Pryce transcript were retrieved directly; image-only slides were not independently transcribed. The RiverGlide article redirected to Medium and returned HTTP 403; its full text/byline could not be verified. Claims above therefore rely on the accessible deck and code, not reconstructed article quotations. No exhaustive origin-history claim is made.
