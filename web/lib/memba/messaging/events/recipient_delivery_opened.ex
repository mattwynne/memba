defmodule Memba.Messaging.Events.RecipientDeliveryOpened do
  @moduledoc """
  Event raised when a recipient delivery has been opened at least once.
  """

  @derive Jason.Encoder
  @enforce_keys [:message_id, :delivery_id]
  defstruct [:message_id, :delivery_id]
end
