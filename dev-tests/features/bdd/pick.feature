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
