defmodule Memba.Messaging.Commands.ReportEmailDeliveryOpened do
  @moduledoc """
  DEPRECATED: Open tracking has been removed from Memba.

  This compatibility struct is retained for historic opened-report command
  data, but it is no longer routed by `Memba.Messaging.Router`. Attempting to
  dispatch this command will raise `Commanded.Router.UnregisteredCommandError`.
  """

  @enforce_keys [:message_id, :delivery_id]
  defstruct [:message_id, :delivery_id]
end
