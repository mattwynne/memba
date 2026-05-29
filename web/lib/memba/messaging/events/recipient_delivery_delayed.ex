defmodule Memba.Messaging.Events.RecipientDeliveryDelayed do
  @moduledoc """
  Event raised when a recipient delivery has been delayed.
  """

  @derive Jason.Encoder
  @enforce_keys [:message_id, :delivery_id, :reason]
  defstruct [:message_id, :delivery_id, :reason]
end
