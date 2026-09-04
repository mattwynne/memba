defmodule Memba.Messaging.ConversationGroupAccessProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Messaging
  alias Memba.Messaging.Events.ConversationAccessGrantedToGroup
  alias Memba.Messaging.Projectors.ConversationGroupAccess, as: ConversationGroupAccessProjector
  alias Memba.Messaging.Projections.ConversationGroupAccess, as: ConversationGroupAccessProjection

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

  defp projector_metadata(event_number) do
    %{
      handler_name: "conversation-group-access-projection-test-#{Ecto.UUID.generate()}",
      event_number: event_number
    }
  end
end
