defmodule Memba.Messaging.Commands.ReportEmailDeliveryOpened do
  @moduledoc """
  Legacy command kept only so historic/test-support code can compile.

  Current Messaging behaviour does not route, dispatch, or emit opened delivery
  reports.
  """

  @enforce_keys [:message_id, :delivery_id]
  defstruct [:message_id, :delivery_id]
end
