defmodule Memba.Messaging do
  @moduledoc """
  Public application service API for the Messaging bounded context.
  """

  alias Memba.Membership
  alias Memba.Messaging.App
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.DeliveryProvider
  alias Memba.Messaging.DeliveryRequest
  alias Memba.Messaging.Recipient

  @doc """
  Send a message to the active members of a club.

  The service resolves recipients through Membership's public query API, builds
  a `SendMessage` command containing those resolved recipients, and dispatches it
  to the Messaging Commanded application.
  """
  def send_club_message(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- send_club_message_command(attrs),
         {:ok, dispatch_result} <- dispatch_send_message(command, dispatch_opts),
         :ok <- deliver_to_provider(command) do
      dispatch_result
    end
  end

  defp dispatch_send_message(%SendMessage{} = command, dispatch_opts) do
    case App.dispatch(command, dispatch_opts) do
      :ok -> {:ok, :ok}
      {:ok, _result} = ok -> {:ok, ok}
      {:error, _reason} = error -> error
    end
  end

  defp send_club_message_command(attrs) do
    with {:ok, message_id} <- fetch_required(attrs, :message_id),
         {:ok, club_id} <- fetch_required(attrs, :club_id),
         {:ok, sender_id} <- fetch_required(attrs, :sender_id),
         {:ok, subject} <- fetch_required(attrs, :subject),
         {:ok, body} <- fetch_required(attrs, :body) do
      {:ok,
       %SendMessage{
         message_id: message_id,
         club_id: club_id,
         sender_id: sender_id,
         subject: subject,
         body: body,
         recipients: resolve_recipients(club_id)
       }}
    end
  end

  defp fetch_required(attrs, key) do
    case Map.fetch(attrs, key) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, {:missing_required_attribute, key}}
    end
  end

  defp resolve_recipients(club_id) do
    club_id
    |> Membership.list_active_members_of_club()
    |> Enum.map(&resolved_recipient/1)
  end

  defp resolved_recipient(%{id: person_id, name: name, email: email}) do
    %Recipient{
      delivery_id: Ecto.UUID.generate(),
      person_id: person_id,
      name: name,
      email: email
    }
  end

  defp deliver_to_provider(%SendMessage{} = command) do
    Enum.reduce_while(command.recipients, :ok, fn %Recipient{} = recipient, :ok ->
      case DeliveryProvider.deliver(delivery_request(command, recipient)) do
        :ok -> {:cont, :ok}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
  end

  defp delivery_request(%SendMessage{} = command, %Recipient{} = recipient) do
    %DeliveryRequest{
      message_id: command.message_id,
      delivery_id: recipient.delivery_id,
      recipient_id: recipient.person_id,
      recipient_name: recipient.name,
      recipient_address: recipient.email,
      channel: :email,
      subject: command.subject,
      body: command.body
    }
  end
end
