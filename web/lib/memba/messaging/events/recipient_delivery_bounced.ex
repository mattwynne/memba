defmodule Memba.Messaging.Events.RecipientDeliveryBounced do
  @moduledoc """
  Event raised when a recipient delivery has bounced.
  """

  @derive Jason.Encoder
  @enforce_keys [:message_id, :delivery_id, :reason]
  defstruct [:message_id, :delivery_id, :reason]
end
