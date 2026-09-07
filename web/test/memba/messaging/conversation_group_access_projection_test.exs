defmodule Memba.Messaging.ConversationGroupAccessProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership.Projections.Group
  alias Memba.Membership.Projections.GroupMembership
  alias Memba.Membership.Projections.Membership
  alias Memba.Messaging
  alias Memba.Messaging.Events.ConversationAccessGrantedToGroup
  alias Memba.Messaging.Events.ConversationAccessRevokedFromGroup
  alias Memba.Messaging.Projectors.ConversationGroupAccess, as: ConversationGroupAccessProjector
  alias Memba.Messaging.Projections.ConversationGroupAccess, as: ConversationGroupAccessProjection
  alias Memba.Messaging.Projections.Message

  test "projects a write grant and exposes read-through-write in the Messaging query API" do
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

    assert Messaging.group_has_conversation_access?(conversation_id, group_id, :write)
    assert Messaging.group_has_conversation_access?(conversation_id, group_id, "write")
    assert Messaging.group_has_conversation_access?(conversation_id, group_id, :read)
    assert Messaging.group_has_conversation_access?(conversation_id, group_id, "read")
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

    assert Messaging.group_has_conversation_access?(conversation_id, group_id, :read)
    refute Messaging.group_has_conversation_access?(conversation_id, group_id, :write)
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

    assert Messaging.group_has_conversation_access?(conversation_id, group_id, :write)
    assert Messaging.group_has_conversation_access?(conversation_id, group_id, :read)
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

    refute Messaging.group_has_conversation_access?(conversation_id, revoked_group_id, :read)
    assert Messaging.group_has_conversation_access?(conversation_id, retained_group_id, :write)
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
    refute Messaging.group_has_conversation_access?("not-a-message-id", group_id, :read)
    refute Messaging.group_has_conversation_access?(conversation_id, "not-a-group-id", :read)
  end

  test "member access resolves replies through an active group and honors the required level" do
    club = insert_membership_club!(name: "Alpine Club")
    person = insert_membership_person!(name: "Alice Adams", email: "alice@example.com")
    group = insert_group!(club.club_id, "Trip planners")
    insert_active_group_member!(club.club_id, group.group_id, person.person_id)

    root =
      insert_message!(
        club_id: club.club_id,
        sender_id: person.person_id,
        subject: "Private trip planning"
      )

    reply =
      insert_message!(
        club_id: club.club_id,
        sender_id: person.person_id,
        conversation_id: root.message_id,
        reply_to_message_id: root.message_id,
        subject: root.subject
      )

    Repo.insert!(%ConversationGroupAccessProjection{
      conversation_id: root.message_id,
      club_id: club.club_id,
      group_id: group.group_id,
      access_level: "read"
    })

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

  test "member access composes grants across every active group on a shared conversation" do
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

    assert Messaging.member_has_conversation_access?(
             root.message_id,
             club.club_id,
             reader.person_id,
             :read
           )

    refute Messaging.member_has_conversation_access?(
             root.message_id,
             club.club_id,
             reader.person_id,
             :write
           )

    assert Messaging.member_has_conversation_access?(
             root.message_id,
             club.club_id,
             writer.person_id,
             :read
           )

    assert Messaging.member_has_conversation_access?(
             root.message_id,
             club.club_id,
             writer.person_id,
             :write
           )

    refute Messaging.member_has_conversation_access?(
             root.message_id,
             club.club_id,
             outsider.person_id,
             :read
           )
  end

  test "member access and in-app follow actions reject a club member outside the access group" do
    club = insert_membership_club!(name: "Alpine Club")
    alice = insert_membership_person!(name: "Alice Adams", email: "alice@example.com")
    bob = insert_membership_person!(name: "Bob Builder", email: "bob@example.com")
    group = insert_group!(club.club_id, "Trip planners")
    insert_active_club_member!(club.club_id, alice.person_id)
    insert_active_club_member!(club.club_id, bob.person_id)

    root =
      insert_message!(
        club_id: club.club_id,
        sender_id: alice.person_id,
        subject: "Private trip planning"
      )

    Repo.insert!(%ConversationGroupAccessProjection{
      conversation_id: root.message_id,
      club_id: club.club_id,
      group_id: group.group_id,
      access_level: "write"
    })

    attrs = %{
      club_id: club.club_id,
      conversation_id: root.message_id,
      member_id: bob.person_id
    }

    refute Messaging.member_has_conversation_access?(
             root.message_id,
             club.club_id,
             bob.person_id,
             :read
           )

    assert {:error, :not_current_member} =
             Messaging.follow_conversation_as_current_member(attrs, consistency: :strong)

    refute Messaging.following_conversation?(root.message_id, bob.person_id)

    bob_group_membership =
      insert_active_group_member!(club.club_id, group.group_id, bob.person_id)

    assert :ok =
             Messaging.follow_conversation_as_current_member(attrs, consistency: :strong)

    assert Messaging.following_conversation?(root.message_id, bob.person_id)

    assert :ok =
             Messaging.unfollow_conversation_as_current_member(attrs, consistency: :strong)

    refute Messaging.following_conversation?(root.message_id, bob.person_id)

    assert :ok =
             Messaging.follow_conversation_as_current_member(attrs, consistency: :strong)

    assert Messaging.following_conversation?(root.message_id, bob.person_id)

    assert {:error, :conversation_not_found} =
             attrs
             |> Map.put(:club_id, Memba.ID.generate(:club))
             |> Messaging.unfollow_conversation_as_current_member(consistency: :strong)

    assert Messaging.following_conversation?(root.message_id, bob.person_id)

    from(group_membership in GroupMembership,
      where:
        group_membership.group_id == ^bob_group_membership.group_id and
          group_membership.membership_id == ^bob_group_membership.membership_id
    )
    |> Repo.update_all(set: [active: false])

    assert {:error, :not_current_member} =
             Messaging.unfollow_conversation_as_current_member(attrs, consistency: :strong)

    assert Messaging.following_conversation?(root.message_id, bob.person_id)
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
      name: name
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
