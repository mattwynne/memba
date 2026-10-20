Feature: Find pending BDD work
  Developers can inspect an immutable project snapshot for work in the active iteration.

  Rule: Pending reports exact declarations that can be picked

    Scenario: Dirty files do not change the JSON report for HEAD
      Given a committed project with this feature:
        """
        @iteration-068
        Feature: Member profiles
          @todo @fast
          Scenario: Add a profile photo
            Given a member without a photo

          @journey @todo
          Scenario: Complete a public profile
            Given a new member
        """
      And the feature is replaced without committing by:
        """
        @iteration-067 @todo
        Feature: Dirty and invalid
          Scenario: This must not be read
            Given an old example
        """
      When I run "dev bdd pending --json"
      Then the command succeeds
      And the JSON report names the committed HEAD
      And pending domain declarations are:
        | declaration | scenario            |
        | Scenario    | Add a profile photo |
      And pending journeys are:
        | declaration | scenario                  |
        | Scenario    | Complete a public profile |
      And the pending reference points at the exact "Scenario: Add a profile photo" line

    Scenario: Human output distinguishes a completed domain loop from an outstanding journey
      Given a committed project with this feature:
        """
        @iteration-068 @journey
        Feature: Member journey
          @todo
          Scenario: Complete a public profile
            Given a new member
        """
      When I run "dev bdd pending"
      Then the command succeeds
      And stdout includes "Domain loop complete"
      And stdout includes "Pending journeys (1)"
      And stdout includes "acceptance-tests/features/example.feature:4"
      And stdout does not include "Iteration merged"

    Scenario: A requested commit is resolved without reading a newer HEAD
      Given a committed project with this feature:
        """
        @iteration-068
        Feature: Member profiles
          @todo
          Scenario: Original work
            Given something
        """
      And I remember the commit as "original"
      And another commit replaces the feature with:
        """
        @iteration-068
        Feature: Member profiles
          @todo
          Scenario: New work
            Given something else
        """
      When I run pending for commit "original" as JSON
      Then the command succeeds
      And the JSON report names commit "original"
      And stdout includes "Original work"
      And stdout does not include "New work"

    Scenario: Outline and Examples choices report their own exact declaration lines
      Given a committed project with this feature:
        """
        @iteration-068
        Feature: Profile formats
          @todo
          Scenario Outline: Resize a profile photo
            Given a <size> photo
            Examples:
              | size  |
              | large |

          Scenario Outline: Import a profile photo
            Given a <format> photo
            @todo
            Examples: Portable formats
              | format |
              | png    |
        """
      When I run "dev bdd pending --json"
      Then the command succeeds
      And pending domain declarations are:
        | declaration     | scenario               |
        | Scenario Outline | Resize a profile photo |
        | Examples         | Import a profile photo |
      And pending declaration references match their source lines

  Rule: Invalid project snapshots never look complete

    Scenario Outline: Invalid lifecycle state is rejected
      Given a committed project with this feature:
        """
        <feature>
        """
      When I run "dev bdd pending --json"
      Then the command fails without stdout
      And stderr includes "<error>"

      Examples:
        | feature                                                                                                                        | error                         |
        | @iteration-067 @journey @todo\nFeature: Old journey\n  Scenario: Left behind\n    Given something                            | dangling @todo               |
        | @iteration-069 @wip\nFeature: Future work\n  Scenario: Started early\n    Given something                                         | WIP prevents completion       |
        | @todo\nFeature: Ownerless work\n  Scenario: Missing iteration\n    Given something                                                 | expected one iteration tag    |
        | @iteration-999 @todo\nFeature: Unknown work\n  Scenario: Unknown iteration\n    Given something                               | absent from the index         |
        | @iteration-068 @iteration-069 @todo\nFeature: Ambiguous work\n  Scenario: Two owners\n    Given something                  | expected one iteration tag    |
        | this is not Gherkin                                                                                                           | example.feature               |

    Scenario: A missing active plan is rejected
      Given a committed project with this feature:
        """
        @iteration-068
        Feature: Nothing pending
          Scenario: Complete example
            Given something
        """
      And the active plan is removed in another commit
      When I run "dev bdd pending --json"
      Then the command fails without stdout
      And stderr includes "docs/iterations/068-current/plan.md"

    Scenario Outline: The iteration index must identify one active iteration
      Given a committed project with this feature:
        """
        @iteration-068
        Feature: Nothing pending
          Scenario: Complete example
            Given something
        """
      And the iteration index is committed with active iteration count <count>
      When I run "dev bdd pending --json"
      Then the command fails without stdout
      And stderr includes "Expected one active iteration, found <count>"

      Examples:
        | count |
        | 0     |
        | 2     |

    Scenario: A current inherited TODO with no pickable local declaration is rejected explicitly
      Given a committed project with this feature:
        """
        @iteration-068 @todo
        Feature: Inherited pending work
          Scenario: No local activation point
            Given something
        """
      When I run "dev bdd pending --json"
      Then the command fails without stdout
      And stderr includes "no eligible local @todo declaration"

    Scenario: Hostile option-shaped commit input is rejected as usage
      Given a committed project with this feature:
        """
        @iteration-068
        Feature: Complete work
          Scenario: Complete example
            Given something
        """
      When I run "dev bdd pending --upload-pack=malicious --json"
      Then the command exits with status 2
      And stderr includes "Usage: dev bdd pending"
