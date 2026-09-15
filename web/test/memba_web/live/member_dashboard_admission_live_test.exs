defmodule MembaWeb.MemberDashboardAdmissionLiveTest do
  use MembaWeb.FeatureCase, async: false

  import ExUnit.CaptureLog
  import Phoenix.LiveViewTest, only: [has_element?: 2, has_element?: 3, live: 2, render_click: 3]

  alias Memba.Membership
  alias Memba.Membership.Projections.GroupMembership
  alias Memba.Repo
  alias MembaWeb.ClubSite
  alias MembaWeb.IdentityAuth

  test "a custom-group member adds an active club member and immediately sees fresh membership",
       %{conn: conn} do
    club = create_club!("Alpine Club", "alpine")
    alice = create_member!(club, "Alice Adams", "alice@example.com")
    carol = create_member!(club, "Carol Canoe", "carol@example.com")
    group = create_custom_group!(club, alice, "Trip Planning")

    session =
      conn
      |> signed_in_club_host("alice@example.com", club)
      |> visit(~p"/groups/#{group.group_id}/members")
      |> click_button("Add member")
      |> assert_has(
        "#custom-group-member-candidate-#{carol.person_id}" <>
          "[data-membership-id='#{carol.membership_id}']",
        "Carol Canoe"
      )
      |> click_button("#custom-group-member-candidate-add-#{carol.person_id}", "Add")

    session
    |> assert_has("#custom-group-member-picker")
    |> refute_has("#custom-group-member-candidate-#{carol.person_id}")
    |> assert_has("#club-member-#{carol.person_id}", "Carol Canoe")
    |> assert_has("#member-group-member-count", "2 members")

    assert Membership.active_member_of_group?(group.group_id, carol.person_id)
  end

  test "an outside club admin adds themselves and immediately receives the participating view",
       %{conn: conn} do
    club = create_club!("Alpine Club", "alpine")
    creator = create_member!(club, "Alice Adams", "alice@example.com")
    admin = create_member!(club, "Dan Delgado", "dan@example.com")
    group = create_custom_group!(club, creator, "Board")
    make_admin!(club, creator, admin)

    session =
      conn
      |> signed_in_club_host("dan@example.com", club)
      |> visit(~p"/groups/#{group.group_id}/members")
      |> assert_has("#member-group-outside-admin-notice")
      |> click_button("#member-group-add-self", "Add yourself to Board")

    session
    |> refute_has("#member-group-outside-admin-notice")
    |> assert_has(
      "#member-section-tab-conversations[href='/groups/#{group.group_id}']",
      "Conversations"
    )
    |> assert_has("#club-member-#{admin.person_id}", "Dan Delgado")
    |> assert_has("#member-group-member-count", "2 members")

    assert Membership.active_member_of_group?(group.group_id, admin.person_id)
  end

  test "a confirmed new admission sends one welcome and an idempotent retry sends none",
       %{conn: conn} do
    club = create_club!("Alpine Club", "alpine")
    alice = create_member!(club, "Alice Adams", "alice@example.com")
    carol = create_member!(club, "Carol Canoe", "carol@example.com")
    group = create_custom_group!(club, alice, "Trip Planning")

    conn = signed_in_club_host(conn, "alice@example.com", club)
    {:ok, view, _html} = live(conn, ~p"/groups/#{group.group_id}/members")

    refute_received {:email, %Swoosh.Email{}}

    admission_params = %{
      "membership_id" => carol.membership_id,
      "person_id" => carol.person_id
    }

    _html =
      render_click(
        view,
        "add_custom_group_member",
        admission_params
      )

    assert_received {:email, %Swoosh.Email{} = email}
    assert email.to == [{"Carol Canoe", "carol@example.com"}]
    assert email.subject == "[alpine] You've been added to Trip Planning"

    assert email.text_body =~
             ClubSite.url(club, ~p"/groups/#{group.group_id}")

    _html =
      render_click(
        view,
        "add_custom_group_member",
        admission_params
      )

    refute_received {:email, %Swoosh.Email{}}
  end

  test "replaying the admission rebuilds membership without resending its welcome", %{conn: conn} do
    club = create_club!("Alpine Club", "alpine")
    alice = create_member!(club, "Alice Adams", "alice@example.com")
    carol = create_member!(club, "Carol Canoe", "carol@example.com")
    group = create_custom_group!(club, alice, "Trip Planning")

    conn = signed_in_club_host(conn, "alice@example.com", club)
    {:ok, view, _html} = live(conn, ~p"/groups/#{group.group_id}/members")

    _html =
      render_click(
        view,
        "add_custom_group_member",
        %{"membership_id" => carol.membership_id, "person_id" => carol.person_id}
      )

    assert_received {:email, %Swoosh.Email{} = welcome}
    assert welcome.to == [{"Carol Canoe", "carol@example.com"}]

    view_ref = Process.monitor(view.pid)
    :ok = GenServer.stop(view.pid)
    assert_receive {:DOWN, ^view_ref, :process, _, :normal}

    replay_projectors = [
      Memba.Membership.Projectors.Club,
      Memba.Membership.Projectors.Group,
      Memba.Membership.Projectors.GroupMembership,
      Memba.Membership.Projectors.Membership,
      Memba.Membership.Projectors.Person,
      Memba.Membership.Projectors.Role
    ]

    projection_positions =
      Memba.EventSourcedCase.event_sourced_projection_positions(replay_projectors)

    Memba.EventSourcedCase.rebuild_event_sourced_projections!()

    Memba.EventSourcedCase.await_event_sourced_projection_positions!(projection_positions)

    assert Membership.active_member_of_group?(group.group_id, carol.person_id)
    refute_received {:email, %Swoosh.Email{}}
  end

  test "an admission refreshes permissions in the admitted member's already-open view",
       %{conn: conn} do
    club = create_club!("Alpine Club", "alpine")
    alice = create_member!(club, "Alice Adams", "alice@example.com")
    carol = create_member!(club, "Carol Canoe", "carol@example.com")
    group = create_custom_group!(club, alice, "Trip Planning")

    {:ok, carol_view, _html} =
      conn
      |> signed_in_club_host("carol@example.com", club)
      |> live(~p"/groups/#{group.group_id}")

    assert has_element?(
             carol_view,
             "#member-group-access-title",
             "Trip Planning is a private group"
           )

    refute has_element?(carol_view, "#member-section-tabs")

    {:ok, alice_view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", club)
      |> live(~p"/groups/#{group.group_id}/members")

    _html =
      render_click(
        alice_view,
        "add_custom_group_member",
        %{"membership_id" => carol.membership_id, "person_id" => carol.person_id}
      )

    assert_received {:email, %Swoosh.Email{}}

    _state = :sys.get_state(carol_view.pid)

    refute has_element?(carol_view, "#member-group-access-guidance")

    assert has_element?(
             carol_view,
             "#member-section-tab-conversations[href='/groups/#{group.group_id}']",
             "Conversations"
           )

    assert has_element?(carol_view, "#club-member-#{carol.person_id}", "Carol Canoe")
    assert has_element?(carol_view, "#member-group-member-count", "2 members")
  end

  test "a provider failure is logged without adding delivery UI or hiding the admission",
       %{conn: conn} do
    original_mailer_config = Application.fetch_env!(:memba, Memba.Mailer)

    on_exit(fn ->
      Application.put_env(:memba, Memba.Mailer, original_mailer_config)
    end)

    Application.put_env(:memba, Memba.Mailer,
      adapter: Memba.TestSupport.FailingSwooshAdapter,
      test_owner: self(),
      test_delivery_result: {:error, :timeout}
    )

    club = create_club!("Alpine Club", "alpine")
    alice = create_member!(club, "Alice Adams", "alice@example.com")
    carol = create_member!(club, "Carol Canoe", "carol@example.com")
    group = create_custom_group!(club, alice, "Trip Planning")

    {session, log} =
      with_log(fn ->
        conn
        |> signed_in_club_host("alice@example.com", club)
        |> visit(~p"/groups/#{group.group_id}/members")
        |> click_button("Add member")
        |> click_button("#custom-group-member-candidate-add-#{carol.person_id}", "Add")
      end)

    assert_received {:failing_swoosh_adapter_deliver, %Swoosh.Email{}}

    assert log =~ "Could not deliver custom-group welcome email"
    assert log =~ "group_welcome_email_delivery_error"
    assert log =~ ":timeout"

    session
    |> assert_has("#club-member-#{carol.person_id}", "Carol Canoe")
    |> refute_has("#custom-group-member-candidate-#{carol.person_id}")
    |> refute_has("#flash-error")
    |> refute_has("[data-testid='delivery-status']")

    assert Membership.active_member_of_group?(group.group_id, carol.person_id)
  end

  test "submit reauthorizes in the Club aggregate when projected group access is stale",
       %{conn: conn} do
    club = create_club!("Alpine Club", "alpine")
    creator = create_member!(club, "Alice Adams", "alice@example.com")
    outsider = create_member!(club, "Bob Builder", "bob@example.com")
    target = create_member!(club, "Carol Canoe", "carol@example.com")
    group = create_custom_group!(club, creator, "Board")

    Repo.insert!(%GroupMembership{
      club_id: club.club_id,
      group_id: group.group_id,
      membership_id: outsider.membership_id,
      person_id: outsider.person_id,
      active: true
    })

    session =
      conn
      |> signed_in_club_host("bob@example.com", club)
      |> visit(~p"/groups/#{group.group_id}/members")
      |> click_button("Add member")
      |> click_button("#custom-group-member-candidate-add-#{target.person_id}", "Add")

    session
    |> assert_has("#flash-error", "We couldn't add that member. Refresh and try again.")
    |> assert_has("#custom-group-member-candidate-#{target.person_id}", "Carol Canoe")
    |> refute_has("#club-member-#{target.person_id}")

    refute Membership.active_member_of_group?(group.group_id, target.person_id)
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

    %{club_id: club.club_id, membership_id: membership_id, person_id: person_id}
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

  defp signed_in_club_host(conn, email, club) do
    %{host: host} = club |> ClubSite.url() |> URI.parse()

    conn
    |> Map.put(:host, host)
    |> Plug.Test.init_test_session(%{IdentityAuth.identity_session_key() => email})
  end
end
