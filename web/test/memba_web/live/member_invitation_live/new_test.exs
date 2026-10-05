defmodule MembaWeb.MemberInvitationLive.NewTest do
  use MembaWeb.ConnCase, async: true

  import Ecto.Query
  import Phoenix.LiveViewTest

  alias Memba.Membership.Events.ClubMemberAdded
  alias Memba.Membership.Events.ClubMemberRemoved
  alias Memba.Membership.Events.ClubRoleRemovedFromMember
  alias Memba.Membership.Events.ClubUpdated
  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Permissions
  alias Memba.Membership.Projections.MemberPermission
  alias Memba.Membership.Projections.Membership
  alias Memba.Repo
  alias MembaWeb.ClubSite
  alias MembaWeb.IdentityAuth

  test "routed GET on the club subdomain passes the selected club to the LiveView",
       %{conn: conn} do
    robin =
      create_active_member(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers"
      )

    grant_manage_members!(robin)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("robin@example.com", robin)
      |> live(~p"/members/invitations/new")

    assert has_element?(
             view,
             "#member-club-invitation-new[data-live-view='member-club-invitation-new'][data-club-id='#{robin.club_id}'][data-current-member-id='#{robin.person_id}']"
           )

    assert has_element?(
             view,
             "#club-site-identity-menu .app-menu__who-name",
             "Robin Rivers"
           )

    assert has_element?(
             view,
             "#club-site-identity-menu-button .global-bar__avatar",
             "RR"
           )

    assert has_element?(
             view,
             "#member-club-invitation-selected-club[data-club-id='#{robin.club_id}']",
             "West Coast Paddlers"
           )

    assert has_element?(
             view,
             "#member-club-invitation-club-home-link[href='/conversations']",
             "Club home"
           )

    assert has_element?(
             view,
             "#member-club-invitation-current-member-avatar.avatar.avatar-placeholder[data-testid='member-club-invitation-current-member-avatar'][title='Robin Rivers']",
             "RR"
           )

    assert has_element?(
             view,
             "button#send-member-club-invitation-button.btn.btn-primary.btn-lg[type='submit']",
             "Send invitation"
           )

    assert has_element?(
             view,
             "#cancel-member-club-invitation-link.btn.btn-soft.btn-lg[href='/conversations']",
             "Cancel"
           )
  end

  test "club subdomain routed mount keeps the host-selected club after LiveView connects", %{
    conn: conn
  } do
    robin =
      create_active_member(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers",
        slug: "wcp"
      )

    grant_manage_members!(robin)

    _alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "West Coast Paddlers",
        club_id: robin.club_id,
        slug: "wcp"
      )

    {:ok, view, _html} =
      conn
      |> Map.put(:host, "wcp.lvh.me")
      |> init_test_session(%{IdentityAuth.identity_session_key() => "robin@example.com"})
      |> live(~p"/members/invitations/new")

    assert has_element?(
             view,
             "#member-club-invitation-new[data-club-id='#{robin.club_id}'][data-current-member-id='#{robin.person_id}'][data-active-member-count='2']"
           )

    assert has_element?(view, "#member-club-invitation-club-home-link[href='/conversations']")
    refute has_element?(view, "#member-club-invitation-club-home-link[href*='club_id=']")
  end

  test "invitation return links preserve selected-group context", %{conn: conn} do
    robin =
      create_active_member(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers"
      )

    grant_manage_members!(robin)
    group_id = Memba.Membership.SystemGroups.everyone_group_id(robin.club_id)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("robin@example.com", robin)
      |> live(~p"/members/invitations/new?#{[group_id: group_id]}")

    assert has_element?(
             view,
             "#member-club-invitation-club-home-link[href='/groups/#{group_id}']",
             "Club home"
           )

    assert has_element?(
             view,
             "#cancel-member-club-invitation-link[href='/groups/#{group_id}']",
             "Cancel"
           )
  end

  test "membership admin invitation form asks for email address only", %{conn: conn} do
    robin =
      create_active_member(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers"
      )

    grant_manage_members!(robin)

    {:ok, view, initial_html} =
      conn
      |> signed_in_club_host("robin@example.com", robin)
      |> live(~p"/members/invitations/new")

    initial_document = LazyHTML.from_fragment(initial_html)

    assert_invitation_form_is_email_only(initial_document)
    assert has_element?(view, "#member-club-invitation-email-input[type='email']")
    refute has_element?(view, "#member-club-invitation-form input[name='invitation[name]']")
    refute has_element?(view, "#member-club-invitation-form select[name='invitation[role]']")

    html =
      render_change(view, "validate_invitation", %{
        "invitation" => %{
          "email" => "dana@example.com",
          "name" => "Dana Example",
          "role" => "membership_admin"
        }
      })

    html
    |> LazyHTML.from_fragment()
    |> assert_invitation_form_is_email_only()
  end

  test "selected-club members enter and leave an already-open invitation context", %{
    conn: conn
  } do
    robin =
      create_active_member(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers"
      )

    bob =
      create_active_member(
        email: "bob@example.com",
        name: "Bob Builder",
        club_id: robin.club_id,
        club_name: "West Coast Paddlers"
      )

    grant_manage_members!(robin)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("robin@example.com", robin)
      |> live(~p"/members/invitations/new")

    assert has_element?(
             view,
             "#member-club-invitation-new[data-active-member-count='2']"
           )

    %{socket: initial_socket} = :sys.get_state(view.pid)
    assert initial_socket.assigns.invitation_context.active_member_count == 2
    refute Map.has_key?(initial_socket.assigns, :selected_club)
    refute Map.has_key?(initial_socket.assigns, :current_member)
    refute Map.has_key?(initial_socket.assigns, :active_member_count)

    carol =
      create_active_member(
        email: "carol@example.com",
        name: "Carol Canoe",
        club_id: robin.club_id,
        club_name: "West Coast Paddlers"
      )

    notify_read_model_change(
      view,
      Memba.Membership.Projectors.Membership,
      %ClubMemberAdded{
        club_id: robin.club_id,
        membership_id: carol.membership_id,
        person_id: carol.person_id
      }
    )

    assert has_element?(
             view,
             "#member-club-invitation-new[data-active-member-count='3']"
           )

    Membership
    |> where([membership], membership.membership_id == ^bob.membership_id)
    |> Repo.update_all(set: [active: false])

    notify_read_model_change(
      view,
      Memba.Membership.Projectors.Membership,
      %ClubMemberRemoved{
        club_id: robin.club_id,
        membership_id: bob.membership_id,
        person_id: bob.person_id
      }
    )

    assert has_element?(
             view,
             "#member-club-invitation-new[data-active-member-count='2']"
           )
  end

  test "a relevant refresh preserves typed invitation input and validation errors", %{conn: conn} do
    robin =
      create_active_member(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers"
      )

    grant_manage_members!(robin)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("robin@example.com", robin)
      |> live(~p"/members/invitations/new")

    view
    |> form("#member-club-invitation-form", invitation: %{email: "not-an-email"})
    |> render_change()

    club = Memba.Membership.get_club(robin.club_id)

    club
    |> Ecto.Changeset.change(name: "West Coast Alpine Club")
    |> Repo.update!()

    notify_read_model_change(
      view,
      Memba.Membership.Projectors.Club,
      %ClubUpdated{
        club_id: robin.club_id,
        name: "West Coast Alpine Club",
        slug: club.slug
      }
    )

    assert has_element?(
             view,
             "#member-club-invitation-selected-club",
             "West Coast Alpine Club"
           )

    assert has_element?(
             view,
             "#member-club-invitation-email-input[value='not-an-email'][aria-invalid='true']"
           )

    assert has_element?(
             view,
             "#member-club-invitation-email-input-error-1",
             "Enter a valid email address."
           )

    %{socket: socket} = :sys.get_state(view.pid)
    assert socket.assigns.form.params == %{"email" => "not-an-email"}
    assert socket.assigns.form_errors == %{email: ["Enter a valid email address."]}
  end

  test "an unrelated-club notification leaves context, form, and route state untouched", %{
    conn: conn
  } do
    robin =
      create_active_member(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers"
      )

    other =
      create_active_member(
        email: "other@example.com",
        name: "Other Member",
        club_name: "Other Club"
      )

    grant_manage_members!(robin)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("robin@example.com", robin)
      |> live(~p"/members/invitations/new?#{[group_id: "selected-group"]}")

    view
    |> form("#member-club-invitation-form", invitation: %{email: "dana@example.com"})
    |> render_change()

    %{socket: before_socket} = :sys.get_state(view.pid)
    selected_club = Memba.Membership.get_club(robin.club_id)
    other_club = Memba.Membership.get_club(other.club_id)

    selected_club
    |> Ecto.Changeset.change(name: "Must Not Be Loaded")
    |> Repo.update!()

    notify_read_model_change(
      view,
      Memba.Membership.Projectors.Club,
      %ClubUpdated{
        club_id: other.club_id,
        name: other_club.name,
        slug: other_club.slug
      }
    )

    assert has_element?(
             view,
             "#member-club-invitation-selected-club",
             "West Coast Paddlers"
           )

    refute has_element?(view, "#member-club-invitation-selected-club", "Must Not Be Loaded")
    assert has_element?(view, "#member-club-invitation-email-input[value='dana@example.com']")

    assert has_element?(
             view,
             "#cancel-member-club-invitation-link[href='/groups/selected-group']"
           )

    %{socket: after_socket} = :sys.get_state(view.pid)
    assert after_socket.assigns.invitation_context == before_socket.assigns.invitation_context
    assert after_socket.assigns.route_params == before_socket.assigns.route_params
    assert after_socket.assigns.form.params == before_socket.assigns.form.params
    assert after_socket.assigns.form_errors == before_socket.assigns.form_errors
  end

  test "fresh club-membership loss leaves an already-open private surface", %{conn: conn} do
    robin =
      create_active_member(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers"
      )

    grant_manage_members!(robin)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("robin@example.com", robin)
      |> live(~p"/members/invitations/new")

    Membership
    |> where([membership], membership.membership_id == ^robin.membership_id)
    |> Repo.update_all(set: [active: false])

    monitor = Process.monitor(view.pid)

    notify_read_model_change(
      view,
      Memba.Membership.Projectors.Membership,
      %ClubMemberRemoved{
        club_id: robin.club_id,
        membership_id: robin.membership_id,
        person_id: robin.person_id
      }
    )

    assert_receive {:DOWN, ^monitor, :process, _pid, {%MembaWeb.ForbiddenError{}, _stacktrace}}
  end

  test "fresh manage-members loss leaves an already-open private surface", %{conn: conn} do
    robin =
      create_active_member(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers"
      )

    grant_manage_members!(robin)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("robin@example.com", robin)
      |> live(~p"/members/invitations/new")

    revoke_projected_manage_members!(robin)
    monitor = Process.monitor(view.pid)

    notify_read_model_change(
      view,
      Memba.Membership.Projectors.Role,
      %ClubRoleRemovedFromMember{
        club_id: robin.club_id,
        membership_id: robin.membership_id,
        person_id: robin.person_id,
        role_id: Memba.ID.generate(:role)
      }
    )

    assert_receive {:DOWN, ^monitor, :process, _pid, {%MembaWeb.ForbiddenError{}, _stacktrace}}
  end

  test "routed GET requires the current club member to have club.manage_members", %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "West Coast Paddlers"
      )

    assert_raise MembaWeb.ForbiddenError, fn ->
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> get(~p"/members/invitations/new")
    end
  end

  test "direct LiveView mount rejects ordinary members before rendering the invitation action",
       %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "West Coast Paddlers"
      )

    assert_raise MembaWeb.ForbiddenError, fn ->
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/members/invitations/new")
    end

    refute Repo.exists?(Memba.Membership.Projections.ClubInvitation)
  end

  test "club subdomain routed GET requires the current club member to have club.manage_members",
       %{conn: conn} do
    _alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "West Coast Paddlers",
        slug: "wcp"
      )

    assert_raise MembaWeb.ForbiddenError, fn ->
      conn
      |> Map.put(:host, "wcp.lvh.me")
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> get(~p"/members/invitations/new")
    end
  end

  test "routed GET redirects signed-out visitors and preserves the selected club return path",
       %{conn: conn} do
    robin =
      create_active_member(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers"
      )

    %{host: host} =
      robin.club_id
      |> Memba.Membership.get_club()
      |> ClubSite.url("/members/invitations/new")
      |> URI.parse()

    return_path = "http://#{host}/members/invitations/new"

    conn =
      conn
      |> club_host(robin)
      |> get(~p"/members/invitations/new")

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
      attrs
      |> club_attrs(club_id)
      |> insert_membership_club!()

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

    %{
      club_id: club_id,
      membership_id: membership.membership_id,
      person_id: person.person_id
    }
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

  defp revoke_projected_manage_members!(member) do
    Repo.delete_all(
      from member_permission in MemberPermission,
        where: member_permission.club_id == ^member.club_id,
        where: member_permission.membership_id == ^member.membership_id,
        where: member_permission.person_id == ^member.person_id,
        where: member_permission.permission == ^Permissions.club_manage_members()
    )
  end

  defp notify_read_model_change(view, projector, source_event) do
    send(
      view.pid,
      {:read_model_changed,
       %{
         projector: projector,
         source_event: source_event,
         metadata: %{},
         changes: %{}
       }}
    )
  end

  defp assert_invitation_form_is_email_only(html) do
    assert html
           |> LazyHTML.query(
             "#member-club-invitation-form input[name^='invitation['], #member-club-invitation-form select[name^='invitation['], #member-club-invitation-form textarea[name^='invitation[']"
           )
           |> Enum.count() == 1

    assert html
           |> LazyHTML.query(
             "#member-club-invitation-form input#member-club-invitation-email-input[name='invitation[email]'][type='email']"
           )
           |> Enum.any?()

    html
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
