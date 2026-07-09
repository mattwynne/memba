defmodule MembaWeb.MemberDashboardPresentation do
  @moduledoc """
  Loads and shapes data for the member dashboard LiveView.

  The LiveView owns the route/session boundary; this helper owns the selected
  club authorization checks and presentation-friendly row data so the mount path
  stays readable and the dashboard data model can be unit-tested directly.
  """

  alias Memba.Accounts
  alias Memba.ID
  alias Memba.Membership
  alias Memba.Membership.Authorization
  alias Memba.Messaging

  @participant_avatar_limit 3

  @doc """
  Load dashboard assigns for a signed-in active member of the selected club.

  Returns `{:ok, assigns}` when the selected club belongs to the current
  identity and the identity can be resolved to an active member row. Missing,
  invalid, inactive, or unauthorized club/member combinations return
  `{:error, :forbidden}` so the LiveView can preserve existing route semantics.
  """
  def load(club_id, current_identity, active_clubs)
      when is_list(active_clubs) do
    with {:ok, club_id} <- cast_selected_club_id(club_id),
         {:ok, selected_club} <- fetch_selected_club(active_clubs, club_id),
         members <- load_members(club_id),
         {:ok, current_member} <- fetch_current_member(members, current_identity) do
      messages = load_messages(club_id)
      member_names_by_id = Map.new(members, &{&1.id, &1.name})
      message_rows = present_message_rows(messages, member_names_by_id)

      {:ok,
       %{
         page_title: selected_club.name,
         selected_club: selected_club,
         members: members,
         active_member_count: Enum.count(members),
         current_member: current_member,
         current_member_can_manage_members?: can_manage_members?(club_id, current_member),
         member_names_by_id: member_names_by_id,
         messages: messages,
         message_rows: message_rows
       }}
    else
      _missing_or_unauthorized -> {:error, :forbidden}
    end
  end

  def load(_club_id, _current_identity, _active_clubs), do: {:error, :forbidden}

  defp cast_selected_club_id(club_id) do
    case ID.cast(:club, club_id) do
      {:ok, club_id} -> {:ok, club_id}
      :error -> {:error, :forbidden}
    end
  end

  defp fetch_selected_club(active_clubs, club_id) do
    case Enum.find(active_clubs, fn club -> club.club_id == club_id end) do
      nil -> {:error, :forbidden}
      selected_club -> {:ok, selected_club}
    end
  end

  defp load_members(club_id) do
    club_id
    |> Membership.list_active_members_of_club()
    |> Enum.map(&present_member/1)
  end

  defp fetch_current_member(_members, nil), do: {:error, :forbidden}

  defp fetch_current_member(members, identity) do
    identity_email =
      identity
      |> Map.get(:email)
      |> Accounts.normalize_email()

    case Enum.find(members, fn member ->
           Accounts.normalize_email(member.email) == identity_email
         end) do
      nil -> {:error, :forbidden}
      current_member -> {:ok, current_member}
    end
  end

  defp can_manage_members?(club_id, %{id: person_id}) do
    Authorization.authorize_manage_members(club_id, person_id) == :ok
  end

  defp can_manage_members?(_club_id, _current_member), do: false

  defp load_messages(club_id) do
    Messaging.list_conversations_for_club(club_id)
  end

  @doc """
  Shapes recent conversation rows for dashboard rendering.

  The row data uses the root message's originator and `inserted_at` value, folds
  replies into a count/latest-replier summary, and intentionally omits delivery
  glance fields from the club home. Rows without `inserted_at` leave the label
  empty instead of inventing placeholder copy.
  """
  def present_message_rows(conversations, member_names_by_id)
      when is_list(conversations) and is_map(member_names_by_id) do
    Enum.map(conversations, fn conversation ->
      message_id = conversation.message_id
      conversation_id = Map.get(conversation, :conversation_id, message_id) || message_id
      reply_count = Map.get(conversation, :reply_count, 0) || 0
      latest_replier_id = Map.get(conversation, :latest_replier_id)
      originator_name = Map.get(member_names_by_id, conversation.sender_id, "Club member")
      originator_initials = initials(originator_name)
      latest_replier_name = latest_replier_name(conversation)
      participant_ids = participant_ids(conversation)
      participants = present_participants(participant_ids, member_names_by_id)

      %{
        message: Map.get(conversation, :message),
        message_id: message_id,
        conversation_id: conversation_id,
        sender_id: conversation.sender_id,
        sender_name: originator_name,
        sender_initials: originator_initials,
        originator_id: conversation.sender_id,
        originator_name: originator_name,
        originator_initials: originator_initials,
        subject: conversation.subject,
        body: conversation.body,
        sent_at: conversation.inserted_at,
        sent_at_label: sent_at_label(conversation.inserted_at),
        reply_count: reply_count,
        latest_replier_id: latest_replier_id,
        latest_replier_name: latest_replier_name,
        reply_activity_label: reply_activity_label(reply_count, latest_replier_name),
        participants: participants,
        additional_participant_count: additional_participant_count(participant_ids, participants)
      }
    end)
  end

  def present_message_rows(_conversations, _member_names_by_id), do: []

  defp present_member(member) do
    initials = initials(member.name)

    member
    |> Map.put(:roles, Map.get(member, :roles, []))
    |> Map.put(:initials, initials)
    |> Map.put(:avatar_initials, initials)
  end

  defp initials(name) when is_binary(name) do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map_join("", fn <<first::utf8, _rest::binary>> -> String.upcase(<<first::utf8>>) end)
    |> case do
      "" -> "?"
      value -> value
    end
  end

  defp initials(_name), do: "?"

  defp latest_replier_name(%{latest_replier_name: name}) when is_binary(name), do: name
  defp latest_replier_name(_conversation), do: nil

  defp participant_ids(conversation) do
    case Map.get(conversation, :participant_ids, []) do
      participant_ids when is_list(participant_ids) -> participant_ids
      _missing_or_unexpected -> []
    end
  end

  defp present_participants(participant_ids, member_names_by_id) do
    participant_ids
    |> Enum.take(@participant_avatar_limit)
    |> Enum.map(fn participant_id ->
      name = Map.get(member_names_by_id, participant_id, "Club member")

      %{
        id: participant_id,
        name: name,
        initials: initials(name)
      }
    end)
  end

  defp additional_participant_count(participant_ids, participants) do
    max(Enum.count(participant_ids) - Enum.count(participants), 0)
  end

  defp reply_activity_label(0, _latest_replier_name), do: "No replies yet"

  defp reply_activity_label(reply_count, latest_replier_name) when is_integer(reply_count) do
    reply_word = if reply_count == 1, do: "reply", else: "replies"
    latest_replier_name = latest_replier_name || "Club member"

    "#{reply_count} #{reply_word} · latest from #{latest_replier_name}"
  end

  defp reply_activity_label(_reply_count, _latest_replier_name), do: "No replies yet"

  defp sent_at_label(%DateTime{} = sent_at), do: Calendar.strftime(sent_at, "%b %d, %Y")
  defp sent_at_label(_sent_at), do: nil
end
