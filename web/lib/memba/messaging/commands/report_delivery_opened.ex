defmodule Memba.Messaging.Commands.ReportDeliveryOpened do
  @moduledoc """
  Command to report that a recipient opened an email delivery at least once.
  """

  @enforce_keys [:message_id, :delivery_id]
  defstruct [:message_id, :delivery_id]
end
