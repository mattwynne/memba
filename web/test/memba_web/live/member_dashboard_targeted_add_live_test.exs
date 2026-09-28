defmodule MembaWeb.MemberDashboardTargetedAddLiveTest do
  use MembaWeb.FeatureCase, async: false

  import Phoenix.LiveViewTest,
    only: [
      assert_patch: 2,
      element: 2,
      has_element?: 2,
      has_element?: 3,
      live: 2,
      render_click: 1,
      render_click: 3,
      render_keydown: 2
    ]

  alias Commanded.EventStore
  alias Memba.Membership
  alias Memba.Membership.App, as: MembershipApp
  alias Memba.Membership.Commands.RemoveClubMember
  alias Memba.Membership.Events.GroupMemberAdded
  alias Memba.Membership.Projections.Group, as: GroupProjection
  alias Memba.Membership.Projectors.GroupMembership, as: GroupMembershipProjector
  alias Memba.Membership.Projectors.Membership, as: MembershipProjector
  alias Memba.Membership.Projectors.Role, as: RoleProjector
  alias Memba.Membership.SystemGroups
  alias Memba.Repo
  alias MembaWeb.ClubSite
  alias MembaWeb.IdentityAuth

  test "an unauthenticated club-host request preserves the full targeted return URL", %{
    conn: conn
  } do
    club = create_club!("Alpine Club", "alpine")
    group_id = Memba.ID.generate(:group)
    person_id = Memba.ID.generate(:person)
    path = ~p"/groups/#{group_id}/members/add/#{person_id}"

    conn =
      conn
      |> club_host(club)
      |> get(path)

    %{host: host} = URI.parse(ClubSite.url(club))

    assert redirected_to(conn) == ~p"/auth"

    assert Plug.Conn.get_session(conn, IdentityAuth.return_to_session_key()) ==
             "http://#{host}#{path}"
  end

  test "a group participant sees the authoritative target on the Members page and GET is inert",
       %{conn: conn} do
    club = create_club!("Alpine Club", "alpine")
    alice = create_member!(club, "Alice Adams", "alice@example.com")
    eve = create_member!(club, "Eve Ekwueme", "eve@example.com")
    group = create_custom_group!(club, alice, "Board")
    path = ~p"/groups/#{group.group_id}/members/add/#{eve.person_id}"
    additions_before = target_addition_count(club.club_id, group.group_id, eve.person_id)

    conn = signed_in_club_host(conn, "alice@example.com", club)

    assert conn
           |> get(path)
           |> html_response(200)
           |> LazyHTML.from_fragment()
           |> LazyHTML.query("#targeted-group-member-heading[tabindex='-1'][phx-mounted]")
           |> Enum.any?()

    {:ok, view, _html} = live(conn, path)

    assert has_element?(
             view,
             "#member-section-tab-members[aria-current='page'][href='/groups/#{group.group_id}/members']"
           )

    assert has_element?(
             view,
             "#member-section-panel-members:not([hidden]) #targeted-group-member-panel"
           )

    assert has_element?(view, "#targeted-group-member-heading", "Add to Board")

    assert has_element?(
             view,
             "#targeted-group-member-person-#{eve.person_id}" <>
               "[data-membership-id='#{eve.membership_id}']",
             "Eve Ekwueme"
           )

    assert has_element?(view, "#targeted-group-member-context", "Club member")

    assert has_element?(
             view,
             "#targeted-group-member-consequences",
             "welcome email"
           )

    assert has_element?(view, "#targeted-group-member-actions")

    assert has_element?(
             view,
             "#targeted-group-member-add[phx-click='confirm_targeted_group_member']",
             "Add Eve Ekwueme to Board"
           )

    assert has_element?(view, "#targeted-group-member-cancel", "Cancel")
    assert has_element?(view, "#club-member-#{alice.person_id}", "Alice Adams")
    refute Membership.active_member_of_group?(group.group_id, eve.person_id)
    assert target_addition_count(club.club_id, group.group_id, eve.person_id) == additions_before
    refute_received {:email, %Swoosh.Email{}}
  end

  test "explicit Add ignores browser identities, admits the routed target, and announces success",
       %{conn: conn} do
    club = create_club!("Alpine Club", "alpine")
    alice = create_member!(club, "Alice Adams", "alice@example.com")
    eve = create_member!(club, "Eve Ekwueme", "eve@example.com")
    mallory = create_member!(club, "Mallory Misroute", "mallory@example.com")
    group = create_custom_group!(club, alice, "Board")
    path = ~p"/groups/#{group.group_id}/members/add/#{eve.person_id}"
    additions_before = target_addition_count(club.club_id, group.group_id, eve.person_id)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", club)
      |> live(path)

    refute_received {:email, %Swoosh.Email{}}

    _html =
      render_click(view, "confirm_targeted_group_member", %{
        "actor_person_id" => mallory.person_id,
        "club_id" => Memba.ID.generate(:club),
        "group_id" => Memba.ID.generate(:group),
        "membership_id" => mallory.membership_id,
        "person_id" => mallory.person_id
      })

    assert_patch(view, ~p"/groups/#{group.group_id}/members")
    refute has_element?(view, "#targeted-group-member-panel")

    assert has_element?(
             view,
             "#targeted-group-member-success[role='status'][aria-live='polite']",
             "Eve Ekwueme is now a member of Board."
           )

    assert has_element?(
             view,
             "#club-member-#{eve.person_id}[tabindex='-1'][phx-mounted]",
             "Eve Ekwueme"
           )

    refute has_element?(view, "#club-member-#{alice.person_id}[tabindex]")
    assert Membership.active_member_of_group?(group.group_id, eve.person_id)
    refute Membership.active_member_of_group?(group.group_id, mallory.person_id)

    assert target_addition_count(club.club_id, group.group_id, eve.person_id) ==
             additions_before + 1

    assert_received {:email, %Swoosh.Email{} = welcome}
    assert welcome.to == [{"Eve Ekwueme", "eve@example.com"}]
    assert welcome.subject == "[alpine] You've been added to Board"
    assert welcome.text_body =~ ClubSite.url(club, ~p"/groups/#{group.group_id}")
    refute_received {:email, %Swoosh.Email{}}
  end

  test "a confirmation race becomes an already-member no-op without another event or welcome",
       %{conn: conn} do
    club = create_club!("Alpine Club", "alpine")
    alice = create_member!(club, "Alice Adams", "alice@example.com")
    eve = create_member!(club, "Eve Ekwueme", "eve@example.com")
    group = create_custom_group!(club, alice, "Board")
    path = ~p"/groups/#{group.group_id}/members/add/#{eve.person_id}"

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", club)
      |> live(path)

    assert has_element?(view, "#targeted-group-member-add")
    add_group_member!(club, group, alice, eve)
    additions_after_race = target_addition_count(club.club_id, group.group_id, eve.person_id)
    refute_received {:email, %Swoosh.Email{}}

    _html = render_click(view, "confirm_targeted_group_member", %{})

    assert has_element?(
             view,
             "#targeted-group-member-status[role='status'][aria-live='polite']",
             "Eve Ekwueme is already a member of Board."
           )

    refute has_element?(view, "#targeted-group-member-add")

    assert target_addition_count(club.club_id, group.group_id, eve.person_id) ==
             additions_after_race

    refute_received {:email, %Swoosh.Email{}}
  end

  test "confirmation denies a stale outside Admin after authoritative role revocation",
       %{conn: conn} do
    club = create_club!("Alpine Club", "alpine")
    alice = create_member!(club, "Alice Adams", "alice@example.com")
    dan = create_member!(club, "Dan Delgado", "dan@example.com")
    eve = create_member!(club, "Eve Ekwueme", "eve@example.com")
    group = create_custom_group!(club, alice, "Board")
    make_admin!(club, alice, dan)
    additions_before = target_addition_count(club.club_id, group.group_id, eve.person_id)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("dan@example.com", club)
      |> live(~p"/groups/#{group.group_id}/members/add/#{eve.person_id}")

    assert has_element?(view, "#targeted-group-member-add")
    role_projector_child_id = stop_projector!(RoleProjector)

    assert :ok =
             Membership.remove_membership_administrator_as_club_member(
               %{
                 club_id: club.club_id,
                 membership_id: dan.membership_id,
                 person_id: dan.person_id,
                 actor_person_id: alice.person_id
               },
               consistency: :eventual
             )

    assert Membership.person_has_club_permission?(
             club.club_id,
             dan.person_id,
             Memba.Membership.Permissions.club_manage_members()
           )

    _html = render_click(view, "confirm_targeted_group_member", %{})

    assert has_element?(
             view,
             "#flash-error",
             "We couldn't add that member. Refresh and try again."
           )

    refute Membership.active_member_of_group?(group.group_id, eve.person_id)
    assert target_addition_count(club.club_id, group.group_id, eve.person_id) == additions_before
    refute_received {:email, %Swoosh.Email{}}

    stop_live_view!(view)
    restart_projector!(role_projector_child_id)
    await_restarted_projectors!([RoleProjector])
  end

  test "confirmation denies a target who left while the displayed membership is stale",
       %{conn: conn} do
    club = create_club!("Alpine Club", "alpine")
    alice = create_member!(club, "Alice Adams", "alice@example.com")
    eve = create_member!(club, "Eve Ekwueme", "eve@example.com")
    group = create_custom_group!(club, alice, "Board")
    additions_before = target_addition_count(club.club_id, group.group_id, eve.person_id)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", club)
      |> live(~p"/groups/#{group.group_id}/members/add/#{eve.person_id}")

    assert has_element?(view, "#targeted-group-member-add")

    stopped_projectors =
      for projector <- [
            Memba.Membership.Projectors.Group,
            GroupMembershipProjector,
            MembershipProjector,
            RoleProjector
          ] do
        {projector, stop_projector!(projector)}
      end

    assert :ok =
             MembershipApp.dispatch(
               %RemoveClubMember{
                 club_id: club.club_id,
                 membership_id: eve.membership_id,
                 person_id: eve.person_id
               },
               consistency: :eventual
             )

    assert Membership.active_member_of_club?(club.club_id, eve.person_id)
    _html = render_click(view, "confirm_targeted_group_member", %{})

    assert has_element?(
             view,
             "#flash-error",
             "We couldn't add that member. Refresh and try again."
           )

    refute Membership.active_member_of_group?(group.group_id, eve.person_id)
    assert target_addition_count(club.club_id, group.group_id, eve.person_id) == additions_before
    refute_received {:email, %Swoosh.Email{}}

    stop_live_view!(view)
    Enum.each(stopped_projectors, fn {_projector, child_id} -> restart_projector!(child_id) end)
    await_restarted_projectors!(Enum.map(stopped_projectors, &elem(&1, 0)))
  end

  test "Cancel and Escape leave targeted mode without admission or welcome", %{conn: conn} do
    club = create_club!("Alpine Club", "alpine")
    alice = create_member!(club, "Alice Adams", "alice@example.com")
    eve = create_member!(club, "Eve Ekwueme", "eve@example.com")
    group = create_custom_group!(club, alice, "Board")
    path = ~p"/groups/#{group.group_id}/members/add/#{eve.person_id}"
    ordinary_path = ~p"/groups/#{group.group_id}/members"
    additions_before = target_addition_count(club.club_id, group.group_id, eve.person_id)
    conn = signed_in_club_host(conn, "alice@example.com", club)

    {:ok, cancel_view, _html} = live(conn, path)

    cancel_view
    |> element("#targeted-group-member-cancel")
    |> render_click()

    assert_patch(cancel_view, ordinary_path)
    refute has_element?(cancel_view, "#targeted-group-member-panel")

    {:ok, escape_view, _html} = live(conn, path)

    escape_view
    |> element("#targeted-group-member-panel")
    |> render_keydown(%{"key" => "Escape"})

    assert_patch(escape_view, ordinary_path)
    refute has_element?(escape_view, "#targeted-group-member-panel")
    refute Membership.active_member_of_group?(group.group_id, eve.person_id)
    assert target_addition_count(club.club_id, group.group_id, eve.person_id) == additions_before
    refute_received {:email, %Swoosh.Email{}}
  end

  test "the targeted panel uses the authoritative group name instead of projected copy",
       %{conn: conn} do
    club = create_club!("Alpine Club", "alpine")
    alice = create_member!(club, "Alice Adams", "alice@example.com")
    dan = create_member!(club, "Dan Delgado", "dan@example.com")
    eve = create_member!(club, "Eve Ekwueme", "eve@example.com")
    group = create_custom_group!(club, alice, "Board")
    make_admin!(club, alice, dan)

    group.group_id
    |> then(&Repo.get!(GroupProjection, &1))
    |> Ecto.Changeset.change(name: "Projected Board")
    |> Repo.update!()

    assert Repo.get!(GroupProjection, group.group_id).name == "Projected Board"

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("dan@example.com", club)
      |> live(~p"/groups/#{group.group_id}/members/add/#{eve.person_id}")

    assert has_element?(view, "#targeted-group-member-heading", "Add to Board")

    assert has_element?(
             view,
             "#targeted-group-member-consequences",
             "read all Board conversations"
           )

    refute has_element?(view, "#targeted-group-member-panel", "Projected Board")
  end

  test "an outside club admin sees only the targeted Members surface", %{conn: conn} do
    club = create_club!("Alpine Club", "alpine")
    alice = create_member!(club, "Alice Adams", "alice@example.com")
    dan = create_member!(club, "Dan Delgado", "dan@example.com")
    eve = create_member!(club, "Eve Ekwueme", "eve@example.com")
    group = create_custom_group!(club, alice, "Board")
    make_admin!(club, alice, dan)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("dan@example.com", club)
      |> live(~p"/groups/#{group.group_id}/members/add/#{eve.person_id}")

    assert has_element?(view, "#targeted-group-member-person-#{eve.person_id}", "Eve Ekwueme")
    assert has_element?(view, "#member-group-outside-admin-notice")
    assert has_element?(view, "#member-section-panel-members:not([hidden])")
    refute has_element?(view, "#member-section-tab-conversations")
    refute has_element?(view, "#member-section-panel-conversations")
  end

  test "an authoritative existing participant gets an already-member status and no Add control",
       %{conn: conn} do
    club = create_club!("Alpine Club", "alpine")
    alice = create_member!(club, "Alice Adams", "alice@example.com")
    eve = create_member!(club, "Eve Ekwueme", "eve@example.com")
    group = create_custom_group!(club, alice, "Board")
    add_group_member!(club, group, alice, eve)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", club)
      |> live(~p"/groups/#{group.group_id}/members/add/#{eve.person_id}")

    assert has_element?(
             view,
             "#targeted-group-member-status[role='status']",
             "Eve Ekwueme is already a member of Board."
           )

    assert has_element?(view, "#club-member-#{eve.person_id}", "Eve Ekwueme")
    refute has_element?(view, "#targeted-group-member-actions")
    refute has_element?(view, "#targeted-group-member-add")
  end

  test "an ordinary group outsider is forbidden without target or group-member disclosure",
       %{conn: conn} do
    club = create_club!("Alpine Club", "alpine")
    alice = create_member!(club, "Alice Adams", "alice@example.com")
    eve = create_member!(club, "Eve Ekwueme", "eve@example.com")
    _oscar = create_member!(club, "Oscar Outsider", "oscar@example.com")
    group = create_custom_group!(club, alice, "Board")

    error =
      assert_raise MembaWeb.ForbiddenError, fn ->
        conn
        |> signed_in_club_host("oscar@example.com", club)
        |> get(~p"/groups/#{group.group_id}/members/add/#{eve.person_id}")
      end

    message = Exception.message(error)

    assert message == "Forbidden"
    refute message =~ "Eve Ekwueme"
    refute message =~ eve.person_id
    refute message =~ eve.membership_id
    refute message =~ "Alice Adams"
    refute message =~ "board@"
  end

  test "an inactive actor is denied before any target details are loaded", %{conn: conn} do
    club = create_club!("Alpine Club", "alpine")
    alice = create_member!(club, "Alice Adams", "alice@example.com")
    bob = create_member!(club, "Bob Former", "bob@example.com")
    eve = create_member!(club, "Eve Ekwueme", "eve@example.com")
    group = create_custom_group!(club, alice, "Board")
    add_group_member!(club, group, alice, bob)

    assert :ok =
             Membership.remove_member(
               %{membership_id: bob.membership_id},
               consistency: :strong
             )

    body =
      conn
      |> signed_in_club_host("bob@example.com", club)
      |> get(~p"/groups/#{group.group_id}/members/add/#{eve.person_id}")
      |> response(403)

    assert body == "Forbidden"
    refute body =~ "Eve Ekwueme"
    refute body =~ eve.membership_id
    refute body =~ "Alice Adams"
  end

  test "invalid, missing, cross-club, inactive, and built-in targets disclose no person details",
       %{conn: conn} do
    club = create_club!("Alpine Club", "alpine")
    alice = create_member!(club, "Alice Adams", "alice@example.com")
    eve = create_member!(club, "Eve Ekwueme", "eve@example.com")
    group = create_custom_group!(club, alice, "Board")

    other_club = create_club!("Cycling Club", "cycling")
    foreign = create_member!(other_club, "Fiona Foreign", "fiona@example.com")
    foreign_group = create_custom_group!(other_club, foreign, "Foreign Board")
    missing_person_id = Memba.ID.generate(:person)
    missing_group_id = Memba.ID.generate(:group)

    assert :ok =
             Membership.remove_member(
               %{membership_id: eve.membership_id},
               consistency: :strong
             )

    not_found_paths = [
      "/groups/not-a-group-id/members/add/#{alice.person_id}",
      ~p"/groups/#{missing_group_id}/members/add/#{alice.person_id}",
      ~p"/groups/#{foreign_group.group_id}/members/add/#{foreign.person_id}",
      "/groups/#{group.group_id}/members/add/not-a-person-id",
      ~p"/groups/#{group.group_id}/members/add/#{missing_person_id}",
      ~p"/groups/#{group.group_id}/members/add/#{foreign.person_id}",
      ~p"/groups/#{group.group_id}/members/add/#{eve.person_id}"
    ]

    for path <- not_found_paths do
      conn
      |> recycle()
      |> signed_in_club_host("alice@example.com", club)
      |> assert_not_found_without_details(path, [
        "Eve Ekwueme",
        "Fiona Foreign",
        eve.membership_id,
        foreign.membership_id
      ])
    end

    built_in_path =
      ~p"/groups/#{SystemGroups.everyone_group_id(club.club_id)}/members/add/#{alice.person_id}"

    error =
      assert_raise MembaWeb.ForbiddenError, fn ->
        conn
        |> recycle()
        |> signed_in_club_host("alice@example.com", club)
        |> get(built_in_path)
      end

    assert Exception.message(error) == "Forbidden"
  end

  defp create_club!(name, slug) do
    club_id = Memba.ID.generate(:club)

    assert :ok =
             Membership.create_club(
               %{club_id: club_id, name: name, slug: slug},
               consistency: :strong
             )

    Membership.get_club(club_id)
  end

  defp create_member!(club, name, email) do
    person_id = Memba.ID.generate(:person)
    membership_id = Memba.ID.generate(:membership)

    assert :ok =
             Membership.create_person(
               %{person_id: person_id, name: name, email: email},
               consistency: :strong
             )

    assert :ok =
             Membership.add_member(
               %{
                 club_id: club.club_id,
                 membership_id: membership_id,
                 person_id: person_id
               },
               consistency: :strong
             )

    %{
      club_id: club.club_id,
      membership_id: membership_id,
      person_id: person_id,
      name: name
    }
  end

  defp create_custom_group!(club, creator, name) do
    group_id = Memba.ID.generate(:group)

    assert :ok =
             Membership.create_custom_group(
               %{
                 club_id: club.club_id,
                 group_id: group_id,
                 actor_person_id: creator.person_id,
                 name: name
               },
               consistency: :strong
             )

    Membership.get_group(group_id)
  end

  defp add_group_member!(club, group, actor, target) do
    assert {:ok, _admission} =
             Membership.add_custom_group_member(
               %{
                 club_id: club.club_id,
                 group_id: group.group_id,
                 membership_id: target.membership_id,
                 person_id: target.person_id,
                 actor_person_id: actor.person_id
               },
               consistency: :strong
             )
  end

  defp make_admin!(club, actor, target) do
    assert :ok =
             Membership.assign_membership_administrator_as_club_member(
               %{
                 club_id: club.club_id,
                 membership_id: target.membership_id,
                 person_id: target.person_id,
                 actor_person_id: actor.person_id
               },
               consistency: :strong
             )
  end

  defp target_addition_count(club_id, group_id, person_id) do
    club_id
    |> then(&EventStore.stream_forward(MembershipApp, &1))
    |> Enum.count(fn recorded_event ->
      match?(
        %GroupMemberAdded{group_id: ^group_id, person_id: ^person_id},
        recorded_event.data
      )
    end)
  end

  defp stop_projector!(projector) do
    child_id =
      Supervisor.which_children(Memba.Supervisor)
      |> Enum.find_value(fn
        {child_id, _pid, :worker, [module]} when module == projector -> child_id
        _child -> nil
      end)

    assert child_id,
           "Expected #{inspect(projector)} in #{inspect(Supervisor.which_children(Memba.Supervisor))}"

    assert :ok = Supervisor.terminate_child(Memba.Supervisor, child_id)
    on_exit(fn -> restart_projector!(child_id) end)
    child_id
  end

  defp restart_projector!(child_id) do
    case Supervisor.restart_child(Memba.Supervisor, child_id) do
      {:ok, _pid} -> :ok
      {:ok, _pid, _info} -> :ok
      {:error, :running} -> :ok
      {:error, :not_found} -> :ok
    end
  end

  defp await_restarted_projectors!(projectors) do
    checkpoint = Memba.ProjectionBarrier.current_checkpoint()

    Memba.ProjectionBarrier.await!(
      projectors,
      checkpoint: checkpoint,
      timeout: 5_000
    )

    final_checkpoint = Memba.ProjectionBarrier.current_checkpoint()

    Memba.ProjectionBarrier.await!(
      projectors,
      checkpoint: final_checkpoint,
      timeout: 5_000
    )
  end

  defp stop_live_view!(view) do
    view_ref = Process.monitor(view.pid)
    :ok = GenServer.stop(view.pid)
    assert_receive {:DOWN, ^view_ref, :process, _, :normal}
  end

  defp assert_not_found_without_details(conn, path, protected_details) do
    result =
      try do
        {:response, get(conn, path)}
      rescue
        error in Phoenix.Router.NoRouteError -> {:exception, error}
      end

    rendered_or_exception =
      case result do
        {:response, conn} ->
          assert conn.status == 404
          response(conn, 404)

        {:exception, error} ->
          Exception.message(error)
      end

    Enum.each(protected_details, fn detail ->
      refute rendered_or_exception =~ detail
    end)
  end

  defp signed_in_club_host(conn, email, club) do
    conn
    |> club_host(club)
    |> Plug.Test.init_test_session(%{IdentityAuth.identity_session_key() => email})
  end

  defp club_host(conn, club) do
    %{host: host} = club |> ClubSite.url() |> URI.parse()
    Map.put(conn, :host, host)
  end
end
