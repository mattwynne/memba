defmodule Memba.Messaging.Events.EmailDeliveryDelayed do
  @moduledoc """
  Event raised when a email delivery has been delayed.
  """

  @derive Jason.Encoder
  @enforce_keys [:message_id, :delivery_id, :reason]
  defstruct [:message_id, :delivery_id, :reason]
end
