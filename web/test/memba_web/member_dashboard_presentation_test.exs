defmodule MembaWeb.MemberDashboardPresentationTest do
  use Memba.DataCase, async: true

  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Membership
  alias Memba.Messaging.Projections.MemberEmailDelivery
  alias Memba.Messaging.Projections.Message
  alias MembaWeb.MemberDashboardPresentation

  test "loads selected-club dashboard assigns with grouped conversation row data" do
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

    carol =
      create_active_member(
        email: "carol@example.com",
        name: "Carol Canoe",
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

    older_root =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Saturday ridge walk",
        inserted_at: DateTime.add(now, -60, :second)
      )

    newer_root =
      create_message(
        club_id: alice.club_id,
        sender_id: bob.person_id,
        subject: "Trip planning night",
        inserted_at: now
      )

    _first_reply =
      create_message(
        club_id: alice.club_id,
        sender_id: bob.person_id,
        conversation_id: older_root.message_id,
        reply_to_message_id: older_root.message_id,
        subject: older_root.subject,
        inserted_at: DateTime.add(now, 30, :second)
      )

    latest_reply =
      create_message(
        club_id: alice.club_id,
        sender_id: carol.person_id,
        conversation_id: older_root.message_id,
        reply_to_message_id: older_root.message_id,
        subject: older_root.subject,
        inserted_at: DateTime.add(now, 60, :second)
      )

    create_member_email_delivery(
      message_id: older_root.message_id,
      recipient_id: alice.person_id,
      recipient_name: "Alice Adams",
      status: "delivered"
    )

    create_member_email_delivery(
      message_id: older_root.message_id,
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
    assert assigns.active_member_count == 3

    assert Enum.map(assigns.members, &{&1.id, &1.name, &1.initials}) == [
             {alice.person_id, "Alice Adams", "AA"},
             {bob.person_id, "Bob Builder", "BB"},
             {carol.person_id, "Carol Canoe", "CC"}
           ]

    assert assigns.member_names_by_id == %{
             alice.person_id => "Alice Adams",
             bob.person_id => "Bob Builder",
             carol.person_id => "Carol Canoe"
           }

    assert Enum.map(assigns.messages, & &1.message_id) == [
             newer_root.message_id,
             older_root.message_id
           ]

    assert [newer_row, older_row] = assigns.message_rows
    assert newer_row.message_id == newer_root.message_id
    assert newer_row.conversation_id == newer_root.message_id
    assert newer_row.sender_id == bob.person_id
    assert newer_row.originator_id == bob.person_id
    assert newer_row.originator_name == "Bob Builder"
    assert newer_row.originator_initials == "BB"
    assert newer_row.subject == "Trip planning night"
    assert newer_row.sent_at == newer_root.inserted_at
    assert newer_row.sent_at_label == Calendar.strftime(newer_root.inserted_at, "%b %d, %Y")
    assert newer_row.reply_count == 0
    assert newer_row.latest_replier_id == nil
    assert newer_row.latest_replier_name == nil
    assert newer_row.reply_activity_label == "No replies yet"

    assert older_row.message_id == older_root.message_id
    assert older_row.conversation_id == older_root.message_id
    assert older_row.sender_id == alice.person_id
    assert older_row.originator_id == alice.person_id
    assert older_row.originator_name == "Alice Adams"
    assert older_row.originator_initials == "AA"
    assert older_row.subject == "Saturday ridge walk"
    assert older_row.sent_at == older_root.inserted_at
    assert older_row.sent_at_label == Calendar.strftime(older_root.inserted_at, "%b %d, %Y")
    assert older_row.reply_count == 2
    assert older_row.latest_replier_id == latest_reply.sender_id
    assert older_row.latest_replier_name == "Carol Canoe"
    assert older_row.reply_activity_label == "2 replies · latest from Carol Canoe"

    for row <- assigns.message_rows do
      refute Map.has_key?(row, :receipt_count)
      refute Map.has_key?(row, :receipt_summary)
      refute Map.has_key?(row, :status_counts)
      refute Map.has_key?(row, :receipt_segments)
      refute Map.has_key?(row, :receipt_glance_copy)
      refute Map.has_key?(row, :has_receipt_glance?)
      refute Map.has_key?(row, :receipt_groups)
    end
  end

  test "omits timestamp labels for conversation rows without an inserted_at timestamp" do
    root = %Message{
      message_id: Memba.ID.generate(:message),
      sender_id: Memba.ID.generate(:person),
      conversation_id: Memba.ID.generate(:message),
      subject: "Projection without timestamp",
      body: "Body",
      inserted_at: nil
    }

    assert [
             %{
               sent_at: nil,
               sent_at_label: nil
             }
           ] =
             MemberDashboardPresentation.present_message_rows(
               [
                 %{
                   message: root,
                   message_id: root.message_id,
                   conversation_id: root.message_id,
                   sender_id: root.sender_id,
                   subject: root.subject,
                   body: root.body,
                   inserted_at: nil,
                   reply_count: 0,
                   latest_replier_id: nil,
                   latest_replier_name: nil
                 }
               ],
               %{}
             )
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
    club_id = Keyword.get_lazy(attrs, :club_id, fn -> Memba.ID.generate(:club) end)
    person_id = Memba.ID.generate(:person)
    club_name = Keyword.get(attrs, :club_name, "Kootenay Mountaineering Club")

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

    %{
      club: club,
      club_id: club_id,
      person_id: person.person_id
    }
  end

  defp create_message(attrs) do
    inserted_at = Keyword.get_lazy(attrs, :inserted_at, &DateTime.utc_now/0)
    message_id = Memba.ID.generate(:message)

    Repo.insert!(%Message{
      message_id: message_id,
      club_id: Keyword.fetch!(attrs, :club_id),
      sender_id: Keyword.fetch!(attrs, :sender_id),
      conversation_id: Keyword.get(attrs, :conversation_id, message_id),
      reply_to_message_id: Keyword.get(attrs, :reply_to_message_id),
      subject: Keyword.fetch!(attrs, :subject),
      body: Keyword.get(attrs, :body, "Message body"),
      inserted_at: inserted_at,
      updated_at: inserted_at
    })
  end

  defp create_member_email_delivery(attrs) do
    Repo.insert!(%MemberEmailDelivery{
      delivery_id: Memba.ID.generate(:delivery),
      message_id: Keyword.fetch!(attrs, :message_id),
      recipient_id: Keyword.fetch!(attrs, :recipient_id),
      recipient_name: Keyword.fetch!(attrs, :recipient_name),
      status: Keyword.fetch!(attrs, :status)
    })
  end
end
