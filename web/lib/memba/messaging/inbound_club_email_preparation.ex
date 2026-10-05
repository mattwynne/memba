defmodule Memba.Messaging.InboundClubEmailPreparation do
  @moduledoc """
  Resolve and authorize a newly received club email before posting it.

  This is only the first-post decision. The caller must durably receive the
  email before preparing it, and must retain its committed-message recovery
  path and receipt commands after preparation. A rejected decision is data for
  that receipt path, not a command dispatch or a sent rejection email.
  """

  alias Memba.Messaging.AuthorizationCheckpoint
  alias Memba.Messaging.GroupEmailPostingPolicy
  alias Memba.Messaging.InboundClubDestination
  alias Memba.Messaging.InboundClubSender
  alias Memba.Messaging.InboundEmail

  @doc "Return resolved posting context, a rejection decision, or a transient authorization error."
  def prepare(%InboundEmail{} = inbound_email) do
    case InboundClubDestination.resolve(inbound_email) do
      {:ok, %InboundClubDestination{} = destination} ->
        prepare_sender(inbound_email, destination)

      {:error, reason, to_address} ->
        {:reject, to_address, rejection_reason(reason), []}
    end
  end

  @doc "Authorize a resolved sender at the stable membership projection checkpoint."
  def authorize(sender, destination) do
    case AuthorizationCheckpoint.run(fn ->
           case GroupEmailPostingPolicy.authorize(sender, destination) do
             :ok -> {:ok, :authorized}
             {:error, _reason, _details} = error -> error
           end
         end) do
      {:ok, :authorized} -> :ok
      {:error, _reason, _details} = error -> error
      {:error, _reason} = error -> error
    end
  end

  defp prepare_sender(inbound_email, destination) do
    case InboundClubSender.resolve(inbound_email) do
      {:ok, %InboundClubSender{} = sender} ->
        case authorize(sender, destination) do
          :ok ->
            {:ok, destination, sender}

          {:error, reason, _details} ->
            {:reject, destination.to_address, rejection_reason(reason),
             club_name: destination.club_name}

          {:error, _reason} = error ->
            error
        end

      {:error, reason, _details} ->
        {:reject, destination.to_address, rejection_reason(reason),
         club_name: destination.club_name}
    end
  end

  defp rejection_reason(reason) when is_atom(reason), do: Atom.to_string(reason)
  defp rejection_reason(reason) when is_binary(reason), do: reason
end
