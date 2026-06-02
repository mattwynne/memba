defmodule MembaWeb.MemberDashboardLiveTest do
  use MembaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Membership
  alias Memba.Messaging.Projections.MemberEmailDelivery
  alias Memba.Messaging.Projections.Message
  alias Memba.Messaging.Projections.MembaStaffEmailDelivery
  alias Memba.Repo
  alias MembaWeb.MemberDashboardPresentation
  alias MembaWeb.IdentityAuth

  test "routed club home renders signed-in active members through the dashboard LiveView", %{
    conn: conn
  } do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    bob =
      create_active_member(
        email: "bob@example.com",
        name: "Bob Builder",
        club_name: "Alpine Club",
        club_id: alice.club_id
      )

    message =
      create_message(club_id: alice.club_id, sender_id: bob.person_id, subject: "Trip night")

    {:ok, view, _html} =
      conn
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> live(~p"/?club_id=#{alice.club_id}")

    assert has_element?(
             view,
             "#member-club-home[data-live-view='member-dashboard'][data-club-id='#{alice.club_id}']"
           )

    assert has_element?(view, "#club-site-current-identity", "Signed in as alice@example.com")
    assert has_element?(view, "#member-message-#{message.message_id}")
    assert has_element?(view, "#club-member-#{alice.person_id}")
    assert has_element?(view, "#club-member-#{bob.person_id}")
  end

  test "dashboard renders polished CTA, message rows, receipt glance, and active-member card",
       %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    bob =
      create_active_member(
        email: "bob@example.com",
        name: "Bob Builder",
        club_name: "Alpine Club",
        club_id: alice.club_id
      )

    sent_at = ~U[2026-05-30 12:00:00.000000Z]

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: bob.person_id,
        subject: "Trip night",
        inserted_at: sent_at
      )

    create_member_email_delivery(
      message_id: message.message_id,
      recipient_id: alice.person_id,
      recipient_name: "Alice Adams",
      status: "opened"
    )

    create_member_email_delivery(
      message_id: message.message_id,
      recipient_id: bob.person_id,
      recipient_name: "Bob Builder",
      status: "sent"
    )

    {:ok, view, _html} =
      conn
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> live(~p"/?club_id=#{alice.club_id}")

    assert has_element?(view, "#member-dashboard-hero", "Hello, Alice.")

    assert has_element?(
             view,
             "#member-dashboard-cta #member-send-message-link[href='/messages/new?club_id=#{alice.club_id}']",
             "Send club message"
           )

    assert has_element?(
             view,
             "#member-message-#{message.message_id} [data-testid='club-message-link'][href='/messages/#{message.message_id}?club_id=#{alice.club_id}']"
           )

    refute has_element?(view, "#member-message-list-empty")

    assert has_element?(
             view,
             "#member-message-#{message.message_id} [data-testid='message-sender-initials']",
             "BB"
           )

    assert has_element?(
             view,
             "#member-message-#{message.message_id} [data-testid='message-sender-name']",
             "Bob Builder"
           )

    assert has_element?(
             view,
             "#member-message-#{message.message_id} [data-testid='message-sent-at']",
             Calendar.strftime(sent_at, "%b %d, %Y")
           )

    assert has_element?(
             view,
             "#member-message-#{message.message_id} [data-testid='message-receipt-glance']",
             "1 of 2 opened"
           )

    assert has_element?(
             view,
             "#member-message-#{message.message_id} [data-testid='message-receipt-segment'][data-receipt-status='opened'][data-receipt-percentage='50']"
           )

    assert has_element?(view, "#active-members-card[data-active-member-count='2']")
    assert has_element?(view, "#active-members-card[data-active-members-state='active-members']")
    refute has_element?(view, "#active-members-empty-state", "You're the first one here")

    assert has_element?(
             view,
             "#active-members-avatar-stack #club-member-#{alice.person_id}[data-testid='club-member-row'][data-member-name='Alice Adams']",
             "AA"
           )
  end

  test "dashboard receipt glance uses member vocabulary and does not leak Memba-staff-only fields",
       %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    bob =
      create_active_member(
        email: "bob@example.com",
        name: "Bob Builder",
        club_name: "Alpine Club",
        club_id: alice.club_id
      )

    carol =
      create_active_member(
        email: "carol@example.com",
        name: "Carol Canoe",
        club_name: "Alpine Club",
        club_id: alice.club_id
      )

    dana =
      create_active_member(
        email: "dana@example.com",
        name: "Dana Downhill",
        club_name: "Alpine Club",
        club_id: alice.club_id
      )

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: bob.person_id,
        subject: "Weekend conditions"
      )

    create_member_email_delivery(
      message_id: message.message_id,
      recipient_id: alice.person_id,
      recipient_name: "Alice Adams",
      status: "opened"
    )

    create_member_email_delivery(
      message_id: message.message_id,
      recipient_id: bob.person_id,
      recipient_name: "Bob Builder",
      status: "delivered"
    )

    create_member_email_delivery(
      message_id: message.message_id,
      recipient_id: carol.person_id,
      recipient_name: "Carol Canoe",
      status: "sent"
    )

    dana_delivery_id =
      create_member_email_delivery(
        message_id: message.message_id,
        recipient_id: dana.person_id,
        recipient_name: "Dana Downhill",
        status: "delivery problem"
      ).delivery_id

    create_memba_staff_email_delivery(
      delivery_id: dana_delivery_id,
      message_id: message.message_id,
      recipient_id: dana.person_id,
      recipient_name: "Dana Downhill",
      recipient_address: "dana.operator@example.net",
      channel: "postmark-webhook",
      status: "bounced",
      reason: "SMTP 550 Mailbox full from ProviderEvent::Bounce"
    )

    {:ok, view, _html} =
      conn
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> live(~p"/?club_id=#{alice.club_id}")

    message_selector = "#member-message-#{message.message_id}"

    assert has_element?(
             view,
             "#{message_selector} [data-testid='message-receipt-glance']",
             "1 of 4 opened"
           )

    assert has_element?(
             view,
             "#{message_selector} [data-testid='message-receipt-segment'][data-receipt-status='opened'][data-receipt-label='Opened'][data-receipt-count='1']"
           )

    assert has_element?(
             view,
             "#{message_selector} [data-testid='message-receipt-segment'][data-receipt-status='delivered'][data-receipt-label='Delivered'][data-receipt-count='1']"
           )

    assert has_element?(
             view,
             "#{message_selector} [data-testid='message-receipt-segment'][data-receipt-status='sent'][data-receipt-label='Sending'][data-receipt-count='1']"
           )

    assert has_element?(
             view,
             "#{message_selector} [data-testid='message-receipt-segment'][data-receipt-status='delivery problem'][data-receipt-label='Delivery problem'][data-receipt-count='1']"
           )

    html = render(view)

    refute html =~ dana_delivery_id
    refute html =~ "dana.operator@example.net"
    refute html =~ "postmark-webhook"
    refute html =~ "bounced"
    refute html =~ "SMTP 550 Mailbox full"
    refute html =~ "ProviderEvent::Bounce"
  end

  test "dashboard omits timestamp label when a message row has no inserted_at timestamp" do
    club_id = Ecto.UUID.generate()
    sender_id = Ecto.UUID.generate()
    message_id = Ecto.UUID.generate()

    message = %Message{
      message_id: message_id,
      club_id: club_id,
      sender_id: sender_id,
      subject: "Projection without timestamp",
      body: "Body",
      inserted_at: nil
    }

    assert [message_row] =
             MemberDashboardPresentation.present_message_rows([message], %{
               sender_id => "Bob Builder"
             })

    html =
      dashboard_html(%{
        selected_club: %{club_id: club_id, name: "Alpine Club"},
        message_rows: [message_row]
      })

    assert html_has_selector?(
             html,
             "#member-message-#{message_id}[data-testid='club-message-row']"
           )

    refute html_has_selector?(
             html,
             "#member-message-#{message_id} [data-testid='message-sent-at']"
           )
  end

  test "dashboard preserves browser acceptance selectors for messages and members", %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    bob =
      create_active_member(
        email: "bob@example.com",
        name: "Bob Builder",
        club_name: "Alpine Club",
        club_id: alice.club_id
      )

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: bob.person_id,
        subject: "Trip planning night"
      )

    {:ok, view, _html} =
      conn
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> live(~p"/?club_id=#{alice.club_id}")

    assert has_element?(
             view,
             "#member-club-home[data-club-id='#{alice.club_id}']"
           )

    assert has_element?(
             view,
             "#member-send-message-link[href='/messages/new?club_id=#{alice.club_id}']"
           )

    assert has_element?(
             view,
             "[data-testid='club-message-row'][data-message-id='#{message.message_id}'][data-message-subject='Trip planning night']"
           )

    assert has_element?(
             view,
             "[data-testid='club-message-row'][data-message-id='#{message.message_id}'] " <>
               "[data-testid='club-message-link'][href='/messages/#{message.message_id}?club_id=#{alice.club_id}']"
           )

    assert has_element?(
             view,
             "[data-testid='club-member-row'][data-member-id='#{alice.person_id}'][data-member-name='Alice Adams']"
           )

    assert has_element?(
             view,
             "[data-testid='club-member-row'][data-member-id='#{bob.person_id}'][data-member-name='Bob Builder']"
           )
  end

  test "dashboard reaches compose through links instead of inline compose controls", %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    {:ok, view, _html} =
      conn
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> live(~p"/?club_id=#{alice.club_id}")

    assert has_element?(
             view,
             "#member-dashboard-cta #member-send-message-link[href='/messages/new?club_id=#{alice.club_id}']",
             "Send club message"
           )

    refute has_element?(view, "form#member-message-form")
    refute has_element?(view, "form#member-message-compose-form")
    refute has_element?(view, "[phx-submit='send_message']")
    refute has_element?(view, "select#member-message-sender-select")
    refute has_element?(view, "input#member-message-subject-input")
    refute has_element?(view, "textarea#member-message-body-input")
    refute has_element?(view, "button#member-message-send-button")
  end

  test "dashboard renders a designed empty message state with a compose action", %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    {:ok, view, _html} =
      conn
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> live(~p"/?club_id=#{alice.club_id}")

    assert has_element?(view, "#member-message-list-empty", "No messages yet")

    assert has_element?(
             view,
             "#member-message-empty-send-link[href='/messages/new?club_id=#{alice.club_id}']",
             "Send the first one"
           )
  end

  test "dashboard renders first-member active-member copy only when current member is alone",
       %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    {:ok, view, _html} =
      conn
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> live(~p"/?club_id=#{alice.club_id}")

    assert has_element?(
             view,
             "#active-members-card[data-active-member-count='1'][data-active-members-state='first-member']"
           )

    assert has_element?(view, "#active-members-empty-state", "You're the first one here")

    assert has_element?(
             view,
             "#active-members-empty-state",
             "As members join and renew, you'll see them listed here."
           )

    assert has_element?(
             view,
             "#active-members-empty-avatar #club-member-#{alice.person_id}[data-testid='club-member-row'][data-member-name='Alice Adams']",
             "AA"
           )

    refute has_element?(
             view,
             "#active-members-card-copy",
             "Everyone with a current membership. They'll all receive your messages."
           )
  end

  test "logged-out club home still renders the public club page", %{conn: conn} do
    club = create_club(name: "Alpine Club")

    conn = get(conn, ~p"/?club_id=#{club.club_id}")
    response = html_response(conn, 200)
    html = LazyHTML.from_fragment(response)

    assert html
           |> LazyHTML.query("#public-club-page-page[data-club-id='#{club.club_id}']")
           |> Enum.any?()

    refute html
           |> LazyHTML.query("#member-club-home[data-live-view='member-dashboard']")
           |> Enum.any?()
  end

  test "signed-in identities outside the selected club are still forbidden", %{conn: conn} do
    alice = create_active_member(email: "alice@example.com", club_name: "Alpine Club")

    conn =
      conn
      |> init_test_session(%{IdentityAuth.identity_session_key() => "pat@example.com"})
      |> get(~p"/?club_id=#{alice.club_id}")

    assert response(conn, 403) == "Forbidden"
  end

  test "signed-in inactive members of the selected club are still forbidden", %{conn: conn} do
    inactive_alice =
      create_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club",
        active: false
      )

    conn =
      conn
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> get(~p"/?club_id=#{inactive_alice.club_id}")

    assert response(conn, 403) == "Forbidden"
  end

  defp create_club(attrs) do
    insert_membership_club!(attrs)
  end

  defp create_active_member(attrs) do
    attrs
    |> Keyword.put(:active, true)
    |> create_member()
  end

  defp create_member(attrs) do
    club_id = Keyword.get_lazy(attrs, :club_id, &Ecto.UUID.generate/0)
    person_id = Ecto.UUID.generate()
    club_name = Keyword.get(attrs, :club_name, "Kootenay Mountaineering Club")

    Repo.get(Club, club_id) ||
      insert_membership_club!(
        club_id: club_id,
        name: club_name
      )

    person =
      insert_membership_person!(
        person_id: person_id,
        name: Keyword.get(attrs, :name, "Test Member"),
        email: Keyword.fetch!(attrs, :email)
      )

    Repo.insert!(%Membership{
      membership_id: Ecto.UUID.generate(),
      club_id: club_id,
      person_id: person.person_id,
      active: Keyword.get(attrs, :active, true)
    })

    %{
      club_id: club_id,
      person_id: person.person_id
    }
  end

  defp create_message(attrs) do
    inserted_at = Keyword.get_lazy(attrs, :inserted_at, &DateTime.utc_now/0)

    Repo.insert!(%Message{
      message_id: Ecto.UUID.generate(),
      club_id: Keyword.fetch!(attrs, :club_id),
      sender_id: Keyword.fetch!(attrs, :sender_id),
      subject: Keyword.fetch!(attrs, :subject),
      body: Keyword.get(attrs, :body, "Message body"),
      inserted_at: inserted_at,
      updated_at: inserted_at
    })
  end

  defp create_member_email_delivery(attrs) do
    Repo.insert!(%MemberEmailDelivery{
      delivery_id: Keyword.get_lazy(attrs, :delivery_id, &Ecto.UUID.generate/0),
      message_id: Keyword.fetch!(attrs, :message_id),
      recipient_id: Keyword.fetch!(attrs, :recipient_id),
      recipient_name: Keyword.fetch!(attrs, :recipient_name),
      status: Keyword.fetch!(attrs, :status)
    })
  end

  defp create_memba_staff_email_delivery(attrs) do
    Repo.insert!(%MembaStaffEmailDelivery{
      delivery_id: Keyword.fetch!(attrs, :delivery_id),
      message_id: Keyword.fetch!(attrs, :message_id),
      recipient_id: Keyword.fetch!(attrs, :recipient_id),
      recipient_name: Keyword.fetch!(attrs, :recipient_name),
      recipient_address: Keyword.fetch!(attrs, :recipient_address),
      channel: Keyword.fetch!(attrs, :channel),
      status: Keyword.fetch!(attrs, :status),
      reason: Keyword.fetch!(attrs, :reason)
    })
  end

  defp dashboard_html(assigns) do
    %{
      flash: %{},
      current_identity: %{email: "alice@example.com"},
      selected_club: %{club_id: Ecto.UUID.generate(), name: "Alpine Club"},
      current_member: %{name: "Alice Adams"},
      members: [],
      active_member_count: 0,
      message_rows: []
    }
    |> Map.merge(assigns)
    |> MembaWeb.PageHTML.club()
    |> rendered_to_string()
  end

  defp html_has_selector?(html, selector) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(selector)
    |> Enum.any?()
  end
end
