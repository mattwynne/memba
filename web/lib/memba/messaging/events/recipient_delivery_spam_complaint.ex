defmodule Memba.Messaging.Events.RecipientDeliverySpamComplaint do
  @moduledoc """
  Event raised when a recipient delivery has a spam complaint.
  """

  @derive Jason.Encoder
  @enforce_keys [:message_id, :delivery_id, :reason]
  defstruct [:message_id, :delivery_id, :reason]
end
