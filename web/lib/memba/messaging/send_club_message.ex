defmodule Memba.Messaging.SendClubMessage do
  @moduledoc """
  Prepare a club message from a requested audience, resolving its recipients
  through Membership. No command is dispatched here.
  """

  alias Memba.ID
  alias Memba.Membership.AuthoritativeMembershipQueries
  alias Memba.Membership.ClubGroupQueries
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging.AuthorizationCheckpoint
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Recipient

  def prepare(attrs) when is_map(attrs) do
    with {:ok, message_id} <- required(attrs, :message_id),
         {:ok, club_id} <- required(attrs, :club_id),
         {:ok, club_id} <- cast_club_id(club_id),
         {:ok, sender_id} <- required(attrs, :sender_id),
         {:ok, subject} <- required(attrs, :subject),
         {:ok, body} <- required(attrs, :body),
         {:ok, audience_group} <- audience_group(attrs, club_id) do
      {:ok,
       %SendMessage{
         operation_intent: Map.get(attrs, "operation_intent"),
         message_id: message_id,
         club_id: club_id,
         sender_id: sender_id,
         audience_group_id: audience_group.group_id,
         subject: subject,
         body: body,
         recipients: recipients(club_id, audience_group.group_id)
       }}
    end
  end

  def prepare_current_member(attrs) when is_map(attrs) do
    AuthorizationCheckpoint.run(fn ->
      with {:ok, command} <- prepare(attrs),
           :ok <- authorize_sender(command) do
        {:ok, command}
      end
    end)
  end

  defp authorize_sender(%SendMessage{} = command) do
    if AuthoritativeMembershipQueries.active_member_of_group_authoritatively?(
         command.club_id,
         command.audience_group_id,
         command.sender_id
       ) do
      :ok
    else
      {:error, :not_current_member}
    end
  end

  defp audience_group(attrs, club_id) do
    group_id =
      case required(attrs, :audience_group_id) do
        {:ok, value} ->
          value

        {:error, {:missing_required_attribute, :audience_group_id}} ->
          SystemGroups.everyone_group_id(club_id)
      end

    with {:ok, group_id} <- ID.cast(:group, group_id) do
      case ClubGroupQueries.get_group(group_id) do
        %{club_id: ^club_id} = group -> {:ok, group}
        _missing_or_foreign_group -> {:error, :audience_group_not_found}
      end
    else
      :error -> {:error, :invalid_audience_group_id}
    end
  end

  defp recipients(club_id, group_id) do
    club_id
    |> AuthoritativeMembershipQueries.list_active_members_of_group_authoritatively(group_id)
    |> Enum.map(fn %{id: person_id, name: name, email: email} ->
      %Recipient{
        delivery_id: ID.generate(:delivery),
        person_id: person_id,
        name: name,
        email: email
      }
    end)
  end

  defp cast_club_id(club_id) do
    case ID.cast(:club, club_id) do
      {:ok, ^club_id} -> {:ok, club_id}
      :error -> {:error, :invalid_club_id}
    end
  end

  defp required(attrs, key) do
    string_key = Atom.to_string(key)

    case attrs do
      %{^key => value} -> {:ok, value}
      %{^string_key => value} -> {:ok, value}
      _attrs -> {:error, {:missing_required_attribute, key}}
    end
  end
end
