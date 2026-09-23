Feature: Joining and leaving custom groups
  Membership grants the whole conversation history.
  Losing membership ends access and future emails, not ownership of delivered copies.

  Background:
    Given Kootenay Mountaineering Club has club email slug "kmc"
    And Alice and Dan are its club admins
    And Bob, Carol, and Eve are its ordinary active club members
    And Alice and Bob are the only members of its custom group Board
    And Board's email address is "board@kmc.clubs.memba.io"
    And Board has the conversation "September agenda" with the reply "Include the hut budget"

  @iteration-062
  Rule: Leaving the club ends custom-group memberships and their follows

    Scenario: Carol's club departure ends Board and Trips membership
      Given Carol belongs to Board and the custom group Trips
      And Carol follows conversations in both groups
      When Carol's KMC membership ends
      Then Carol should no longer belong to Board or Trips
      And Carol should no longer follow their conversations
      And Carol should have no access to their conversations
      And Carol should receive no future conversation or followed-reply emails from either group

    Scenario: Returning to KMC does not put Carol back into Board or Trips
      Given Carol belonged to Board and Trips before her KMC membership ended
      When Carol becomes an active KMC member again
      Then Carol should belong to Everyone
      But Carol should belong to neither Board nor Trips
      And Carol should have no access to their conversations or future group emails
      And Carol should see their access guidance

  @iteration-063
  Rule: Being added grants history and a welcome, not a replay of old emails

    Scenario: Carol joins after the agenda discussion has begun
      When Bob adds Carol to Board
      Then Carol should be able to read "September agenda" and "Include the hut budget"
      And Carol should receive a welcome email with a link to Board
      But Carol should not be sent old conversation emails from Board

    Scenario: Bob explicitly restores Carol's Board membership after she returns to KMC
      Given Carol has rejoined KMC after losing her Board membership
      When Bob adds Carol to Board
      Then Carol should belong to Board
      And Carol should be able to read Board's whole conversation history
      And Carol should receive a welcome email with a link to Board
      But Carol's former conversation follows should not be restored

  @iteration-064 @todo-domain @todo-ui
  Rule: Current group participation controls conversation activity

    Scenario Outline: Carol loses access even with an old Board conversation open
      Given Carol belongs to Board and follows "September agenda"
      And Carol is viewing "September agenda"
      When <membership_change>
      Then Carol should immediately lose access to every Board conversation
      And "September agenda" should no longer be available in her open view or through its link
      And Carol should no longer be allowed to post, reply to, or follow Board conversations
      And an email reply from Carol should not be added to "September agenda"
      And Carol should see the usual authorization error for each stale action
      But Carol should remain an active KMC member and see Board listed

      Examples:
        | membership_change            |
        | Carol leaves Board           |
        | Bob removes Carol from Board |

    Scenario Outline: Messages posted while Carol is absent create no delivery for her
      Given Carol belongs to Board and follows "September agenda"
      And <membership_change>
      When Bob replies "The budget is ready" to "September agenda"
      And Bob starts the Board conversation "October agenda"
      Then no email delivery should be created for Carol for "The budget is ready" or "October agenda"

      Examples:
        | membership_change            |
        | Carol leaves Board           |
        | Bob removes Carol from Board |

  @iteration-064 @todo-ui
  Rule: A message's email recipients are fixed when it is posted

    Scenario: Removing Carol does not cancel her queued email
      Given Carol belongs to Board and follows "September agenda"
      And Bob has posted the reply "The budget is ready" to "September agenda"
      And Carol's email delivery for "The budget is ready" is queued
      When Bob removes Carol from Board
      Then Carol should still receive "The budget is ready" by email
      But its conversation link should no longer give Carol access

    Scenario: Removing Carol cannot withdraw an email she already received
      Given Carol belongs to Board
      And Carol has received the Board message "Hut budget" by email
      When Bob removes Carol from Board
      Then Carol's delivered copy of "Hut budget" should not be withdrawn
      But its conversation link should no longer give Carol access

  @iteration-064 @todo-ui
  Rule: Follow preferences survive absence without creating a backlog

    Scenario: Carol's Board follow remains while she is absent
      Given Carol belongs to Board and follows "September agenda"
      When Carol leaves Board
      Then Carol should still follow "September agenda"
      But the follow should not give Carol access to it

    Scenario: Rejoining does not send messages posted during Carol's absence
      Given Carol belongs to Board and follows "September agenda"
      And Carol leaves Board
      And Bob replies "The budget is ready" to "September agenda"
      When Bob adds Carol back to Board
      Then Carol should receive no email or backlog for "The budget is ready"
      But Carol should be able to read "The budget is ready" on the website

    Scenario: Carol's follow resumes for messages posted after she rejoins
      Given Carol followed "September agenda" before leaving Board
      And Bob has added Carol back to Board
      When Bob replies "The figures are final" to "September agenda"
      Then Carol should receive "The figures are final" by email
      And Carol should still be following "September agenda"

  @iteration-064 @todo-ui
  Rule: The last member may leave without archiving or deleting the group

    Scenario: Bob leaves Board empty
      Given Bob is Board's only remaining member
      When Bob leaves Board
      Then Board should have no members
      And Board should remain listed for KMC members
      And its name, email address, and conversation history should be unchanged
      And Board should not be archived

    Scenario: Dan repopulates empty Board without joining it himself
      Given Board has no members
      When Dan adds Carol to Board
      Then Carol should be Board's only member
      And Carol should be able to read "September agenda" and "Include the hut budget"
      But Dan should still have no access to Board conversations

    Scenario: Eve cannot post to empty Board from outside the group
      Given Board has no members
      When Eve emails "Can Board consider a hut repair?" to board@kmc.clubs.memba.io
      Then Board should not have the conversation "Can Board consider a hut repair?"
      And Eve should receive the usual authorization rejection
      And no group recipient should receive an email for it
