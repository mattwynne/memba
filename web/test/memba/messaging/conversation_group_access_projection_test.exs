defmodule Memba.Messaging.ConversationGroupAccessProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership.Projections.Group
  alias Memba.Membership.Projections.GroupMembership
  alias Memba.Membership.Projections.Membership
  alias Memba.Messaging
  alias Memba.Messaging.App, as: MessagingApp
  alias Memba.Messaging.Commands.GrantConversationAccessToGroup
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Events.ConversationAccessGrantedToGroup
  alias Memba.Messaging.Events.ConversationAccessRevokedFromGroup
  alias Memba.Messaging.Projectors.ConversationGroupAccess, as: ConversationGroupAccessProjector
  alias Memba.Messaging.Projections.ConversationGroupAccess, as: ConversationGroupAccessProjection
  alias Memba.Messaging.Projections.Message
  alias Memba.Messaging.Recipient

  test "projects a write grant" do
    conversation_id = Memba.ID.generate(:message)
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)

    assert :ok =
             ConversationGroupAccessProjector.handle(
               %ConversationAccessGrantedToGroup{
                 conversation_id: conversation_id,
                 club_id: club_id,
                 group_id: group_id,
                 access_level: "write"
               },
               projector_metadata(1)
             )

    assert [
             %ConversationGroupAccessProjection{
               conversation_id: ^conversation_id,
               club_id: ^club_id,
               group_id: ^group_id,
               access_level: "write",
               inserted_at: %DateTime{},
               updated_at: %DateTime{}
             }
           ] = Repo.all(ConversationGroupAccessProjection)
  end

  test "a read grant does not imply write access" do
    conversation_id = Memba.ID.generate(:message)
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)

    assert :ok =
             ConversationGroupAccessProjector.handle(
               %ConversationAccessGrantedToGroup{
                 conversation_id: conversation_id,
                 club_id: club_id,
                 group_id: group_id,
                 access_level: "read"
               },
               projector_metadata(1)
             )
  end

  test "read grants can be upgraded to write grants" do
    conversation_id = Memba.ID.generate(:message)
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)

    assert :ok =
             ConversationGroupAccessProjector.handle(
               %ConversationAccessGrantedToGroup{
                 conversation_id: conversation_id,
                 club_id: club_id,
                 group_id: group_id,
                 access_level: "read"
               },
               projector_metadata(1)
             )

    assert :ok =
             ConversationGroupAccessProjector.handle(
               %ConversationAccessGrantedToGroup{
                 conversation_id: conversation_id,
                 club_id: club_id,
                 group_id: group_id,
                 access_level: "write"
               },
               projector_metadata(2)
             )

    assert [
             %ConversationGroupAccessProjection{
               conversation_id: ^conversation_id,
               club_id: ^club_id,
               group_id: ^group_id,
               access_level: "write"
             }
           ] = Repo.all(ConversationGroupAccessProjection)
  end

  test "repeated grants keep one current row per conversation and group" do
    conversation_id = Memba.ID.generate(:message)
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)

    event = %ConversationAccessGrantedToGroup{
      conversation_id: conversation_id,
      club_id: club_id,
      group_id: group_id,
      access_level: "write"
    }

    assert :ok = ConversationGroupAccessProjector.handle(event, projector_metadata(1))
    assert :ok = ConversationGroupAccessProjector.handle(event, projector_metadata(2))

    assert [
             %ConversationGroupAccessProjection{
               conversation_id: ^conversation_id,
               club_id: ^club_id,
               group_id: ^group_id,
               access_level: "write"
             }
           ] = Repo.all(ConversationGroupAccessProjection)
  end

  test "a revocation removes only the selected group's access" do
    conversation_id = Memba.ID.generate(:message)
    club_id = Memba.ID.generate(:club)
    revoked_group_id = Memba.ID.generate(:group)
    retained_group_id = Memba.ID.generate(:group)

    for {event_number, group_id} <- [{1, revoked_group_id}, {2, retained_group_id}] do
      assert :ok =
               ConversationGroupAccessProjector.handle(
                 %ConversationAccessGrantedToGroup{
                   conversation_id: conversation_id,
                   club_id: club_id,
                   group_id: group_id,
                   access_level: "write"
                 },
                 projector_metadata(event_number)
               )
    end

    assert :ok =
             ConversationGroupAccessProjector.handle(
               %ConversationAccessRevokedFromGroup{
                 conversation_id: conversation_id,
                 club_id: club_id,
                 group_id: revoked_group_id,
                 access_level: "write"
               },
               projector_metadata(3)
             )

    refute Repo.get_by(ConversationGroupAccessProjection,
             conversation_id: conversation_id,
             group_id: revoked_group_id
           )

    assert Repo.get_by(ConversationGroupAccessProjection,
             conversation_id: conversation_id,
             group_id: retained_group_id
           )
  end

  test "invalid access levels are rejected by the projector and query API" do
    conversation_id = Memba.ID.generate(:message)
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)

    assert {:error, :invalid_access_level} =
             ConversationGroupAccessProjector.handle(
               %ConversationAccessGrantedToGroup{
                 conversation_id: conversation_id,
                 club_id: club_id,
                 group_id: group_id,
                 access_level: "admin"
               },
               projector_metadata(1)
             )

    assert Repo.all(ConversationGroupAccessProjection) == []
    refute Messaging.group_has_conversation_access?(conversation_id, group_id, "admin")
    refute Messaging.group_has_conversation_access?(conversation_id, group_id, :read)
    refute Messaging.group_has_conversation_access?("not-a-message-id", group_id, :read)
    refute Messaging.group_has_conversation_access?(conversation_id, "not-a-group-id", :read)
  end

  test "member access resolves replies through authoritative participation and honors the required level" do
    club_id = Memba.ID.generate(:club)
    person_id = Memba.ID.generate(:person)
    group_id = Memba.ID.generate(:group)

    assert :ok =
             Memba.Membership.create_club(
               membership_club_attrs(club_id: club_id, name: "Alpine Club"),
               consistency: :strong
             )

    assert :ok =
             Memba.Membership.create_person(
               %{person_id: person_id, name: "Alice Adams", email: "alice@example.com"},
               consistency: :strong
             )

    assert :ok =
             Memba.Membership.add_member(
               %{
                 club_id: club_id,
                 membership_id: Memba.ID.generate(:membership),
                 person_id: person_id
               },
               consistency: :strong
             )

    assert :ok =
             Memba.Membership.create_custom_group(
               %{
                 club_id: club_id,
                 group_id: group_id,
                 actor_person_id: person_id,
                 name: "Trip planners"
               },
               consistency: :strong
             )

    club = Memba.Membership.get_club(club_id)
    person = Memba.Membership.get_person(person_id)

    root_message_id = Memba.ID.generate(:message)

    assert :ok =
             MessagingApp.dispatch(
               %SendMessage{
                 message_id: root_message_id,
                 club_id: club.club_id,
                 sender_id: person.person_id,
                 subject: "Private trip planning",
                 body: "Message body",
                 recipients: [
                   %Recipient{
                     delivery_id: Memba.ID.generate(:delivery),
                     person_id: person.person_id,
                     name: person.name,
                     email: person.email
                   }
                 ]
               },
               consistency: :strong
             )

    root = Repo.get!(Message, root_message_id)

    reply =
      insert_message!(
        club_id: club.club_id,
        sender_id: person.person_id,
        conversation_id: root.message_id,
        reply_to_message_id: root.message_id,
        subject: root.subject
      )

    assert :ok =
             MessagingApp.dispatch(
               %GrantConversationAccessToGroup{
                 conversation_id: root.message_id,
                 club_id: club.club_id,
                 group_id: group_id,
                 access_level: :read
               },
               consistency: :eventual
             )

    assert Messaging.member_has_conversation_access?(
             reply.message_id,
             club.club_id,
             person.person_id,
             :read
           )

    refute Messaging.member_has_conversation_access?(
             reply.message_id,
             club.club_id,
             person.person_id,
             :write
           )

    refute Messaging.member_has_conversation_access?(
             reply.message_id,
             Memba.ID.generate(:club),
             person.person_id,
             :read
           )
  end

  test "member access fails closed when a conversation has more than one group" do
    club = insert_membership_club!(name: "Alpine Club")
    reader = insert_membership_person!(name: "Riley Reader", email: "riley@example.com")
    writer = insert_membership_person!(name: "Wendy Writer", email: "wendy@example.com")
    outsider = insert_membership_person!(name: "Oscar Outsider", email: "oscar@example.com")
    readers_group = insert_group!(club.club_id, "Trip followers")
    writers_group = insert_group!(club.club_id, "Trip planners")

    insert_active_group_member!(club.club_id, readers_group.group_id, reader.person_id)
    insert_active_group_member!(club.club_id, writers_group.group_id, writer.person_id)
    insert_active_club_member!(club.club_id, outsider.person_id)

    root =
      insert_message!(
        club_id: club.club_id,
        sender_id: writer.person_id,
        subject: "Shared trip planning"
      )

    for {group_id, access_level} <- [
          {readers_group.group_id, "read"},
          {writers_group.group_id, "write"}
        ] do
      Repo.insert!(%ConversationGroupAccessProjection{
        conversation_id: root.message_id,
        club_id: club.club_id,
        group_id: group_id,
        access_level: access_level
      })
    end

    for {person_id, access_level} <- [
          {reader.person_id, :read},
          {reader.person_id, :write},
          {writer.person_id, :read},
          {writer.person_id, :write},
          {outsider.person_id, :read}
        ] do
      refute Messaging.member_has_conversation_access?(
               root.message_id,
               club.club_id,
               person_id,
               access_level
             )
    end

    assert Messaging.list_conversations_for_group(readers_group.group_id) == []
    assert Messaging.list_conversations_for_group(writers_group.group_id) == []
  end

  test "discovering a group does not confer member access or permit in-app follow actions" do
    club_id = Memba.ID.generate(:club)
    alice_person_id = Memba.ID.generate(:person)
    alice_membership_id = Memba.ID.generate(:membership)
    bob_person_id = Memba.ID.generate(:person)
    bob_membership_id = Memba.ID.generate(:membership)
    group_id = Memba.ID.generate(:group)
    conversation_id = Memba.ID.generate(:message)

    assert :ok =
             Memba.Membership.create_club(
               membership_club_attrs(club_id: club_id, name: "Alpine Club"),
               consistency: :strong
             )

    assert :ok =
             Memba.Membership.create_person(
               %{
                 person_id: alice_person_id,
                 name: "Alice Adams",
                 email: "alice@example.com"
               },
               consistency: :strong
             )

    assert :ok =
             Memba.Membership.create_person(
               %{
                 person_id: bob_person_id,
                 name: "Bob Builder",
                 email: "bob@example.com"
               },
               consistency: :strong
             )

    assert :ok =
             Memba.Membership.add_member(
               %{
                 club_id: club_id,
                 membership_id: alice_membership_id,
                 person_id: alice_person_id
               },
               consistency: :strong
             )

    assert :ok =
             Memba.Membership.add_member(
               %{
                 club_id: club_id,
                 membership_id: bob_membership_id,
                 person_id: bob_person_id
               },
               consistency: :strong
             )

    assert :ok =
             Memba.Membership.App.dispatch(
               %Memba.Membership.Commands.CreateGroup{
                 club_id: club_id,
                 group_id: group_id,
                 email_slug: "trip-planners",
                 name: "Trip planners"
               },
               consistency: :strong
             )

    assert :ok =
             Memba.Membership.App.dispatch(
               %Memba.Membership.Commands.AddGroupMember{
                 club_id: club_id,
                 group_id: group_id,
                 membership_id: alice_membership_id,
                 person_id: alice_person_id
               },
               consistency: :strong
             )

    assert Enum.any?(
             Memba.Membership.list_discoverable_groups_for_member(
               club_id,
               bob_person_id
             ),
             &(&1.group_id == group_id)
           )

    refute Enum.any?(
             Memba.Membership.list_active_groups_for_member(club_id, bob_person_id),
             &(&1.group_id == group_id)
           )

    assert :ok =
             Messaging.send_club_message(
               %{
                 message_id: conversation_id,
                 club_id: club_id,
                 sender_id: alice_person_id,
                 audience_group_id: group_id,
                 subject: "Private trip planning",
                 body: "Bring route ideas."
               },
               consistency: :strong
             )

    attrs = %{
      club_id: club_id,
      conversation_id: conversation_id,
      member_id: bob_person_id
    }

    refute Messaging.member_has_conversation_access?(
             conversation_id,
             club_id,
             bob_person_id,
             :read
           )

    assert {:error, :not_current_member} =
             Messaging.follow_conversation_as_current_member(attrs, consistency: :strong)

    refute Messaging.following_conversation?(conversation_id, bob_person_id)

    assert :ok =
             Memba.Membership.App.dispatch(
               %Memba.Membership.Commands.AddGroupMember{
                 club_id: club_id,
                 group_id: group_id,
                 membership_id: bob_membership_id,
                 person_id: bob_person_id
               },
               consistency: :strong
             )

    assert :ok =
             Messaging.follow_conversation_as_current_member(attrs, consistency: :strong)

    assert Messaging.following_conversation?(conversation_id, bob_person_id)

    assert :ok =
             Messaging.unfollow_conversation_as_current_member(attrs, consistency: :strong)

    refute Messaging.following_conversation?(conversation_id, bob_person_id)

    assert :ok =
             Messaging.follow_conversation_as_current_member(attrs, consistency: :strong)

    assert Messaging.following_conversation?(conversation_id, bob_person_id)

    assert {:error, :conversation_not_found} =
             attrs
             |> Map.put(:club_id, Memba.ID.generate(:club))
             |> Messaging.unfollow_conversation_as_current_member(consistency: :strong)

    assert Messaging.following_conversation?(conversation_id, bob_person_id)

    assert {:ok, %Memba.Membership.CustomGroupRemoval{transition: :member_removed}} =
             Memba.Membership.remove_custom_group_member(
               %{
                 club_id: club_id,
                 group_id: group_id,
                 membership_id: bob_membership_id,
                 person_id: bob_person_id,
                 actor_person_id: alice_person_id,
                 removal_operation_id: Ecto.UUID.generate()
               },
               consistency: :strong
             )

    assert {:error, :not_current_member} =
             Messaging.unfollow_conversation_as_current_member(attrs, consistency: :strong)

    assert Messaging.following_conversation?(conversation_id, bob_person_id)
  end

  defp projector_metadata(event_number) do
    %{
      handler_name: "conversation-group-access-projection-test-#{Ecto.UUID.generate()}",
      event_number: event_number
    }
  end

  defp insert_group!(club_id, name) do
    Repo.insert!(%Group{
      group_id: Memba.ID.generate(:group),
      club_id: club_id,
      email_slug: name |> String.downcase() |> String.replace(" ", "-"),
      name: name,
      name_uniqueness_key: Memba.Membership.GroupName.uniqueness_key(name)
    })
  end

  defp insert_active_group_member!(club_id, group_id, person_id) do
    membership =
      Repo.get_by(Membership, club_id: club_id, person_id: person_id) ||
        insert_active_club_member!(club_id, person_id)

    Repo.insert!(%GroupMembership{
      club_id: club_id,
      group_id: group_id,
      membership_id: membership.membership_id,
      person_id: person_id,
      active: true
    })
  end

  defp insert_active_club_member!(club_id, person_id) do
    Repo.insert!(%Membership{
      membership_id: Memba.ID.generate(:membership),
      club_id: club_id,
      person_id: person_id,
      active: true
    })
  end

  defp insert_message!(attrs) do
    message_id = Keyword.get_lazy(attrs, :message_id, fn -> Memba.ID.generate(:message) end)

    Repo.insert!(%Message{
      message_id: message_id,
      club_id: Keyword.fetch!(attrs, :club_id),
      sender_id: Keyword.fetch!(attrs, :sender_id),
      conversation_id: Keyword.get(attrs, :conversation_id, message_id),
      reply_to_message_id: Keyword.get(attrs, :reply_to_message_id),
      subject: Keyword.fetch!(attrs, :subject),
      body: Keyword.get(attrs, :body, "Message body")
    })
  end
end
