Feature: Homepage
  Scenario: Visiting the homepage
    When I visit the homepage
    Then I should see the Memba homepage

  Scenario: Visiting the homepage on a phone
    Given I am using a phone
    When I visit the homepage
    Then I should see the Memba homepage
    And the homepage should fit the screen
