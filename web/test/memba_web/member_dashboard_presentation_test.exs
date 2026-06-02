defmodule MembaWeb.MemberDashboardPresentationTest do
  use Memba.DataCase, async: true

  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Membership
  alias Memba.Membership.Projections.Person
  alias Memba.Messaging.Projections.MemberEmailDelivery
  alias Memba.Messaging.Projections.Message
  alias MembaWeb.MemberDashboardPresentation

  test "loads selected-club dashboard assigns with member, message, sender, and receipt row data" do
    alice =
      create_active_member(
        email: "Alice@Example.com",
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

    _other_club_member =
      create_active_member(
        email: "cora@example.com",
        name: "Cora Canoe",
        club_name: "Paddling Club"
      )

    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    older_message =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Earlier update",
        inserted_at: DateTime.add(now, -60, :second)
      )

    newer_message =
      create_message(
        club_id: alice.club_id,
        sender_id: bob.person_id,
        subject: "Trip planning night",
        inserted_at: now
      )

    create_member_email_delivery(
      message_id: newer_message.message_id,
      recipient_id: alice.person_id,
      recipient_name: "Alice Adams",
      status: "opened"
    )

    create_member_email_delivery(
      message_id: newer_message.message_id,
      recipient_id: bob.person_id,
      recipient_name: "Bob Builder",
      status: "sent"
    )

    assert {:ok, assigns} =
             MemberDashboardPresentation.load(
               alice.club_id,
               %{email: " alice@example.com "},
               [alice.club]
             )

    assert assigns.page_title == "Alpine Club"
    assert assigns.selected_club.club_id == alice.club_id
    assert assigns.current_member.id == alice.person_id
    assert assigns.current_member.name == "Alice Adams"
    assert assigns.current_member.initials == "AA"
    assert assigns.active_member_count == 2

    assert Enum.map(assigns.members, &{&1.id, &1.name, &1.initials}) == [
             {alice.person_id, "Alice Adams", "AA"},
             {bob.person_id, "Bob Builder", "BB"}
           ]

    assert assigns.member_names_by_id == %{
             alice.person_id => "Alice Adams",
             bob.person_id => "Bob Builder"
           }

    assert Enum.map(assigns.messages, & &1.message_id) == [
             newer_message.message_id,
             older_message.message_id
           ]

    assert [newer_row, older_row] = assigns.message_rows
    assert newer_row.message_id == newer_message.message_id
    assert newer_row.sender_id == bob.person_id
    assert newer_row.sender_name == "Bob Builder"
    assert newer_row.sender_initials == "BB"
    assert newer_row.sent_at == newer_message.inserted_at
    assert newer_row.sent_at_label == Calendar.strftime(newer_message.inserted_at, "%b %d, %Y")
    assert newer_row.receipt_count == 2

    assert newer_row.status_counts == %{
             "opened" => 1,
             "delivered" => 0,
             "sent" => 1,
             "delivery problem" => 0
           }

    assert Enum.map(newer_row.receipt_summary, &{&1.status, &1.count, &1.percentage}) == [
             {"opened", 1, 50},
             {"delivered", 0, 0},
             {"sent", 1, 50},
             {"delivery problem", 0, 0}
           ]

    assert Enum.map(
             newer_row.receipt_segments,
             &{&1.status, &1.status_label, &1.count, &1.width_percentage}
           ) == [
             {"opened", "Opened", 1, 50},
             {"sent", "Sending", 1, 50}
           ]

    assert newer_row.receipt_glance_copy == "1 of 2 opened"
    assert newer_row.has_receipt_glance?

    assert older_row.message_id == older_message.message_id
    assert older_row.sender_name == "Alice Adams"
    assert older_row.sender_initials == "AA"
    assert older_row.sent_at == older_message.inserted_at
    assert older_row.sent_at_label == Calendar.strftime(older_message.inserted_at, "%b %d, %Y")
    assert older_row.receipt_count == 0
    assert older_row.receipt_segments == []
    assert older_row.receipt_glance_copy == nil
    refute older_row.has_receipt_glance?
  end

  test "omits timestamp labels for message rows without an inserted_at timestamp" do
    message = %Message{
      message_id: Ecto.UUID.generate(),
      sender_id: Ecto.UUID.generate(),
      subject: "Projection without timestamp",
      body: "Body",
      inserted_at: nil
    }

    assert [
             %{
               sent_at: nil,
               sent_at_label: nil
             }
           ] = MemberDashboardPresentation.present_message_rows([message], %{})
  end

  test "forbids missing, invalid, unauthorized, or identity-mismatched selected clubs" do
    alice = create_active_member(email: "alice@example.com", club_name: "Alpine Club")
    other_club_member = create_active_member(email: "pat@example.com", club_name: "Paddling Club")

    assert {:error, :forbidden} =
             MemberDashboardPresentation.load(
               "not-a-uuid",
               %{email: "alice@example.com"},
               [alice.club]
             )

    assert {:error, :forbidden} =
             MemberDashboardPresentation.load(
               other_club_member.club_id,
               %{email: "alice@example.com"},
               [alice.club]
             )

    assert {:error, :forbidden} =
             MemberDashboardPresentation.load(
               alice.club_id,
               %{email: "missing@example.com"},
               [alice.club]
             )
  end

  defp create_active_member(attrs) do
    club_id = Keyword.get_lazy(attrs, :club_id, &Ecto.UUID.generate/0)
    person_id = Ecto.UUID.generate()
    club_name = Keyword.get(attrs, :club_name, "Kootenay Mountaineering Club")

    club =
      Repo.get(Club, club_id) ||
        insert_membership_club!(
          club_id: club_id,
          name: club_name
        )

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

    %{
      club: club,
      club_id: club_id,
      person_id: person_id
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
      delivery_id: Ecto.UUID.generate(),
      message_id: Keyword.fetch!(attrs, :message_id),
      recipient_id: Keyword.fetch!(attrs, :recipient_id),
      recipient_name: Keyword.fetch!(attrs, :recipient_name),
      status: Keyword.fetch!(attrs, :status)
    })
  end
end
