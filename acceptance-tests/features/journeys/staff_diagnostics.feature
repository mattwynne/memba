@journey
Feature: Staff diagnose a club message without speaking as its members

  Scenario: Pat reviews a club message through the staff MCP server
    Given Kootenay Mountaineering Club is a club
    And Alice is a member of Kootenay Mountaineering Club
    And Bob is a member of Kootenay Mountaineering Club
    And Alice has sent the message "Trip planning night" to Kootenay Mountaineering Club members
    When Pat lists the staff MCP tools
    Then Pat can list clubs, people, messages, and deliveries
    And Pat cannot send club messages as a member
    When Pat finds "Trip planning night" in the staff MCP message list
    Then the staff MCP server shows its delivery diagnostics
