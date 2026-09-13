@iteration-058
Feature: Group-scoped club conversations
  Active club members can discover every group in their club.
  Seeing a group does not grant access to its conversations or membership list.

  Background:
    Given Kootenay Mountaineering Club is a club
    And Alice, Bob, Carol, and Dana are members of Kootenay Mountaineering Club

  Rule: Every active club member can discover the club's groups

    @iteration-061
    Scenario: Alice sees Admin without belonging to it
      When Alice views the Kootenay Mountaineering Club home
      Then Alice should see the Everyone group
      And Alice should see the Admin group
      But Alice should not become a member of the Admin group

    Scenario: Bob sees Everyone and Admin
      Given Bob and Carol are members of the Kootenay Mountaineering Club Admin group
      When Bob views the Kootenay Mountaineering Club home
      Then Bob should see the Everyone group
      And Bob should see the Admin group

    Scenario: A future named group is presented without a bespoke screen
      Given Alice and Carol are members of the Kootenay Mountaineering Club Trips committee group
      When Alice views the Kootenay Mountaineering Club home
      Then Alice should see the Trips committee group
      And Bob should not be listed as a member of the Trips committee group

  Rule: The selected group scopes the club home

    Scenario: An Admin member views Admin conversations and members
      Given Bob and Carol are members of the Kootenay Mountaineering Club Admin group
      And the Kootenay Mountaineering Club Admin group has the conversation "Committee meeting"
      And the Everyone group has the conversation "Trip planning night"
      When Bob selects the Admin group
      Then Bob should see the conversation "Committee meeting"
      And Bob should not see the conversation "Trip planning night"
      And Bob should see Carol in the member list
      And Bob should not see Alice in the member list

  Rule: A new message belongs to the selected group

    Scenario: Bob starts an Admin conversation in the web app
      Given Bob and Carol are members of the Kootenay Mountaineering Club Admin group
      When Bob sends the message "Committee meeting" to the Admin group in the web app
      Then Bob and Carol should be able to read the Admin conversation "Committee meeting"
      And Alice should not be able to read the Admin conversation "Committee meeting"
      And Bob and Carol should each receive the Admin message "Committee meeting" by email from Kootenay Mountaineering Club via Memba

  Rule: Group discovery does not grant conversation or membership-list access

    @iteration-061
    Scenario: Alice follows an Admin group link
      Given Bob and Carol are members of the Kootenay Mountaineering Club Admin group
      When Alice tries to view the Admin group
      Then Alice should be told that she does not belong to Admin
      And Alice should see the club Admin email address
      But Alice should see neither Admin conversations nor its membership list

    @iteration-061
    Scenario: Alice can find Board but cannot read its discussions
      Given Alice is not a club admin
      And Bob and Carol are members of the Kootenay Mountaineering Club Board group
      And Board has the conversation "September agenda"
      When Alice opens Board
      Then Alice should see Board's name and the club Admin email address
      But Alice should see neither Board conversations nor its membership list
      And Alice should not become a member of Board

    @iteration-061
    Scenario: Bob inspects Board's members without joining
      Given Bob is a club admin
      And Carol and Dana are the only members of the Kootenay Mountaineering Club Board group
      When Bob views Board's members
      Then Bob should see Carol and Dana as Board's members
      But Bob should not belong to Board
      And Bob should not have access to Board conversations

    @iteration-061 @not-domain
    Scenario: Bob has Members but no Conversations while outside Board
      Given Bob is a club admin
      And Carol is the only member of the Kootenay Mountaineering Club Board group
      When Bob opens Board
      Then Bob should have Board's Members section available
      But Board's Conversations section and New message action should be absent

    @iteration-061
    Scenario Outline: Neither ordinary membership nor club administration grants Board access
      Given Bob is a club admin
      And Alice is not a club admin
      And Carol is the only member of the Kootenay Mountaineering Club Board group
      And Board has the conversation "September agenda"
      When <person> directly tries to <action>
      Then the attempt should be refused
      And no Board conversation content should be disclosed to <person>
      And no message, reply, or follow should be created by the attempt

      Examples:
        | person | action                                    |
        | Alice  | read "September agenda"                   |
        | Bob    | read "September agenda"                   |
        | Alice  | reply to "September agenda" on the website |
        | Bob    | follow "September agenda"                 |
        | Alice  | start a Board conversation on the website  |
        | Bob    | start a Board conversation on the website  |

    @iteration-061
    Scenario: Another club's member cannot discover KMC groups
      Given Pat belongs to Nelson Paddling Club but not Kootenay Mountaineering Club
      And Carol is a member of the Kootenay Mountaineering Club Board group
      When Pat opens a link to Kootenay Mountaineering Club's Board
      Then no KMC group details should be disclosed to Pat

    @iteration-065 @todo-domain @todo-ui
    Scenario: Alice can request Board access without writing a message
      Given Alice is not a club admin
      And Carol is a member of the Kootenay Mountaineering Club Board group
      When Alice opens Board
      Then Alice should be offered Request access
      And Alice should not be asked to compose a message

  Rule: The club home returns to the member's last selected group

    @iteration-061 @not-domain
    Scenario: Alice returns to a group she has not joined
      Given Alice is not a club admin
      And Carol is a member of the Kootenay Mountaineering Club Board group
      And Alice most recently viewed Board in Kootenay Mountaineering Club
      When Alice opens the Kootenay Mountaineering Club home
      Then Alice should see Board selected with access guidance
      But Alice should see neither Board conversations nor its membership list

    @not-domain
    Scenario: Bob returns to Admin
      Given Bob and Carol are members of the Kootenay Mountaineering Club Admin group
      And Bob most recently viewed the Admin group in Kootenay Mountaineering Club
      When Bob opens the Kootenay Mountaineering Club home
      Then Bob should see the Admin group selected

    @not-domain
    Scenario: Alice has no remembered group
      Given Alice has not previously selected a group in Kootenay Mountaineering Club
      When Alice opens the Kootenay Mountaineering Club home
      Then Alice should see the Everyone group selected
