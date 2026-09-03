defmodule MembaWeb.Admin.ClubsLive.ShowTest do
  use MembaWeb.FeatureCase, async: false

  import Phoenix.LiveViewTest

  alias Memba.Membership
  alias Memba.Membership.Projections.Club, as: ClubProjection
  alias Memba.Messaging
  alias MembaWeb.ClubSite

  test "club detail separates club facts, person records, and memberships", %{conn: conn} do
    club = insert_membership_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    person = insert_membership_person!(name: "Alice Example", email: "alice@example.com")

    assert :ok =
             Membership.add_member(
               %{
                 membership_id: Memba.ID.generate(:membership),
                 club_id: club.club_id,
                 person_id: person.person_id
               },
               consistency: :strong
             )

    {:ok, view, _initial_html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/clubs/#{club.club_id}")

    assert has_element?(view, "#club-show[data-admin-page='club-detail']")
    assert has_element?(view, "#club-facts-card", "Club facts")
    assert has_element?(view, "#club-facts-edit-card #edit-club-form[aria-label='Edit club']")
    assert has_element?(view, "#people-records-card #people[aria-label='People']")
    assert has_element?(view, "#people-records-card #person-#{person.person_id}", "Alice Example")
    assert has_element?(view, "#memberships-card", "Memberships")
    assert has_element?(view, "#memberships-card #invite-member-link", "Invite member")
    assert has_element?(view, "#memberships-invitation-notice", "Invitation required")
    refute has_element?(view, "#memberships-card #add-member-form")
    assert has_element?(view, "#memberships-card #members[aria-label='Members']")
    assert has_element?(view, "#memberships-card #member-#{person.person_id}", "Alice Example")
    assert has_element?(view, "#staff-club-home-link[href='#{ClubSite.url(club)}']")
    refute has_element?(view, "#staff-club-home-link[href^='/?club_id=']")
  end

  test "club detail does not offer staff-side message composition", %{conn: conn} do
    club = insert_membership_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    person = insert_membership_person!(name: "Alice Example", email: "alice@example.com")

    assert :ok =
             Membership.add_member(
               %{
                 membership_id: Memba.ID.generate(:membership),
                 club_id: club.club_id,
                 person_id: person.person_id
               },
               consistency: :strong
             )

    {:ok, view, _initial_html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/clubs/#{club.club_id}")

    assert has_element?(view, "#club-messaging-card")
    assert has_element?(view, "#club-messages-link[href='/admin/messages']")
    assert has_element?(view, "#club-messages-link[aria-label='Open global Messages']")
    refute has_element?(view, "#new-message-form")
    refute has_element?(view, "#message-sender-select")
    refute has_element?(view, "#message-subject-input")
    refute has_element?(view, "#message-body-input")
    refute has_element?(view, "#send-message-button")
    refute has_element?(view, "#club-messaging-card form")
    refute has_element?(view, "#club-messaging-card [aria-label='Send a club message']")
  end

  test "club detail points message review to global Messages instead of embedding club rows", %{
    conn: conn
  } do
    club_id = Memba.ID.generate(:club)

    assert :ok =
             Membership.create_club(
               %{club_id: club_id, name: "Kootenay Mountaineering Club", slug: "kmc"},
               consistency: :strong
             )

    person = insert_membership_person!(name: "Alice Example", email: "alice@example.com")

    assert :ok =
             Membership.add_member(
               %{
                 membership_id: Memba.ID.generate(:membership),
                 club_id: club_id,
                 person_id: person.person_id
               },
               consistency: :strong
             )

    result =
      Messaging.send_club_message(
        %{
          message_id: Memba.ID.generate(:message),
          club_id: club_id,
          sender_id: person.person_id,
          subject: "Trip planning night",
          body: "Bring route ideas."
        },
        consistency: :strong
      )

    assert result == :ok or match?({:ok, _result}, result)

    {:ok, view, _initial_html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/clubs/#{club_id}")

    assert has_element?(view, "#club-messaging-card", "Messages live globally")

    assert has_element?(
             view,
             "#club-messages-link[href='/admin/messages']",
             "Open global Messages"
           )

    refute has_element?(view, "#messages")
    refute has_element?(view, "[data-testid='message-row']")
    refute has_element?(view, "[data-testid='message-link']")
    refute has_element?(view, "#club-messaging-card", "Trip planning night")
  end

  test "edit form displays and saves a club name and slug", %{conn: conn} do
    club_id = Memba.ID.generate(:club)

    assert :ok =
             Membership.create_club(
               %{club_id: club_id, name: "Kootenay Mountaineering Club", slug: "kmc"},
               consistency: :strong
             )

    {:ok, view, initial_html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/clubs/#{club_id}")

    assert has_element?(view, "#edit-club-form[aria-label='Edit club']")
    assert input_value(initial_html, "#edit-club-name-input") == "Kootenay Mountaineering Club"
    assert input_value(initial_html, "#edit-club-slug-input") == "kmc"

    view
    |> form("#edit-club-form", club: %{name: "KMC Alpine Club", slug: "kmc-alpine"})
    |> render_submit()

    assert has_element?(view, "#club-show", "KMC Alpine Club")

    updated_html = render(view)
    assert input_value(updated_html, "#edit-club-name-input") == "KMC Alpine Club"
    assert input_value(updated_html, "#edit-club-slug-input") == "kmc-alpine"

    assert %ClubProjection{name: "KMC Alpine Club", slug: "kmc-alpine"} =
             Membership.get_club(club_id)

    assert %ClubProjection{club_id: ^club_id} = Membership.get_club_by_slug("kmc-alpine")
    assert is_nil(Membership.get_club_by_slug("kmc"))
  end

  test "invalid edit submissions leave the form editable without changing the projection", %{
    conn: conn
  } do
    club_id = Memba.ID.generate(:club)

    assert :ok =
             Membership.create_club(
               %{club_id: club_id, name: "Kootenay Mountaineering Club", slug: "kmc"},
               consistency: :strong
             )

    {:ok, view, _initial_html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/clubs/#{club_id}")

    view
    |> form("#edit-club-form", club: %{name: "KMC Alpine Club", slug: "KMC Club!"})
    |> render_submit()

    invalid_html = render(view)
    assert input_value(invalid_html, "#edit-club-name-input") == "KMC Alpine Club"
    assert input_value(invalid_html, "#edit-club-slug-input") == "KMC Club!"

    assert %ClubProjection{name: "Kootenay Mountaineering Club", slug: "kmc"} =
             Membership.get_club(club_id)
  end

  test "slug validation feedback updates live while editing", %{conn: conn} do
    club_id = Memba.ID.generate(:club)

    assert :ok =
             Membership.create_club(
               %{club_id: club_id, name: "Kootenay Mountaineering Club", slug: "kmc"},
               consistency: :strong
             )

    {:ok, view, _initial_html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/clubs/#{club_id}")

    view
    |> form("#edit-club-form", club: %{name: "KMC", slug: "kmc club!"})
    |> render_change()

    assert has_element?(view, "#edit-club-slug-feedback[data-status='invalid']")
    assert has_element?(view, "#update-club-button[disabled]")

    view
    |> form("#edit-club-form", club: %{name: "KMC", slug: "kmc-alpine"})
    |> render_change()

    assert has_element?(view, "#edit-club-slug-feedback[data-status='available']")
    refute has_element?(view, "#update-club-button[disabled]")
  end

  test "slug availability feedback updates live while editing", %{conn: conn} do
    club_id = Memba.ID.generate(:club)
    other_club_id = Memba.ID.generate(:club)

    assert :ok =
             Membership.create_club(
               %{club_id: club_id, name: "Kootenay Mountaineering Club", slug: "kmc"},
               consistency: :strong
             )

    assert :ok =
             Membership.create_club(
               %{club_id: other_club_id, name: "Alpine Club", slug: "alpine"},
               consistency: :strong
             )

    {:ok, view, _initial_html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/clubs/#{club_id}")

    view
    |> form("#edit-club-form", club: %{name: "KMC", slug: "alpine"})
    |> render_change()

    assert has_element?(view, "#edit-club-slug-feedback[data-status='taken']")
    assert has_element?(view, "#update-club-button[disabled]")

    view
    |> form("#edit-club-form", club: %{name: "KMC", slug: "kmc"})
    |> render_change()

    assert has_element?(view, "#edit-club-slug-feedback[data-status='available']")
    refute has_element?(view, "#update-club-button[disabled]")
  end

  test "people and member lists show primary and alternate email addresses distinctly", %{
    conn: conn
  } do
    club = insert_membership_club!(name: "Kootenay Mountaineering Club")
    person = insert_membership_person!(name: "Alice Example", email: "alice@example.com")

    insert_membership_person_email_address!(
      person_id: person.person_id,
      email: "alice@work.example",
      is_primary: false
    )

    assert :ok =
             Membership.add_member(
               %{
                 membership_id: Memba.ID.generate(:membership),
                 club_id: club.club_id,
                 person_id: person.person_id
               },
               consistency: :strong
             )

    {:ok, view, _initial_html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/clubs/#{club.club_id}")

    refute has_element?(view, "#new-person-form")
    assert has_element?(view, "#new-person-link[href='/admin/clubs/#{club.club_id}/people/new']")

    assert has_element?(
             view,
             "#person-#{person.person_id} [data-testid='person-primary-email']",
             "alice@example.com"
           )

    assert has_element?(
             view,
             "#person-#{person.person_id} [data-testid='person-alternate-emails'][data-alternate-count='1']",
             "Alternate email addresses"
           )

    assert has_element?(
             view,
             "#person-#{person.person_id} [data-testid='person-alternate-email']",
             "alice@work.example"
           )

    assert has_element?(
             view,
             "#edit-person-link-#{person.person_id}[href='/admin/clubs/#{club.club_id}/people/#{person.person_id}/edit']"
           )

    assert has_element?(
             view,
             "#member-#{person.person_id} [data-testid='member-primary-email']",
             "alice@example.com"
           )

    assert has_element?(
             view,
             "#member-#{person.person_id} [data-testid='member-alternate-emails'][data-alternate-count='1']",
             "Alternate email addresses"
           )

    assert has_element?(
             view,
             "#member-#{person.person_id} [data-testid='member-alternate-email']",
             "alice@work.example"
           )
  end

  test "staff are directed to invitations instead of adding existing people directly", %{
    conn: conn
  } do
    club = insert_membership_club!(name: "Kootenay Mountaineering Club")
    alice = insert_membership_person!(name: "Alice Example", email: "alice@example.com")

    {:ok, view, _initial_html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/clubs/#{club.club_id}")

    assert has_element?(view, "#people [data-testid='person-row']", "Alice Example")
    refute has_element?(view, "#members [data-testid='member-row']", "Alice Example")
    refute has_element?(view, "#add-member-form")

    assert has_element?(
             view,
             "#invite-member-link[href='/admin/clubs/#{club.club_id}/invitations/new']"
           )

    assert has_element?(
             view,
             "#memberships-invitation-notice",
             "Staff no longer create active club memberships directly"
           )

    render_hook(view, "add_member", %{"membership" => %{"person_id" => alice.person_id}})

    assert_redirect(view, ~p"/admin/clubs/#{club.club_id}/invitations/new")
    refute Membership.active_member_of_club?(club.club_id, alice.person_id)
  end

  test "staff can remove a member from a club", %{conn: conn} do
    club = insert_membership_club!(name: "Kootenay Mountaineering Club")
    alice = insert_membership_person!(name: "Alice Example", email: "alice@example.com")
    membership_id = Memba.ID.generate(:membership)

    assert :ok =
             Membership.add_member(
               %{
                 membership_id: membership_id,
                 club_id: club.club_id,
                 person_id: alice.person_id
               },
               consistency: :strong
             )

    {:ok, view, _initial_html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/clubs/#{club.club_id}")

    assert has_element?(view, "#member-#{alice.person_id}", "Alice Example")

    view
    |> element("#remove-member-button-#{membership_id}")
    |> render_click()

    refute has_element?(view, "#member-#{alice.person_id}")
    refute Membership.active_member_of_club?(club.club_id, alice.person_id)
  end

  defp input_value(html, selector) do
    values =
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query(selector)
      |> LazyHTML.attribute("value")

    assert [value] = values
    value
  end
end
