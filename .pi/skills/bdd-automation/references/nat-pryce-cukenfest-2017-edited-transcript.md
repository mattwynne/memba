# Nat Pryce: End-to-end functional tests that can run in milliseconds

[Video: Cucumber, CukenFest London 2017](https://www.youtube.com/watch?v=Fk4rCn4YLLU) · [Slides: “Having Our Cake and Eating It,” CukeUp 2017](https://speakerdeck.com/npryce/having-our-cake-and-eating-it-at-cukeup-2017)

**Condensed, edited reading transcript—not a complete or verified verbatim transcript.** Derived from YouTube's English auto-generated captions, not independently checked against audio. I collapsed rolling-caption repetitions; condensed repeated explanations; removed filler, false starts and incidental slide/computer handling; added punctuation and paragraph breaks; and corrected obvious transcription errors where context was clear. Brackets mark significant uncertainty, omission, or a sentence cut off in the captions. Timestamps approximate the start of the speech, not every sentence. For exact ASR wording or tighter timing, consult the [uncorrected timestamped captions](nat-pryce-cukenfest-2017-auto-transcript.txt) and video. Especially avoid treating edited quotations as audio-verified.

## Talk

### 00:05–01:00 — Why this talk

This talk came out of a tweet: I asked whether anyone would be interested in a talk about running end-to-end tests in milliseconds. Matt replied, “Yes, do it at CukeUp,” so here I am. This is a case study of how we approached functional and end-to-end system testing on a project, warts and all. It is about the logistics of testing—our testing strategy and how we arrived at it.

### 01:10–03:05 — The original arrangement

This was a new project, the first in a larger programme for a publisher. The organisation had a fairly siloed culture: frontend developers, backend developers and QAs had separate responsibilities. We were trying to introduce BDD and were inspired by the Screenplay pattern [speaker's reference to Anthony Marcano; proper name not independently verified]. Screenplay models users as actors who perform tasks, ask questions and examine outputs. It helps you think about users while decomposing the technological complexity of functional tests into actors and tasks.

The QAs, who were responsible both for testing and for automating the functional tests, chose a BDD framework that supported Screenplay. They started writing tests with it.

### 03:05–05:48 — Failure of the first test suite

The framework relied heavily on reflection, mutable state, thread-local and global variables. Our development team preferred pure functional code, type safety, null safety and immutable data. The test code and production code were written in very different coding cultures and barely interacted. Developers stepped away from the test code; they couldn't use their IDEs to understand it quickly.

The QAs were building their own models of the users and domain in Java, duplicating the models developers were building in Kotlin. QA work became siloed too: one person ended up focused on automation while others focused on manual and exploratory work. Because experience writing system tests did not feed back into system design, the tests became unreliable and brittle. They could not synchronise properly with the system; changes to the UI broke them; the suite was expensive and red so often that people stopped trusting it. Exploratory testing suggested the product worked, and developers' TDD checks passed. I said we turned the functional tests off; more precisely, we removed them from the build monitor. We needed a different approach.

### 05:51–07:36 — Shared ownership and domain language

We agreed that automation is a software-development job: developers do it with QA input, while QA is responsible for exploratory, manual and qualitative testing. Automation can say that 20 of 20 tests pass, but it cannot tell you what the product feels like to a user. QA learned users' constraints and pressures, tried different routes through the software, and fed that experience back to development, UX and product. Developers could then feed what they learned from automation into system design, making subsequent tests cheaper to write.

We also wanted to avoid duplicating the domain model in production and tests. We wanted functional scenarios expressed in terms of the domain model, not the UI, infrastructure or deployment architecture, yet still able to drive the whole system when needed. How could we do that?

### 07:36–10:57 — Ports and adapters at wider scales

We chose hexagonal, or ports-and-adapters, architecture. The system comprised many services with smaller hexagons. The business logic lives in the middle; adapters translate between technical events and domain actions, or between domain effects and technical operations such as SQL. In our intended architecture the adapters perform no business logic themselves. If an HTTP service maps requests to domain actions, a test driver can map a domain-level action into HTTP requests. The same idea extends to a deployed cloud service and to a web browser.

At each wider boundary there are more technical pieces—replication, load balancing, security, HTML and JavaScript—but the adapters should not add new business logic. The frontend adds usability and maps user interactions to the service. We wanted the same domain-level test code to be executed through inverse mappings against objects directly, through HTTP, or through a browser. [This describes Pryce's architecture, not a universal claim that every frontend contains no policy.]

### 10:57–12:27 — Why wider system checks still matter

Production adds a global CDN and caching rules, which may change without our knowledge. A system test can check that the whole system still hangs together. Whether we test in the IDE or through globally distributed infrastructure, the domain logic is the same, but technical infrastructure supports security, scalability, availability and usability. It may not add business logic, yet it can interfere with users' ability to exercise it. An incorrect cache rule, for example, can change what pages users see.

### 12:27–15:07 — Roles, actors, productions and scenarios

We took the Screenplay metaphor further. A *production* determines which system interface the tests use and creates scenarios. A scenario declares roles, such as author and editor. Different *actors* play those roles at different interfaces. Actors perform tasks through the chosen interface, causing domain actions. One example is an editor requesting an amendment: Alice submits a manuscript, Ed requests an amendment, Alice revises it, and Ed sees the revision for further review. The scenario uses production domain objects such as submission details. It can exercise domain objects directly or drive much wider system behaviour.

### 15:07–17:38 — Fast feedback and reuse, with a qualification

At the quick level, these scenarios run against objects in memory. At another level, the actors map them to HTTP requests, browser interactions, a local system or a deployed cloud system—depending on how much we want to test. We can run them very quickly while working on domain logic. In memory they execute entirely against the domain model; **the same test code can also run against deployed systems, APIs and browsers.** This is not a claim that the browser or deployed run takes milliseconds.

Tests became faster to write and more reliable as they informed the domain model and the testability of the whole system. The domain API was type-safe and refactorable. The concise scenario code had no UI or technical details: looking at it, you could not tell whether it was running against JSON or a browser. The tests themselves were code, not natural language; reporting could express business rules in natural language for analysts. Reusing the production domain concepts avoided a duplicate test model.

### 17:38–19:32 — Added complexity; inside-out or outside-in?

This approach was unfamiliar and more complicated than the team was used to. We debated whether to begin with HTML/HTTP and map inward, or begin with the fast domain logic and map outward. We do both. Sometimes the mappings already exist and we are changing only domain behaviour. Sometimes we are adding a service or HTML interface and start there, writing its mapping toward the domain. Different stories call for different approaches.

### 19:32–21:44 — Avoiding a mapping explosion

We had many domain actions and many interfaces: direct domain calls, a service API, browsers with and without JavaScript, perhaps an Android app. Mapping every action to every interface would multiply the work whenever an action or interface changed. We introduced a common model of user interactions—a lingua franca between domain-level actions and specific remote interfaces. Domain actions map to shared interactions, and actors map those interactions to their service or UI. Instead of roughly M × N mappings, it is roughly M + N. Reusable interactions such as entering text in fields make new actions cheaper to add.

### 21:44–23:39 — Multiple ways through a UI

At the UI there can be multiple navigation paths and places to observe an outcome. One option is to choose a random route on each run and, across many runs, explore more combinations. Because of our CI limitations, we instead used unit tests to check the equivalence of alternative ways to do something, then chose one for the functional test. [The captions cut off the end of this sentence at about 23:17; the contrast is otherwise clear.] This is a choice from this project's constraints, not a universal rule that other paths need no coverage.

### 23:39–24:51 — Cost of direct domain tests

The direct in-memory path differs from the path through user interactions and service interfaces. Some on the team asked whether it was worth the mental overhead: why not run only system tests? When we investigated cases where direct-domain testing felt inappropriate, we found either business logic in an adapter rather than the domain, or a domain model that needed correction. Fixing the design resolved the friction, so we retained the in-memory path. [The auto-caption at 24:27 reads “was conforming,” which conflicts with the next clause; this edition omits the uncertain negative rather than inventing a verbatim correction.]

### 24:51–26:14 — Pyramid and infrastructure

We still have more unit tests than system tests. But the product runs through cloud services, a CDN and networking equipment, some outside our control. We need system tests to check that those parts are not preventing people from using the application. Carefully designed tests can also run against production to monitor it. We created fake users, journals and configurations that would not affect real users. [This is a system-design choice Pryce describes, not a requirement to add test-only product code to every project.]

### 26:14–28:47 — System-scale testability and operations

System tests can test-drive system design. If a check is hard to write, refactor the system to make the check easier; if a failure is hard to diagnose, improve its diagnostic output. A system test needs to know what the system is doing, when an operation completes, when it fails, why it fails, and how to restore a good state for the next test. Those capabilities also make a live system easier to support. At unit scale, test-driving improves code maintainability; at system scale, it can improve operational support and management interfaces.

## Questions and answers

### 29:32–30:25 — Do you run the entire suite at every scale on each commit?

We have several possible scales. On a developer workstation we run in memory; we can also run all HTTP services inside one process to reproduce cloud problems while remaining debuggable. We do not run that latter arrangement in CI/CD. Our delivery pipeline deploys the system to an internal cloud and runs system tests there. Some checks occasionally run against the live system. [He does not claim the entire suite runs at every scale on every commit.]

### 30:25–32:56 — Where does asynchrony belong?

Our interpretation of Screenplay does not let actors ask standalone questions. In an asynchronous system, if you ask for an answer and assert on it, you may not know when computation has finished. Instead actors do something—possibly something they are not allowed to do—and the actor implementation deals with asynchrony at that interface. In memory, the hexagons use a simulation of asynchronous interactions. At HTTP scale the action makes a request and checks the result. In a browser it may navigate, enter data, submit, then revisit and check that the change persisted. For an email outcome, the implementation waits for the message and checks its text. Wider scales require handling the real asynchronous behaviour.

### 33:06–34:09 — External systems in live checks

We are fortunate not to interact with expensive external third-party services apart from reference data. An internal downstream publishing system is an exception: a fake journal routes to a fake publishing system instead of the real one. We added design support at that edge for safe testing, even though production otherwise has only one publishing system. [The caption sentence trails off here.]

### 34:09–34:34 — How did you get permission?

Asked how he obtained permission to build this testing infrastructure rather than features, Pryce answers: “I never asked.” [Applause.]
