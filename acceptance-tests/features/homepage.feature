Feature: Homepage
  @not-domain
  Scenario: Visiting the homepage
    When I visit the homepage
    Then I should see the Memba homepage

Rule: The homepage leads with Memba's volunteering promise

  @iteration-031 @not-domain
  Scenario: Robin sees the volunteering vision first
    When I visit the homepage
    Then I should see that volunteering should not feel like work

  @not-domain
  Scenario: Visiting the homepage on a phone
    Given I am using a phone
    When I visit the homepage
    Then I should see the Memba homepage
    And the homepage should fit the screen
