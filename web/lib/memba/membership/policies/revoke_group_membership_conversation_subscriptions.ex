defmodule Memba.Membership.Policies.RevokeGroupMembershipConversationSubscriptions do
  @moduledoc """
  Durably revokes Messaging grants when an exact GroupMembership ends.

  The deterministic revocation identity makes handler delivery, restart, and
  exact event replay idempotent. The person-owned subscription stream records
  its tombstone before grant revocations and its completion receipt last.
  """

  use Commanded.Event.Handler,
    application: Memba.Membership.App,
    name: "Memba.Membership.Policies.RevokeGroupMembershipConversationSubscriptions",
    consistency: :strong,
    start_from: :origin

  alias Memba.Membership.Events.GroupMembershipEnded
  alias Memba.Messaging
  alias Memba.Messaging.App, as: MessagingApp
  alias Memba.Messaging.Commands.RevokeGroupMembershipConversationSubscriptions
  alias Memba.Messaging.PersonConversationSubscriptions
  alias Memba.Messaging.Projectors.PersonConversationSubscriptionsV1
  @impl Commanded.Event.Handler
  def handle(%GroupMembershipEnded{} = event, _metadata) do
    command = %RevokeGroupMembershipConversationSubscriptions{
      person_id: event.person_id,
      group_membership_id: event.group_membership_id,
      revocation_id: PersonConversationSubscriptions.revocation_id(event.group_membership_id)
    }

    with result <-
           MessagingApp.dispatch(command, consistency: [PersonConversationSubscriptionsV1]),
         :ok <- normalize_dispatch(result),
         %{} <-
           Messaging.get_group_membership_subscription_revocation_receipt(command.revocation_id) do
      :ok
    else
      nil -> {:error, :group_membership_subscription_revocation_receipt_missing}
      {:error, _reason} = error -> error
    end
  end

  def handle(_event, _metadata), do: :ok

  defp normalize_dispatch(:ok), do: :ok
  defp normalize_dispatch({:ok, _result}), do: :ok
  defp normalize_dispatch({:error, _reason} = error), do: error
end
