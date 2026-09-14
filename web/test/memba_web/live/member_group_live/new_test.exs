defmodule MembaWeb.MemberGroupLive.NewTest do
  use MembaWeb.ConnCase, async: false

  import Ecto.Query
  import Phoenix.LiveViewTest

  alias Memba.ClubInboundEmailAddress
  alias Memba.Membership
  alias Memba.Membership.App
  alias Memba.Membership.Club, as: ClubAggregate
  alias Memba.Membership.Permissions
  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Group
  alias Memba.Membership.Projections.GroupMembership
  alias Memba.Membership.Projections.MemberPermission
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.SystemGroups
  alias Memba.Repo
  alias MembaWeb.ClubSite
  alias MembaWeb.IdentityAuth

  setup do
    Memba.EventSourcedCase.reset_event_sourced_system!()
    :ok
  end

  test "a Membership Admin navigates from the group rail to the name-only new-group form", %{
    conn: conn
  } do
    robin =
      create_active_member(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers"
      )

    grant_manage_members!(robin)

    conn
    |> signed_in_club_host("robin@example.com", robin)
    |> visit(~p"/conversations")
    |> assert_has(
      "#member-new-group-link.group-rail__item.group-rail__add[href='/groups/new']",
      "New group"
    )
    |> click_link("New group")
    |> assert_path(~p"/groups/new")
    |> assert_has(
      "#member-group-new[data-live-view='member-group-new'][data-club-id='#{robin.club_id}'][data-current-member-id='#{robin.person_id}']"
    )
    |> assert_has("h1", "New group")
    |> assert_has(
      "#member-group-new-selected-club[data-club-id='#{robin.club_id}']",
      "West Coast Paddlers"
    )
    |> assert_has(
      "#member-group-new-form[aria-label='Create a group'] input#member-group-name-input[name='group[name]'][type='text']"
    )
    |> assert_has("#member-group-email-preview[for='member-group-name-input']")
    |> assert_has(
      "button#member-group-create-button[type='submit'][disabled][phx-disable-with='Creating…']",
      "Create group"
    )
    |> assert_has("#member-group-new-back-link[href='/conversations']", "Back to groups")
    |> assert_has("#member-group-new-cancel-link[href='/conversations']", "Cancel")
    |> refute_has("#member-group-new-form input[name='group[email_slug]']")
    |> refute_has("#member-group-new-form input[name='group[club_id]']")
    |> refute_has("#member-group-new-form input[name='group[actor_person_id]']")
  end

  test "the exact /groups/new route is not consumed as a dashboard group id" do
    assert %{
             mfa: {MembaWeb.MemberGroupLive.New, :__live__, 0},
             path_params: %{},
             plug: Phoenix.LiveView.Plug,
             plug_opts: :new,
             route: "/groups/new"
           } =
             Phoenix.Router.route_info(
               MembaWeb.Router,
               "GET",
               "/groups/new",
               "wcp.lvh.me"
             )
  end

  test "ordinary active members cannot see or directly open the new-group surface", %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "West Coast Paddlers"
      )

    conn = signed_in_club_host(conn, "alice@example.com", alice)

    conn
    |> visit(~p"/conversations")
    |> refute_has("#member-new-group-link")

    assert_raise MembaWeb.ForbiddenError, fn ->
      live(conn, ~p"/groups/new")
    end
  end

  test "signed-out visitors are redirected and can return to the club's new-group route", %{
    conn: conn
  } do
    robin =
      create_active_member(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers"
      )

    %{host: host} =
      robin.club_id
      |> Memba.Membership.get_club()
      |> ClubSite.url(~p"/groups/new")
      |> URI.parse()

    return_path = "http://#{host}/groups/new"

    conn =
      conn
      |> club_host(robin)
      |> get(~p"/groups/new")

    assert redirected_to(conn) == ~p"/auth"
    assert get_session(conn, IdentityAuth.return_to_session_key()) == return_path
  end

  test "typing validates the name and previews its address without creating a group", %{
    conn: conn
  } do
    robin =
      create_active_member(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers"
      )

    grant_manage_members!(robin)
    club = Membership.get_club(robin.club_id)
    insert_custom_group!(robin.club_id, "Board", "board")

    session =
      conn
      |> signed_in_club_host("robin@example.com", robin)
      |> visit(~p"/groups/new")

    session
    |> refute_has("#member-group-name-input[aria-invalid='true']")
    |> assert_has("#member-group-name-input[aria-describedby='member-group-name-hint']")
    |> assert_has(
      "#member-group-email-preview[data-state='empty'][aria-live='polite']",
      "Appears here as you type the name"
    )
    |> assert_has("#member-group-create-button[disabled]")

    session =
      session
      |> fill_in("Group name", with: "Trips")
      |> assert_has(
        "#member-group-email-preview[data-state='available']",
        ClubInboundEmailAddress.address(club, "trips")
      )
      |> refute_has("#member-group-create-button[disabled]")

    assert is_nil(
             Repo.get_by(Group,
               club_id: robin.club_id,
               name_uniqueness_key: Memba.Membership.GroupName.uniqueness_key("Trips")
             )
           )

    session
    |> fill_in("Group name", with: "")
    |> assert_has(
      "#member-group-name-input[aria-invalid='true']" <>
        "[aria-describedby~='member-group-name-hint']" <>
        "[aria-describedby~='member-group-name-input-error-1']"
    )
    |> assert_has("#member-group-name-input-error-1", "Give the group a name.")
    |> assert_has("#member-group-email-preview[data-state='empty']", "")
    |> assert_has("#member-group-create-button[disabled]")
    |> fill_in("Group name", with: " bOaRd ")
    |> assert_has("#member-group-name-input[aria-invalid='true']")
    |> assert_has(
      "#member-group-name-input-error-1",
      "There's already a group called “Board” in West Coast Paddlers. Pick a different name."
    )
    |> assert_has("#member-group-email-preview[data-state='empty']", "")
    |> assert_has("#member-group-create-button[disabled]")
    |> fill_in("Group name", with: "Trips")
    |> refute_has("#member-group-name-input-error-1")
    |> assert_has(
      "#member-group-email-preview[data-state='available']",
      ClubInboundEmailAddress.address(club, "trips")
    )
    |> refute_has("#member-group-create-button[disabled]")
  end

  test "successive server-side typing validations preserve the latest input value", %{conn: conn} do
    robin =
      create_active_member(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers"
      )

    grant_manage_members!(robin)
    club = Membership.get_club(robin.club_id)

    conn = signed_in_club_host(conn, "robin@example.com", robin)
    {:ok, view, _html} = live(conn, ~p"/groups/new")

    for partial_name <- ["T", "Tr", "Tri", "Trip", "Trips"] do
      view
      |> form("#member-group-new-form", group: %{name: partial_name})
      |> render_change()

      assert has_element?(
               view,
               "#member-group-name-input[value='#{partial_name}']"
             )

      assert has_element?(
               view,
               "#member-group-email-preview[data-state='available']",
               ClubInboundEmailAddress.address(club, String.downcase(partial_name))
             )
    end

    refute Repo.get_by(Group,
             club_id: robin.club_id,
             name_uniqueness_key: Memba.Membership.GroupName.uniqueness_key("Trips")
           )
  end

  test "the live preview uses the creation allocator for slug collisions and Unicode fallback", %{
    conn: conn
  } do
    robin =
      create_active_member(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers"
      )

    grant_manage_members!(robin)
    club = Membership.get_club(robin.club_id)
    insert_custom_group!(robin.club_id, "Huts & maintenance", "huts-maintenance")
    insert_custom_group!(robin.club_id, "Translations", "group")

    session =
      conn
      |> signed_in_club_host("robin@example.com", robin)
      |> visit(~p"/groups/new")
      |> fill_in("Group name", with: "Huts maintenance")
      |> assert_has(
        "#member-group-email-preview[data-state='available']" <>
          "[aria-describedby='member-group-email-preview-note']",
        ClubInboundEmailAddress.address(club, "huts-maintenance-2")
      )
      |> assert_has(
        "#member-group-email-preview-note",
        "“huts-maintenance” is already used by Huts & maintenance, so this address gets a number."
      )

    session
    |> fill_in("Group name", with: "董事会")
    |> assert_has(
      "#member-group-email-preview[data-state='available']",
      ClubInboundEmailAddress.address(club, "group-2")
    )
    |> refute_has("#member-group-name-input[aria-invalid='true']")
  end

  test "submit rechecks creation in the Club aggregate when the live preview is stale", %{
    conn: conn
  } do
    robin =
      create_event_sourced_admin(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers",
        club_slug: "wcp"
      )

    conn = signed_in_club_host(conn, "robin@example.com", robin)
    {:ok, view, _html} = live(conn, ~p"/groups/new")

    view
    |> form("#member-group-new-form", group: %{name: "Board"})
    |> render_change()

    assert has_element?(
             view,
             "#member-group-email-preview[data-state='available']",
             "board@wcp.clubs.memba.io"
           )

    assert :ok =
             Membership.create_custom_group(
               %{
                 club_id: robin.club_id,
                 group_id: Memba.ID.generate(:group),
                 actor_person_id: robin.person_id,
                 name: "Board"
               },
               consistency: :strong
             )

    club_id = robin.club_id

    Repo.delete_all(
      from group in Group,
        where: group.club_id == ^club_id and group.name_uniqueness_key == "board"
    )

    view
    |> form("#member-group-new-form", group: %{name: "Board"})
    |> render_submit()

    assert has_element?(view, "#member-group-name-input[aria-invalid='true']")
    assert has_element?(view, "#member-group-name-input-error-1", "already a group")
    assert has_element?(view, "#member-group-create-button[disabled]")

    board_groups =
      robin.club_id
      |> then(&App.aggregate_state(ClubAggregate, &1))
      |> Map.fetch!(:groups)
      |> Map.values()
      |> Enum.filter(&(&1.name == "Board"))

    assert length(board_groups) == 1
  end

  test "successful creation continues through the generic group routes and queries", %{conn: conn} do
    robin =
      create_event_sourced_admin(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers",
        club_slug: "wcp"
      )

    session =
      conn
      |> signed_in_club_host("robin@example.com", robin)
      |> visit(~p"/groups/new")
      |> fill_in("Group name", with: " Board ")
      |> click_button("Create group")

    assert %{
             active_member_count: 1,
             email_address: "board@wcp.clubs.memba.io",
             group_id: group_id,
             name: "Board"
           } =
             Enum.find(
               Membership.list_active_groups_for_member(robin.club_id, robin.person_id),
               &(&1.name == "Board")
             )

    assert %{
             club_id: club_id,
             group_id: ^group_id,
             email_slug: "board",
             group_key: nil,
             name: "Board"
           } = Membership.get_group(group_id)

    assert club_id == robin.club_id

    session
    |> assert_path(~p"/groups/#{group_id}/members")
    |> assert_has("#flash-info", "Board created.")
    |> assert_has("#member-club-home[data-selected-group-id='#{group_id}']")
    |> assert_has(
      "#member-group-link-#{group_id}.is-active[aria-current='true']" <>
        "[href='/groups/#{group_id}']",
      "Board"
    )
    |> assert_has("#member-group-name", "Board")
    |> assert_has("#member-group-metadata", "Private group")
    |> assert_has("#member-group-member-count", "1 member")
    |> assert_has(
      "#member-group-email-address[href='mailto:board@wcp.clubs.memba.io']",
      "board@wcp.clubs.memba.io"
    )
    |> assert_has(
      "#member-section-tab-conversations[href='/groups/#{group_id}']",
      "Conversations"
    )
    |> assert_has(
      "#member-section-tab-members.is-active[aria-selected='true']" <>
        "[href='/groups/#{group_id}/members']",
      "Members"
    )
    |> assert_has("#club-member-#{robin.person_id}", "Robin Rivers")
    |> refute_has("#member-dashboard-cta")
  end

  test "a technical creation failure uses the generic flash and keeps the form ready to retry", %{
    conn: conn
  } do
    robin =
      create_event_sourced_admin(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers",
        club_slug: "wcp"
      )

    conn = signed_in_club_host(conn, "robin@example.com", robin)
    {:ok, view, _html} = live(conn, ~p"/groups/new")
    %{socket: socket} = :sys.get_state(view.pid)
    group_id = socket.assigns.group_id

    assert :ok =
             Membership.create_custom_group(
               %{
                 club_id: robin.club_id,
                 group_id: group_id,
                 actor_person_id: robin.person_id,
                 name: "Already claimed request"
               },
               consistency: :strong
             )

    view
    |> form("#member-group-new-form", group: %{name: "Board"})
    |> render_submit()

    assert has_element?(
             view,
             "#flash-error",
             "We couldn't create the group. Try again."
           )

    assert has_element?(view, "#member-group-name-input[value='Board']")

    assert has_element?(
             view,
             "#member-group-email-preview[data-state='available']",
             "board@wcp.clubs.memba.io"
           )

    refute has_element?(view, "#member-group-create-button[disabled]")
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
      insert_membership_club!(
        club_id: club_id,
        name: Keyword.get(attrs, :club_name, "Kootenay Mountaineering Club")
      )

    person =
      insert_membership_person!(
        person_id: person_id,
        name: Keyword.fetch!(attrs, :name),
        email: Keyword.fetch!(attrs, :email)
      )

    membership =
      Repo.insert!(%MembershipProjection{
        membership_id: Memba.ID.generate(:membership),
        club_id: club_id,
        person_id: person.person_id,
        active: true
      })

    insert_everyone_membership!(club_id, membership.membership_id, person.person_id)

    %{
      club_id: club_id,
      membership_id: membership.membership_id,
      person_id: person.person_id
    }
  end

  defp create_event_sourced_admin(attrs) do
    club_id = Memba.ID.generate(:club)
    person_id = Memba.ID.generate(:person)
    membership_id = Memba.ID.generate(:membership)
    email = Keyword.fetch!(attrs, :email)

    assert :ok =
             Membership.create_club(
               %{
                 club_id: club_id,
                 name: Keyword.fetch!(attrs, :club_name),
                 slug: Keyword.fetch!(attrs, :club_slug)
               },
               consistency: :strong
             )

    assert :ok =
             Membership.create_person(
               %{
                 person_id: person_id,
                 name: Keyword.fetch!(attrs, :name),
                 email: email
               },
               consistency: :strong
             )

    assert :ok =
             Membership.add_member(
               %{membership_id: membership_id, club_id: club_id, person_id: person_id},
               consistency: :strong
             )

    %{club_id: club_id, membership_id: membership_id, person_id: person_id}
  end

  defp insert_everyone_membership!(club_id, membership_id, person_id) do
    group_id = SystemGroups.everyone_group_id(club_id)

    Repo.insert!(
      %Group{
        club_id: club_id,
        group_id: group_id,
        group_key: SystemGroups.everyone_key(),
        name: SystemGroups.everyone_name(),
        name_uniqueness_key:
          Memba.Membership.GroupName.uniqueness_key(SystemGroups.everyone_name())
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

  defp grant_manage_members!(member) do
    Repo.insert!(%MemberPermission{
      club_id: member.club_id,
      membership_id: member.membership_id,
      person_id: member.person_id,
      permission: Permissions.club_manage_members(),
      grant_count: 1
    })
  end

  defp insert_custom_group!(club_id, name, email_slug) do
    Repo.insert!(%Group{
      club_id: club_id,
      group_id: Memba.ID.generate(:group),
      email_slug: email_slug,
      group_key: nil,
      name: name,
      name_uniqueness_key: Memba.Membership.GroupName.uniqueness_key(name)
    })
  end
end
