defmodule MembaWeb.MySettingsLiveTest do
  use MembaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Memba.Membership.Projections.Membership
  alias Memba.Repo
  alias MembaWeb.ClubSite
  alias MembaWeb.IdentityAuth

  test "renders the default settings route with the profile tab selected", %{conn: conn} do
    club = insert_membership_club!(name: "Settings Shell Club", slug: "settings-shell")

    member =
      create_active_member(club, email: "alice.settings@example.com", name: "Alice Settings")

    {:ok, view, _html} =
      conn
      |> signed_in_club_host(club, member.email)
      |> live(~p"/my/settings")

    assert has_element?(
             view,
             "#my-settings[data-live-view='my-settings'][data-active-tab='profile']"
           )

    assert has_element?(view, "#my-settings-title", "Account settings")
    assert has_element?(view, "#club-site-identity-menu-button .app-bar__who", "Alice Settings")

    assert has_element?(
             view,
             "#my-settings-tab-profile[role='tab'][aria-selected='true']" <>
               "[aria-controls='my-settings-panel-profile']" <>
               "[data-phx-link='patch'][href='/my/settings/profile']",
             "Profile"
           )

    assert has_element?(
             view,
             "#my-settings-tab-clubs[role='tab'][aria-selected='false']" <>
               "[aria-controls='my-settings-panel-clubs']" <>
               "[data-phx-link='patch'][href='/my/settings/clubs']",
             "Clubs"
           )

    assert has_element?(
             view,
             "#my-settings-tab-emails[role='tab'][aria-selected='false']" <>
               "[aria-controls='my-settings-panel-emails']" <>
               "[data-phx-link='patch'][href='/my/settings/emails']",
             "Emails"
           )

    assert has_element?(view, "#my-settings-panel-profile[role='tabpanel']")
    refute has_element?(view, "#my-settings-panel-profile[hidden]")
    assert has_element?(view, "#my-settings-panel-clubs[hidden]")
    assert has_element?(view, "#my-settings-panel-emails[hidden]")
  end

  test "direct tab routes restore the selected settings tab", %{conn: conn} do
    club = insert_membership_club!(name: "Direct Settings Club", slug: "direct-settings")
    member = create_active_member(club, email: "direct.settings@example.com", name: "Direct Tab")

    {:ok, view, _html} =
      conn
      |> signed_in_club_host(club, member.email)
      |> live(~p"/my/settings/clubs")

    assert has_element?(
             view,
             "#my-settings[data-live-view='my-settings'][data-active-tab='clubs']"
           )

    assert has_element?(view, "#my-settings-tab-clubs[aria-selected='true']")
    refute has_element?(view, "#my-settings-panel-clubs[hidden]")
    assert has_element?(view, "#my-settings-panel-profile[hidden]")
    assert has_element?(view, "#my-settings-panel-emails[hidden]")
  end

  test "settings tabs patch the URL without client-side-only state", %{conn: conn} do
    club = insert_membership_club!(name: "Patch Settings Club", slug: "patch-settings")
    member = create_active_member(club, email: "patch.settings@example.com", name: "Patch Tab")

    {:ok, view, _html} =
      conn
      |> signed_in_club_host(club, member.email)
      |> live(~p"/my/settings")

    view
    |> element("#my-settings-tab-emails")
    |> render_click()

    assert_patch(view, ~p"/my/settings/emails")

    assert has_element?(
             view,
             "#my-settings[data-live-view='my-settings'][data-active-tab='emails']"
           )

    assert has_element?(view, "#my-settings-tab-emails[aria-selected='true']")
    refute has_element?(view, "#my-settings-panel-emails[hidden]")
    assert has_element?(view, "#my-settings-panel-profile[hidden]")
    assert has_element?(view, "#my-settings-panel-clubs[hidden]")
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

    Repo.insert!(%Membership{
      membership_id: Memba.ID.generate(:membership),
      club_id: club.club_id,
      person_id: person.person_id,
      active: true
    })

    person
  end
end
