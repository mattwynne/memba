defmodule MembaWeb.MemberMessageDetailLoaderTest do
  use Memba.EventSourcedCase, async: false

  import Memba.MessagingFixtures

  alias Memba.Membership
  alias Memba.Membership.Projectors.GroupMembership, as: GroupMembershipProjector
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging.App, as: MessagingApp
  alias Memba.Messaging.Commands.GrantConversationAccessToGroup
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Projections.MemberEmailDelivery
  alias Memba.Messaging.Recipient
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
               [alice],
               %{email: "alice@example.com"}
             )

    assert assigns.page_title == "Trip planning night"
    assert assigns.selected_club.club_id == alice.club_id
    assert assigns.message.message_id == message.message_id
    assert assigns.sender_name == "Alice Adams"
    assert assigns.current_member.id == alice.person_id

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
               [club],
               %{email: "alice@example.com"}
             )

    assert {:error, :not_found} =
             MemberMessageDetail.load(
               %{"club_id" => club.club_id, "message_id" => mismatched_message.message_id},
               [club],
               %{email: "alice@example.com"}
             )
  end

  test "loads a private conversation for an active group member and hides it from other members" do
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

    admin_conversation =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Private Admin planning",
        audience_group_id: SystemGroups.admin_group_id(alice.club_id)
      )

    assert {:ok, assigns} =
             MemberMessageDetail.load(
               %{
                 "club_id" => alice.club_id,
                 "message_id" => admin_conversation.message_id
               },
               [alice],
               %{email: "alice@example.com"}
             )

    assert assigns.current_member.id == alice.person_id
    assert assigns.message.message_id == admin_conversation.message_id

    assert {:error, :not_found} =
             MemberMessageDetail.load(
               %{
                 "club_id" => alice.club_id,
                 "message_id" => admin_conversation.message_id
               },
               [bob],
               %{email: "bob@example.com"}
             )
  end

  test "committed custom-group removal denies direct detail reads while participation projection is stale" do
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

    group_id = Memba.ID.generate(:group)

    assert :ok =
             Membership.create_custom_group(
               %{
                 club_id: alice.club_id,
                 group_id: group_id,
                 actor_person_id: alice.person_id,
                 name: "Board"
               },
               consistency: :strong
             )

    assert {:ok, _admission} =
             Membership.add_custom_group_member(
               %{
                 club_id: alice.club_id,
                 group_id: group_id,
                 membership_id: bob.membership_id,
                 person_id: bob.person_id,
                 actor_person_id: alice.person_id
               },
               consistency: :strong
             )

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Private Board planning",
        audience_group_id: group_id
      )

    projector_child_id = stop_projector!(GroupMembershipProjector)

    assert {:ok, _removal} =
             Membership.remove_custom_group_member(
               %{
                 club_id: alice.club_id,
                 group_id: group_id,
                 membership_id: bob.membership_id,
                 person_id: bob.person_id,
                 actor_person_id: alice.person_id,
                 removal_operation_id: Ecto.UUID.generate()
               },
               consistency: :eventual
             )

    assert Membership.active_member_of_group?(group_id, bob.person_id)

    assert {:error, :not_found} =
             MemberMessageDetail.load(
               %{"club_id" => bob.club_id, "message_id" => message.message_id},
               [bob],
               %{email: "bob@example.com"}
             )

    restart_projector!(projector_child_id)

    Memba.ProjectionBarrier.await!(
      [GroupMembershipProjector],
      checkpoint: Memba.ProjectionBarrier.current_checkpoint(),
      timeout: 5_000
    )
  end

  defp create_club(attrs) do
    insert_membership_club!(attrs)
  end

  defp create_active_member(attrs) do
    club_id = Keyword.get_lazy(attrs, :club_id, fn -> Memba.ID.generate(:club) end)
    person_id = Memba.ID.generate(:person)
    club_name = Keyword.fetch!(attrs, :club_name)

    if is_nil(Membership.get_club(club_id)) do
      assert :ok =
               Membership.create_club(
                 membership_club_attrs(club_id: club_id, name: club_name),
                 consistency: :strong
               )
    end

    assert :ok =
             Membership.create_person(
               %{
                 person_id: person_id,
                 name: Keyword.get(attrs, :name, "Test Member"),
                 email: Keyword.fetch!(attrs, :email)
               },
               consistency: :strong
             )

    membership_id = Memba.ID.generate(:membership)

    assert :ok =
             Membership.add_member(
               %{membership_id: membership_id, club_id: club_id, person_id: person_id},
               consistency: :strong
             )

    club_id
    |> Membership.get_club()
    |> Map.from_struct()
    |> Map.put(:person_id, person_id)
    |> Map.put(:membership_id, membership_id)
  end

  defp create_message(attrs) do
    if is_nil(Keyword.get(attrs, :conversation_id)) do
      message_id = Keyword.get_lazy(attrs, :message_id, fn -> Memba.ID.generate(:message) end)
      club_id = Keyword.fetch!(attrs, :club_id)

      assert :ok =
               MessagingApp.dispatch(
                 %SendMessage{
                   message_id: message_id,
                   club_id: club_id,
                   sender_id: Keyword.fetch!(attrs, :sender_id),
                   subject: Keyword.get(attrs, :subject, "Message subject"),
                   body: Keyword.get(attrs, :body, "Message body"),
                   recipients: [
                     %Recipient{
                       delivery_id: Memba.ID.generate(:delivery),
                       person_id: Keyword.fetch!(attrs, :sender_id),
                       name: "Sender",
                       email: "sender@example.com"
                     }
                   ]
                 },
                 consistency: :strong
               )

      assert :ok =
               MessagingApp.dispatch(
                 %GrantConversationAccessToGroup{
                   conversation_id: message_id,
                   club_id: club_id,
                   group_id:
                     Keyword.get_lazy(attrs, :audience_group_id, fn ->
                       SystemGroups.everyone_group_id(club_id)
                     end),
                   access_level: :write
                 },
                 consistency: :strong
               )

      Repo.delete_all(
        from(delivery in MemberEmailDelivery, where: delivery.message_id == ^message_id)
      )

      Repo.get!(Memba.Messaging.Projections.Message, message_id)
    else
      insert_group_accessible_message!(attrs)
    end
  end

  defp stop_projector!(projector) do
    child_id =
      Supervisor.which_children(Memba.Supervisor)
      |> Enum.find_value(fn
        {child_id, _pid, :worker, [^projector]} -> child_id
        _child -> nil
      end)

    assert child_id
    assert :ok = Supervisor.terminate_child(Memba.Supervisor, child_id)
    on_exit(fn -> restart_projector!(child_id) end)
    child_id
  end

  defp restart_projector!(child_id) do
    case Supervisor.restart_child(Memba.Supervisor, child_id) do
      {:ok, _pid} -> :ok
      {:ok, _pid, _info} -> :ok
      {:error, :running} -> :ok
    end
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
