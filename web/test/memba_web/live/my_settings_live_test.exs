defmodule MembaWeb.MySettingsLiveTest do
  use MembaWeb.ConnCase, async: true

  import Ecto.Query
  import Phoenix.LiveViewTest

  alias Memba.Membership.Projections.Membership
  alias Memba.Membership.Projections.PersonEmailAddress
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
             "#my-settings-back-to-club[href='/conversations']",
             "‹ Back to club"
           )

    assert has_element?(view, "#my-settings-profile-name", "Alice Settings")
    assert has_element?(view, "#my-settings-profile-avatar", "AS")

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

  test "renders club chips and grouped email-address rows from the selected design", %{conn: conn} do
    club = insert_membership_club!(name: "Settings Email Club", slug: "settings-email")
    second_club = insert_membership_club!(name: "Wilderness Book Club", slug: "wilderness-book")

    member =
      create_active_member(club, email: "alice.rows@example.com", name: "Alice Rows")

    Repo.insert!(%Membership{
      membership_id: Memba.ID.generate(:membership),
      club_id: second_club.club_id,
      person_id: member.person_id,
      active: true
    })

    primary_verified_at = ~U[2026-07-01 12:00:00Z]
    verified_at = ~U[2026-07-02 12:00:00Z]

    mark_email_verified!(member.person_id, "alice.rows@example.com", primary_verified_at)

    insert_membership_person_email_address!(
      person_id: member.person_id,
      email: "alice.work@example.com",
      is_primary: false
    )

    mark_email_verified!(member.person_id, "alice.work@example.com", verified_at)

    insert_membership_person_email_address!(
      person_id: member.person_id,
      email: "alice.pending@example.com",
      is_primary: false
    )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host(club, member.email)
      |> live(~p"/my/settings/emails")

    assert has_element?(view, "#my-settings-tabs-list.settings-tabs[aria-orientation='vertical']")
    assert has_element?(view, "#my-settings-panel-clubs[hidden]")
    assert has_element?(view, "#my-settings-panel-emails:not([hidden])")

    assert has_element?(view, "#my-settings-club-chip-#{club.club_id}", "Settings Email Club")
    assert has_element?(view, "#my-settings-club-chip-#{club.club_id}", "Member since")

    assert has_element?(
             view,
             "#my-settings-club-chip-#{second_club.club_id}",
             "Wilderness Book Club"
           )

    assert has_element?(view, "#my-settings-club-chip-#{second_club.club_id}", "Member since")

    primary_row = "#my-settings-email-row-alice-rows-example-com"

    assert has_element?(
             view,
             "#{primary_row}[data-state='primary'] .my-settings-primary-badge",
             "Primary"
           )

    assert has_element?(view, "#{primary_row} .my-settings-verified-badge", "Verified")
    assert has_element?(view, "#{primary_row} .my-settings-verified-badge .hero-check")

    refute has_element?(view, "#{primary_row} button")

    verified_row = "#my-settings-email-row-alice-work-example-com"
    assert has_element?(view, "#{verified_row}[data-state='verified']", "alice.work@example.com")
    assert has_element?(view, "#{verified_row} .my-settings-verified-badge", "Verified")
    assert has_element?(view, "#{verified_row} .my-settings-verified-badge .hero-check")
    assert has_element?(view, "#my-settings-make-primary-alice-work-example-com", "Make primary")
    assert has_element?(view, "#my-settings-remove-email-alice-work-example-com", "Remove")

    pending_row = "#my-settings-email-row-alice-pending-example-com"

    assert has_element?(
             view,
             "#{pending_row}[data-state='pending'] .my-settings-pending-badge",
             "Pending verification"
           )

    assert has_element?(view, "#{pending_row} .my-settings-pending-badge .dot")
    assert has_element?(view, "#my-settings-resend-verification-alice-pending-example-com")
    assert has_element?(view, "#my-settings-remove-email-alice-pending-example-com", "Remove")
    refute has_element?(view, "#my-settings-make-primary-alice-pending-example-com")

    assert has_element?(view, "#my-settings-add-email-form")
    assert has_element?(view, "#settings-add-email-input[type='email']")
    assert has_element?(view, "#my-settings-add-email-button", "Add email address")
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

  defp mark_email_verified!(person_id, email, verified_at) do
    normalized_email = String.downcase(email)

    {1, _rows} =
      Repo.update_all(
        from(email_address in PersonEmailAddress,
          where:
            email_address.person_id == ^person_id and
              email_address.normalized_email == ^normalized_email
        ),
        set: [verified_at: verified_at]
      )

    :ok
  end
end
