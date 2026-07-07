defmodule MembaWeb.MemberMessageLive.ShowTest do
  use MembaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Membership
  alias Memba.Messaging.Projections.MemberEmailDelivery
  alias Memba.Messaging.Projections.Message
  alias Memba.Messaging.Projections.MembaStaffEmailDelivery
  alias Memba.Repo
  alias MembaWeb.ClubSite
  alias MembaWeb.IdentityAuth
  alias MembaWeb.MemberMessageDetail

  test "isolated message detail without route params fails instead of rendering stale shell", %{
    conn: conn
  } do
    assert_raise RuntimeError, ~r/requires a loaded message before rendering/, fn ->
      live_isolated(conn, MembaWeb.MemberMessageLive.Show)
    end
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
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/messages/#{message.message_id}")

    assert has_element?(
             view,
             "#member-message-detail[data-club-id='#{alice.club_id}'][data-message-id='#{message.message_id}']"
           )

    assert has_element?(
             view,
             "#club-site-identity-menu-button .app-bar__who",
             "Alice Adams"
           )

    assert has_element?(
             view,
             "#club-site-identity-menu-button .app-bar__avatar",
             "AA"
           )

    assert has_element?(view, "a#back-to-club-home-link[href='/conversations']")
  end

  test "club subdomain routed mount keeps the host-selected message after LiveView connects", %{
    conn: conn
  } do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Kootenay Mountaineering Club",
        slug: "kmc"
      )

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Trip planning night"
      )

    {:ok, view, _html} =
      conn
      |> Map.put(:host, "kmc.lvh.me")
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> live(~p"/messages/#{message.message_id}")

    assert has_element?(
             view,
             "#member-message-detail[data-club-id='#{alice.club_id}'][data-message-id='#{message.message_id}']"
           )

    assert has_element?(view, "a#back-to-club-home-link[href='/conversations']")
    refute has_element?(view, "a#back-to-club-home-link[href*='club_id=']")
  end

  test "routed message detail places the follow control beside the subject in the detail head", %{
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
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/messages/#{message.message_id}")

    assert has_element?(
             view,
             "#member-message-heading-row.detail-head > .detail-head__main " <>
               "h1#member-message-subject",
             "Trip planning night"
           )

    assert has_element?(
             view,
             "#member-message-heading-row.detail-head > " <>
               "#member-conversation-follow-control.follow-toggle" <>
               "[data-following='false'][data-can-follow='true']",
             "Not following"
           )

    assert has_element?(view, "#member-conversation-follow-toggle[type='checkbox']")
    refute has_element?(view, "#member-conversation-follow-toggle[checked]")
    refute has_element?(view, "#member-conversation-follow-button")
    refute has_element?(view, "#member-conversation-unfollow-button")
  end

  test "message detail shows the current-member follow explanation instead of a toggle when following is not allowed" do
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
        subject: "Trip planning night",
        body: "Bring your maps."
      )

    selected_club = Memba.Membership.get_club(alice.club_id)

    assert {:ok, detail_assigns} =
             MemberMessageDetail.load(
               %{"club_id" => alice.club_id, "message_id" => message.message_id},
               [selected_club],
               %{email: "guest@example.com"}
             )

    html =
      detail_assigns
      |> render_message_detail()
      |> LazyHTML.from_fragment()

    assert html
           |> LazyHTML.query(
             "#member-message-heading-row.detail-head > " <>
               "#member-conversation-follow-control" <>
               "[data-following='false'][data-can-follow='false']"
           )
           |> Enum.any?()

    assert html
           |> LazyHTML.query("#member-conversation-follow-copy")
           |> LazyHTML.text() =~
             "Only current club members can follow this conversation in Memba."

    refute html
           |> LazyHTML.query("#member-conversation-follow-toggle")
           |> Enum.any?()

    refute html
           |> LazyHTML.query("[phx-change='follow_conversation']")
           |> Enum.any?()

    refute html
           |> LazyHTML.query("#member-conversation-follow-button")
           |> Enum.any?()

    refute html
           |> LazyHTML.query("#member-conversation-unfollow-button")
           |> Enum.any?()
  end

  test "routed message detail renders the conversation and inline reply composer", %{
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
        body: "Bring your maps.",
        inserted_at: ~U[2026-06-03 07:02:00.000000Z]
      )

    first_reply =
      create_message(
        club_id: alice.club_id,
        sender_id: bob.person_id,
        conversation_id: message.message_id,
        reply_to_message_id: message.message_id,
        subject: "Trip planning night",
        body: "I'll bring snacks.",
        inserted_at: ~U[2026-06-03 08:15:00.000000Z]
      )

    second_reply =
      create_message(
        club_id: alice.club_id,
        sender_id: carol.person_id,
        conversation_id: message.message_id,
        reply_to_message_id: message.message_id,
        subject: "Trip planning night",
        body: "I can drive.",
        inserted_at: ~U[2026-06-03 09:30:00.000000Z]
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("bob@example.com", bob)
      |> live(~p"/messages/#{message.message_id}")

    assert has_element?(view, "#member-conversation[data-message-count='3']")

    assert has_element?(
             view,
             "#member-conversation-original " <>
               "#member-conversation-entry-#{message.message_id}" <>
               "[data-conversation-kind='original']" <>
               "[data-sender-id='#{alice.person_id}']",
             "Bring your maps."
           )

    assert has_element?(
             view,
             "#member-conversation-entry-#{message.message_id} " <>
               "[data-testid='member-conversation-entry-time']" <>
               "[datetime='2026-06-03T07:02:00.000000Z']",
             "3 Jun, 7:02am"
           )

    assert has_element?(
             view,
             "#member-conversation-replies " <>
               "#member-conversation-entry-#{first_reply.message_id}" <>
               "[data-conversation-kind='reply']" <>
               "[data-sender-id='#{bob.person_id}']",
             "I'll bring snacks."
           )

    assert has_element?(
             view,
             "#member-conversation-entry-#{first_reply.message_id} " <>
               "[data-testid='member-conversation-entry-time']" <>
               "[datetime='2026-06-03T08:15:00.000000Z']",
             "3 Jun, 8:15am"
           )

    assert has_element?(
             view,
             "#member-conversation-replies " <>
               "#member-conversation-entry-#{second_reply.message_id}" <>
               "[data-conversation-kind='reply']" <>
               "[data-sender-id='#{carol.person_id}']",
             "I can drive."
           )

    assert has_element?(
             view,
             "#member-conversation-entry-#{second_reply.message_id} " <>
               "[data-testid='member-conversation-entry-time']" <>
               "[datetime='2026-06-03T09:30:00.000000Z']",
             "3 Jun, 9:30am"
           )

    html =
      view
      |> render()
      |> LazyHTML.from_fragment()

    conversation_child_ids =
      html
      |> LazyHTML.query("#member-conversation > *")
      |> LazyHTML.attribute("id")

    replies_index =
      Enum.find_index(conversation_child_ids, &(&1 == "member-conversation-replies"))

    composer_index =
      Enum.find_index(conversation_child_ids, &(&1 == "member-message-reply-composer"))

    assert replies_index < composer_index

    assert has_element?(
             view,
             "#member-message-reply-from[data-sender-id='#{bob.person_id}']",
             "Replying as Bob Builder"
           )

    assert has_element?(view, "#member-message-reply-form")
    assert has_element?(view, "#member-message-reply-body-input")
    refute has_element?(view, "#member-message-reply-subject-input")
  end

  test "blank reply body validation keeps the inline composer and does not post", %{conn: conn} do
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
        subject: "Trip planning night",
        body: "Bring your maps."
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("bob@example.com", bob)
      |> live(~p"/messages/#{message.message_id}")

    view
    |> element("#member-message-reply-form")
    |> render_submit(%{"reply" => %{"body" => " \n\t "}})

    assert has_element?(view, "#member-message-detail[data-reply-state='composing']")
    assert has_element?(view, "#member-message-reply-body-error", "Reply body can’t be blank.")
    assert has_element?(view, "#member-message-reply-body-input")
    refute has_element?(view, "#member-message-reply-success")
    refute has_element?(view, "#member-message-reply-error")

    assert Enum.map(
             Memba.Messaging.list_conversation_messages(message.message_id),
             & &1.message_id
           ) == [
             message.message_id
           ]
  end

  test "routed message detail renders the delivery summary and polished group headers", %{
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

    create_member_email_delivery(
      message_id: message.message_id,
      recipient_id: alice.person_id,
      recipient_name: "Alice Adams",
      status: "sent"
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
      recipient_name: "Carol Clark",
      status: "delivered"
    )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/messages/#{message.message_id}")

    assert has_element?(view, "#member-receipt-summary", "Message delivery")
    assert has_element?(view, "#member-receipt-summary-bar")

    assert has_element?(
             view,
             "[data-testid='member-receipt-summary-status'][data-receipt-status='delivered'][data-receipt-count='2'][data-receipt-percentage='67']",
             "Email delivered"
           )

    assert has_element?(
             view,
             "[data-testid='member-receipt-summary-status'][data-receipt-status='sent'][data-receipt-count='1'][data-receipt-percentage='33']",
             "Email still sending"
           )

    assert has_element?(
             view,
             "[data-testid='member-receipt-summary-status'][data-receipt-status='delivery problem'][data-receipt-count='0'][data-receipt-percentage='0']",
             "Email not delivered"
           )

    assert has_element?(
             view,
             "[data-testid='member-receipt-summary-bar-segment'][data-receipt-status='delivered'].bg-sage-600"
           )

    assert has_element?(
             view,
             "[data-testid='member-receipt-summary-bar-segment'][data-receipt-status='sent'].bg-warning"
           )

    assert has_element?(
             view,
             "[data-testid='member-receipt-summary-bar-segment'][data-receipt-status='delivery problem'].bg-error"
           )

    assert has_element?(
             view,
             "[data-testid='member-receipt-group'][data-receipt-status='delivered']",
             "67%"
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

    create_member_email_delivery(
      message_id: message.message_id,
      recipient_id: bob.person_id,
      recipient_name: "Bob Builder",
      status: "delivered"
    )

    create_member_email_delivery(
      message_id: message.message_id,
      recipient_id: carol.person_id,
      recipient_name: "Carol Clark",
      status: "delivered"
    )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/messages/#{message.message_id}")

    delivered_toggle = "#member-receipt-group-toggle-delivered"
    delivered_rows = "#member-receipts-delivered"

    delivered_recipient =
      "#{delivered_rows} [data-testid='member-receipt'][data-recipient-name='Bob Builder']"

    assert has_element?(view, "#{delivered_toggle}.btn.btn-ghost[aria-expanded='false']")
    refute has_element?(view, delivered_rows)
    refute has_element?(view, delivered_recipient)

    view
    |> element(delivered_toggle)
    |> render_click()

    assert has_element?(view, "#{delivered_toggle}[aria-expanded='true']")
    assert has_element?(view, delivered_rows)
    assert has_element?(view, delivered_recipient, "Bob Builder")

    assert has_element?(
             view,
             "#{delivered_rows} [data-testid='receipt-status'][data-receipt-status='delivered'].badge.badge-soft.badge-success",
             "Delivered"
           )

    view
    |> element(delivered_toggle)
    |> render_click()

    assert has_element?(view, "#{delivered_toggle}[aria-expanded='false']")
    refute has_element?(view, delivered_rows)
    refute has_element?(view, delivered_recipient)
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

    create_member_email_delivery(
      message_id: message.message_id,
      recipient_id: alice.person_id,
      recipient_name: "Alice Adams",
      status: "delivered"
    )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/messages/#{message.message_id}")

    assert has_element?(
             view,
             "[data-testid='member-receipt-summary-status']" <>
               "[data-receipt-status='delivered']" <>
               "[data-receipt-count='1']" <>
               "[data-receipt-percentage='100']",
             "Delivered"
           )

    for {status, label} <- [{"sent", "Sending"}, {"delivery problem", "Delivery problem"}] do
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
             "[data-testid='member-receipt-group'][data-receipt-status='delivered'] " <>
               "#member-receipt-group-toggle-delivered[aria-expanded='false']",
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

    create_member_email_delivery(
      message_id: message.message_id,
      recipient_id: bob.person_id,
      recipient_name: "Bob Builder",
      status: "delivered"
    )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/messages/#{message.message_id}")

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

  test "expanded member email delivery rows do not expose Memba-staff-only delivery fields", %{
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
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Provider details stay private"
      )

    delivery_id = Memba.ID.generate(:delivery)
    provider_reason = "Postmark webhook reported SpamComplaint from mx.example.invalid"

    create_member_email_delivery(
      delivery_id: delivery_id,
      message_id: message.message_id,
      recipient_id: bob.person_id,
      recipient_name: "Bob Builder",
      status: "delivery problem"
    )

    create_memba_staff_email_delivery(
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
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/messages/#{message.message_id}")

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

    assert has_element?(
             view,
             "#member-receipts-delivery-problem " <>
               "[data-testid='receipt-status'][data-receipt-status='delivery problem']" <>
               ".badge.badge-soft.badge-error",
             "Delivery problem"
           )

    refute html =~ delivery_id
    refute html =~ "bob-private@example.invalid"
    refute html =~ "postmark-email"
    refute html =~ "spam complaint"
    refute html =~ provider_reason
    refute html =~ "Postmark webhook"
    refute html =~ "Provider reason"
    refute html =~ "Email deliveries"
    refute html =~ ~s(href="/admin/)
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

  defp render_message_detail(detail_assigns) do
    detail_assigns
    |> Map.merge(%{
      current_identity: %{email: "guest@example.com"},
      expanded_receipt_groups: MapSet.new(),
      flash: %{},
      reply_body_error: nil,
      reply_error: nil,
      reply_form: Phoenix.Component.to_form(%{}, as: :reply),
      reply_state: :composing,
      route_params: %{"club_id_source" => "host"}
    })
    |> MembaWeb.PageHTML.message()
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  defp create_active_member(attrs) do
    club_id = Keyword.get_lazy(attrs, :club_id, fn -> Memba.ID.generate(:club) end)
    person_id = Memba.ID.generate(:person)
    club_name = Keyword.fetch!(attrs, :club_name)

    club =
      Repo.get(Club, club_id) ||
        attrs
        |> club_attrs(club_id, club_name)
        |> insert_membership_club!()

    person =
      insert_membership_person!(
        person_id: person_id,
        name: Keyword.get(attrs, :name, "Test Member"),
        email: Keyword.fetch!(attrs, :email)
      )

    Repo.insert!(%Membership{
      membership_id: Memba.ID.generate(:membership),
      club_id: club_id,
      person_id: person.person_id,
      active: true
    })

    club
    |> Map.from_struct()
    |> Map.put(:person_id, person.person_id)
  end

  defp club_attrs(attrs, club_id, club_name) do
    base = [club_id: club_id, name: club_name]

    case Keyword.fetch(attrs, :slug) do
      {:ok, slug} -> Keyword.put(base, :slug, slug)
      :error -> base
    end
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
      body: Keyword.get(attrs, :body, "Message body"),
      inserted_at: Keyword.get(attrs, :inserted_at),
      updated_at: Keyword.get(attrs, :updated_at, Keyword.get(attrs, :inserted_at))
    })
  end

  defp create_member_email_delivery(attrs) do
    Repo.insert!(%MemberEmailDelivery{
      delivery_id: Keyword.get_lazy(attrs, :delivery_id, fn -> Memba.ID.generate(:delivery) end),
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
end
