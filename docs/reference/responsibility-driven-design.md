# Responsibility-Driven Design (RDD)

Responsibility-Driven Design is Rebecca Wirfs-Brock’s approach to object-oriented design. It starts from behavior, roles, and collaboration rather than data structures. A system is viewed as a community of objects that know things, do things, and ask one another for help.

Wirfs-Brock introduced the approach with Brian Wilkerson in the 1989 OOPSLA paper “Object-Oriented Design: A Responsibility-Driven Approach.” She expanded it with Brian Wilkerson and Lauren Wiener in *Designing Object-Oriented Software* (1990), and later with Alan McKean in *Object Design: Roles, Responsibilities, and Collaborations* (2002/2003).

## Core idea

RDD asks: what responsibilities should each object have?

A responsibility is an obligation an object has to provide a service, maintain information, make a decision, coordinate work, or know something relevant to the domain. Responsibilities are intentionally higher-level than methods. A responsibility may later become one method, several methods, or a collaboration with other objects.

RDD shifts design away from:

```text
What data fields does this class have?
```

and toward:

```text
What is this object responsible for knowing or doing?
Who does it collaborate with to fulfill those responsibilities?
```

## Responsibilities

Responsibilities commonly fall into two broad categories:

- **Knowing responsibilities**: information an object can provide, remember, calculate, or derive.
- **Doing responsibilities**: actions an object performs, decisions it makes, services it offers, or work it coordinates.

Examples:

- An `Invoice` knows its line items, total, due date, and payment status.
- An `Invoice` can determine whether it is overdue.
- A `PaymentAllocator` can allocate a payment across open invoices.
- A `NotificationGateway` can send a message through an external channel.

Good responsibilities are stated in domain language and describe intent, not implementation details.

## Collaborations

Objects rarely fulfill responsibilities alone. A collaboration is a relationship in which one object asks another object to help.

RDD treats collaboration as a design concern in its own right. When an object cannot or should not do something itself, it delegates to a collaborator whose responsibility is clearer.

This creates a client/server view of object design:

- the client asks for a service,
- the server promises to provide it,
- the request is expressed through a public interface,
- internal implementation remains hidden.

The goal is not to make objects tiny for its own sake. The goal is to distribute responsibilities coherently so objects are understandable, encapsulated, and replaceable.

## CRC cards

CRC cards are a lightweight design tool associated with RDD. CRC originally means Class–Responsibility–Collaborator, though Wirfs-Brock has also suggested reading the first C as Candidate when exploring early designs.

A CRC card contains:

- **Class / Candidate**: the object, role, or concept under discussion.
- **Responsibilities**: what it knows or does.
- **Collaborators**: other objects it relies on.

CRC cards work well because they are physical or lightweight. Teams can move them around, role-play scenarios, discard weak ideas, and discover missing collaborators without prematurely committing to code.

A typical CRC session follows scenarios:

1. Pick a user goal or domain story.
2. Identify candidate objects.
3. Assign responsibilities to objects.
4. Walk through the scenario by passing requests between cards.
5. Add, split, merge, or rename cards as the design becomes clearer.
6. Translate stable responsibilities into interfaces and code.

## Object role stereotypes

Wirfs-Brock’s later work describes recurring object role stereotypes. These are not rigid categories, but useful design lenses for responsibility assignment.

Common stereotypes include:

- **Information Holder**: knows and provides information.
- **Structurer**: maintains relationships between objects or organizes collections.
- **Service Provider**: performs a specific service or calculation for others.
- **Controller**: makes decisions and directs significant work.
- **Coordinator**: delegates work to others, often in a more mechanical way than a controller.
- **Interfacer**: translates between parts of the system, external APIs, user interfaces, devices, or subsystems.

Role stereotypes help expose design imbalances. For example, if one controller makes every decision, the model may be too centralized. If every object is only an information holder, the design may be anemic and data-centric.

## Contracts

RDD emphasizes contracts between collaborators. A contract defines what one object can ask of another and what response or effect it can expect.

Contracts support encapsulation because clients depend on promised behavior rather than internal data layout. An object’s public methods are the surface of the contract; its internal algorithms and storage are private choices.

This way of thinking encourages designers to ask:

- What service does this object promise?
- What does the client need to know to use it?
- What should remain hidden?
- What preconditions and postconditions matter?
- What collaborator would be easier to substitute in tests or future designs?

## Relationship to encapsulation

RDD is deeply aligned with encapsulation. Encapsulation is not merely making fields private. It is assigning responsibility so that decisions live with the objects best qualified to make them.

Poor design asks for data and makes decisions elsewhere:

