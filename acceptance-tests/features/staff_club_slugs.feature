@wip
Feature: Staff club slugs
  Memba staff prepare clubs for future email addresses and hosted club sites by managing each club's slug.

  Background:
    Given Pat is signed in as Memba staff

  Rule: A club gets an address-safe default slug from its name

    Scenario: Staff create a club with the suggested slug
      When Pat starts creating the club "Kootenay Mountaineering Club"
      Then Pat should see the suggested slug "kootenay-mountaineering-club"
      When Pat saves the club
      Then Kootenay Mountaineering Club should have the slug "kootenay-mountaineering-club"

  Rule: Staff-edited slugs must already be address-safe

    Scenario: Staff enter an invalid slug
      Given Kootenay Mountaineering Club is a club
      When Pat changes Kootenay Mountaineering Club's slug to "kmc club!"
      Then Pat should be told the slug is invalid
      And Pat should not be able to save the club slug

  Rule: A slug can belong to only one club

    Scenario: Staff enter a slug that another club already uses
      Given Kootenay Mountaineering Club has the slug "kmc"
      And Nelson Paddling Club is a club
      When Pat changes Nelson Paddling Club's slug to "kmc"
      Then Pat should be told the slug is already taken
      And Pat should not be able to save the club slug

  Rule: A club slug routes public visitors to that club's public page

    Scenario: Robin opens a club public page on its subdomain
      Given Kootenay Mountaineering Club has the slug "kmc"
      When Robin opens "kmc.clubs.memba.io"
      Then Robin should see the Kootenay Mountaineering Public club page
      And the club page should show Powered by Memba in the footer

    Scenario: Robin opens an unknown club subdomain
      When Robin opens "unknown.clubs.memba.io"
      Then Robin should see a not found page
