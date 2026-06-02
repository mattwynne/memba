defmodule Memba.Messaging.Events.EmailDeliveryDelivered do
  @moduledoc """
  Event raised when a email delivery has been delivered.
  """

  @derive Jason.Encoder
  @enforce_keys [:message_id, :delivery_id]
  defstruct [:message_id, :delivery_id]
end
