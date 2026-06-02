defmodule Memba.Messaging.Events.EmailDeliveryOpened do
  @moduledoc """
  Event raised when a email delivery has been opened at least once.
  """

  @derive Jason.Encoder
  @enforce_keys [:message_id, :delivery_id]
  defstruct [:message_id, :delivery_id]
end
