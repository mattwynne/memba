@iteration-058
Feature: Group-scoped club conversations
  Club members need to find and use the conversations and people in the groups
  they belong to, without learning about private groups they do not belong to.

  Background:
    Given Kootenay Mountaineering Club is a club
    And Alice, Bob, Carol, and Dana are members of Kootenay Mountaineering Club

  Rule: A member can choose from the groups they belong to

    Scenario: Alice sees only Everyone
      When Alice views the Kootenay Mountaineering Club home
      Then Alice should see the Everyone group
      And Alice should not see the Admin group

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

  Rule: A private group does not disclose itself to non-members

    Scenario: Alice follows an Admin group link
      Given Bob and Carol are members of the Kootenay Mountaineering Club Admin group
      When Alice tries to view the Admin group
      Then Alice should be shown that the page was not found

  Rule: The club home returns to the member's last selected group

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
