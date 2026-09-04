defmodule MembaWeb.ClubSiteShellSurfacesTest do
  use MembaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Memba.Membership.Permissions
  alias Memba.Membership.Projections.Group
  alias Memba.Membership.Projections.GroupMembership
  alias Memba.Membership.Projections.MemberPermission
  alias Memba.Membership.Projections.Membership
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging.Projections.Message
  alias Memba.Repo
  alias MembaWeb.ClubSite
  alias MembaWeb.IdentityAuth

  test "signed-in club shell falls back to email identity when the member name is blank", %{
    conn: conn
  } do
    club = insert_membership_club!(name: "Blank Name Shell Club", slug: "blank-name-shell")

    member =
      create_active_member(club,
        email: "alice.no-name@example.com",
        name: "   "
      )

    club_home_html =
      conn
      |> signed_in_club_host(club, member.email)
      |> get(~p"/conversations")
      |> html_response(200)

    assert_club_site_shell(
      club_home_html,
      "#member-club-home[data-club-id='#{club.club_id}']",
      club.name,
      member_name: "alice.no-name",
      member_initials: "AN"
    )
  end

  test "every club_site surface renders inside the shared app shell", %{conn: conn} do
    club = insert_membership_club!(name: "Shared Shell Club", slug: "shared-shell")

    alice =
      create_active_member(club,
        email: "alice.shared-shell@example.com",
        name: "Alice Shell"
      )

    _bob =
      create_active_member(club,
        email: "bob.shared-shell@example.com",
        name: "Bob Shell"
      )

    grant_manage_members!(alice)

    message =
      create_message(
        club_id: club.club_id,
        sender_id: alice.person_id,
        subject: "Shared shell conversation"
      )

    public_html =
      conn
      |> club_host(club)
      |> get(~p"/")
      |> html_response(200)

    assert_club_site_shell(
      public_html,
      "#public-club-page-page[data-club-id='#{club.club_id}']",
      club.name
    )

    club_home_html =
      conn
      |> signed_in_club_host(club, alice.email)
      |> get(~p"/conversations")
      |> html_response(200)

    assert_club_site_shell(
      club_home_html,
      "#member-club-home[data-club-id='#{club.club_id}']",
      club.name,
      member_name: alice.name
    )

    {:ok, conversation_view, _html} =
      conn
      |> signed_in_club_host(club, alice.email)
      |> live(~p"/messages/#{message.message_id}")

    conversation_view
    |> render()
    |> assert_club_site_shell(
      "#member-message-detail[data-club-id='#{club.club_id}'][data-message-id='#{message.message_id}']",
      club.name,
      member_name: alice.name
    )

    {:ok, compose_view, _html} =
      conn
      |> signed_in_club_host(club, alice.email)
      |> live(~p"/messages/new")

    compose_view
    |> render()
    |> assert_club_site_shell(
      "#member-message-compose[data-club-id='#{club.club_id}']",
      club.name,
      member_name: alice.name
    )

    {:ok, invitation_view, _html} =
      conn
      |> signed_in_club_host(club, alice.email)
      |> live(~p"/members/invitations/new")

    invitation_view
    |> render()
    |> assert_club_site_shell(
      "#member-club-invitation-new[data-club-id='#{club.club_id}']",
      club.name,
      member_name: alice.name
    )
  end

  defp assert_club_site_shell(html, content_selector, club_name, opts \\ []) do
    document = LazyHTML.from_fragment(html)

    assert_selector(document, "#club-site-layout.app-frame[data-surface='club-site']")
    assert_selector(document, "#club-site-layout > .app-card > header > .app-bar")
    assert_selector(document, "#club-site-layout > .app-card > main > #{content_selector}")
    assert_text(document, "#club-site-layout header .app-bar__club", club_name)
    assert_selector(document, "#club-site-footer.app-foot")
    assert_text(document, "#club-site-footer", "Powered by Memba")

    case Keyword.fetch(opts, :member_name) do
      {:ok, member_name} ->
        assert_selector(document, "#club-site-global-bar #club-site-identity-menu-button")
        assert_text(document, "#club-site-identity-menu .app-menu__who-name", member_name)

        if member_initials = Keyword.get(opts, :member_initials) do
          assert_text(
            document,
            "#club-site-identity-menu-button .global-bar__avatar",
            member_initials
          )
        end

        assert_selector(document, "#club-site-sign-out-form[action='/auth'][method='post']")

      :error ->
        refute_selector(document, "#club-site-identity-menu-button")
        refute_selector(document, "#club-site-sign-out-form")
    end
  end

  defp assert_selector(document, selector) do
    assert document |> LazyHTML.query(selector) |> Enum.any?(), "Expected selector #{selector}"
  end

  defp refute_selector(document, selector) do
    refute document |> LazyHTML.query(selector) |> Enum.any?(), "Expected no selector #{selector}"
  end

  defp assert_text(document, selector, expected_text) do
    actual_text =
      document
      |> LazyHTML.query(selector)
      |> LazyHTML.text()
      |> normalize_whitespace()

    assert actual_text =~ normalize_whitespace(expected_text)
  end

  defp normalize_whitespace(text) do
    text
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp signed_in_club_host(conn, club, email) do
    conn
    |> club_host(club)
    |> init_test_session(%{IdentityAuth.identity_session_key() => email})
  end

  defp club_host(conn, club) do
    %{host: host} = URI.parse(ClubSite.url(club))
    Map.put(conn, :host, host)
  end

  defp create_active_member(club, attrs) do
    person =
      insert_membership_person!(
        person_id: Memba.ID.generate(:person),
        name: Keyword.fetch!(attrs, :name),
        email: Keyword.fetch!(attrs, :email)
      )

    membership =
      Repo.insert!(%Membership{
        membership_id: Memba.ID.generate(:membership),
        club_id: club.club_id,
        person_id: person.person_id,
        active: true
      })

    insert_everyone_group_membership!(club.club_id, membership.membership_id, person.person_id)

    club
    |> Map.from_struct()
    |> Map.merge(%{
      membership_id: membership.membership_id,
      person_id: person.person_id,
      name: person.name,
      email: person.email
    })
  end

  defp insert_everyone_group_membership!(club_id, membership_id, person_id) do
    group_id = SystemGroups.everyone_group_id(club_id)

    Repo.insert!(
      %Group{
        club_id: club_id,
        group_id: group_id,
        group_key: SystemGroups.everyone_key(),
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

  defp grant_manage_members!(member) do
    Repo.insert!(%MemberPermission{
      club_id: member.club_id,
      membership_id: member.membership_id,
      person_id: member.person_id,
      permission: Permissions.club_manage_members(),
      grant_count: 1
    })
  end

  defp create_message(attrs) do
    message_id = Memba.ID.generate(:message)

    Repo.insert!(%Message{
      message_id: message_id,
      club_id: Keyword.fetch!(attrs, :club_id),
      sender_id: Keyword.fetch!(attrs, :sender_id),
      conversation_id: Keyword.get(attrs, :conversation_id, message_id),
      reply_to_message_id: Keyword.get(attrs, :reply_to_message_id),
      subject: Keyword.fetch!(attrs, :subject),
      body: Keyword.get(attrs, :body, "Message body")
    })
  end
end
