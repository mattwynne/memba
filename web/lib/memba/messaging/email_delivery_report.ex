defmodule Memba.Messaging.EmailDeliveryReport do
  @moduledoc """
  Prepare provider-neutral delivery-status commands for the Messaging aggregate.

  Webhook controllers translate and authenticate provider payloads before preparing
  and dispatching commands. The aggregate owns transition validation,
  reason normalization, and idempotency; this module only prepares commands.
  """

  alias Memba.Messaging.Commands.ReportEmailDeliveryBounced
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelayed
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelivered
  alias Memba.Messaging.Commands.ReportEmailDeliverySpamComplaint

  def delivered(attrs) when is_map(attrs) do
    with {:ok, message_id} <- required(attrs, :message_id),
         {:ok, delivery_id} <- required(attrs, :delivery_id) do
      {:ok, %ReportEmailDeliveryDelivered{message_id: message_id, delivery_id: delivery_id}}
    end
  end

  def delayed(attrs) when is_map(attrs), do: with_reason(attrs, ReportEmailDeliveryDelayed)
  def bounced(attrs) when is_map(attrs), do: with_reason(attrs, ReportEmailDeliveryBounced)

  def spam_complaint(attrs) when is_map(attrs),
    do: with_reason(attrs, ReportEmailDeliverySpamComplaint)

  defp with_reason(attrs, command_module) do
    with {:ok, message_id} <- required(attrs, :message_id),
         {:ok, delivery_id} <- required(attrs, :delivery_id),
         {:ok, reason} <- required(attrs, :reason) do
      {:ok,
       struct(command_module,
         message_id: message_id,
         delivery_id: delivery_id,
         reason: reason
       )}
    end
  end

  defp required(attrs, key) do
    string_key = Atom.to_string(key)

    case attrs do
      %{^key => value} -> {:ok, value}
      %{^string_key => value} -> {:ok, value}
      _attrs -> {:error, {:missing_required_attribute, key}}
    end
  end
end
