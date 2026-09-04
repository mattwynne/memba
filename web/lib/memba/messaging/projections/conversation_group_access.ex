defmodule Memba.Messaging.Projections.ConversationGroupAccess do
  @moduledoc """
  Read model projection for a group's access to a message conversation.
  """

  use Ecto.Schema

  @primary_key false
  schema "messaging_conversation_group_access" do
    field :conversation_id, :string
    field :club_id, :string
    field :group_id, :string
    field :access_level, :string

    timestamps(type: :utc_datetime_usec)
  end
end
