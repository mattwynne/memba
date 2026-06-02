defmodule MembaWeb.MemberMessageDetailTest do
  use MembaWeb.ConnCase, async: true

  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Membership
  alias Memba.Membership.Projections.Person
  alias Memba.Messaging.Projections.MemberEmailDelivery
  alias Memba.Messaging.Projections.Message
  alias Memba.Messaging.Projections.MembaStaffEmailDelivery
  alias Memba.Repo
  alias MembaWeb.IdentityAuth

  describe "member message route authorization" do
    test "forbids signed-in inactive members and does not leak message details", %{conn: conn} do
      inactive_alice =
        create_member(
          email: "alice@example.com",
          name: "Alice Adams",
          club_name: "Alpine Club",
          active: false
        )

      bob =
        create_member(
          email: "bob@example.com",
          name: "Bob Builder",
          club_name: "Alpine Club",
          club_id: inactive_alice.club_id
        )

      message =
        create_message(
          club_id: inactive_alice.club_id,
          sender_id: bob.person_id,
          subject: "Inactive members must not see this",
          body: "This message belongs to active members only."
        )

      conn =
        conn
        |> sign_in_as("alice@example.com")
        |> get(~p"/messages/#{message.message_id}?#{[club_id: inactive_alice.club_id]}")

      assert response(conn, 403) == "Forbidden"
      refute conn.resp_body =~ "Inactive members must not see this"
      refute conn.resp_body =~ "This message belongs to active members only."
    end
  end

  describe "member message club ownership" do
    test "returns not found when the selected club does not own the message", %{conn: conn} do
      alpine =
        create_member(
          email: "alice@example.com",
          name: "Alice Alpine",
          club_name: "Alpine Club"
        )

      paddling =
        create_member(
          email: "alice@example.com",
          name: "Alice Paddling",
          club_name: "Paddling Club"
        )

      message =
        create_message(
          club_id: alpine.club_id,
          sender_id: alpine.person_id,
          subject: "Alpine-only route notes",
          body: "These details must not appear through another club."
        )

      conn =
        conn
        |> sign_in_as("alice@example.com")
        |> get(~p"/messages/#{message.message_id}?#{[club_id: paddling.club_id]}")

      response = html_response(conn, 404)

      refute response =~ "Alpine-only route notes"
      refute response =~ "These details must not appear through another club."
    end
  end

  describe "member-facing email delivery presentation on message detail" do
    test "renders every member email delivery status with its member-facing label and Heroicon",
         %{
           conn: conn
         } do
      alice =
        create_member(
          email: "alice@example.com",
          name: "Alice Adams",
          club_name: "Alpine Club"
        )

      bob =
        create_member(
          email: "bob@example.com",
          name: "Bob Builder",
          club_name: "Alpine Club",
          club_id: alice.club_id
        )

      carol =
        create_member(
          email: "carol@example.com",
          name: "Carol Climber",
          club_name: "Alpine Club",
          club_id: alice.club_id
        )

      dana =
        create_member(
          email: "dana@example.com",
          name: "Dana Downhill",
          club_name: "Alpine Club",
          club_id: alice.club_id
        )

      message =
        create_message(
          club_id: alice.club_id,
          sender_id: alice.person_id,
          subject: "Status check"
        )

      receipt_cases = [
        {alice, "sent", "Sending", "hero-clock"},
        {bob, "delivered", "Delivered", "hero-check-circle"},
        {carol, "delivery problem", "Delivery problem", "hero-exclamation-triangle"},
        {dana, "opened", "Opened", "hero-envelope-open"}
      ]

      Enum.each(receipt_cases, fn {member, status, _label, _icon} ->
        create_member_email_delivery(
          message_id: message.message_id,
          recipient_id: member.person_id,
          recipient_name: member.name,
          status: status
        )
      end)

      response =
        conn
        |> sign_in_as("bob@example.com")
        |> get(~p"/messages/#{message.message_id}?#{[club_id: alice.club_id]}")
        |> html_response(200)

      html = LazyHTML.from_fragment(response)

      assert_selector_exists(
        html,
        "#member-receipts-summary[data-receipt-count='4']"
      )

      Enum.each(receipt_cases, fn {member, status, label, icon} ->
        group_selector = "[data-testid='member-receipt-group'][data-receipt-status='#{status}']"
        status_slug = String.replace(status, " ", "-")

        assert_selector_exists(html, group_selector)

        assert_selector_exists(
          html,
          "#{group_selector} #member-receipt-group-toggle-#{status_slug}[aria-expanded='false']"
        )

        assert_text_in(html, "#{group_selector} h3", label)
        assert_exact_text(html, "#{group_selector} [data-testid='receipt-group-count']", "1")
        assert_selector_exists(html, "#{group_selector} .#{icon}")

        refute html
               |> LazyHTML.query(
                 "[data-testid='member-receipt'][data-recipient-name='#{member.name}'][data-receipt-status='#{status}']"
               )
               |> Enum.any?()
      end)
    end

    test "does not expose Memba-staff-only delivery fields on member message detail", %{
      conn: conn
    } do
      alice =
        create_member(
          email: "alice@example.com",
          name: "Alice Adams",
          club_name: "Alpine Club"
        )

      bob =
        create_member(
          email: "bob@example.com",
          name: "Bob Builder",
          club_name: "Alpine Club",
          club_id: alice.club_id
        )

      message =
        create_message(
          club_id: alice.club_id,
          sender_id: alice.person_id,
          subject: "Provider details stay private",
          body: "Members should only see the simple receipt."
        )

      delivery_id = Ecto.UUID.generate()
      provider_reason = "Postmark webhook reported SpamComplaint from mx.example.invalid"

      create_member_email_delivery(
        delivery_id: delivery_id,
        message_id: message.message_id,
        recipient_id: bob.person_id,
        recipient_name: bob.name,
        status: "delivery problem"
      )

      create_memba_staff_email_delivery(
        delivery_id: delivery_id,
        message_id: message.message_id,
        recipient_id: bob.person_id,
        recipient_name: bob.name,
        recipient_address: "bob-private@example.invalid",
        channel: "postmark-email",
        status: "spam complaint",
        reason: provider_reason
      )

      response =
        conn
        |> sign_in_as("alice@example.com")
        |> get(~p"/messages/#{message.message_id}?#{[club_id: alice.club_id]}")
        |> html_response(200)

      html = LazyHTML.from_fragment(response)

      assert_text_in(
        html,
        "[data-testid='member-receipt-group'][data-receipt-status='delivery problem'] h3",
        "Delivery problem"
      )

      refute response =~ delivery_id
      refute response =~ "bob-private@example.invalid"
      refute response =~ "postmark-email"
      refute response =~ "spam complaint"
      refute response =~ provider_reason
      refute response =~ "Postmark webhook"
      refute response =~ "Email deliveries"
      refute response =~ "Provider reason"
      refute response =~ ~s(href="/admin/)
    end
  end

  defp sign_in_as(conn, email) do
    init_test_session(conn, %{IdentityAuth.identity_session_key() => email})
  end

  defp create_member(attrs) do
    club_id = Keyword.get_lazy(attrs, :club_id, &Ecto.UUID.generate/0)
    person_id = Keyword.get_lazy(attrs, :person_id, &Ecto.UUID.generate/0)

    club =
      Repo.get(Club, club_id) ||
        insert_membership_club!(
          club_id: club_id,
          name: Keyword.fetch!(attrs, :club_name)
        )

    Repo.insert!(%Person{
      person_id: person_id,
      name: Keyword.fetch!(attrs, :name),
      email: Keyword.fetch!(attrs, :email)
    })

    Repo.insert!(%Membership{
      membership_id: Ecto.UUID.generate(),
      club_id: club_id,
      person_id: person_id,
      active: Keyword.get(attrs, :active, true)
    })

    club
    |> Map.from_struct()
    |> Map.put(:person_id, person_id)
    |> Map.put(:name, Keyword.fetch!(attrs, :name))
    |> Map.put(:email, Keyword.fetch!(attrs, :email))
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

  defp assert_selector_exists(html, selector) do
    assert html |> LazyHTML.query(selector) |> Enum.any?(), "Expected selector #{selector}"
  end

  defp assert_exact_text(html, selector, expected_text) do
    actual_text =
      html
      |> LazyHTML.query(selector)
      |> LazyHTML.text()
      |> String.trim()

    assert actual_text == expected_text
  end

  defp assert_text_in(html, selector, expected_text) do
    actual_text =
      html
      |> LazyHTML.query(selector)
      |> LazyHTML.text()

    assert actual_text =~ expected_text
  end
end
