defmodule Memba.Messaging.InboundClubAuthorization do
  @moduledoc """
  Everyone-group authorization for inbound club-message email.

  Authorization deliberately uses Membership's public query API so Messaging can
  enforce posting rules without coupling to Membership projection storage.
  """

  alias Memba.Membership
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging.InboundClubDestination
  alias Memba.Messaging.InboundClubSender

  @type rejection_reason :: :sender_not_active_member | :invalid_inbound_authorization
  @type rejection_details :: %{
          sender_id: String.t(),
          club_id: String.t(),
          from_address: String.t(),
          to_address: String.t()
        }
  @type rejection :: {:error, rejection_reason(), rejection_details() | nil}

  @doc """
  Authorize a resolved sender to post to a resolved club destination.

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
