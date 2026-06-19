@iteration-039 @todo-domain @todo-ui
Feature: Club message replies (conversations)
  Club members want to reply to a club message and keep the conversation in Memba,
  instead of replies scattering to private inboxes and never being tracked.
  A reply belongs to the original message's conversation, and is emailed to the club.
  (A later iteration lets members follow a conversation so only followers are emailed.)

  Background:
    Given Kootenay Mountaineering Club is a club
    And Nelson Paddling Club is a club
    And Alice, Bob, Carol, and Dana are people
    And Pat is a person
    And Alice, Bob, Carol, and Dana are members of Kootenay Mountaineering Club
    And Pat is a member of Nelson Paddling Club
    And Alice sent the message "Trip planning night" to Kootenay Mountaineering Club members

  Rule: A member can reply to a club message, and the reply joins that message's conversation

    Scenario: Bob replies to Alice's club message
      When Bob replies "I can drive, three seats spare" to "Trip planning night"
      Then the conversation for "Trip planning night" should show Bob's reply "I can drive, three seats spare"
      And Alice should see Bob's reply in the conversation for "Trip planning night"

    Scenario: Replies are shown in the order they were posted
      When Bob replies "I can drive, three seats spare" to "Trip planning night"
      And Carol replies "I'll bring the maps" to "Trip planning night"
      Then the conversation for "Trip planning night" should show "I can drive, three seats spare" before "I'll bring the maps"

  Rule: A reply is emailed to every current member of the club

    Scenario: Every other member receives Bob's reply
      When Bob replies "I can drive, three seats spare" to "Trip planning night"
      Then Alice, Carol, and Dana should each receive Bob's reply by email from Kootenay Mountaineering Club via Memba
      And Bob should not receive his own reply by email

  Rule: Only a current member of the club can reply to its messages

    Scenario: A member of another club cannot reply
      Then Pat should not be able to reply to "Trip planning night"
