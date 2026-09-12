defmodule MembaWeb.MemberMessageLive.NewTest do
  use MembaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Group
  alias Memba.Membership.Projections.GroupMembership
  alias Memba.Membership.Projections.Membership
  alias Memba.Membership.Projections.Person
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

  test "existing compose route defaults to the Everyone group", %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Climbing Club"
      )

    everyone_group_id = SystemGroups.everyone_group_id(alice.club_id)

    _bob =
      create_active_member(
        email: "bob@example.com",
        name: "Bob Builder",
        club_name: "Climbing Club",
        club_id: alice.club_id,
        everyone_group?: false
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/messages/new")

    assert has_element?(
             view,
             "#member-message-compose[data-club-id='#{alice.club_id}']" <>
               "[data-current-member-id='#{alice.person_id}']" <>
               "[data-audience-group-id='#{everyone_group_id}']" <>
               "[data-audience-group-name='Everyone']" <>
               "[data-active-member-count='1']"
           )

    assert has_element?(view, "h1", "New message to Everyone")

    assert has_element?(
             view,
             "#member-compose-recipient-summary" <>
               "[data-active-member-count='1']" <>
               "[data-audience-group-id='#{everyone_group_id}']" <>
               "[data-audience-group-name='Everyone']",
             "1 member"
           )

    assert has_element?(view, "#member-compose-recipient-summary", "Everyone")
    refute has_element?(view, "#member-compose-recipient-summary", "the current member")
  end

  test "requested audience group drives compose copy, count, email, and club context", %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Kootenay Mountaineering Club",
        slug: "kmc"
      )

    bob =
      create_active_member(
        email: "bob@example.com",
        name: "Bob Builder",
        club_name: "Kootenay Mountaineering Club",
        club_id: alice.club_id,
        slug: "kmc"
      )

    _carol =
      create_active_member(
        email: "carol@example.com",
        name: "Carol Canoe",
        club_name: "Kootenay Mountaineering Club",
        club_id: alice.club_id,
        slug: "kmc"
      )

    trip_planning_group =
      create_group(
        club_id: alice.club_id,
        group_key: "trip_planning",
        name: "Trip Planning",
        email_slug: "trip-planning"
      )

    add_group_member(trip_planning_group, alice)
    add_group_member(trip_planning_group, bob)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/messages/new?#{[group_id: trip_planning_group.group_id]}")

    assert has_element?(
             view,
             "#member-message-compose" <>
               "[data-club-id='#{alice.club_id}']" <>
               "[data-audience-group-id='#{trip_planning_group.group_id}']" <>
               "[data-audience-group-name='Trip Planning']" <>
               "[data-active-member-count='2']"
           )

    assert has_element?(view, "h1", "New message to Trip Planning")

    assert has_element?(
             view,
             "#member-compose-selected-club[data-club-id='#{alice.club_id}']",
             "In Kootenay Mountaineering Club"
           )

    assert has_element?(
             view,
             "#member-compose-recipient-summary" <>
               "[data-active-member-count='2']" <>
               "[data-audience-group-id='#{trip_planning_group.group_id}']" <>
               "[data-audience-group-name='Trip Planning']",
             "2 members"
           )

    assert has_element?(view, "#member-compose-recipient-summary", "Trip Planning")
    refute has_element?(view, "#member-compose-recipient-summary", "all current members")

    assert has_element?(
             view,
             "#member-compose-inbound-email" <>
               "[data-inbound-address='trip-planning@kmc.clubs.memba.io']" <>
               "[data-audience-group-id='#{trip_planning_group.group_id}']" <>
               "[data-audience-group-name='Trip Planning']",
             "Send a message to Trip Planning at"
           )

    assert has_element?(
             view,
             "#member-compose-inbound-email-link[href='mailto:trip-planning@kmc.clubs.memba.io']",
             "trip-planning@kmc.clubs.memba.io"
           )

    assert has_element?(
             view,
             "button#member-message-send-button.btn.btn-primary.btn-lg[type='submit']",
             "Send message"
           )

    refute render(view) =~ "club-wide"
    refute render(view) =~ "Send to all current members"
  end

  test "recipient count follows members with primary email addresses", %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Climbing Club"
      )

    _unreachable_member =
      create_active_member_without_primary_email(
        club_id: alice.club_id,
        email: "unreachable@example.com",
        name: "Unreachable Member"
      )

    [everyone_group] =
      Memba.Membership.list_active_groups_for_member(alice.club_id, alice.person_id)

    assert everyone_group.active_member_count == 2

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/messages/new")

    assert has_element?(
             view,
             "#member-message-compose" <>
               "[data-audience-group-id='#{everyone_group.group_id}']" <>
               "[data-active-member-count='1']"
           )

    assert has_element?(view, "#member-compose-recipient-summary", "1 member")
    refute has_element?(view, "#member-compose-recipient-summary", "2 members")
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
             "2 members"
           )

    assert has_element?(view, "#member-compose-recipient-summary", "Everyone")

    refute has_element?(view, "#member-compose-recipient-summary", "There is no list to pick")

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
             "Send message"
           )

    assert has_element?(
             view,
             "#member-message-cancel-link.btn.btn-soft.btn-lg[href='/conversations']",
             "Cancel"
           )

    refute has_element?(view, "select")
    refute has_element?(view, "[name='message[sender_id]']")
    refute has_element?(view, "#member-message-compose-form [name='message[audience_group_id]']")
    refute has_element?(view, "#member-message-compose-form [name='message[group_id]']")
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
             "Send a message to Everyone at"
           )

    refute has_element?(view, "#member-compose-inbound-email", "club-wide")

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

  test "routed GET returns not found when the requested audience group is not available to the member",
       %{conn: conn} do
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

    private_group =
      create_group(
        club_id: alice.club_id,
        group_key: "private_planning",
        name: "Private Planning"
      )

    add_group_member(private_group, bob)

    response =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> get(~p"/messages/new?#{[group_id: private_group.group_id]}")
      |> html_response(404)

    assert response =~ "Not Found"
    refute response =~ private_group.name
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

    ensure_membership_club!(attrs, club_id)

    person =
      insert_membership_person!(
        person_id: person_id,
        name: Keyword.fetch!(attrs, :name),
        email: Keyword.fetch!(attrs, :email)
      )

    membership_id = Memba.ID.generate(:membership)

    insert_active_membership!(club_id, membership_id, person.person_id)

    if Keyword.get(attrs, :everyone_group?, true) do
      insert_everyone_group_membership!(club_id, membership_id, person.person_id)
    end

    %{club_id: club_id, membership_id: membership_id, person_id: person.person_id}
  end

  defp create_active_member_without_primary_email(attrs) do
    club_id = Keyword.fetch!(attrs, :club_id)
    person_id = Memba.ID.generate(:person)

    ensure_membership_club!(attrs, club_id)

    Repo.insert!(%Person{
      person_id: person_id,
      name: Keyword.fetch!(attrs, :name),
      email: Keyword.fetch!(attrs, :email)
    })

    membership_id = Memba.ID.generate(:membership)

    insert_active_membership!(club_id, membership_id, person_id)
    insert_everyone_group_membership!(club_id, membership_id, person_id)

    %{club_id: club_id, membership_id: membership_id, person_id: person_id}
  end

  defp ensure_membership_club!(attrs, club_id) do
    Repo.get(Club, club_id) ||
      attrs
      |> club_attrs(club_id)
      |> insert_membership_club!()
  end

  defp insert_active_membership!(club_id, membership_id, person_id) do
    Repo.insert!(%Membership{
      membership_id: membership_id,
      club_id: club_id,
      person_id: person_id,
      active: true
    })
  end

  defp insert_everyone_group_membership!(club_id, membership_id, person_id) do
    group_id = SystemGroups.everyone_group_id(club_id)

    Repo.insert!(
      %Group{
        club_id: club_id,
        group_id: group_id,
        group_key: SystemGroups.everyone_key(),
        email_slug: SystemGroups.everyone_email_slug(),
        name: SystemGroups.everyone_name()
      },
      on_conflict: :nothing
    )

    Repo.insert!(%GroupMembership{
      club_id: club_id,
      group_id: group_id,
      membership_id: membership_id,
      person_id: person_id,
      active: true
    })
  end

  defp create_group(attrs) do
    Repo.insert!(%Group{
      club_id: Keyword.fetch!(attrs, :club_id),
      group_id: Memba.ID.generate(:group),
      email_slug: Keyword.get(attrs, :email_slug),
      group_key: Keyword.fetch!(attrs, :group_key),
      name: Keyword.fetch!(attrs, :name)
    })
  end

  defp add_group_member(group, member) do
    Repo.insert!(%GroupMembership{
      club_id: member.club_id,
      group_id: group.group_id,
      membership_id: member.membership_id,
      person_id: member.person_id,
      active: true
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
