defmodule Memba.Messaging.Commands.ReportEmailDeliveryOpened do
  @moduledoc """
  Compatibility struct for historic opened-report command data.

  Memba no longer routes this command or records email opens as current
  behaviour.
  """

  @enforce_keys [:message_id, :delivery_id]
  defstruct [:message_id, :delivery_id]
end
