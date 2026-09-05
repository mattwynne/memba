defmodule Memba.Messaging.GroupEmailPostingPolicy do
  @moduledoc """
  Fixed posting policy for new group-email conversations.

  The policy is named `:club_members_only`: only active members of the
  destination club may start a conversation by email. It is deliberately fixed
  in code rather than persisted or configurable.

  Authorization uses Membership's public query API so Messaging can enforce the
  policy without coupling to Membership projection storage. Active club
  membership is currently represented by membership of the club's deterministic
  Everyone group.
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

  Returns `:ok` only when the sender person currently has an active membership in
  the destination club's deterministic Everyone group. Known people who are
  active only in other clubs, destination-club members absent from Everyone,
  inactive destination-club members, and invalid inputs are rejected without
  relying on Messaging-owned membership state.
  """
  @spec authorize(InboundClubSender.t() | term(), InboundClubDestination.t() | term()) ::
          :ok | rejection()
  def authorize(
        %InboundClubSender{} = sender,
        %InboundClubDestination{} = destination
      ) do
    everyone_group_id = SystemGroups.everyone_group_id(destination.club_id)

    if Membership.active_member_of_group?(everyone_group_id, sender.person_id) do
      :ok
    else
      {:error, :sender_not_active_member, rejection_details(sender, destination)}
    end
  end

  def authorize(_sender, _destination), do: {:error, :invalid_inbound_authorization, nil}

  defp rejection_details(%InboundClubSender{} = sender, %InboundClubDestination{} = destination) do
    %{
      sender_id: sender.person_id,
      club_id: destination.club_id,
      from_address: sender.from_address,
      to_address: destination.to_address
    }
  end
end
