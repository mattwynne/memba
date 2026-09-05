defmodule Memba.MessagingFixtures do
  @moduledoc """
  Shared fixtures for member-facing Messaging projection tests.

  These fixtures intentionally insert read-model rows directly; domain and projector
  behaviour is covered separately by Messaging tests.

  Inserting a root message (where `message_id == conversation_id`) also creates its
  conversation-to-group access grant. Inserting a reply creates only the message row,
  so the root message and its grant must already exist.
  """

  alias Memba.Membership.SystemGroups
  alias Memba.Messaging.Projections.ConversationGroupAccess
  alias Memba.Messaging.Projections.Message
  alias Memba.Repo

  @doc """
  Insert a projected message for a group-accessible conversation.

  Root messages receive a grant for `:audience_group_id` (Everyone by default) at
  the requested `:access_level` (`"write"` by default). Replies are identified by a
  different `:conversation_id` and assume the root and grant were inserted first.
  """
  def insert_group_accessible_message!(attrs) when is_list(attrs) do
    message_id = Keyword.get_lazy(attrs, :message_id, fn -> Memba.ID.generate(:message) end)
    club_id = Keyword.fetch!(attrs, :club_id)

    message =
      Repo.insert!(%Message{
        message_id: message_id,
        club_id: club_id,
        sender_id: Keyword.fetch!(attrs, :sender_id),
        conversation_id: Keyword.get(attrs, :conversation_id, message_id),
        reply_to_message_id: Keyword.get(attrs, :reply_to_message_id),
        subject: Keyword.fetch!(attrs, :subject),
        body: Keyword.get(attrs, :body, "Message body"),
        inserted_at: Keyword.get(attrs, :inserted_at),
        updated_at: Keyword.get(attrs, :updated_at, Keyword.get(attrs, :inserted_at))
      })

    if message.message_id == message.conversation_id do
      Repo.insert!(%ConversationGroupAccess{
        conversation_id: message.message_id,
        club_id: club_id,
        group_id:
          Keyword.get_lazy(attrs, :audience_group_id, fn ->
            SystemGroups.everyone_group_id(club_id)
          end),
        access_level: Keyword.get(attrs, :access_level, "write")
      })
    end

    message
  end
end
