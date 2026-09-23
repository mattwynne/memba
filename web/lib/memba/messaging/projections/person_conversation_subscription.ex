defmodule Memba.Messaging.Projections.PersonConversationSubscription do
  @moduledoc "Current canonical effective subscription read model."
  use Ecto.Schema

  @primary_key {:subscription_id, :string, autogenerate: false}
  schema "messaging_person_conversation_subscriptions" do
    field :person_id, :string
    field :conversation_id, :string
    field :effective, :boolean, default: false
    field :last_intent_id, :string
    field :last_unfollow_id, :string
    timestamps(type: :utc_datetime_usec)
  end
end
