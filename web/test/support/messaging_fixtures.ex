defmodule Memba.MessagingFixtures do
  @moduledoc """
  Shared fixtures for member-facing Messaging projection tests.

  Member web surfaces read conversations through group access grants, so these
  fixtures create the message projection and its root-conversation grant
  together.
  """

  alias Memba.Membership.SystemGroups
  alias Memba.Messaging.Projections.ConversationGroupAccess
  alias Memba.Messaging.Projections.Message
  alias Memba.Repo

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
