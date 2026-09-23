defmodule Memba.Messaging.Projections.ConversationSubscriptionAuthorization do
  @moduledoc "Canonical read model for one exact subscription authority grant."
  use Ecto.Schema

  @primary_key {:authorization_id, :string, autogenerate: false}
  schema "messaging_conversation_subscription_authorizations" do
    field :person_id, :string
    field :conversation_id, :string
    field :subscription_id, :string
    field :subscription_intent_id, :string
    field :authority_decision_id, :string
    field :club_membership_id, :string
    field :group_membership_id, :string
    field :effective, :boolean, default: true
    field :revocation_id, :string
    field :unfollow_id, :string
    field :revocation_reason, :string
    timestamps(type: :utc_datetime_usec)
  end
end
