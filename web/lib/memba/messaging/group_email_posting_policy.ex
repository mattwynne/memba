defmodule Memba.Messaging.GroupEmailPostingPolicy do
  @moduledoc """
  Fixed posting policy for new group-email conversations.

  The policy is named `:club_members_only`: active club members may post to
  system groups, while custom-group roots additionally require current
  participation in the destination group. It is deliberately fixed in code
  rather than persisted or configurable.

  Authorization uses Membership's public authoritative API so Messaging can
  enforce the policy without coupling to Membership aggregate or projection
  storage.
  """

  alias Memba.Membership
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging.InboundClubDestination
  alias Memba.Messaging.InboundClubSender

  @fixed_name :club_members_only

  @type name :: :club_members_only
  @type rejection_reason :: :sender_not_active_member | :invalid_inbound_authorization
  @type rejection_details :: %{
          sender_id: String.t(),
          club_id: String.t(),
          from_address: String.t(),
          to_address: String.t()
        }
  @type rejection :: {:error, rejection_reason(), rejection_details() | nil}

  @doc "Return the stable name of the fixed group-email posting policy."
  @spec name() :: name()
  def name, do: @fixed_name

  @doc """
  Authorize a resolved sender under the fixed group-email posting policy.

  Returns `:ok` when the sender is active in the destination club and, for a
  custom group, currently participates in that group. Existing Everyone and
  Admin posting semantics remain club-members-only. Known people who are active
  only in other clubs, inactive destination-club members, absent custom-group
  members, and invalid inputs are rejected without relying on Messaging-owned
  membership state.
  """
  @spec authorize(InboundClubSender.t() | term(), InboundClubDestination.t() | term()) ::
          :ok | rejection()
  def authorize(
        %InboundClubSender{} = sender,
        %InboundClubDestination{} = destination
      ) do
    if authorized_sender?(sender, destination) do
      :ok
    else
      {:error, :sender_not_active_member, rejection_details(sender, destination)}
    end
  end

  def authorize(_sender, _destination), do: {:error, :invalid_inbound_authorization, nil}

  defp authorized_sender?(sender, destination) do
    Membership.active_member_of_club_authoritatively?(destination.club_id, sender.person_id) and
      (not SystemGroups.custom_group?(destination) or
         Membership.active_member_of_group_authoritatively?(
           destination.club_id,
           destination.group_id,
           sender.person_id
         ))
  end

  defp rejection_details(%InboundClubSender{} = sender, %InboundClubDestination{} = destination) do
    %{
      sender_id: sender.person_id,
      club_id: destination.club_id,
      from_address: sender.from_address,
      to_address: destination.to_address
    }
  end
end
