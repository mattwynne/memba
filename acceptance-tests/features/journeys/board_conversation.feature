@journey @iteration-062
Feature: Start a private Board conversation on the club website
  A member can write to Board, another Board member can find the conversation,
  and someone outside Board cannot open it.

  Background:
    Given Kootenay Mountaineering Club has club email slug "kmc"
    And Alice and Dan are its club admins
    And Bob, Carol, and Eve are its ordinary active club members
    And Alice, Bob, and Carol are the only members of its custom group Board
    And Board's email address is "board@kmc.clubs.memba.io"

  Scenario: Bob posts September agenda, Alice finds it, and Dan cannot read it
    When Bob sends "September agenda" to Board on the website
    Then "September agenda" should be a Board conversation
    But Dan should neither be able to read it nor receive its email
