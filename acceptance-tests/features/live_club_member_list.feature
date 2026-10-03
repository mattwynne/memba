Feature: Open club member lists stay current
  Club members see changes to their club while their page is open.

  Rule: An open club member list reflects membership changes

    @iteration-067
    Scenario: Bob sees Alice join without reloading
      Given Bob is a member of Kootenay Mountaineering Club
      And Bob is viewing the Kootenay Mountaineering Club member list
      And Alice is not a member of Kootenay Mountaineering Club
      When Alice becomes a member of Kootenay Mountaineering Club
      Then Bob should see Alice appear in the member list automatically
