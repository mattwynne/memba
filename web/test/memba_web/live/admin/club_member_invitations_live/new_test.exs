defmodule MembaWeb.Admin.ClubMemberInvitationsLive.NewTest do
  use MembaWeb.FeatureCase, async: false

  import Phoenix.LiveViewTest
  import Swoosh.TestAssertions

  alias Memba.Accounts.AuthEmail
  alias Memba.Membership
  alias Memba.Membership.Projections.ClubInvitation

  setup :set_swoosh_global

  setup do
    original_mailer_config = Application.get_env(:memba, Memba.Mailer)
    original_auth_email_config = Application.get_env(:memba, AuthEmail)

    Application.put_env(:memba, Memba.Mailer,
      adapter: Swoosh.Adapters.Test,
      api_key: "server-token"
    )

    Application.put_env(:memba, AuthEmail,
      from: "auth@mail.memba.local",
      message_stream: "test-auth"
    )

    on_exit(fn ->
      restore_env(Memba.Mailer, original_mailer_config)
      restore_env(AuthEmail, original_auth_email_config)
    end)

    :ok
  end

  test "staff can open the club-scoped member invitation form", %{conn: conn} do
    club = insert_membership_club!(name: "Kootenay Mountaineering Club")

    conn
    |> sign_in_staff()
    |> visit(~p"/admin/clubs/#{club.club_id}/invitations/new")
    |> assert_path("/admin/clubs/*/invitations/new")
    |> assert_has("#admin-layout[data-surface='admin']")
    |> assert_has(
      "#club-member-invitation-new[data-admin-page='club-member-invitation-new'][data-club-id='#{club.club_id}']"
    )
    |> assert_has("#club-member-invitation-page-header", "Invite a member")
    |> assert_has("#club-member-invitation-context-card", "Kootenay Mountaineering Club")
    |> assert_has("#back-to-club-link[href='/admin/clubs/#{club.club_id}']")
    |> assert_has("#club-member-invitation-form[aria-label='Invite member']")
    |> assert_has("#club-member-invitation-email-input[aria-label='Invitee email address']")
    |> assert_has("#send-club-member-invitation-button")
    |> refute_has("#person-name-input")
    |> refute_has("input[name='invitation[name]']")
  end

  test "staff can submit an email-only invitation without creating a person or membership", %{
    conn: conn
  } do
    club = insert_membership_club!(name: "Kootenay Mountaineering Club")

    {:ok, view, _html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/clubs/#{club.club_id}/invitations/new")

    view
    |> form("#club-member-invitation-form", invitation: %{email: " ROBIN@Example.COM "})
    |> render_submit()

    assert has_element?(view, "#flash-info", "Invitation sent to robin@example.com")

    assert %ClubInvitation{
             club_id: club_id,
             email: "robin@example.com",
             normalized_email: "robin@example.com",
             status: "pending"
           } =
             Membership.get_pending_club_member_invitation_by_email(
               club.club_id,
               "robin@example.com"
             )

    assert club_id == club.club_id

    refute Membership.get_person_by_email("robin@example.com")
    refute Membership.active_member_of_club_by_email?(club.club_id, "robin@example.com")

    assert_email_sent(fn email ->
      assert email.to == [{"", "robin@example.com"}]
      assert email.subject == "You're invited to join Kootenay Mountaineering Club"
      assert email.text_body =~ "/invitations/club-members/"
      assert email.text_body =~ "This invitation link can be used once"
    end)
  end

  test "staff email invitation link carries an unknown invitee through profile completion to the club",
       %{conn: conn} do
    club =
      insert_membership_club!(
        name: "Kootenay Mountaineering Club",
        slug: "kootenay-mountaineering"
      )

    conn
    |> sign_in_staff()
    |> visit(~p"/admin/clubs/#{club.club_id}/invitations/new")
    |> assert_has("#club-member-invitation-form")
    |> fill_in("Email address", with: " ROBIN@Example.COM ")
    |> click_button("Send invitation")
    |> assert_has("#flash-info", "Invitation sent to robin@example.com")

    invitation_path = delivered_invitation_path!("robin@example.com")

    new_browser_conn()
    |> visit(invitation_path)
    |> assert_path(~p"/invitations/club-members/profile")
    |> assert_has("section#club-member-profile-completion[data-club-id='#{club.club_id}']")
    |> assert_has("#club-member-profile-completion-form[aria-label='Complete your profile']")
    |> assert_has("#club-member-profile-name-input")
    |> fill_in("Your name", with: " Robin Example ")
    |> click_button("Join Kootenay Mountaineering Club")
    |> assert_path(~p"/conversations")
    |> assert_has("#member-club-home[data-club-id='#{club.club_id}']")
    |> assert_has("#club-site-identity-menu .app-menu__who-name", "Robin Example")
    |> assert_has("#member-section-tab-conversations[aria-selected='true']", "Conversations")

    assert %{name: "Robin Example", email: "robin@example.com"} =
             Membership.get_person_by_email("robin@example.com")

    assert Membership.active_member_of_club_by_email?(club.club_id, "robin@example.com")
  end

  test "staff sees a form error for an invalid invitation email", %{conn: conn} do
    club = insert_membership_club!(name: "Kootenay Mountaineering Club")

    {:ok, view, _html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/clubs/#{club.club_id}/invitations/new")

    view
    |> form("#club-member-invitation-form", invitation: %{email: "not-an-email"})
    |> render_submit()

    assert has_element?(view, "#club-member-invitation-email-input.input-error")
    assert has_element?(view, "#club-member-invitation-form", "Enter a valid email address.")

    assert is_nil(
             Membership.get_pending_club_member_invitation_by_email(club.club_id, "not-an-email")
           )

    assert_no_email_sent()
  end

  test "club detail links to the member invitation route without replacing person edit", %{
    conn: conn
  } do
    club = insert_membership_club!(name: "Kootenay Mountaineering Club")
    person = insert_membership_person!(name: "Alice Example", email: "alice@example.com")

    {:ok, view, _initial_html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/clubs/#{club.club_id}")

    assert has_element?(
             view,
             "#invite-member-link[href='/admin/clubs/#{club.club_id}/invitations/new']",
             "Invite member"
           )

    assert has_element?(
             view,
             "#edit-person-link-#{person.person_id}[href='/admin/clubs/#{club.club_id}/people/#{person.person_id}/edit']"
           )
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)

  defp delivered_invitation_path!(email_address) do
    assert_receive {:email, email}

    assert email.to == [{"", email_address}]
    assert email.subject == "You're invited to join Kootenay Mountaineering Club"

    [invitation_url] =
      Regex.run(~r{https?://[^\s]+/invitations/club-members/[^\s]+}, email.text_body)

    assert email.html_body =~ invitation_url

    %URI{path: path} = URI.parse(invitation_url)
    assert path =~ ~r{^/invitations/club-members/.+}

    path
  end

  defp new_browser_conn do
    Phoenix.ConnTest.build_conn()
    |> PhoenixTest.put_endpoint(MembaWeb.Endpoint)
  end
end
