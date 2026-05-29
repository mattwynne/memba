defmodule Memba.Messaging.Commands.ReportDeliveryBounced do
  @moduledoc """
  Command to report that an email delivery bounced.
  """

  @enforce_keys [:message_id, :delivery_id, :reason]
  defstruct [:message_id, :delivery_id, :reason]
end
