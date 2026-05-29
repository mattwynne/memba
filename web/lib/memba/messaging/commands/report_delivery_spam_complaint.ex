defmodule Memba.Messaging.Commands.ReportDeliverySpamComplaint do
  @moduledoc """
  Command to report that a recipient marked an email delivery as spam.
  """

  @enforce_keys [:message_id, :delivery_id, :reason]
  defstruct [:message_id, :delivery_id, :reason]
end
