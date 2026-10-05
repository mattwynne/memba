defmodule Memba.Messaging.ConversationGroupAccessPreparationTest do
  use ExUnit.Case, async: true

  alias Memba.ID
  alias Memba.Messaging.ConversationGroupAccess
  alias Memba.Messaging.Commands.GrantConversationAccessToGroup
  alias Memba.Messaging.Commands.GrantInitialConversationAccessToGroup
  alias Memba.Messaging.Commands.RevokeConversationAccessFromGroup

  setup do
    {:ok,
     attrs: %{
       conversation_id: ID.generate(:message),
       club_id: ID.generate(:club),
       group_id: ID.generate(:group)
     }}
  end

  test "prepares both grant variants with normalized access without dispatching", %{attrs: attrs} do
    for {prepare, command_type} <- [
          {:prepare_grant, GrantConversationAccessToGroup},
          {:prepare_initial_grant, GrantInitialConversationAccessToGroup}
        ] do
      assert {:ok, command} =
               apply(ConversationGroupAccess, prepare, [Map.put(attrs, :access_level, " WRITE ")])

      assert command.__struct__ == command_type
      assert Map.take(command, [:conversation_id, :club_id, :group_id]) == attrs
      assert command.access_level == "write"
    end
  end

  test "prepares revocation without requiring an access level", %{attrs: attrs} do
    assert {:ok, %RevokeConversationAccessFromGroup{} = command} =
             ConversationGroupAccess.prepare_revoke(attrs)

    assert Map.take(command, [:conversation_id, :club_id, :group_id]) == attrs
  end

  test "accepts string keys and prefers atom keys", %{attrs: attrs} do
    string_attrs = Map.new(attrs, fn {key, value} -> {Atom.to_string(key), value} end)

    assert {:ok, %GrantConversationAccessToGroup{access_level: "read"}} =
             ConversationGroupAccess.prepare_grant(Map.put(string_attrs, "access_level", :read))

    assert {:error, :invalid_group_id} =
             ConversationGroupAccess.prepare_revoke(Map.put(string_attrs, :group_id, nil))
  end

  test "preserves required-field ordering and typed ID errors", %{attrs: attrs} do
    assert {:error, {:missing_required_attribute, :conversation_id}} =
             ConversationGroupAccess.prepare_grant(%{})

    assert {:error, {:missing_required_attribute, :club_id}} =
             ConversationGroupAccess.prepare_revoke(%{conversation_id: attrs.conversation_id})

    for {key, wrong_type, reason} <- [
          {:conversation_id, :club, :invalid_conversation_id},
          {:club_id, :person, :invalid_club_id},
          {:group_id, :message, :invalid_group_id}
        ] do
      for prepare <- [:prepare_grant, :prepare_initial_grant, :prepare_revoke] do
        assert {:error, ^reason} =
                 apply(ConversationGroupAccess, prepare, [
                   attrs |> Map.put(key, ID.generate(wrong_type)) |> Map.put(:access_level, :read)
                 ])
      end
    end
  end

  test "grant variants require a valid access level, while revoke ignores it", %{attrs: attrs} do
    for prepare <- [:prepare_grant, :prepare_initial_grant] do
      assert {:error, {:missing_required_attribute, :access_level}} =
               apply(ConversationGroupAccess, prepare, [attrs])

      assert {:error, :invalid_access_level} =
               apply(ConversationGroupAccess, prepare, [Map.put(attrs, :access_level, nil)])
    end

    assert {:ok, %RevokeConversationAccessFromGroup{}} =
             ConversationGroupAccess.prepare_revoke(Map.put(attrs, :access_level, :invalid))
  end
end
