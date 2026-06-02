defmodule Memba.Messaging.Events.EmailDeliveryBounced do
  @moduledoc """
  Event raised when a email delivery has bounced.
  """

  @derive Jason.Encoder
  @enforce_keys [:message_id, :delivery_id, :reason]
  defstruct [:message_id, :delivery_id, :reason]
end
