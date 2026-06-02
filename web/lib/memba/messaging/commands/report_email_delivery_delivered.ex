defmodule Memba.Messaging.Commands.ReportEmailDeliveryDelivered do
  @moduledoc """
  Command to report that an email delivery was accepted by the recipient server.
  """

  @enforce_keys [:message_id, :delivery_id]
  defstruct [:message_id, :delivery_id]
end
