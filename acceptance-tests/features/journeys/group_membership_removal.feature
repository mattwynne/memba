@journey @iteration-064
Feature: Losing access to an open group conversation

  Background:
    Given Kootenay Mountaineering Club has club email slug "kmc"
    And Alice and Dan are its club admins
    And Bob, Carol, and Eve are its ordinary active club members
    And Alice, Bob, and Carol are the only members of its custom group Board

  Rule: Losing group membership ends viewing of an already-open conversation

    Scenario: Bob removes Carol while she is reading September agenda
      Given Carol is reading Board's conversation "September agenda"
      When Bob removes Carol from Board
      Then Carol's open page should stop displaying "September agenda" without her navigating or refreshing
