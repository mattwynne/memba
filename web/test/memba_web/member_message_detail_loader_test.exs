defmodule MembaWeb.MemberMessageDetailLoaderTest do
  use MembaWeb.ConnCase, async: true

  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Membership
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging.Projections.MemberEmailDelivery
  alias Memba.Repo
  alias MembaWeb.MemberMessageDetail

  test "loads detail assigns for an active selected club message" do
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

    create_member_email_delivery(
      message_id: message.message_id,
      recipient_id: bob.person_id,
      recipient_name: "Bob Builder",
      status: "delivered"
    )

    assert {:ok, assigns} =
             MemberMessageDetail.load(
               %{"club_id" => alice.club_id, "message_id" => message.message_id},
               [alice]
             )

    assert assigns.page_title == "Trip planning night"
    assert assigns.selected_club.club_id == alice.club_id
    assert assigns.message.message_id == message.message_id
    assert assigns.sender_name == "Alice Adams"
    assert assigns.current_member == nil

    assert [%{kind: :original, sender_name: "Alice Adams", message: ^message}] =
             assigns.conversation_entries

    assert assigns.member_email_delivery_count == 1

    assert Enum.map(assigns.member_email_delivery_summary, &{&1.status, &1.count, &1.percentage}) ==
             [
               {"delivered", 1, 100},
               {"sent", 0, 0},
               {"delivery problem", 0, 0}
             ]

    assert [%{status: "delivered", status_label: "Delivered", count: 1}] =
             assigns.member_email_delivery_groups
  end

  test "loads the conversation in order with sender names and the signed-in current member" do
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

    first_reply =
      create_message(
        club_id: alice.club_id,
        sender_id: bob.person_id,
        conversation_id: message.message_id,
        reply_to_message_id: message.message_id,
        subject: "Trip planning night",
        body: "I'll bring snacks."
      )

    second_reply =
      create_message(
        club_id: alice.club_id,
        sender_id: carol.person_id,
        conversation_id: message.message_id,
        reply_to_message_id: message.message_id,
        subject: "Trip planning night",
        body: "I can drive."
      )

    assert {:ok, assigns} =
             MemberMessageDetail.load(
               %{"club_id" => alice.club_id, "message_id" => message.message_id},
               [alice],
               %{email: "bob@example.com"}
             )

    assert assigns.current_member.id == bob.person_id

    assert Enum.map(
             assigns.conversation_entries,
             &{&1.kind, &1.sender_name, &1.message.message_id}
           ) ==
             [
               {:original, "Alice Adams", message.message_id},
               {:reply, "Bob Builder", first_reply.message_id},
               {:reply, "Carol Clark", second_reply.message_id}
             ]
  end

  test "forbids missing, invalid, or unauthorized selected clubs" do
    club = create_active_member(email: "alice@example.com", club_name: "Alpine Club")
    other_club = create_active_member(email: "pat@example.com", club_name: "Paddling Club")

    message =
      create_message(
        club_id: club.club_id,
        sender_id: club.person_id,
        subject: "Members only"
      )

    assert {:error, :forbidden} =
             MemberMessageDetail.load(%{"message_id" => message.message_id}, [club])

    assert {:error, :forbidden} =
             MemberMessageDetail.load(
               %{"club_id" => "not-a-uuid", "message_id" => message.message_id},
               [club]
             )

    assert {:error, :forbidden} =
             MemberMessageDetail.load(
               %{"club_id" => club.club_id, "message_id" => message.message_id},
               [other_club]
             )
  end

  test "returns not found for missing messages and message club mismatches" do
    club = create_active_member(email: "alice@example.com", club_name: "Alpine Club")
    other_club = create_club(name: "Paddling Club")

    mismatched_message =
      create_message(
        club_id: other_club.club_id,
        sender_id: club.person_id,
        subject: "Wrong club"
      )

    assert {:error, :not_found} =
             MemberMessageDetail.load(
               %{"club_id" => club.club_id, "message_id" => Memba.ID.generate(:message)},
               [club]
             )

    assert {:error, :not_found} =
             MemberMessageDetail.load(
               %{"club_id" => club.club_id, "message_id" => mismatched_message.message_id},
               [club]
             )
  end

  test "returns not found for a conversation granted only to the Admin group" do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    admin_conversation =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Private Admin planning",
        audience_group_id: SystemGroups.admin_group_id(alice.club_id)
      )

    assert {:error, :not_found} =
             MemberMessageDetail.load(
               %{
                 "club_id" => alice.club_id,
                 "message_id" => admin_conversation.message_id
               },
               [alice],
               %{email: "alice@example.com"}
             )
  end

  defp create_club(attrs) do
    insert_membership_club!(attrs)
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
    Repo.insert!(%MemberEmailDelivery{
      delivery_id: Memba.ID.generate(:delivery),
      message_id: Keyword.fetch!(attrs, :message_id),
      recipient_id: Keyword.fetch!(attrs, :recipient_id),
      recipient_name: Keyword.fetch!(attrs, :recipient_name),
      status: Keyword.fetch!(attrs, :status)
    })
  end
end
