Feature: Pick pending BDD work
  Developers can activate exactly one locally tagged declaration without changing anything else.

  Rule: A precise eligible declaration is activated

    Scenario: Pick an exact Scenario declaration
      Given a committed project with this feature:
        """
        @iteration-068
        Feature: Member profiles
          @todo @fast
          Scenario: Add a profile photo
            Given a member without a photo

          @todo
          Scenario: Change a profile photo
            Given a member with a photo
        """
      When I pick the declaration "Scenario: Add a profile photo"
      Then the command succeeds
      And the feature now equals:
        """
        @iteration-068
        Feature: Member profiles
          @wip @fast
          Scenario: Add a profile photo
            Given a member without a photo

          @todo
          Scenario: Change a profile photo
            Given a member with a photo
        """
      And stdout includes "Picked acceptance-tests/features/example.feature:4"

    Scenario: Pick an exact Scenario Outline declaration
      Given a committed project with this feature:
        """
        @iteration-068
        Feature: Member profiles
          @todo @fast
          Scenario Outline: Change a profile photo
            Given a member with <state>
            Then the photo is changed

            Examples:
              | state   |
              | a photo |
              | no photo |
        """
      When I pick the declaration "Scenario Outline: Change a profile photo"
      Then the command succeeds
      And the feature contains "  @wip @fast\n  Scenario Outline: Change a profile photo"
      And the feature does not contain "@todo"

    Scenario: Pick one exact Examples declaration without activating its sibling
      Given a committed project with this feature:
        """
        @iteration-068
        Feature: Member profiles
          Scenario Outline: Change a profile photo
            Given a member with <state>

            @todo @mobile
            Examples: Supported photos
              | state |
              | jpg   |

            @todo @desktop
            Examples: Other photos
              | state |
              | png   |
        """
      When I pick the declaration "Examples: Supported photos"
      Then the command succeeds
      And the feature contains "    @wip @mobile\n    Examples: Supported photos"
      And the feature contains "    @todo @desktop\n    Examples: Other photos"

  Rule: The locator must name the declaration itself

    Scenario Outline: Nearby lines are not treated as declarations
      Given a committed project with this feature:
        """
        @iteration-068
        Feature: Member profiles
          @todo
          Scenario Outline: Change a profile photo
            Given a member with <state>

            @todo
            Examples:
              | state |
              | jpg   |
        """
      When I pick the line containing "<line>"
      Then the command fails
      And stderr includes "no Scenario, Scenario Outline, or Examples declaration at this line"
      And no file bytes changed

      Examples:
        | line                          |
        | @todo                         |
        | Given a member with <state>   |
        | \| state \|                   |
        | \| jpg   \|                   |

    Scenario: A blank line is not treated as a declaration
      Given a committed project with this feature:
        """
        @iteration-068
        Feature: Member profiles
          @todo
          Scenario: Change a profile photo

            Given a member
        """
      When I pick the line before "Given a member"
      Then the command fails
      And stderr includes "no Scenario, Scenario Outline, or Examples declaration at this line"
      And no file bytes changed

  Rule: Local TODO and inherited-tag conflicts are rejected atomically

    Scenario Outline: A declaration without its own TODO cannot be picked
      Given a committed project with this feature:
        """
        <feature>
        """
      When I pick the declaration "<declaration>"
      Then the command fails
      And stderr includes "does not have its own local @todo"
      And no file bytes changed

      Examples:
        | feature                                                                                                                                            | declaration                  |
        | @iteration-068 @todo\nFeature: Inherited\n  Scenario: Child scenario\n    Given something                                                   | Scenario: Child scenario     |
        | @iteration-068\nFeature: Inherited\n  @todo\n  Scenario Outline: Parent outline\n    Given <thing>\n    Examples: Child examples\n      \| thing \|\n      \| one   \| | Examples: Child examples     |

    Scenario Outline: Conflicting nested TODO or WIP is rejected
      Given a committed project with this feature:
        """
        @iteration-068
        Feature: Conflicts
          <outline-tag>
          Scenario Outline: Parent outline
            Given <thing>
            <examples-tag>
            Examples: Child examples
              | thing |
              | one   |
        """
      When I pick the declaration "<declaration>"
      Then the command fails
      And stderr includes "<error>"
      And no file bytes changed

      Examples:
        | outline-tag | examples-tag | declaration                      | error                   |
        | @todo       | @todo        | Scenario Outline: Parent outline | nested local @todo      |
        | @todo       | @todo        | Examples: Child examples          | inherited @todo         |
        | @wip        | @todo        | Examples: Child examples          | WIP prevents completion |

  Rule: Repository and eligibility guards run before any edit

    Scenario Outline: Every kind of dirty worktree is rejected
      Given a committed project with this feature:
        """
        @iteration-068
        Feature: Member profiles
          @todo
          Scenario: Add a profile photo
            Given something
        """
      And the worktree has an unrelated <kind> change
      When I pick the declaration "Scenario: Add a profile photo"
      Then the command fails
      And stderr includes "worktree must be completely clean"
      And no file bytes changed

      Examples:
        | kind      |
        | staged    |
        | unstaged  |
        | untracked |

    Scenario: A --from commit that is no longer HEAD is rejected
      Given a committed project with this feature:
        """
        @iteration-068
        Feature: Member profiles
          @todo
          Scenario: Original work
            Given something
        """
      And I remember the commit as "original"
      And another commit adds an unrelated file
      When I pick "Scenario: Original work" from commit "original"
      Then the command fails
      And stderr includes "must resolve to HEAD"
      And no file bytes changed

    Scenario Outline: Work outside the active domain loop cannot be picked
      Given a committed project with this feature:
        """
        <tags>
        Feature: Member profiles
          @todo
          Scenario: Out of scope work
            Given something
        """
      When I pick the declaration "Scenario: Out of scope work"
      Then the command fails
      And stderr includes "<error>"
      And no file bytes changed

      Examples:
        | tags                       | error                    |
        | @iteration-068 @journey    | journey                  |
        | @iteration-069             | active iteration         |
        | @iteration-067             | dangling @todo           |
        | @iteration-068 @wip        | WIP prevents completion  |

    Scenario: A path outside the acceptance feature directory is rejected safely
      Given a committed project with this feature:
        """
        @iteration-068
        Feature: Member profiles
          @todo
          Scenario: Add a profile photo
            Given something
        """
      When I run "dev bdd pick ../../hostile.feature:4"
      Then the command fails
      And stderr includes "feature must be a repository path below acceptance-tests/features"
      And no file bytes changed

    Scenario: Malformed Gherkin is rejected without changing repository bytes
      Given a committed project with this feature:
        """
        this is not Gherkin
        """
      When I run "dev bdd pick acceptance-tests/features/example.feature:1"
      Then the command fails
      And stderr includes "example.feature"
      And no file bytes changed

  Rule: A whole-outline pick must be eligible for every Examples group

    Scenario: An outline cannot activate nested journey examples
      Given a committed project with this feature:
        """
        @iteration-068
        Feature: Profile formats
          @todo
          Scenario Outline: Import a profile photo
            Given a <format> photo
            @journey
            Examples: Browser import
              | format |
              | png    |
        """
      When I pick the declaration "Scenario Outline: Import a profile photo"
      Then the command fails
      And stderr includes "outline affects ineligible journey Examples"
      And no file bytes changed

    Scenario: An outline cannot span active and future iteration ownership
      Given a committed project with this feature:
        """
        Feature: Profile formats
          @todo
          Scenario Outline: Import a profile photo
            Given a <format> photo
            @iteration-068
            Examples: Current formats
              | format |
              | jpg    |
            @iteration-069
            Examples: Future formats
              | format |
              | png    |
        """
      When I pick the declaration "Scenario Outline: Import a profile photo"
      Then the command fails
      And stderr includes "outline spans multiple iterations"
      And no file bytes changed

  Rule: Tags and repository bytes remain unambiguous

    Scenario: Duplicate local TODO tags are rejected
      Given a committed project with this feature:
        """
        @iteration-068
        Feature: Member profiles
          @todo @fast @todo
          Scenario: Add a profile photo
            Given something
        """
      When I pick the declaration "Scenario: Add a profile photo"
      Then the command fails
      And stderr includes "exactly one local @todo"
      And no file bytes changed

    Scenario: Aliased iteration spellings are rejected as conflicting ownership
      Given a committed project with this feature:
        """
        @iteration-068
        Feature: Member profiles
          @iteration-68 @todo
          Scenario: Add a profile photo
            Given something
        """
      When I pick the declaration "Scenario: Add a profile photo"
      Then the command fails
      And stderr includes "conflicting iteration tag spellings"
      And no file bytes changed

    Scenario: Repeated inherited spelling for the same owner remains valid
      Given a committed project with this feature:
        """
        @iteration-068
        Feature: Member profiles
          @iteration-068
          Rule: Photos
            @todo
            Scenario: Add a profile photo
              Given something
        """
      When I pick the declaration "Scenario: Add a profile photo"
      Then the command succeeds
      And the feature contains "    @wip\n    Scenario: Add a profile photo"

    Scenario: Invalid comment bytes, executable mode and an astral tag survive pick
      Given a committed project with this feature:
        """
        @iteration-068
        Feature: Member profiles
          @😀 @todo @fast
          Scenario: Add a profile photo
            Given something
        """
      And the feature has invalid comment bytes and mode "0751"
      When I pick the declaration "Scenario: Add a profile photo"
      Then the command succeeds
      And only the TODO tag bytes changed and mode remains "0751"
      And the feature contains "  @😀 @wip @fast"

  Rule: Mutation refuses stale state and owns only its temporary file

    Scenario Outline: A concurrent feature replacement is preserved
      Given a committed project with this feature:
        """
        @iteration-068
        Feature: Member profiles
          @todo
          Scenario: Add a profile photo
            Given original state
        """
      And I remember the commit as "snapshot A"
      And a concurrent <kind> replaces the feature during pick with:
        """
        @iteration-068
        Feature: Member profiles
          @todo
          Scenario: Add a profile photo
            Given concurrent state
        """
      When I pick "Scenario: Add a profile photo" from commit "snapshot A" during the concurrent change
      Then the command fails
      And stderr includes "repository changed while pick was validating"
      And the concurrent feature is preserved
      And no owned pick temporary file remains

      Examples:
        | kind       |
        | edit       |
        | commit     |

    Scenario: An unowned colliding temporary file is never deleted
      Given a committed project with this feature:
        """
        @iteration-068
        Feature: Member profiles
          @todo
          Scenario: Add a profile photo
            Given something
        """
      And a colliding ignored pick temporary file will be created by the CLI process
      When I pick the declaration through the PID-collision shell "Scenario: Add a profile photo"
      Then the command fails
      And stderr includes "EEXIST"
      And the unowned collision sentinel remains unchanged
      And no file bytes changed

    Scenario: An unrelated concurrent commit changes HEAD without changing the selected feature
      Given a committed project with this feature:
        """
        @iteration-068
        Feature: Member profiles
          @todo
          Scenario: Add a profile photo
            Given original state
        """
      And I remember the commit as "snapshot A"
      And a concurrent unrelated commit occurs during pick
      When I pick "Scenario: Add a profile photo" from commit "snapshot A" during the concurrent change
      Then the command fails
      And stderr includes "repository changed while pick was validating"
      And the selected feature remains unchanged
      And HEAD no longer names commit "snapshot A"
      And no owned pick temporary file remains

    Scenario: A partial owned temporary write is cleaned up without changing the target
      Given a committed project with this feature:
        """
        @iteration-068
        Feature: Member profiles
          @todo
          Scenario: Add a profile photo
            Given original state
        """
      And the owned temporary write will fail after writing some bytes
      When I pick the declaration "Scenario: Add a profile photo"
      Then the command fails
      And stderr includes "injected partial owned-temp write failure"
      And the owned temporary descriptor was closed
      And the selected feature remains unchanged
      And no owned pick temporary file remains

  Rule: Help is available without starting application infrastructure

    Scenario Outline: Every BDD command provides successful help
      Given a committed project with this feature:
        """
        @iteration-068
        Feature: Complete work
          Scenario: Complete example
            Given something
        """
      When I run "<command>"
      Then the command succeeds
      And stdout includes "<usage>"

      Examples:
        | command                | usage                  |
        | dev bdd --help         | Usage: dev bdd         |
        | dev bdd pending -h     | dev bdd pending        |
        | dev bdd pick --help    | dev bdd pick           |

    Scenario: Root help discovers the BDD command
      Given a committed project with this feature:
        """
        @iteration-068
        Feature: Complete work
          Scenario: Complete example
            Given something
        """
      And argc is available from the managed development profile
      When I run "dev --help"
      Then the command succeeds
      And command output includes "bdd"
