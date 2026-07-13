defmodule MembaWeb.AdminPeopleLiveTest do
  use MembaWeb.FeatureCase, async: false

  import Phoenix.LiveViewTest

  alias Memba.Membership
  alias MembaWeb.Admin.PersonEmailAddressForm

  test "staff can open the dedicated new-person LiveView for a club", %{conn: conn} do
    club = insert_membership_club!(name: "Kootenay Mountaineering Club")

    conn
    |> sign_in_staff()
    |> visit(~p"/admin/clubs/#{club.club_id}/people/new")
    |> assert_path("/admin/clubs/*/people/new")
    |> assert_has("#admin-layout[data-surface='admin']")
    |> assert_has("#person-new[data-admin-page='person-new'][data-club-id='#{club.club_id}']")
    |> assert_has("#person-page-header", "New person")
    |> assert_has("#person-workflow-summary")
    |> assert_has("#person-form-card")
    |> assert_has("#person-club-context-card", "Kootenay Mountaineering Club")
    |> assert_has("#back-to-club-link[href='/admin/clubs/#{club.club_id}']")
    |> assert_has("#person-form[aria-label='Create person']")
    |> assert_has("#person-name-input[aria-label='Person name']")
    |> assert_has("#person-email-addresses[aria-label='Email addresses']")
    |> assert_has("#person-email-row-0[data-testid='person-email-row'][data-primary='true']")
    |> assert_has("#person-email-input-0[aria-label='Email address 0']")
    |> assert_has("#person-primary-radio-0[checked]")
    |> assert_has("#add-person-email-address")
  end

  test "staff can open the dedicated edit-person LiveView for a club person", %{conn: conn} do
    club = insert_membership_club!(name: "Kootenay Mountaineering Club")
    person = insert_membership_person!(name: "Alice Example", email: "alice@example.com")

    insert_membership_person_email_address!(
      person_id: person.person_id,
      email: "alice@work.example",
      is_primary: false
    )

    conn
    |> sign_in_staff()
    |> visit(~p"/admin/clubs/#{club.club_id}/people/#{person.person_id}/edit")
    |> assert_path("/admin/clubs/*/people/*/edit")
    |> assert_has("#admin-layout[data-surface='admin']")
    |> assert_has(
      "#person-edit[data-admin-page='person-edit'][data-club-id='#{club.club_id}'][data-person-id='#{person.person_id}']"
    )
    |> assert_has("#person-page-header", "Edit Alice Example")
    |> assert_has("#person-workflow-summary")
    |> assert_has("#person-form-card")
    |> assert_has("#person-club-context-card", "Kootenay Mountaineering Club")
    |> assert_has("#back-to-club-link[href='/admin/clubs/#{club.club_id}']")
    |> assert_has("#person-form[aria-label='Edit person']")
    |> assert_has("#person-name-input[aria-label='Person name']")
    |> assert_has("#person-email-addresses[aria-label='Email addresses']")
    |> assert_has("#person-email-row-0[data-testid='person-email-row'][data-primary='true']")
    |> assert_has("#person-email-row-1[data-testid='person-email-row'][data-primary='false']")
    |> assert_has("#person-email-input-0[value='alice@example.com']")
    |> assert_has("#person-email-input-1[value='alice@work.example']")
    |> assert_has("#person-primary-radio-0[checked]")
    |> assert_has("#add-person-email-address")
  end

  test "staff creates a person with primary and alternate email rows", %{conn: conn} do
    club = insert_membership_club!(name: "Kootenay Mountaineering Club")

    {:ok, view, _html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/clubs/#{club.club_id}/people/new")

    view
    |> element("#add-person-email-address")
    |> render_click()

    view
    |> form("#person-form",
      person: %{
        name: "Alice Example",
        primary_email_index: "0",
        email_addresses: %{
          "0" => %{email: " Alice@Example.COM "},
          "1" => %{email: "alice@work.example"}
        }
      }
    )
    |> render_submit()

    assert_redirect(view, ~p"/admin/clubs/#{club.club_id}")

    assert %{person_id: person_id, email: "Alice@Example.COM"} =
             Membership.list_people()
             |> Enum.find(&(&1.name == "Alice Example"))

    assert [
             %{
               email: "Alice@Example.COM",
               normalized_email: "alice@example.com",
               primary?: true,
               verified_at: %DateTime{}
             },
             %{
               email: "alice@work.example",
               normalized_email: "alice@work.example",
               primary?: false,
               verified_at: %DateTime{}
             }
           ] = Membership.list_person_email_addresses(person_id)

    refute Membership.active_member_of_club?(club.club_id, person_id)
  end

  test "staff create form rejects malformed, missing-primary, multiple-primary, and duplicate email submissions",
       %{conn: conn} do
    club = insert_membership_club!(name: "Kootenay Mountaineering Club")

    assert :ok =
             Membership.create_person(
               %{
                 person_id: Memba.ID.generate(:person),
                 name: "Existing Alice",
                 email: "alice@example.com",
                 email_addresses: [%{email: "alice@example.com", is_primary: true}]
               },
               consistency: :strong
             )

    {:ok, view, _html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/clubs/#{club.club_id}/people/new")

    view
    |> form("#person-form",
      person: %{
        name: "Malformed Alice",
        primary_email_index: "0",
        email_addresses: %{"0" => %{email: "not-an-email"}}
      }
    )
    |> render_submit()

    assert has_element?(view, "#person-email-addresses-error", "Fix invalid email addresses.")
    assert has_element?(view, "#person-email-input-0.input-error")

    view
    |> element("#person-form")
    |> render_submit(%{
      "person" => %{
        "name" => "No Primary Alice",
        "primary_email_index" => "not-a-row",
        "email_addresses" => %{"0" => %{"email" => "alice@work.example"}}
      }
    })

    assert has_element?(
             view,
             "#person-email-addresses-error",
             "Choose exactly one primary email address."
           )

    assert {:error, %{global: "Choose exactly one primary email address."}} =
             PersonEmailAddressForm.validate(%{
               "name" => "Two Primary Alice",
               "email_addresses" => [
                 %{"email" => "alice@home.example", "is_primary" => "true"},
                 %{"email" => "alice@work.example", "is_primary" => "true"}
               ]
             })

    view
    |> form("#person-form",
      person: %{
        name: "Duplicate Alice",
        primary_email_index: "0",
        email_addresses: %{"0" => %{email: "alice@example.com"}}
      }
    )
    |> render_submit()

    assert has_element?(
             view,
             "#person-email-addresses-error",
             "An email address is already used by another person."
           )

    refute Membership.list_people() |> Enum.any?(&(&1.name == "Duplicate Alice"))
  end

  test "staff edit form replaces addresses and primary selection", %{conn: conn} do
    club = insert_membership_club!(name: "Kootenay Mountaineering Club")
    person_id = Memba.ID.generate(:person)

    assert :ok =
             Membership.create_person(
               %{
                 person_id: person_id,
                 name: "Alice Example",
                 email_addresses: [
                   %{email: "alice@example.com", is_primary: true},
                   %{email: "alice@work.example", is_primary: false}
                 ]
               },
               consistency: :strong
             )

    {:ok, view, _html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/clubs/#{club.club_id}/people/#{person_id}/edit")

    view
    |> form("#person-form",
      person: %{
        name: "Alice Example",
        primary_email_index: "1",
        email_addresses: %{
          "0" => %{email: "alice@example.com"},
          "1" => %{email: " alice@work.example "}
        }
      }
    )
    |> render_submit()

    assert_redirect(view, ~p"/admin/clubs/#{club.club_id}")

    assert %{email: "alice@work.example"} = Membership.get_person(person_id)

    assert [
             %{
               email: "alice@work.example",
               normalized_email: "alice@work.example",
               primary?: true,
               verified_at: %DateTime{}
             },
             %{
               email: "alice@example.com",
               normalized_email: "alice@example.com",
               primary?: false,
               verified_at: %DateTime{}
             }
           ] = Membership.list_person_email_addresses(person_id)
  end
end
