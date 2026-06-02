defmodule Memba.Messaging.Events.EmailDeliverySpamComplaint do
  @moduledoc """
  Event raised when a email delivery has a spam complaint.
  """

  @derive Jason.Encoder
  @enforce_keys [:message_id, :delivery_id, :reason]
  defstruct [:message_id, :delivery_id, :reason]
end
