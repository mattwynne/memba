defmodule Memba.Messaging.Commands.EndPersonConversationSubscription do
  @moduledoc """
  Records an explicit unfollow in the person's subscription stream.

  It cancels older intents and ends their grants before the final subscription
  tombstone is appended.
  """

  @enforce_keys [:person_id, :conversation_id, :unfollow_id]
  defstruct @enforce_keys
end
