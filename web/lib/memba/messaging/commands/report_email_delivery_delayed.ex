defmodule Memba.Messaging.Commands.ReportEmailDeliveryDelayed do
  @moduledoc """
  Command to report that an email delivery was temporarily delayed.
  """

  @enforce_keys [:message_id, :delivery_id, :reason]
  defstruct [:message_id, :delivery_id, :reason]
end
