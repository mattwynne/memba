defmodule Memba.Membership.Policies.RevokeSystemConversationSubscriptions do
  @moduledoc "Revokes grants backed by derived Everyone or Admin authority."

  use Commanded.Event.Handler,
    application: Memba.Membership.App,
    name: "Memba.Membership.Policies.RevokeSystemConversationSubscriptions",
    consistency: :strong,
    start_from: :origin

  alias Memba.Membership.Events.ClubMemberRemoved
  alias Memba.Membership.Events.ClubRoleRemovedFromMember
  alias Memba.Membership.Roles
  alias Memba.Messaging
  alias Memba.Messaging.App, as: MessagingApp
  alias Memba.Messaging.Projectors.PersonConversationSubscriptionsV1
  alias Memba.Messaging.Commands.RevokeSystemConversationSubscriptions

  @impl Commanded.Event.Handler
  def handle(%ClubMemberRemoved{} = event, metadata) do
    with :ok <- revoke(event, "everyone", metadata),
         :ok <- revoke(event, "admin", metadata) do
      :ok
    end
  end

  def handle(%ClubRoleRemovedFromMember{} = event, metadata) do
    if event.role_id == Roles.membership_administrator_role_id(event.club_id),
      do: revoke(event, "admin", metadata),
      else: :ok
  end

  def handle(_event, _metadata), do: :ok

  defp revoke(event, authority_kind, metadata) do
    event_id = Map.fetch!(metadata, :event_id)

    command = %RevokeSystemConversationSubscriptions{
      person_id: event.person_id,
      club_id: event.club_id,
      club_membership_id: event.membership_id,
      authority_kind: authority_kind,
      authority_through_club_stream_version: Map.fetch!(metadata, :stream_version),
      revocation_id:
        stable_uuid([
          event_id,
          event.club_id,
          event.membership_id,
          authority_kind,
          event.person_id
        ])
    }

    with result <-
           MessagingApp.dispatch(command, consistency: [PersonConversationSubscriptionsV1]),
         :ok <- normalize_dispatch(result),
         %{completed: true} <-
           Messaging.get_system_authority_subscription_revocation_receipt(command.revocation_id) do
      :ok
    else
      nil -> {:error, :system_authority_subscription_revocation_receipt_missing}
      {:error, _reason} = error -> error
    end
  end

  defp normalize_dispatch(:ok), do: :ok
  defp normalize_dispatch({:ok, _result}), do: :ok
  defp normalize_dispatch({:error, _reason} = error), do: error

  defp stable_uuid(parts) do
    <<a::32, b::16, c::16, d::16, e::48>> =
      parts
      |> Enum.join(":")
      |> then(&:crypto.hash(:sha256, &1))
      |> binary_part(0, 16)

    Ecto.UUID.cast!(
      :io_lib.format("~8.16.0b-~4.16.0b-~4.16.0b-~4.16.0b-~12.16.0b", [a, b, c, d, e])
      |> IO.iodata_to_binary()
    )
  end
end
