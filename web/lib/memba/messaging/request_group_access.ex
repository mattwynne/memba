defmodule Memba.Messaging.RequestGroupAccess do
  @moduledoc """
  Prepare a current member's request to join a custom group as an ordinary
  message to the club Admin group. Dispatch belongs to the Messaging API.
  """

  alias Memba.ID
  alias Memba.Membership
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging.AuthorizationCheckpoint
  alias Memba.Messaging.Commands.RequestGroupAccess, as: Request
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Recipient
  alias MembaWeb.ClubSite

  def prepare(attrs) when is_map(attrs) do
    with {:ok, request} <- parse_request(attrs) do
      AuthorizationCheckpoint.run(fn -> prepare_message(request) end)
    end
  end

  defp parse_request(attrs) do
    with {:ok, message_id} <- required_id(attrs, :message_id, :message),
         {:ok, club_id} <- required_id(attrs, :club_id, :club),
         {:ok, requester_person_id} <- required_id(attrs, :requester_person_id, :person),
         {:ok, group_id} <- required_id(attrs, :group_id, :group) do
      {:ok,
       %Request{
         operation_intent: Map.get(attrs, "operation_intent"),
         message_id: message_id,
         club_id: club_id,
         requester_person_id: requester_person_id,
         group_id: group_id
       }}
    end
  end

  defp prepare_message(%Request{} = request) do
    with {:ok, target} <-
           Membership.resolve_custom_group_target_authoritatively(
             request.club_id,
             request.requester_person_id,
             request.group_id
           ),
         :ok <- reject_current_group_member(target) do
      admin_group_id = SystemGroups.admin_group_id(target.club.club_id)

      {:ok,
       %SendMessage{
         operation_intent: request.operation_intent,
         message_id: request.message_id,
         club_id: target.club.club_id,
         sender_id: target.person.person_id,
         audience_group_id: admin_group_id,
         subject: "Access request: #{target.group.name}",
         body: body(target),
         recipients: recipients(target.club.club_id, admin_group_id)
       }}
    end
  end

  defp reject_current_group_member(%{active_group_member?: false}), do: :ok
  defp reject_current_group_member(%{active_group_member?: true}), do: {:error, :already_member}

  defp body(target) do
    add_url =
      ClubSite.url(
        target.club,
        "/groups/#{target.group.group_id}/members/add/#{target.person.person_id}"
      )

    """
    #{target.person.name} would like to join #{target.group.name}.

    #{target.person.name} asked from #{target.group.name}'s page in #{target.club.name}.

    Add #{target.person.name} to #{target.group.name}:
    #{add_url}

    You'll confirm on the website before #{target.person.name} is added.
    """
  end

  defp recipients(club_id, admin_group_id) do
    club_id
    |> Membership.list_active_members_of_group_authoritatively(admin_group_id)
    |> Enum.map(fn %{id: person_id, name: name, email: email} ->
      %Recipient{
        delivery_id: ID.generate(:delivery),
        person_id: person_id,
        name: name,
        email: email
      }
    end)
  end

  defp required_id(attrs, key, type) do
    string_key = Atom.to_string(key)

    value =
      case attrs do
        %{^key => value} -> {:ok, value}
        %{^string_key => value} -> {:ok, value}
        _attrs -> {:error, {:missing_required_attribute, key}}
      end

    with {:ok, value} <- value do
      case ID.cast(type, value) do
        {:ok, ^value} -> {:ok, value}
        :error -> {:error, invalid_id_reason(key)}
      end
    end
  end

  defp invalid_id_reason(:message_id), do: :invalid_message_id
  defp invalid_id_reason(:club_id), do: :invalid_club_id
  defp invalid_id_reason(:requester_person_id), do: :invalid_person_id
  defp invalid_id_reason(:group_id), do: :invalid_group_id
end
