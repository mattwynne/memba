defmodule MembaWeb.MySettingsLiveTest do
  use MembaWeb.ConnCase, async: false

  import Ecto.Query
  import Phoenix.LiveViewTest

  alias Memba.Membership, as: MembershipContext
  alias Memba.Membership.Projections.Membership
  alias Memba.Membership.Projections.PersonEmailAddress
  alias Memba.ReadModelChanges
  alias Memba.Repo
  alias MembaWeb.ClubSite
  alias MembaWeb.IdentityAuth

  setup do
    Memba.EventSourcedCase.reset_event_sourced_system!()

    original_mailer_config = Application.get_env(:memba, Memba.Mailer)
    original_auth_email_config = Application.get_env(:memba, Memba.Accounts.AuthEmail)

    Application.put_env(:memba, Memba.Mailer,
      adapter: Swoosh.Adapters.Test,
      api_key: "settings-test-token"
    )

    Application.put_env(:memba, Memba.Accounts.AuthEmail,
      provider: :postmark,
      from: "auth@mail.memba.test",
      message_stream: "settings-test-auth"
    )

    on_exit(fn ->
      restore_env(Memba.Mailer, original_mailer_config)
      restore_env(Memba.Accounts.AuthEmail, original_auth_email_config)
    end)

    :ok
  end

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

  test "avatar menu contains Account settings, a separator, and Sign out", %{conn: conn} do
    club = insert_membership_club!(name: "Avatar Settings Club", slug: "avatar-settings")
    member = create_active_member(club, email: "avatar.settings@example.com", name: "Avatar Menu")

    {:ok, view, _html} =
      conn
      |> signed_in_club_host(club, member.email)
      |> live(~p"/my/settings")

    assert has_element?(
             view,
             "#club-site-identity-menu " <>
               "a#club-site-account-settings-link.app-menu__item[href='/my/settings'][role='menuitem']",
             "Account settings"
           )

    assert has_element?(
             view,
             "#club-site-account-settings-link + " <>
               "#club-site-identity-menu-divider.app-menu__divider[role='separator']" <>
               "[aria-orientation='horizontal'] + " <>
               "form#club-site-sign-out-form"
           )

    assert has_element?(
             view,
             "#club-site-sign-out-form[action='/auth'] input[name='_method'][value='delete']"
           )

    assert has_element?(view, "#club-site-sign-out-button[role='menuitem']", "Sign out")
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

  test "add email flow creates a pending row, leaves it non-primary, and sends verification",
       %{conn: conn} do
    club = insert_membership_club!(name: "Add Email Club", slug: "add-email")

    member =
      create_commanded_active_member(club,
        email: "add.primary@example.com",
        name: "Add Email"
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host(club, member.email)
      |> live(~p"/my/settings/emails")

    view
    |> form("#my-settings-add-email-form",
      email_address: %{email: " Add.Pending@Example.COM "}
    )
    |> render_submit()

    pending_row = "#my-settings-email-row-add-pending-example-com"

    assert has_element?(
             view,
             "#flash-info",
             "You've been sent a verification email. Click the link in your email to verify this address"
           )

    assert has_element?(view, "#{pending_row}[data-state='pending']", "Add.Pending@Example.COM")
    assert has_element?(view, "#my-settings-resend-verification-add-pending-example-com")
    assert has_element?(view, "#my-settings-remove-email-add-pending-example-com")
    refute has_element?(view, "#my-settings-make-primary-add-pending-example-com")

    assert %PersonEmailAddress{
             is_primary: false,
             verified_at: nil
           } =
             Repo.get_by(PersonEmailAddress,
               person_id: member.person_id,
               normalized_email: "add.pending@example.com"
             )

    assert_received {:email, %Swoosh.Email{} = email}
    assert email.to == [{"", "add.pending@example.com"}]
    assert email.subject == "Verify this email address for your Memba account"
    assert email.text_body =~ "/my/settings/email-verifications/"
  end

  test "add email flow shows the privacy-safe duplicate-address error", %{conn: conn} do
    club = insert_membership_club!(name: "Duplicate Email Club", slug: "duplicate-email")

    member =
      create_commanded_active_member(club,
        email: "duplicate.primary@example.com",
        name: "Duplicate Email"
      )

    _other_member =
      create_commanded_active_member(club,
        email: "already.used@example.com",
        name: "Already Used"
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host(club, member.email)
      |> live(~p"/my/settings/emails")

    view
    |> form("#my-settings-add-email-form",
      email_address: %{email: "ALREADY.USED@example.com"}
    )
    |> render_submit()

    assert has_element?(
             view,
             "#my-settings-add-email-error",
             "That email address is already in use by another Memba user."
           )

    refute has_element?(view, "#my-settings-email-row-already-used-example-com")
    refute_received {:email, %Swoosh.Email{to: [{"", "already.used@example.com"}]}}
  end

  test "resend and remove pending email flows update email delivery and domain state",
       %{conn: conn} do
    club = insert_membership_club!(name: "Pending Email Club", slug: "pending-email")

    member =
      create_commanded_active_member(club,
        email: "pending.primary@example.com",
        name: "Pending Email"
      )

    add_pending_email_address!(member.person_id, "pending.flow@example.com")

    {:ok, view, _html} =
      conn
      |> signed_in_club_host(club, member.email)
      |> live(~p"/my/settings/emails")

    pending_row = "#my-settings-email-row-pending-flow-example-com"
    assert has_element?(view, "#{pending_row}[data-state='pending']")

    view
    |> element("#my-settings-resend-verification-pending-flow-example-com")
    |> render_click()

    assert has_element?(view, "#{pending_row}[data-state='pending']")

    assert has_element?(
             view,
             "#flash-info",
             "You've been sent a verification email. Click the link in your email to verify this address"
           )

    assert %PersonEmailAddress{verified_at: nil, is_primary: false} =
             Repo.get_by(PersonEmailAddress,
               person_id: member.person_id,
               normalized_email: "pending.flow@example.com"
             )

    assert_received {:email, %Swoosh.Email{} = email}
    assert email.to == [{"", "pending.flow@example.com"}]
    assert email.subject == "Verify this email address for your Memba account"
    assert email.text_body =~ "/my/settings/email-verifications/"

    view
    |> element("#my-settings-remove-email-pending-flow-example-com")
    |> render_click()

    refute has_element?(view, pending_row)

    refute Repo.get_by(PersonEmailAddress,
             person_id: member.person_id,
             normalized_email: "pending.flow@example.com"
           )
  end

  test "make-primary and remove verified non-primary flows update UI and domain state",
       %{conn: conn} do
    club = insert_membership_club!(name: "Primary Email Club", slug: "primary-email")

    member =
      create_commanded_active_member(club,
        email: "old.primary@example.com",
        name: "Primary Email"
      )

    add_verified_email_address!(member.person_id, "new.primary@example.com")

    {:ok, view, _html} =
      conn
      |> signed_in_club_host(club, member.email)
      |> live(~p"/my/settings/emails")

    old_primary_row = "#my-settings-email-row-old-primary-example-com"
    new_primary_row = "#my-settings-email-row-new-primary-example-com"

    assert has_element?(view, "#{old_primary_row}[data-state='primary']")
    assert has_element?(view, "#{new_primary_row}[data-state='verified']")

    view
    |> element("#my-settings-make-primary-new-primary-example-com")
    |> render_click()

    assert has_element?(
             view,
             "#{new_primary_row}[data-state='primary'] .my-settings-primary-badge"
           )

    assert has_element?(view, "#{old_primary_row}[data-state='verified']")
    assert has_element?(view, "#my-settings-remove-email-old-primary-example-com")
    refute has_element?(view, "#my-settings-remove-email-new-primary-example-com")

    assert %PersonEmailAddress{is_primary: true, verified_at: %DateTime{}} =
             Repo.get_by(PersonEmailAddress,
               person_id: member.person_id,
               normalized_email: "new.primary@example.com"
             )

    assert %PersonEmailAddress{is_primary: false, verified_at: %DateTime{}} =
             Repo.get_by(PersonEmailAddress,
               person_id: member.person_id,
               normalized_email: "old.primary@example.com"
             )

    view
    |> element("#my-settings-remove-email-old-primary-example-com")
    |> render_click()

    refute has_element?(view, old_primary_row)

    refute Repo.get_by(PersonEmailAddress,
             person_id: member.person_id,
             normalized_email: "old.primary@example.com"
           )

    assert %PersonEmailAddress{is_primary: true} =
             Repo.get_by(PersonEmailAddress,
               person_id: member.person_id,
               normalized_email: "new.primary@example.com"
             )
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

  test "refreshes email rows after a matching person email-address read-model notification", %{
    conn: conn
  } do
    club = insert_membership_club!(name: "Refresh Settings Club", slug: "refresh-settings")

    member =
      create_active_member(club,
        email: "refresh.settings@example.com",
        name: "Refresh Settings"
      )

    other_member =
      create_active_member(club,
        email: "other.refresh.settings@example.com",
        name: "Other Refresh"
      )

    insert_membership_person_email_address!(
      person_id: member.person_id,
      email: "refresh.pending@example.com",
      is_primary: false
    )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host(club, member.email)
      |> live(~p"/my/settings/emails")

    pending_row = "#my-settings-email-row-refresh-pending-example-com"
    assert has_element?(view, "#{pending_row}[data-state='pending']")
    assert has_element?(view, "#my-settings-resend-verification-refresh-pending-example-com")

    verified_at = ~U[2026-07-03 12:00:00Z]
    mark_email_verified!(member.person_id, "refresh.pending@example.com", verified_at)

    broadcast_email_verified!(other_member.person_id, "other.refresh.settings@example.com")

    assert has_element?(view, "#{pending_row}[data-state='pending']")
    assert has_element?(view, "#my-settings-resend-verification-refresh-pending-example-com")

    broadcast_email_verified!(member.person_id, "refresh.pending@example.com",
      verified_at: verified_at
    )

    assert has_element?(view, "#{pending_row}[data-state='verified']")
    assert has_element?(view, "#{pending_row} .my-settings-verified-badge", "Verified")
    refute has_element?(view, "#my-settings-resend-verification-refresh-pending-example-com")
    assert has_element?(view, "#my-settings-make-primary-refresh-pending-example-com")
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

  defp create_commanded_active_member(club, attrs) do
    person_id = Keyword.get_lazy(attrs, :person_id, fn -> Memba.ID.generate(:person) end)
    email = Keyword.fetch!(attrs, :email)

    assert :ok =
             MembershipContext.create_person(
               %{person_id: person_id, name: Keyword.fetch!(attrs, :name), email: email},
               consistency: :strong
             )

    Repo.insert!(%Membership{
      membership_id: Memba.ID.generate(:membership),
      club_id: club.club_id,
      person_id: person_id,
      active: true
    })

    MembershipContext.get_person(person_id)
  end

  defp add_pending_email_address!(person_id, email) do
    assert :ok =
             MembershipContext.add_person_email_address(
               %{person_id: person_id, email: email},
               consistency: :strong
             )

    :ok
  end

  defp add_verified_email_address!(person_id, email) do
    add_pending_email_address!(person_id, email)

    assert :ok =
             MembershipContext.verify_person_email_address(
               %{person_id: person_id, email: email},
               consistency: :strong
             )

    :ok
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

  defp broadcast_email_verified!(person_id, email, opts \\ []) do
    normalized_email = String.downcase(email)
    verified_at = Keyword.get(opts, :verified_at, ~U[2026-07-03 12:00:00Z])

    Phoenix.PubSub.broadcast!(
      Memba.PubSub,
      ReadModelChanges.topic(),
      {:read_model_changed,
       %{
         projector: Memba.Membership.Projectors.Person,
         source_event: %Memba.Membership.Events.PersonEmailAddressVerified{
           person_id: person_id,
           email: email,
           normalized_email: normalized_email,
           verified_at: verified_at
         },
         metadata: %{},
         changes: %{person_id: person_id}
       }}
    )
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
