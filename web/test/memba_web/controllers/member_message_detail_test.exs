defmodule MembaWeb.MemberMessageDetailTest do
  use MembaWeb.ConnCase, async: true

  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Membership
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging.Projections.MemberEmailDelivery
  alias Memba.Messaging.Projections.MembaStaffEmailDelivery
  alias Memba.Repo
  alias MembaWeb.ClubSite
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
        |> club_host(inactive_alice)
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
        |> club_host(paddling)
        |> sign_in_as("alice@example.com")
        |> get(~p"/messages/#{message.message_id}?#{[club_id: paddling.club_id]}")

      response = html_response(conn, 404)

      refute response =~ "Alpine-only route notes"
      refute response =~ "These details must not appear through another club."
    end

    test "returns not found for an Admin-only conversation in the selected club", %{conn: conn} do
      alice =
        create_member(
          email: "alice@example.com",
          name: "Alice Adams",
          club_name: "Alpine Club"
        )

      message =
        create_message(
          club_id: alice.club_id,
          sender_id: alice.person_id,
          subject: "Private Admin route notes",
          body: "These details must remain email-only.",
          audience_group_id: SystemGroups.admin_group_id(alice.club_id)
        )

      conn =
        conn
        |> club_host(alice)
        |> sign_in_as("alice@example.com")
        |> get(~p"/messages/#{message.message_id}?#{[club_id: alice.club_id]}")

      response = html_response(conn, 404)

      refute response =~ "Private Admin route notes"
      refute response =~ "These details must remain email-only."
    end
  end

  describe "member-facing delivery relocation on message detail" do
    test "does not render the inline delivery presentation on the message detail",
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

      message =
        create_message(
          club_id: alice.club_id,
          sender_id: alice.person_id,
          subject: "Status check"
        )

      seeded_receipt_cases = [
        {alice, "sent"},
        {bob, "delivered"},
        {carol, "delivery problem"}
      ]

      Enum.each(seeded_receipt_cases, fn {member, status} ->
        create_member_email_delivery(
          message_id: message.message_id,
          recipient_id: member.person_id,
          recipient_name: member.name,
          status: status
        )
      end)

      response =
        conn
        |> club_host(alice)
        |> sign_in_as("bob@example.com")
        |> get(~p"/messages/#{message.message_id}?#{[club_id: alice.club_id]}")
        |> html_response(200)

      html = LazyHTML.from_fragment(response)

      refute html |> LazyHTML.query("#member-receipt-summary") |> Enum.any?()
      refute html |> LazyHTML.query("#member-receipts-section") |> Enum.any?()
      refute html |> LazyHTML.query("#member-receipts") |> Enum.any?()

      refute html
             |> LazyHTML.query("[data-testid='member-receipt-summary-status']")
             |> Enum.any?()

      refute html
             |> LazyHTML.query("[data-testid='member-receipt-summary-bar-segment']")
             |> Enum.any?()

      refute html
             |> LazyHTML.query("[data-testid='member-receipt-group']")
             |> Enum.any?()

      refute response =~ ~r/sent to[\s\S]*3[\s\S]*members/
      refute response =~ "Members by delivery status"
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

      delivery_id = Memba.ID.generate(:delivery)
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
        |> club_host(alice)
        |> sign_in_as("alice@example.com")
        |> get(~p"/messages/#{message.message_id}?#{[club_id: alice.club_id]}")
        |> html_response(200)

      html = LazyHTML.from_fragment(response)

      refute html |> LazyHTML.query("#member-receipt-summary") |> Enum.any?()
      refute html |> LazyHTML.query("#member-receipts-section") |> Enum.any?()
      refute html |> LazyHTML.query("[data-testid='member-receipt-group']") |> Enum.any?()

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

  defp club_host(conn, club) do
    %{host: host} = URI.parse(ClubSite.url(club))
    Map.put(conn, :host, host)
  end

  defp create_member(attrs) do
    club_id = Keyword.get_lazy(attrs, :club_id, fn -> Memba.ID.generate(:club) end)
    person_id = Keyword.get_lazy(attrs, :person_id, fn -> Memba.ID.generate(:person) end)

    club =
      Repo.get(Club, club_id) ||
        insert_membership_club!(
          club_id: club_id,
          name: Keyword.fetch!(attrs, :club_name)
        )

    person =
      insert_membership_person!(
        person_id: person_id,
        name: Keyword.fetch!(attrs, :name),
        email: Keyword.fetch!(attrs, :email)
      )

    Repo.insert!(%Membership{
      membership_id: Memba.ID.generate(:membership),
      club_id: club_id,
      person_id: person.person_id,
      active: Keyword.get(attrs, :active, true)
    })

    club
    |> Map.from_struct()
    |> Map.put(:person_id, person.person_id)
    |> Map.put(:name, Keyword.fetch!(attrs, :name))
    |> Map.put(:email, Keyword.fetch!(attrs, :email))
  end

  defp create_message(attrs) do
    insert_group_accessible_message!(attrs)
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
