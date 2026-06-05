defmodule Memba.Messaging.InboundEmailReceipt do
  @moduledoc """
  Inbound email aggregate for provider retry identity.

  One aggregate instance represents exactly one provider inbound message id,
  keyed by a deterministic `inb_...` ID derived from provider and provider message. Duplicate receives
  for the same provider message are explicit no-ops; accepted/rejected business
  outcomes are recorded in this same stream.
  """

  alias Commanded.Aggregates.Aggregate
  alias Memba.ID
  alias Memba.Messaging.Commands.AcceptInboundClubEmail
  alias Memba.Messaging.Commands.RejectInboundClubEmail
  alias Memba.Messaging.Commands.ReceiveInboundEmail
  alias Memba.Messaging.Events.InboundClubEmailAccepted
  alias Memba.Messaging.Events.InboundClubEmailRejected
  alias Memba.Messaging.Events.InboundEmailReceived
  alias Memba.Messaging.InboundEmail

  @behaviour Aggregate

  defstruct [
    :inbound_email_id,
    :provider,
    :provider_message_id,
    :status,
    :message_id,
    :rejection_reason
  ]

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

  def execute(%__MODULE__{inbound_email_id: nil}, %AcceptInboundClubEmail{} = command) do
    with {:ok, _inbound_email_id} <- validate_command_identity(command) do
      {:error, :inbound_email_not_received}
    end
  end

  def execute(%__MODULE__{status: nil} = receipt, %AcceptInboundClubEmail{} = command) do
    with {:ok, inbound_email_id} <- validate_command_identity(command),
         :ok <- validate_same_provider_message(receipt, command.inbound_email),
         :ok <- validate_id(:club, command.club_id, :invalid_club_id),
         :ok <- validate_id(:person, command.sender_id, :invalid_sender_id),
         :ok <- validate_id(:message, command.message_id, :invalid_message_id),
         {:ok, to_address} <- normalize_email(command.to_address, :invalid_to_address) do
      %InboundClubEmailAccepted{
        inbound_email_id: inbound_email_id,
        provider: command.inbound_email.provider,
        provider_message_id: command.inbound_email.provider_message_id,
        provider_event_id: command.inbound_email.provider_event_id,
        from_address: command.inbound_email.from_address,
        to_address: to_address,
        club_id: command.club_id,
        sender_id: command.sender_id,
        message_id: command.message_id
      }
    end
  end

  def execute(%__MODULE__{status: :accepted} = receipt, %AcceptInboundClubEmail{} = command) do
    with {:ok, _inbound_email_id} <- validate_command_identity(command),
         :ok <- validate_same_provider_message(receipt, command.inbound_email),
         :ok <- validate_same_accepted_message(receipt, command.message_id) do
      []
    end
  end

  def execute(%__MODULE__{status: :rejected} = receipt, %AcceptInboundClubEmail{} = command) do
    with {:ok, _inbound_email_id} <- validate_command_identity(command),
         :ok <- validate_same_provider_message(receipt, command.inbound_email) do
      {:error, :inbound_email_already_rejected}
    end
  end

  def execute(%__MODULE__{inbound_email_id: nil}, %RejectInboundClubEmail{} = command) do
    with {:ok, _inbound_email_id} <- validate_command_identity(command) do
      {:error, :inbound_email_not_received}
    end
  end

  def execute(%__MODULE__{status: nil} = receipt, %RejectInboundClubEmail{} = command) do
    with {:ok, inbound_email_id} <- validate_command_identity(command),
         :ok <- validate_same_provider_message(receipt, command.inbound_email),
         {:ok, to_address} <- normalize_optional_email(command.to_address, :invalid_to_address),
         {:ok, rejection_reason} <- normalize_rejection_reason(command.rejection_reason),
         {:ok, rejection_email_delivery_reference} <-
           normalize_optional_string(
             command.rejection_email_delivery_reference,
             :invalid_rejection_email_delivery_reference
           ) do
      %InboundClubEmailRejected{
        inbound_email_id: inbound_email_id,
        provider: command.inbound_email.provider,
        provider_message_id: command.inbound_email.provider_message_id,
        provider_event_id: command.inbound_email.provider_event_id,
        from_address: command.inbound_email.from_address,
        to_address: to_address,
        rejection_reason: rejection_reason,
        rejection_email_delivery_reference: rejection_email_delivery_reference
      }
    end
  end

  def execute(%__MODULE__{status: :rejected} = receipt, %RejectInboundClubEmail{} = command) do
    with {:ok, _inbound_email_id} <- validate_command_identity(command),
         :ok <- validate_same_provider_message(receipt, command.inbound_email),
         :ok <- validate_same_rejection_reason(receipt, command.rejection_reason) do
      []
    end
  end

  def execute(%__MODULE__{status: :accepted} = receipt, %RejectInboundClubEmail{} = command) do
    with {:ok, _inbound_email_id} <- validate_command_identity(command),
         :ok <- validate_same_provider_message(receipt, command.inbound_email) do
      {:error, :inbound_email_already_accepted}
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

  def apply(%__MODULE__{} = receipt, %InboundClubEmailAccepted{} = event) do
    %__MODULE__{
      receipt
      | status: :accepted,
        message_id: event.message_id
    }
  end

  def apply(%__MODULE__{} = receipt, %InboundClubEmailRejected{} = event) do
    %__MODULE__{
      receipt
      | status: :rejected,
        rejection_reason: event.rejection_reason
    }
  end

  defp validate_command_identity(%ReceiveInboundEmail{
         inbound_email_id: inbound_email_id,
         inbound_email: %InboundEmail{} = inbound_email
       }) do
    expected_inbound_email_id = InboundEmail.identity(inbound_email)

    cond do
      ID.cast(:inbound_email, inbound_email_id) == :error ->
        {:error, :invalid_inbound_email_id}

      inbound_email_id == expected_inbound_email_id ->
        {:ok, inbound_email_id}

      true ->
        {:error, :inbound_email_id_mismatch}
    end
  end

  defp validate_command_identity(%ReceiveInboundEmail{}), do: {:error, :invalid_inbound_email}

  defp validate_command_identity(%AcceptInboundClubEmail{
         inbound_email_id: inbound_email_id,
         inbound_email: %InboundEmail{} = inbound_email
       }) do
    expected_inbound_email_id = InboundEmail.identity(inbound_email)

    cond do
      ID.cast(:inbound_email, inbound_email_id) == :error ->
        {:error, :invalid_inbound_email_id}

      inbound_email_id == expected_inbound_email_id ->
        {:ok, inbound_email_id}

      true ->
        {:error, :inbound_email_id_mismatch}
    end
  end

  defp validate_command_identity(%AcceptInboundClubEmail{}), do: {:error, :invalid_inbound_email}

  defp validate_command_identity(%RejectInboundClubEmail{
         inbound_email_id: inbound_email_id,
         inbound_email: %InboundEmail{} = inbound_email
       }) do
    expected_inbound_email_id = InboundEmail.identity(inbound_email)

    cond do
      ID.cast(:inbound_email, inbound_email_id) == :error ->
        {:error, :invalid_inbound_email_id}

      inbound_email_id == expected_inbound_email_id ->
        {:ok, inbound_email_id}

      true ->
        {:error, :inbound_email_id_mismatch}
    end
  end

  defp validate_command_identity(%RejectInboundClubEmail{}), do: {:error, :invalid_inbound_email}

  defp validate_same_provider_message(
         %__MODULE__{provider: provider, provider_message_id: provider_message_id},
         %InboundEmail{provider: provider, provider_message_id: provider_message_id}
       ) do
    :ok
  end

  defp validate_same_provider_message(%__MODULE__{}, %InboundEmail{}) do
    {:error, :provider_message_id_mismatch}
  end

  defp validate_same_accepted_message(%__MODULE__{message_id: message_id}, message_id), do: :ok

  defp validate_same_accepted_message(%__MODULE__{}, _message_id) do
    {:error, :inbound_email_already_accepted}
  end

  defp validate_same_rejection_reason(
         %__MODULE__{rejection_reason: rejection_reason},
         rejection_reason
       ) do
    :ok
  end

  defp validate_same_rejection_reason(%__MODULE__{}, _rejection_reason) do
    {:error, :inbound_email_already_rejected}
  end

  defp validate_id(type, value, error) do
    case ID.cast(type, value) do
      {:ok, ^value} -> :ok
      _other -> {:error, error}
    end
  end

  defp normalize_email(email, error) when is_binary(email) do
    email = email |> String.trim() |> String.downcase()

    if valid_email?(email) do
      {:ok, email}
    else
      {:error, error}
    end
  end

  defp normalize_email(_email, error), do: {:error, error}

  defp normalize_optional_email(nil, _error), do: {:ok, nil}
  defp normalize_optional_email(email, error), do: normalize_email(email, error)

  defp normalize_rejection_reason(reason) when is_binary(reason) do
    case String.trim(reason) do
      "" -> {:error, :invalid_rejection_reason}
      reason -> {:ok, reason}
    end
  end

  defp normalize_rejection_reason(_reason), do: {:error, :invalid_rejection_reason}

  defp normalize_optional_string(nil, _error), do: {:ok, nil}

  defp normalize_optional_string(value, _error) when is_binary(value) do
    case String.trim(value) do
      "" -> {:ok, nil}
      value -> {:ok, value}
    end
  end

  defp normalize_optional_string(_value, error), do: {:error, error}

  defp valid_email?(email) do
    case String.split(email, "@") do
      [local, domain] -> local != "" and domain != "" and String.contains?(domain, ".")
      _parts -> false
    end
  end
end
