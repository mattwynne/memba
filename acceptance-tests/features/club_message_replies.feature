@iteration-039
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

  @todo-ui
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

    @todo-ui
    Scenario: Former members do not receive replies even if they followed before leaving
      Given Dana follows the conversation for "Trip planning night"
      And Dana is no longer a member of Kootenay Mountaineering Club
      When Bob replies "I can drive, three seats spare" to "Trip planning night"
      Then Alice should receive Bob's reply by email from Kootenay Mountaineering Club via Memba
      And Dana should not receive Bob's reply by email

    @todo-ui
    Scenario: A reply-email stop-follow link unfollows only that recipient
      Given Carol follows the conversation for "Trip planning night"
      When Bob replies "I can drive, three seats spare" to "Trip planning night"
      Then Alice and Carol should each receive Bob's reply by email from Kootenay Mountaineering Club via Memba
      When Carol follows the stop-follow link from Bob's reply email
      Then Carol should not be following the conversation for "Trip planning night"
      When Alice replies "Leaving at seven from the trailhead" to "Trip planning night"
      Then Bob should receive Alice's reply by email from Kootenay Mountaineering Club via Memba
      And Carol should not receive Alice's reply by email

    @todo-ui
    Scenario: A tampered stop-follow link changes nothing
      Given Carol follows the conversation for "Trip planning night"
      When Carol follows a tampered stop-follow link for "Trip planning night"
      Then Carol should be told the stop-follow link is not valid
      And Carol should be following the conversation for "Trip planning night"

  @todo-ui
  Rule: Only a current member of the club can reply to its messages

    Scenario: A member of another club cannot reply
      Then Pat should not be able to reply to "Trip planning night"

  @iteration-041 @todo-ui
  Rule: Email replies use standard reply headers to join conversations

    Scenario: Bob replies by email and followers receive the reply
      Given Carol follows the conversation for "Trip planning night"
      When Bob replies by email to "Trip planning night" with:
        """
        I can bring maps.

        On Tue, Alice wrote:
        > Trip planning night details.
        """
      Then the conversation for "Trip planning night" should show Bob's reply "I can bring maps."
      And Bob should be following the conversation for "Trip planning night"
      And Alice and Carol should each receive Bob's reply by email from Kootenay Mountaineering Club via Memba
      And Dana should not receive Bob's reply by email
      And Bob should not receive his own reply by email

    @iteration-042
    Scenario: Email to the club address without reply headers starts a new club-wide message
      When Bob emails "Re: Trip planning night" to everyone@kmc.clubs.memba.io
      Then Bob should see the message "Re: Trip planning night" in Kootenay Mountaineering Club
      And the conversation for "Trip planning night" should not show Bob's reply "Re: Trip planning night details."

    Scenario: A non-member email reply is rejected
      When Pat replies by email to "Trip planning night" with:
        """
        I should not be able to reply from email.
        """
      Then the conversation for "Trip planning night" should not show Pat's reply "I should not be able to reply from email."
      And Pat should receive a rejection email explaining the message was not posted
      And Pat should be told how to contact support

    @iteration-042
    Scenario: Reply headers from another club do not create a cross-club reply
      Given Pat sent the message "Paddle planning" to Nelson Paddling Club members
      When Alice emails "Re: Paddle planning" to everyone@kmc.clubs.memba.io with reply headers from "Paddle planning"
      Then Alice should see the message "Re: Paddle planning" in Kootenay Mountaineering Club
      And the conversation for "Paddle planning" should not show Alice's reply "Re: Paddle planning details."

  @todo-ui
  Rule: Email replies use the everyone address on the club email subdomain

    @iteration-042
    Scenario: Bob replies by email through the KMC everyone address
      When Bob replies by email to "Trip planning night" through everyone@kmc.clubs.memba.io
      Then the conversation for "Trip planning night" should show Bob's reply
      And Alice should receive Bob's reply by email from Kootenay Mountaineering Club via Memba

  @iteration-043 @todo-ui
  Rule: On the club home, each conversation is one entry with its reply count

    @iteration-050
    Scenario: Conversation rows show previews without the redundant panel heading
      Then Alice's club home should show the "Trip planning night" conversation preview "Trip planning night details."
      And Alice's club home should not show the "Recent club messages" heading

    Scenario: A replied-to message appears once, with its reply count
      When Bob replies "I can drive, three seats spare" to "Trip planning night"
      And Carol replies "I'll bring the maps" to "Trip planning night"
      Then Alice's club home should list one conversation for "Trip planning night"
      And the "Trip planning night" conversation should show 2 replies
      And the "Trip planning night" conversation should show the latest reply is from Carol

    Scenario: A message with no replies shows none yet
      Then Alice's club home should list one conversation for "Trip planning night"
      And the "Trip planning night" conversation should show no replies yet

    Scenario: Conversations are ordered by original message, newest first
      Given Bob sent the message "Gear swap shelf" to Kootenay Mountaineering Club members
      When Carol replies "I'll take the old skis" to "Trip planning night"
      Then Alice's club home should list "Gear swap shelf" before "Trip planning night"

  @iteration-050 @todo-ui
  Rule: Conversation pages match the member-visible conversation design

    Scenario: Conversation entries omit kind badges and the duplicate sender line
      When Bob replies "I can drive, three seats spare" to "Trip planning night"
      Then Alice should not see conversation entry kind badges for "Trip planning night"
      And Alice should not see a separate "From Alice" line under the title for "Trip planning night"