```text
invoice.status == "overdue" && invoice.balance > 0
```

Better responsibility-driven design asks the object to answer a meaningful question:

```text
invoice.isCollectable()
```

The second form hides the rule and gives the object a behavioral responsibility.

## Relationship to Domain-Driven Design

RDD and Domain-Driven Design reinforce each other.

DDD contributes domain language, bounded contexts, aggregates, and a focus on business complexity. RDD contributes object-level responsibility assignment: once the domain concepts are known, which objects should know what, do what, decide what, and collaborate with whom?

In a DDD system, RDD is useful when modeling aggregates, value objects, domain services, policies, and process coordinators. It helps prevent domain models from becoming passive bags of data.

## Relationship to GRASP and SOLID

RDD overlaps with later responsibility-assignment ideas such as GRASP and SOLID.

- Like GRASP, it asks where responsibilities should live.
- Like Single Responsibility Principle, it seeks cohesive objects with focused reasons to change.
- Like Dependency Inversion, it values contracts over concrete implementation details.
- Like Tell, Don’t Ask, it prefers asking objects to do domain work rather than extracting their data.

RDD is less a rule checklist than a way of thinking and conversing about design.

## Benefits

- **Behavior-first modeling**: objects are designed around what they do, not just what they store.
- **Better encapsulation**: decisions stay close to the information and roles that justify them.
- **Clear collaborations**: object interactions are explicit and discussable.
- **More cohesive objects**: responsibilities can be grouped by role and purpose.
- **Lower premature detail**: CRC cards let teams explore before committing to classes and methods.
- **Improved testability**: contracts and collaborators create seams for substitution.
- **Domain-aligned names**: responsibilities can be stated in business language.

## Costs and risks

- **Can feel abstract**: responsibility language may seem vague to teams used to database-first design.
- **Needs practice**: good responsibility assignment is a design skill, not a mechanical recipe.
- **Over-fragmentation**: excessive delegation can produce too many small objects and indirection.
- **God controllers**: assigning all decisions to controllers can recreate procedural design.
- **Anemic models**: treating objects only as information holders misses the point.
- **Implementation drift**: code can drift from CRC/design conversations unless names and tests preserve intent.

## When to use RDD

Use RDD when:

- object behavior and collaboration are central to the design,
- a domain model is becoming passive or data-centric,
- a team is unsure where methods should live,
- scenarios cut across several objects,
- you want to explore a design before coding,
- responsibilities are tangled in controllers, services, or transaction scripts.

Use it lightly when the feature is simple CRUD or primarily data transformation.

## Practical heuristics

- Start with scenarios, not class diagrams.
- Name responsibilities in plain domain language.
- Prefer “who should be responsible for this?” over “where can I put this method?”
- Give information and behavior to the same object when it makes domain sense.
- Use collaborators when a responsibility does not naturally belong to the current object.
- Watch for objects that only expose data and make no decisions.
- Watch for controllers that make every decision.
- Treat CRC cards as disposable thinking tools, not documentation bureaucracy.
- Let role stereotypes guide questions, not dictate architecture.

## Example

For “a member sends a message to their study group,” candidate responsibilities might be:

- `Member` knows whether they are active and allowed to send messages.
- `StudyGroup` knows its members and message policy.
- `MessageDraft` knows subject and body validity.
- `MessageDelivery` coordinates delivery to recipients.
- `EmailGateway` interfaces with the external email provider.
- `DeliveryReceipt` records the result.

A data-first design might start with tables. RDD starts by asking which objects participate in the story and what each is accountable for.

## Primary references

- Rebecca Wirfs-Brock and Brian Wilkerson, “Object-Oriented Design: A Responsibility-Driven Approach” (OOPSLA 1989): https://wirfs-brock.com/rebecca/papers/oodesign-a-responsibility-driven-approach/
- Rebecca Wirfs-Brock, Brian Wilkerson, and Lauren Wiener, *Designing Object-Oriented Software*.
- Rebecca Wirfs-Brock and Alan McKean, *Object Design: Roles, Responsibilities, and Collaborations*.
- Rebecca Wirfs-Brock, “A Brief Tour of Responsibility-Driven Design”: https://www.wirfs-brock.com/PDFs/A_Brief-Tour-of-RDD.pdf
- Rebecca Wirfs-Brock, “Design” resources: https://www.wirfs-brock.com/Design.html
- Microsoft MSDN Magazine archive, “Object Role Stereotypes”: https://learn.microsoft.com/en-us/archive/msdn-magazine/2008/august/patterns-in-practice-object-role-stereotypes
