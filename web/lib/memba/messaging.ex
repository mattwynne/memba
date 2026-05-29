defmodule Memba.Messaging do
  @moduledoc """
  Public application service API for the Messaging bounded context.
  """

  alias Memba.Membership
  alias Memba.Messaging.App
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Recipient

  @doc """
  Send a message to the active members of a club.

  The service resolves recipients through Membership's public query API, builds
  a `SendMessage` command containing those resolved recipients, and dispatches it
  to the Messaging Commanded application.
  """
  def send_club_message(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- send_club_message_command(attrs) do
      App.dispatch(command, dispatch_opts)
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
end
