@not-ui @iteration-039
Feature: Club message replies (conversations)
  Club members want to reply to a club message and keep the conversation in Memba,
  instead of replies scattering to private inboxes and never being tracked.
  A reply belongs to the original message's conversation, and is emailed to the
  current club-member followers of that conversation.

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

  @iteration-040
  Rule: A reply is emailed to current club-member followers

    Scenario: The sender and repliers automatically follow the conversation
      Then Alice should be following the conversation for "Trip planning night"
      And Carol should not be following the conversation for "Trip planning night"
      When Bob replies "I can drive, three seats spare" to "Trip planning night"
      Then Bob should be following the conversation for "Trip planning night"
      And Carol should not be following the conversation for "Trip planning night"

    Scenario: A member can follow and stop following the conversation
      When Carol follows the conversation for "Trip planning night"
      Then Carol should be following the conversation for "Trip planning night"
      When Carol stops following the conversation for "Trip planning night"
      Then Carol should not be following the conversation for "Trip planning night"

    Scenario: Followers receive Bob's reply, but non-followers and the author do not
      Given Carol follows the conversation for "Trip planning night"
      When Bob replies "I can drive, three seats spare" to "Trip planning night"
      Then Alice and Carol should each receive Bob's reply by email from Kootenay Mountaineering Club via Memba
      And Dana should not receive Bob's reply by email
      And Bob should not receive his own reply by email

    Scenario: Former members do not receive replies even if they followed before leaving
      Given Dana follows the conversation for "Trip planning night"
      And Dana is no longer a member of Kootenay Mountaineering Club
      When Bob replies "I can drive, three seats spare" to "Trip planning night"
      Then Alice should receive Bob's reply by email from Kootenay Mountaineering Club via Memba
      And Dana should not receive Bob's reply by email

    Scenario: A reply-email stop-follow link unfollows only that recipient
      Given Carol follows the conversation for "Trip planning night"
      When Bob replies "I can drive, three seats spare" to "Trip planning night"
      Then Alice and Carol should each receive Bob's reply by email from Kootenay Mountaineering Club via Memba
      When Carol follows the stop-follow link from Bob's reply email
      Then Carol should not be following the conversation for "Trip planning night"
      When Alice replies "Leaving at seven from the trailhead" to "Trip planning night"
      Then Bob should receive Alice's reply by email from Kootenay Mountaineering Club via Memba
      And Carol should not receive Alice's reply by email

    Scenario: A tampered stop-follow link changes nothing
      Given Carol follows the conversation for "Trip planning night"
      When Carol follows a tampered stop-follow link for "Trip planning night"
      Then Carol should be told the stop-follow link is not valid
      And Carol should be following the conversation for "Trip planning night"

  Rule: Only a current member of the club can reply to its messages

    Scenario: A member of another club cannot reply
      Then Pat should not be able to reply to "Trip planning night"

  Rule: Email replies use the everyone address on the club email subdomain

    @iteration-042 @todo-domain @todo-ui
    Scenario: Bob replies by email through the KMC everyone address
      When Bob replies by email to "Trip planning night" through everyone@kmc.clubs.memba.io
      Then the conversation for "Trip planning night" should show Bob's reply
      And Alice should receive Bob's reply by email from Kootenay Mountaineering Club via Memba
