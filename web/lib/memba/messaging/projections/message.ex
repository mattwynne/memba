defmodule Memba.Messaging.Projections.Message do
  @moduledoc """
  Read model projection for a sent message in the Messaging bounded context.
  """

  use Ecto.Schema

  @primary_key {:message_id, :string, autogenerate: false}
  schema "messaging_messages" do
    field :club_id, :string
    field :sender_id, :string
    field :conversation_id, :string
    field :reply_to_message_id, :string
    field :subject, :string
    field :body, :string

    timestamps(type: :utc_datetime_usec)
  end
end
