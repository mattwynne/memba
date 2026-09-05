defmodule MembaWeb.MemberMessageDeliveryLive.ShowTest do
  use MembaWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Membership
  alias Memba.Messaging.Projections.MemberEmailDelivery
  alias Memba.Messaging.Projections.MembaStaffEmailDelivery
  alias Memba.Repo
  alias MembaWeb.ClubSite
  alias MembaWeb.IdentityAuth

  test "routed delivery page loads the selected club message and receipt model", %{conn: conn} do
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
      status: "bounced",
      reason: "Address does not exist"
    )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/messages/#{message.message_id}/delivery")

    assert has_element?(
             view,
             "#member-message-delivery-detail" <>
               "[data-club-id='#{alice.club_id}']" <>
               "[data-message-id='#{message.message_id}']" <>
               "[data-receipt-count='2']"
           )

    assert has_element?(
             view,
             "#member-delivery-message-subject",
             "Delivery — “Trip planning night”"
           )

    assert has_element?(view, "#member-delivery-message-meta", "Sent by Alice Adams")

    assert has_element?(
             view,
             "#member-delivery-message-sent-at[datetime='#{DateTime.to_iso8601(message.inserted_at)}']",
             format_message_time(message.inserted_at)
           )

    assert has_element?(view, "#member-delivery-message-meta", "to 2 members")

    assert has_element?(view, "#member-delivery-summary.delivery-summary")

    assert has_element?(
             view,
             "#member-delivery-summary-bar.delivery-bar " <>
               "[data-testid='member-delivery-summary-bar-segment']" <>
               "[data-receipt-status='delivered']" <>
               "[data-receipt-count='1']" <>
               "[data-receipt-percentage='50']" <>
               "[style='width: 50%;']"
           )

    assert has_element?(
             view,
             "#member-delivery-summary-bar.delivery-bar " <>
               "[data-testid='member-delivery-summary-bar-segment']" <>
               "[data-receipt-status='sent']" <>
               "[data-receipt-count='0']" <>
               "[data-receipt-percentage='0']" <>
               "[style='width: 0%;']"
           )

    assert has_element?(
             view,
             "#member-delivery-summary-bar.delivery-bar " <>
               "[data-testid='member-delivery-summary-bar-segment']" <>
               "[data-receipt-status='delivery problem']" <>
               "[data-receipt-count='1']" <>
               "[data-receipt-percentage='50']" <>
               "[style='width: 50%;']"
           )

    assert has_element?(
             view,
             "#member-delivery-summary-legend.delivery-legend " <>
               "[data-testid='member-delivery-summary-status']" <>
               "[data-receipt-status='delivered']" <>
               "[data-receipt-count='1']" <>
               "[data-receipt-percentage='50']",
             "Delivered"
           )

    assert has_element?(
             view,
             "#member-delivery-summary-legend.delivery-legend " <>
               "[data-testid='member-delivery-summary-status']" <>
               "[data-receipt-status='sent']" <>
               "[data-receipt-count='0']" <>
               "[data-receipt-percentage='0']",
             "Sending"
           )

    assert has_element?(
             view,
             "#member-delivery-summary-legend.delivery-legend " <>
               "[data-testid='member-delivery-summary-status']" <>
               "[data-receipt-status='delivery problem']" <>
               "[data-receipt-count='1']" <>
               "[data-receipt-percentage='50']",
             "Didn't go through"
           )

    assert has_element?(
             view,
             "#member-delivery-group-delivery-problem.delivery-group[open]" <>
               "[data-receipt-status='delivery problem']" <>
               "[data-receipt-count='1']",
             "Didn't go through"
           )

    assert has_element?(
             view,
             "#member-delivery-group-delivered.delivery-group" <>
               "[data-receipt-status='delivered']" <>
               "[data-receipt-count='1']",
             "Delivered"
           )

    refute has_element?(view, "#member-delivery-group-delivered[open]")

    assert has_element?(
             view,
             "[data-testid='member-delivery-receipt']" <>
               "[data-recipient-id='#{bob.person_id}']" <>
               "[data-recipient-name='Bob Builder']" <>
               "[data-receipt-status='delivered']",
             "Bob Builder"
           )

    assert has_element?(
             view,
             "[data-testid='member-delivery-receipt']" <>
               "[data-recipient-id='#{carol.person_id}']" <>
               "[data-recipient-name='Carol Clark']" <>
               "[data-receipt-status='delivery problem']",
             "Carol Clark"
           )

    assert has_element?(
             view,
             "[data-testid='member-delivery-receipt']" <>
               "[data-recipient-id='#{carol.person_id}']" <>
               " .recipient__reason",
             "Address does not exist"
           )
  end

  test "routed delivery page rejects messages outside the selected active club", %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    other_club = insert_membership_club!(name: "Paddling Club")

    message =
      create_message(
        club_id: other_club.club_id,
        sender_id: alice.person_id,
        subject: "Wrong club"
      )

    conn =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> get(~p"/messages/#{message.message_id}/delivery")

    assert html_response(conn, 404) =~ "Not Found"
  end

  test "routed delivery page forbids signed-in users outside the requested club", %{conn: conn} do
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

    _pat =
      create_active_member(
        email: "pat@example.com",
        name: "Pat Paddler",
        club_name: "Paddling Club"
      )

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Private alpine delivery",
        body: "This delivery detail belongs to Alpine Club."
      )

    create_member_email_delivery(
      message_id: message.message_id,
      recipient_id: bob.person_id,
      recipient_name: "Bob Builder",
      status: "delivery problem",
      reason: "Mailbox does not exist"
    )

    conn =
      conn
      |> signed_in_club_host("pat@example.com", alice)
      |> get(~p"/messages/#{message.message_id}/delivery")

    assert response(conn, 403) == "Forbidden"
    refute conn.resp_body =~ "Private alpine delivery"
    refute conn.resp_body =~ "This delivery detail belongs to Alpine Club."
    refute conn.resp_body =~ "Bob Builder"
    refute conn.resp_body =~ "Mailbox does not exist"
  end

  test "routed delivery page redirects unauthenticated visitors and preserves return path", %{
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
        subject: "Members only delivery"
      )

    return_path = ~p"/messages/#{message.message_id}/delivery"

    conn =
      conn
      |> club_host(alice)
      |> get(return_path)

    %{host: club_host} = URI.parse(ClubSite.url(alice))

    assert redirected_to(conn) == ~p"/auth"

    assert get_session(conn, IdentityAuth.return_to_session_key()) ==
             "http://#{club_host}#{return_path}"
  end

  test "routed delivery page links back to the containing conversation", %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    conversation =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Trip planning night"
      )

    reply =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        conversation_id: conversation.message_id,
        reply_to_message_id: conversation.message_id,
        subject: "Re: Trip planning night"
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/messages/#{reply.message_id}/delivery")

    assert has_element?(
             view,
             "a#member-delivery-back-to-conversation-link[href='/messages/#{conversation.message_id}']",
             "Back to conversation"
           )

    refute has_element?(
             view,
             "a#member-delivery-back-to-conversation-link[href='/messages/#{reply.message_id}']"
           )
  end

  test "routed delivery page shows an explicit zero-recipient state with safe bar widths", %{
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
        subject: "Draft delivery model"
      )

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/messages/#{message.message_id}/delivery")

    assert has_element?(
             view,
             "#member-message-delivery-detail" <>
               "[data-message-id='#{message.message_id}']" <>
               "[data-receipt-count='0']"
           )

    assert has_element?(
             view,
             "#member-delivery-summary-count[data-receipt-count='0']",
             "0 members"
           )

    for status <- ["delivered", "sent", "delivery problem"] do
      assert has_element?(
               view,
               "#member-delivery-summary-bar.delivery-bar " <>
                 "[data-testid='member-delivery-summary-bar-segment']" <>
                 "[data-receipt-status='#{status}']" <>
                 "[data-receipt-count='0']" <>
                 "[data-receipt-percentage='0']" <>
                 "[style='width: 0%;']"
             )
    end

    assert has_element?(
             view,
             "#member-delivery-receipts-empty",
             "Memba has not prepared the delivery list for this message yet."
           )

    refute has_element?(
             view,
             "#member-delivery-receipt-groups [data-testid='member-delivery-group']"
           )
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
    club_name = Keyword.fetch!(attrs, :club_name)

    club =
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
      membership_id: Memba.ID.generate(:membership),
      club_id: club_id,
      person_id: person.person_id,
      active: true
    })

    club
    |> Map.from_struct()
    |> Map.put(:person_id, person.person_id)
  end

  defp create_message(attrs) do
    insert_group_accessible_message!(attrs)
  end

  defp create_member_email_delivery(attrs) do
    delivery_id = Keyword.get_lazy(attrs, :delivery_id, fn -> Memba.ID.generate(:delivery) end)

    delivery =
      Repo.insert!(%MemberEmailDelivery{
        delivery_id: delivery_id,
        message_id: Keyword.fetch!(attrs, :message_id),
        recipient_id: Keyword.fetch!(attrs, :recipient_id),
        recipient_name: Keyword.fetch!(attrs, :recipient_name),
        status: Keyword.fetch!(attrs, :status)
      })

    maybe_create_staff_email_delivery(delivery, attrs)

    delivery
  end

  defp maybe_create_staff_email_delivery(%MemberEmailDelivery{} = delivery, attrs) do
    reason = Keyword.get(attrs, :reason)

    if is_binary(reason) and reason != "" do
      Repo.insert!(%MembaStaffEmailDelivery{
        delivery_id: delivery.delivery_id,
        message_id: delivery.message_id,
        recipient_id: delivery.recipient_id,
        recipient_name: delivery.recipient_name,
        recipient_address: Keyword.get(attrs, :recipient_address, "carol@example.com"),
        channel: "email",
        status: Keyword.fetch!(attrs, :status),
        reason: reason
      })
    end
  end

  defp format_message_time(%DateTime{} = inserted_at) do
    Calendar.strftime(inserted_at, "%-d %b, %-I:%M%P")
  end
end
