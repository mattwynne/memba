defmodule Memba.Messaging.Projections.ConversationFollow do
  @moduledoc """
  Read model projection for a member's follow state on a message conversation.
  """

  use Ecto.Schema

  @primary_key {:follow_id, :string, autogenerate: false}
  schema "messaging_conversation_follows" do
    field :club_id, :string
    field :conversation_id, :string
    field :member_id, :string
    field :following, :boolean, default: true

    timestamps(type: :utc_datetime_usec)
  end
end
