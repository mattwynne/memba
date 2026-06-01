defmodule MembaWeb.MemberMessageLive.ShowTest do
  use MembaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Membership
  alias Memba.Membership.Projections.Person
  alias Memba.Messaging.Projections.MemberReceipt
  alias Memba.Messaging.Projections.Message
  alias Memba.Messaging.Projections.OperatorDeliverability
  alias Memba.Repo
  alias MembaWeb.UserAuth

  test "renders a member message detail LiveView shell in the club site layout", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, MembaWeb.MemberMessageLive.Show)

    assert has_element?(view, "#club-site-layout[data-surface='club-site']")
    assert has_element?(view, "#member-message-detail[data-live-view='member-message-detail']")
  end

  test "routed GET keeps the member message URL shape and passes club_id to the LiveView", %{
    conn: conn
  } do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Trip planning night"
      )

    {:ok, view, _html} =
      conn
      |> init_test_session(%{UserAuth.identity_session_key() => "alice@example.com"})
      |> live(~p"/messages/#{message.message_id}?#{[club_id: alice.club_id]}")

    assert has_element?(
             view,
             "#member-message-detail[data-club-id='#{alice.club_id}'][data-message-id='#{message.message_id}']"
           )

    assert has_element?(view, "a#back-to-club-home-link[href='/?club_id=#{alice.club_id}']")
  end

  test "routed message detail renders the Who got this summary and polished group headers", %{
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

    carol =
      create_active_member(
        email: "carol@example.com",
        name: "Carol Clark",
        club_name: "Alpine Club",
        club_id: alice.club_id
      )

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Trip planning night",
        body: "Bring your maps."
      )

    create_member_receipt(
      message_id: message.message_id,
      recipient_id: alice.person_id,
      recipient_name: "Alice Adams",
      receipt_status: "sent"
    )

    create_member_receipt(
      message_id: message.message_id,
      recipient_id: bob.person_id,
      recipient_name: "Bob Builder",
      receipt_status: "opened"
    )

    create_member_receipt(
      message_id: message.message_id,
      recipient_id: carol.person_id,
      recipient_name: "Carol Clark",
      receipt_status: "delivered"
    )

    {:ok, view, _html} =
      conn
      |> init_test_session(%{UserAuth.identity_session_key() => "alice@example.com"})
      |> live(~p"/messages/#{message.message_id}?#{[club_id: alice.club_id]}")

    assert has_element?(view, "#member-receipt-summary", "Who got this")
    assert has_element?(view, "#member-receipt-summary-bar")

    assert has_element?(
             view,
             "[data-testid='member-receipt-summary-status'][data-receipt-status='opened'][data-receipt-count='1'][data-receipt-percentage='33']",
             "read it"
           )

    assert has_element?(
             view,
             "[data-testid='member-receipt-summary-status'][data-receipt-status='delivered'][data-receipt-count='1'][data-receipt-percentage='33']",
             "arrived, not opened yet"
           )

    assert has_element?(
             view,
             "[data-testid='member-receipt-summary-status'][data-receipt-status='sent'][data-receipt-count='1'][data-receipt-percentage='33']",
             "on its way"
           )

    assert has_element?(
             view,
             "[data-testid='member-receipt-summary-status'][data-receipt-status='delivery problem'][data-receipt-count='0'][data-receipt-percentage='0']",
             "we couldn't reach them"
           )

    assert has_element?(
             view,
             "[data-testid='member-receipt-group'][data-receipt-status='opened']",
             "Opened"
           )

    assert has_element?(
             view,
             "[data-testid='member-receipt-group'][data-receipt-status='delivered']",
             "33%"
           )

    assert has_element?(
             view,
             "[data-testid='member-receipt-group'][data-receipt-status='sent']",
             "Sending"
           )

    refute has_element?(
             view,
             "[data-testid='member-receipt-group'][data-receipt-status='delivery problem']"
           )
  end

  test "receipt groups are collapsed by default and toggle recipient rows", %{conn: conn} do
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
        name: "Carol Clark",
        club_name: "Alpine Club",
        club_id: alice.club_id
      )

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Trip planning night"
      )

    create_member_receipt(
      message_id: message.message_id,
      recipient_id: bob.person_id,
      recipient_name: "Bob Builder",
      receipt_status: "opened"
    )

    create_member_receipt(
      message_id: message.message_id,
      recipient_id: carol.person_id,
      recipient_name: "Carol Clark",
      receipt_status: "delivered"
    )

    {:ok, view, _html} =
      conn
      |> init_test_session(%{UserAuth.identity_session_key() => "alice@example.com"})
      |> live(~p"/messages/#{message.message_id}?#{[club_id: alice.club_id]}")

    opened_toggle = "#member-receipt-group-toggle-opened"
    opened_rows = "#member-receipts-opened"

    opened_recipient =
      "#{opened_rows} [data-testid='member-receipt'][data-recipient-name='Bob Builder']"

    assert has_element?(view, "#{opened_toggle}[aria-expanded='false']")
    assert has_element?(view, "#member-receipt-group-toggle-delivered[aria-expanded='false']")
    refute has_element?(view, opened_rows)
    refute has_element?(view, opened_recipient)

    view
    |> element(opened_toggle)
    |> render_click()

    assert has_element?(view, "#{opened_toggle}[aria-expanded='true']")
    assert has_element?(view, "#member-receipt-group-toggle-delivered[aria-expanded='false']")
    assert has_element?(view, opened_rows)
    assert has_element?(view, opened_recipient, "Bob Builder")

    view
    |> element(opened_toggle)
    |> render_click()

    assert has_element?(view, "#{opened_toggle}[aria-expanded='false']")
    refute has_element?(view, opened_rows)
    refute has_element?(view, opened_recipient)
  end

  test "zero-count statuses render in the summary only and not as empty groups", %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Trip planning night"
      )

    create_member_receipt(
      message_id: message.message_id,
      recipient_id: alice.person_id,
      recipient_name: "Alice Adams",
      receipt_status: "opened"
    )

    {:ok, view, _html} =
      conn
      |> init_test_session(%{UserAuth.identity_session_key() => "alice@example.com"})
      |> live(~p"/messages/#{message.message_id}?#{[club_id: alice.club_id]}")

    assert has_element?(
             view,
             "[data-testid='member-receipt-summary-status']" <>
               "[data-receipt-status='opened']" <>
               "[data-receipt-count='1']" <>
               "[data-receipt-percentage='100']",
             "Opened"
           )

    for {status, label} <- [
          {"delivered", "Delivered"},
          {"sent", "Sending"},
          {"delivery problem", "Delivery problem"}
        ] do
      assert has_element?(
               view,
               "[data-testid='member-receipt-summary-status']" <>
                 "[data-receipt-status='#{status}']" <>
                 "[data-receipt-count='0']" <>
                 "[data-receipt-percentage='0']",
               label
             )

      status_slug = String.replace(status, " ", "-")

      refute has_element?(
               view,
               "[data-testid='member-receipt-group'][data-receipt-status='#{status}']"
             )

      refute has_element?(view, "#member-receipt-group-toggle-#{status_slug}")
    end

    assert has_element?(
             view,
             "[data-testid='member-receipt-group'][data-receipt-status='opened'] " <>
               "#member-receipt-group-toggle-opened[aria-expanded='false']",
             "100%"
           )
  end

  test "expanded recipient rows preserve stable browser-test attributes", %{conn: conn} do
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
        sender_id: alice.person_id,
        subject: "Trip planning night"
      )

    create_member_receipt(
      message_id: message.message_id,
      recipient_id: bob.person_id,
      recipient_name: "Bob Builder",
      receipt_status: "delivered"
    )

    {:ok, view, _html} =
      conn
      |> init_test_session(%{UserAuth.identity_session_key() => "alice@example.com"})
      |> live(~p"/messages/#{message.message_id}?#{[club_id: alice.club_id]}")

    view
    |> element("#member-receipt-group-toggle-delivered")
    |> render_click()

    assert has_element?(
             view,
             "#member-receipts-delivered " <>
               "#member-receipt-#{bob.person_id}" <>
               "[data-testid='member-receipt']" <>
               "[data-recipient-id='#{bob.person_id}']" <>
               "[data-recipient-name='Bob Builder']" <>
               "[data-receipt-status='delivered']",
             "Bob Builder"
           )
  end

  test "expanded member receipt rows do not expose operator-only delivery fields", %{conn: conn} do
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
        sender_id: alice.person_id,
        subject: "Provider details stay private"
      )

    delivery_id = Ecto.UUID.generate()
    provider_reason = "Postmark webhook reported SpamComplaint from mx.example.invalid"

    create_member_receipt(
      delivery_id: delivery_id,
      message_id: message.message_id,
      recipient_id: bob.person_id,
      recipient_name: "Bob Builder",
      receipt_status: "delivery problem"
    )

    create_operator_deliverability(
      delivery_id: delivery_id,
      message_id: message.message_id,
      recipient_id: bob.person_id,
      recipient_name: "Bob Builder",
      recipient_address: "bob-private@example.invalid",
      channel: "postmark-email",
      status: "spam complaint",
      reason: provider_reason
    )

    {:ok, view, _html} =
      conn
      |> init_test_session(%{UserAuth.identity_session_key() => "alice@example.com"})
      |> live(~p"/messages/#{message.message_id}?#{[club_id: alice.club_id]}")

    html =
      view
      |> element("#member-receipt-group-toggle-delivery-problem")
      |> render_click()

    assert has_element?(
             view,
             "#member-receipts-delivery-problem " <>
               "[data-testid='member-receipt']" <>
               "[data-recipient-name='Bob Builder']" <>
               "[data-receipt-status='delivery problem']",
             "Delivery problem"
           )

    refute html =~ delivery_id
    refute html =~ "bob-private@example.invalid"
    refute html =~ "postmark-email"
    refute html =~ "spam complaint"
    refute html =~ provider_reason
    refute html =~ "Postmark webhook"
    refute html =~ "Provider reason"
    refute html =~ "Delivery records"
    refute html =~ ~s(href="/admin/)
  end

  defp create_active_member(attrs) do
    club_id = Keyword.get_lazy(attrs, :club_id, &Ecto.UUID.generate/0)
    person_id = Ecto.UUID.generate()
    club_name = Keyword.fetch!(attrs, :club_name)

    club =
      Repo.get(Club, club_id) ||
        Repo.insert!(%Club{
          club_id: club_id,
          name: club_name
        })

    Repo.insert!(%Person{
      person_id: person_id,
      name: Keyword.get(attrs, :name, "Test Member"),
      email: Keyword.fetch!(attrs, :email)
    })

    Repo.insert!(%Membership{
      membership_id: Ecto.UUID.generate(),
      club_id: club_id,
      person_id: person_id,
      active: true
    })

    club
    |> Map.from_struct()
    |> Map.put(:person_id, person_id)
  end

  defp create_message(attrs) do
    Repo.insert!(%Message{
      message_id: Ecto.UUID.generate(),
      club_id: Keyword.fetch!(attrs, :club_id),
      sender_id: Keyword.fetch!(attrs, :sender_id),
      subject: Keyword.fetch!(attrs, :subject),
      body: Keyword.get(attrs, :body, "Message body")
    })
  end

  defp create_member_receipt(attrs) do
    Repo.insert!(%MemberReceipt{
      delivery_id: Keyword.get_lazy(attrs, :delivery_id, &Ecto.UUID.generate/0),
      message_id: Keyword.fetch!(attrs, :message_id),
      recipient_id: Keyword.fetch!(attrs, :recipient_id),
      recipient_name: Keyword.fetch!(attrs, :recipient_name),
      receipt_status: Keyword.fetch!(attrs, :receipt_status)
    })
  end

  defp create_operator_deliverability(attrs) do
    Repo.insert!(%OperatorDeliverability{
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
end
