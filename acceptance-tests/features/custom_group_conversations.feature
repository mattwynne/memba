@iteration-062
Feature: Conversations within custom groups
  Group members use the existing conversation, reply, and follow behaviour.
  Emailing a group to start a conversation is not the same as joining it.

  Background:
    Given Kootenay Mountaineering Club has club email slug "kmc"
    And Alice and Dan are its club admins
    And Bob, Carol, and Eve are its ordinary active club members
    And Alice, Bob, and Carol are the only members of its custom group Board
    And Board's email address is "board@kmc.clubs.memba.io"

  Rule: Web composition belongs to the selected group

    Scenario: Bob starts a Board discussion without addressing Everyone
      When Bob sends "September agenda" to Board on the website
      Then "September agenda" should be a Board conversation
      And Alice, Bob, and Carol should be able to read it
      And Alice, Bob, and Carol should each receive its initial email
      But Dan and Eve should neither be able to read it nor receive its email
      And it should not appear among Everyone's conversations

  Rule: Current group participation is required to email a custom group

    Scenario: Eve cannot email Board while remaining outside it
      When Eve emails "Could you fund new ropes?" to board@kmc.clubs.memba.io
      Then no Board conversation named "Could you fund new ropes?" should be created
      And Eve should receive the existing message-not-posted rejection email
      And no email delivery should be created for "Could you fund new ropes?"

    Scenario: Bob receives the ordinary recipient copy of his own Board email
      When Bob emails "September agenda" to board@kmc.clubs.memba.io
      Then Alice, Bob, and Carol should each receive its initial email
      And Bob should be following "September agenda"

    Scenario Outline: Someone outside the active club membership cannot email Board
      Given <membership>
      When <person> emails "September agenda" to board@kmc.clubs.memba.io
      Then no Board conversation named "September agenda" should be created
      And <person> should receive the existing message-not-posted rejection email

      Examples:
        | person | membership                                              |
        | Pat    | Pat belongs to Nelson Paddling Club but not KMC           |
        | Robin  | Robin has no club membership                              |
        | Eve    | Eve is no longer an active member of KMC                  |

  Rule: Replies require current group participation

    Scenario Outline: Eve and Dan cannot reply to Bob's Board conversation
      Given Bob emailed "Could you fund new ropes?" to board@kmc.clubs.memba.io
      When <person> tries to reply "Here are the prices" to that conversation <channel>
      Then "Here are the prices" should not be added to that conversation
      And <person> should not gain access to that conversation

      Examples:
        | person | channel        |
        | Eve    | on the website |
        | Eve    | by email       |
        | Dan    | on the website |
        | Dan    | by email       |

    Scenario: Carol's email reply stays in Bob's Board conversation
      Given Bob emailed "September agenda" to board@kmc.clubs.memba.io
      When Carol replies by email "I can attend" to "September agenda"
      Then "I can attend" should be a reply in Board's "September agenda" conversation
      And Carol should be following that conversation
      And Bob should receive Carol's reply by email
      But Dan and Eve should not receive it

  Rule: Replies are emailed to eligible followers, excluding the reply's author

    Scenario: Carol follows Board's agenda while Alice does not
      Given Bob started Board's conversation "September agenda"
      And Carol follows "September agenda"
      And Alice does not follow "September agenda"
      When Bob replies "Please send your agenda items" to "September agenda" on the website
      Then Carol should receive Bob's reply by email
      But Alice should not receive Bob's reply by email
      And Bob should not receive his own reply by email

    Scenario: Carol stops following but can still read Board's agenda
      Given Bob started Board's conversation "September agenda"
      And Carol has stopped following "September agenda"
      When Bob replies "Please send your agenda items" to "September agenda"
      Then Carol should not receive Bob's reply by email
      But Carol should still be able to read the whole conversation
