defmodule MembaWeb.MemberGroupLive.NewTest do
  use MembaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Memba.Membership.Permissions
  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Group
  alias Memba.Membership.Projections.GroupMembership
  alias Memba.Membership.Projections.MemberPermission
  alias Memba.Membership.Projections.Membership
  alias Memba.Membership.SystemGroups
  alias Memba.Repo
  alias MembaWeb.ClubSite
  alias MembaWeb.IdentityAuth

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
    |> assert_has("button#member-group-create-button[type='submit'][disabled]", "Create group")
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
      Repo.insert!(%Membership{
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
end
