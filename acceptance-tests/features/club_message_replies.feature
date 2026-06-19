@iteration-039 @todo-domain @todo-ui
Feature: Club message replies (thread conversations)
  Club members want to reply to a club message and follow the conversation in Memba,
  instead of replies scattering to private inboxes and never being tracked.
  A reply belongs to the original message's thread. Members opt in to follow a thread;
  the person who sent the message, and anyone who replies, follow it automatically.

  Background:
    Given Kootenay Mountaineering Club is a club
    And Nelson Paddling Club is a club
    And Alice, Bob, Carol, and Dana are people
    And Pat is a person
    And Alice, Bob, Carol, and Dana are members of Kootenay Mountaineering Club
    And Pat is a member of Nelson Paddling Club
    And Alice sent the message "Trip planning night" to Kootenay Mountaineering Club members

  Rule: A member can reply to a club message, and the reply joins that message's thread

    Scenario: Bob replies to Alice's club message
      When Bob replies "I can drive, three seats spare" to "Trip planning night"
      Then the thread for "Trip planning night" should show Bob's reply "I can drive, three seats spare"
      And Alice should see Bob's reply in the thread for "Trip planning night"

    Scenario: Replies are shown in the order they were posted
      When Bob replies "I can drive, three seats spare" to "Trip planning night"
      And Carol replies "I'll bring the maps" to "Trip planning night"
      Then the thread for "Trip planning night" should show "I can drive, three seats spare" before "I'll bring the maps"

  Rule: The sender follows their own thread, and replying to a thread follows it

    Scenario: The original sender follows the thread
      Then Alice should be following the thread for "Trip planning night"

    Scenario: Replying follows the thread
      When Bob replies "I can drive, three seats spare" to "Trip planning night"
      Then Bob should be following the thread for "Trip planning night"

  Rule: Recipients do not follow a thread until they choose to

    Scenario: A recipient is not following a thread by default
      Then Carol should not be following the thread for "Trip planning night"

    Scenario: Carol follows a thread to keep up with replies
      When Carol follows the thread for "Trip planning night"
      Then Carol should be following the thread for "Trip planning night"

    Scenario: Carol stops following a thread
      Given Carol is following the thread for "Trip planning night"
      When Carol stops following the thread for "Trip planning night"
      Then Carol should not be following the thread for "Trip planning night"

  Rule: Only a current member of the club can reply to its messages

    Scenario: A member of another club cannot reply
      Then Pat should not be able to reply to "Trip planning night"
