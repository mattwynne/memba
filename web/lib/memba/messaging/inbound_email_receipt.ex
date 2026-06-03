defmodule Memba.Messaging.InboundEmailReceipt do
  @moduledoc """
  Inbound email aggregate for provider retry identity.

  One aggregate instance represents exactly one provider inbound message id,
  keyed by `inbound-email:<provider>:<provider_message_id>`. Duplicate receives
  for the same provider message are explicit no-ops; later tasks add the
  accepted/rejected business outcome events to this stream.
  """

  alias Commanded.Aggregates.Aggregate
  alias Memba.Messaging.Commands.ReceiveInboundEmail
  alias Memba.Messaging.Events.InboundEmailReceived
  alias Memba.Messaging.InboundEmail

  @behaviour Aggregate

  defstruct [:inbound_email_id, :provider, :provider_message_id]

  @impl Aggregate
  def execute(%__MODULE__{inbound_email_id: nil}, %ReceiveInboundEmail{} = command) do
    with {:ok, inbound_email_id} <- validate_command_identity(command) do
      %InboundEmailReceived{
        inbound_email_id: inbound_email_id,
        provider: command.inbound_email.provider,
        provider_message_id: command.inbound_email.provider_message_id,
        provider_event_id: command.inbound_email.provider_event_id
      }
    end
  end

  def execute(%__MODULE__{} = receipt, %ReceiveInboundEmail{} = command) do
    with {:ok, _inbound_email_id} <- validate_command_identity(command),
         :ok <- validate_same_provider_message(receipt, command.inbound_email) do
      []
    end
  end

  @impl Aggregate
  def apply(%__MODULE__{} = receipt, %InboundEmailReceived{} = event) do
    %__MODULE__{
      receipt
      | inbound_email_id: event.inbound_email_id,
        provider: event.provider,
        provider_message_id: event.provider_message_id
    }
  end

  defp validate_command_identity(%ReceiveInboundEmail{
         inbound_email_id: inbound_email_id,
         inbound_email: %InboundEmail{} = inbound_email
       }) do
    expected_inbound_email_id = InboundEmail.identity(inbound_email)

    cond do
      not is_binary(inbound_email_id) or String.trim(inbound_email_id) == "" ->
        {:error, :invalid_inbound_email_id}

      inbound_email_id == expected_inbound_email_id ->
        {:ok, inbound_email_id}

      true ->
        {:error, :inbound_email_id_mismatch}
    end
  end

  defp validate_command_identity(%ReceiveInboundEmail{}), do: {:error, :invalid_inbound_email}

  defp validate_same_provider_message(
         %__MODULE__{provider: provider, provider_message_id: provider_message_id},
         %InboundEmail{provider: provider, provider_message_id: provider_message_id}
       ) do
    :ok
  end

  defp validate_same_provider_message(%__MODULE__{}, %InboundEmail{}) do
    {:error, :provider_message_id_mismatch}
  end
end
