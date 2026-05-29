defmodule Memba.Messaging.Projections.Message do
  @moduledoc """
  Read model projection for a sent message in the Messaging bounded context.
  """

  use Ecto.Schema

  @primary_key {:message_id, :binary_id, autogenerate: false}
  schema "messaging_messages" do
    field :club_id, :binary_id
    field :sender_id, :binary_id
    field :subject, :string
    field :body, :string

    timestamps(type: :utc_datetime_usec)
  end
end
