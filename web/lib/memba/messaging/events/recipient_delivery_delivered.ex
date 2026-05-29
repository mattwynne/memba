defmodule Memba.Messaging.Events.RecipientDeliveryDelivered do
  @moduledoc """
  Event raised when a recipient delivery has been delivered.
  """

  @derive Jason.Encoder
  @enforce_keys [:message_id, :delivery_id]
  defstruct [:message_id, :delivery_id]
end
