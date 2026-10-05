defmodule MembaWeb.EmailDeliveryStatusAdapter do
  @moduledoc false

  alias Memba.Messaging.CommandDispatch
  alias Memba.Messaging.EmailDeliveryReport

  def report(attrs, status) do
    with {:ok, command} <- prepare(attrs, status),
         {:ok, _result} <- CommandDispatch.dispatch(command) do
      :ok
    end
  end

  defp prepare(attrs, :delivered), do: EmailDeliveryReport.delivered(attrs)
  defp prepare(attrs, :delayed), do: EmailDeliveryReport.delayed(attrs)
  defp prepare(attrs, :bounced), do: EmailDeliveryReport.bounced(attrs)
  defp prepare(attrs, :spam_complaint), do: EmailDeliveryReport.spam_complaint(attrs)
end
