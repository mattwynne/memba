defmodule MembaWeb.MemberMessageLive.NewTest do
  use MembaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Group
  alias Memba.Membership.Projections.GroupMembership
  alias Memba.Membership.Projections.Membership
  alias Memba.Membership.SystemGroups
  alias Memba.Repo
  alias MembaWeb.ClubSite
  alias MembaWeb.IdentityAuth

  test "renders a member message compose LiveView shell in the club site layout", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, MembaWeb.MemberMessageLive.New)

    assert has_element?(view, "#club-site-layout[data-surface='club-site']")
    assert has_element?(view, "#member-message-compose[data-live-view='member-message-compose']")
  end

  test "routed GET on the club subdomain passes the selected club to the LiveView", %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/messages/new")

    assert has_element?(
             view,
             "#member-message-compose[data-club-id='#{alice.club_id}'][data-live-view='member-message-compose']"
           )

    assert has_element?(
             view,
             "#club-site-identity-menu .app-menu__who-name",
             "Alice Adams"
           )

    assert has_element?(
             view,
             "#club-site-identity-menu-button .global-bar__avatar",
             "AA"
           )
  end

  test "club subdomain routed mount keeps the host-selected club after LiveView connects", %{
    conn: conn
  } do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Kootenay Mountaineering Club",
        slug: "kmc"
      )

    _bob =
      create_active_member(
        email: "bob@example.com",
        name: "Bob Builder",
        club_name: "Kootenay Mountaineering Club",
        club_id: alice.club_id,
        slug: "kmc"
      )

    {:ok, view, _html} =
      conn
      |> Map.put(:host, "kmc.lvh.me")
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> live(~p"/messages/new")

    assert has_element?(
             view,
             "#member-message-compose[data-club-id='#{alice.club_id}'][data-current-member-id='#{alice.person_id}'][data-active-member-count='2']"
           )

    assert has_element?(view, "#member-compose-club-home-link[href='/conversations']")
    refute has_element?(view, "#member-compose-club-home-link[href*='club_id=']")
  end

  test "routed mount derives compose context from the signed-in member and selected club", %{
    conn: conn
  } do
    _other_alice_club =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Book Club"
      )

    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Climbing Club"
      )

    bob =
      create_active_member(
        email: "bob@example.com",
        name: "Bob Builder",
        club_name: "Climbing Club",
        club_id: alice.club_id
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/messages/new")

    assert has_element?(
             view,
             "#member-message-compose[data-club-id='#{alice.club_id}'][data-current-member-id='#{alice.person_id}'][data-active-member-count='2']"
           )

    assert has_element?(
             view,
             "#member-compose-selected-club[data-club-id='#{alice.club_id}']",
             "Climbing Club"
           )

    assert has_element?(
             view,
             "#member-compose-from-summary[data-sender-id='#{alice.person_id}']",
             "Alice Adams"
           )

    refute has_element?(view, "#member-compose-from-summary[data-sender-id='#{bob.person_id}']")

    assert has_element?(
             view,
             "#member-compose-recipient-summary[data-active-member-count='2']"
           )

    assert has_element?(view, "form#member-message-compose-form")
    assert has_element?(view, "input#member-message-subject-input[name='message[subject]']")
    assert has_element?(view, "textarea#member-message-body-input[name='message[body]']")
    refute has_element?(view, "[name='message[sender_id]']")
  end

  test "routed compose screen renders the focused member message form affordances", %{
    conn: conn
  } do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Climbing Club"
      )

    _bob =
      create_active_member(
        email: "bob@example.com",
        name: "Bob Builder",
        club_name: "Climbing Club",
        club_id: alice.club_id
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/messages/new")

    assert has_element?(
             view,
             "#member-compose-club-home-link[href='/conversations']",
             "Club home"
           )

    assert has_element?(view, "#member-compose-eyebrow", "New message")

    assert has_element?(
             view,
             "#member-compose-recipient-summary[data-active-member-count='2']",
             "all 2 current members"
           )

    assert has_element?(
             view,
             "#member-compose-recipient-summary",
             "There is no list to pick"
           )

    assert has_element?(
             view,
             "#member-compose-from-summary[data-sender-id='#{alice.person_id}'][aria-label='Sending as Alice Adams']",
             "Sending as yourself"
           )

    assert has_element?(
             view,
             "#member-compose-from-summary #member-compose-from-avatar.avatar.avatar-placeholder[data-testid='member-compose-from-avatar'][title='Alice Adams']",
             "AA"
           )

    assert has_element?(
             view,
             "input#member-message-subject-input[placeholder='Example: Saturday trail day']"
           )

    assert has_element?(
             view,
             "textarea#member-message-body-input[placeholder='Write the message members should receive.'][rows='8']"
           )

    assert has_element?(
             view,
             "button#member-message-send-button.btn.btn-primary.btn-lg[type='submit']",
             "Send to all current members"
           )

    assert has_element?(
             view,
             "#member-message-cancel-link.btn.btn-soft.btn-lg[href='/conversations']",
             "Cancel"
           )

    refute has_element?(view, "select")
    refute has_element?(view, "[name='message[sender_id]']")
  end

  test "routed compose screen shows the selected club inbound email address", %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Kootenay Mountaineering Club",
        slug: "kmc"
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/messages/new")

    assert has_element?(
             view,
             "#member-compose-inbound-email[data-inbound-address='everyone@kmc.clubs.memba.io']"
           )

    assert has_element?(view, "#member-compose-inbound-email", "Prefer email?")

    assert has_element?(
             view,
             "#member-compose-inbound-email",
             "You can also send a club-wide message to"
           )

    assert has_element?(
             view,
             "#member-compose-inbound-email-link[href='mailto:everyone@kmc.clubs.memba.io']",
             "everyone@kmc.clubs.memba.io"
           )

    refute has_element?(
             view,
             "#member-compose-inbound-email[data-inbound-address='kmc@clubs.memba.io']"
           )

    refute has_element?(
             view,
             "#member-compose-inbound-email-link[href='mailto:kmc@clubs.memba.io']"
           )
  end

  test "routed GET redirects signed-out visitors and preserves the selected club return path",
       %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Climbing Club"
      )

    %{host: host} =
      alice.club_id |> Memba.Membership.get_club() |> ClubSite.url("/messages/new") |> URI.parse()

    return_path = "http://#{host}/messages/new"

    conn =
      conn
      |> club_host(alice)
      |> get(~p"/messages/new")

    assert redirected_to(conn) == ~p"/auth"
    assert get_session(conn, IdentityAuth.return_to_session_key()) == return_path
  end

  test "routed GET forbids a signed-in identity when the selected club is missing", %{
    conn: conn
  } do
    _alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Climbing Club"
      )

    conn =
      conn
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> get(~p"/messages/new")

    assert response(conn, 403) == "Forbidden"
  end

  test "routed GET forbids a signed-in identity outside the selected club", %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Climbing Club"
      )

    conn =
      conn
      |> club_host(alice)
      |> init_test_session(%{IdentityAuth.identity_session_key() => "pat@example.com"})
      |> get(~p"/messages/new")

    assert response(conn, 403) == "Forbidden"
  end

  defp signed_in_club_host(conn, email, club) do
    conn
    |> club_host(club)
    |> init_test_session(%{IdentityAuth.identity_session_key() => email})
  end

  defp club_host(conn, club) do
    club = Memba.Membership.get_club(club.club_id) || club
    %{host: host} = URI.parse(ClubSite.url(club))
    Map.put(conn, :host, host)
  end

  defp create_active_member(attrs) do
    club_id = Keyword.get_lazy(attrs, :club_id, fn -> Memba.ID.generate(:club) end)
    person_id = Memba.ID.generate(:person)

    Repo.get(Club, club_id) ||
      attrs
      |> club_attrs(club_id)
      |> insert_membership_club!()

    person =
      insert_membership_person!(
        person_id: person_id,
        name: Keyword.fetch!(attrs, :name),
        email: Keyword.fetch!(attrs, :email)
      )

    insert_everyone_group!(club_id)
    membership_id = Memba.ID.generate(:membership)

    Repo.insert!(%Membership{
      membership_id: membership_id,
      club_id: club_id,
      person_id: person.person_id,
      active: true
    })

    Repo.insert!(%GroupMembership{
      club_id: club_id,
      group_id: SystemGroups.everyone_group_id(club_id),
      membership_id: membership_id,
      person_id: person.person_id,
      active: true
    })

    %{club_id: club_id, person_id: person.person_id}
  end

  defp insert_everyone_group!(club_id) do
    group_id = SystemGroups.everyone_group_id(club_id)

    Repo.get(Group, group_id) ||
      Repo.insert!(%Group{
        club_id: club_id,
        group_id: group_id,
        group_key: SystemGroups.everyone_key(),
        name: SystemGroups.everyone_name()
      })
  end

  defp club_attrs(attrs, club_id) do
    base = [
      club_id: club_id,
      name: Keyword.get(attrs, :club_name, "Kootenay Mountaineering Club")
    ]

    case Keyword.fetch(attrs, :slug) do
      {:ok, slug} -> Keyword.put(base, :slug, slug)
      :error -> base
    end
  end
end
