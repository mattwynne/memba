Feature: Homepage
  Memba gives each person the most useful starting point for their relationship with Memba.

Rule: Visitors see Memba's public volunteering promise

  @not-domain
  Scenario: Robin arrives without signing in
    When Robin visits the homepage
    Then Robin should see that volunteering should not feel like work
    And Robin should be invited to request access for a group
    And Robin should be offered to sign in

Rule: Club members go straight to their clubs

  @not-domain
  Scenario: Alice belongs to two clubs
    Given Alice is a member of Kootenay Mountaineering Club
    And Alice is a member of Nelson Paddling Club
    When Alice signs in
    And Alice visits the homepage
    Then Alice should see Kootenay Mountaineering Club in their clubs
    And Alice should see Nelson Paddling Club in their clubs
    But Alice should not see the public volunteering promise

Rule: Memba staff can reach staff operations

  @not-domain
  Scenario: Pat is Memba staff
    Given Pat is signed in as Memba staff
    When Pat visits the homepage
    Then Pat should be offered Memba staff access

Rule: Memba staff who are also club members can choose either path

  @not-domain
  Scenario: Pat is staff and a club member
    Given Pat is a member of Kootenay Mountaineering Club
    And Pat is signed in as Memba staff
    When Pat visits the homepage
    Then Pat should be offered Memba staff access
    And Pat should see Kootenay Mountaineering Club in their clubs

Rule: The homepage layout works on narrow screens

  @not-domain
  Scenario: Robin visits on a phone
    Given I am using a phone
    When Robin visits the homepage
    Then Robin should see that volunteering should not feel like work
    And the homepage should fit the screen
