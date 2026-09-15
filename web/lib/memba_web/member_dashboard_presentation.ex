defmodule MembaWeb.MemberDashboardPresentation do
  @moduledoc """
  Loads and shapes data for the member dashboard LiveView.

  The LiveView owns the route/session boundary; this helper owns the selected
  club and group authorization checks and presentation-friendly row data so the
  mount path stays readable and the dashboard data model can be unit-tested
  directly.
  """

  alias Memba.Accounts
  alias Memba.ClubInboundEmailAddress
  alias Memba.ID
  alias Memba.Membership
  alias Memba.Membership.Authorization
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging

  @participant_avatar_limit 3

  @doc """
  Load Everyone dashboard assigns for a signed-in active member of the selected
  club.

  Returns `{:ok, assigns}` when the selected club belongs to the current
  identity and the identity can be resolved to an active member row. Missing,
  invalid, inactive, or unauthorized club/member combinations return
  `{:error, :forbidden}` so the LiveView can preserve existing route semantics.
  """
  def load(club_id, current_identity, active_clubs)
      when is_list(active_clubs) do
    with {:ok, club_id} <- cast_selected_club_id(club_id),
         everyone_group_id = SystemGroups.everyone_group_id(club_id) do
      case load_authorized_group(
             club_id,
             current_identity,
             active_clubs,
             everyone_group_id
           ) do
        {:error, :not_found} -> {:error, :forbidden}
        result -> result
      end
    else
      _missing_or_unauthorized -> {:error, :forbidden}
    end
  end

  def load(_club_id, _current_identity, _active_clubs), do: {:error, :forbidden}

  @doc """
  Load dashboard assigns scoped to an explicitly selected conversation group.

  The group identity is resolved from Membership's safe discovery summaries
  after the signed-in identity has been resolved to an active member of the
  selected club. Participating members receive the member and conversation
  surfaces, club admins outside the group receive only its membership surface,
  and ordinary non-members receive neither private surface. Missing, invalid,
  and foreign-club group selections return `{:error, :not_found}` without
  disclosing which condition applied. Club and identity authorization failures
  continue to return `{:error, :forbidden}`.
  """
  def load(club_id, current_identity, active_clubs, nil) when is_list(active_clubs) do
    load(club_id, current_identity, active_clubs)
  end

  def load(club_id, current_identity, active_clubs, selected_group_id)
      when is_list(active_clubs) do
    with {:ok, club_id} <- cast_selected_club_id(club_id),
         {:ok, selected_group_id} <- cast_selected_group_id(selected_group_id) do
      load_authorized_group(club_id, current_identity, active_clubs, selected_group_id)
    else
      {:error, :not_found} -> {:error, :not_found}
      _missing_or_unauthorized -> {:error, :forbidden}
    end
  end

  def load(_club_id, _current_identity, _active_clubs, _selected_group_id),
    do: {:error, :forbidden}

  defp load_authorized_group(club_id, current_identity, active_clubs, selected_group_id) do
    with {:ok, selected_club} <- fetch_selected_club(active_clubs, club_id),
         club_members <- load_club_members(club_id),
         {:ok, current_member} <- fetch_current_member(club_members, current_identity) do
      groups = Membership.list_discoverable_groups_for_member(club_id, current_member.id)

      participating_groups_by_id =
        club_id
        |> Membership.list_active_groups_for_member(current_member.id)
        |> Map.new(&{&1.group_id, &1})

      groups = mark_group_participation(groups, participating_groups_by_id)
      current_member_can_manage_members? = can_manage_members?(club_id, current_member)

      load_selected_group(
        selected_club,
        current_member,
        club_members,
        groups,
        participating_groups_by_id,
        selected_group_id,
        current_member_can_manage_members?
      )
    else
      _missing_or_unauthorized -> {:error, :forbidden}
    end
  end

  defp mark_group_participation(groups, participating_groups_by_id) do
    Enum.map(groups, fn group ->
      Map.put(group, :participating?, Map.has_key?(participating_groups_by_id, group.group_id))
    end)
  end

  defp load_selected_group(
         selected_club,
         current_member,
         club_members,
         groups,
         participating_groups_by_id,
         selected_group_id,
         current_member_can_manage_members?
       ) do
    with {:ok, selected_group} <- fetch_selected_group(groups, selected_group_id) do
      {selected_group, surface_assigns} =
        load_permitted_surface(
          selected_group,
          Map.get(participating_groups_by_id, selected_group_id),
          selected_club,
          current_member_can_manage_members?
        )

      admission_assigns =
        custom_group_admission_assigns(
          selected_group,
          club_members,
          surface_assigns
        )

      {:ok,
       surface_assigns
       |> Map.merge(admission_assigns)
       |> Map.merge(%{
         page_title: selected_club.name,
         selected_club: selected_club,
         groups: groups,
         selected_group: selected_group,
         current_member: current_member,
         current_member_can_manage_members?: current_member_can_manage_members?,
         club_admin_email_address:
           ClubInboundEmailAddress.address(
             selected_club.slug,
             SystemGroups.admin_email_slug()
           )
       })}
    else
      _missing_or_unauthorized -> {:error, :not_found}
    end
  end

  defp custom_group_admission_assigns(
         selected_group,
         club_members,
         %{selected_group_access: selected_group_access, members: members}
       ) do
    can_add_members? =
      SystemGroups.custom_group?(selected_group) and
        selected_group_access in [:participating_member, :outside_admin]

    can_add_self? = can_add_members? and selected_group_access == :outside_admin

    candidates =
      if can_add_members? do
        active_group_member_ids = MapSet.new(members, & &1.id)

        Enum.reject(club_members, fn candidate ->
          MapSet.member?(active_group_member_ids, candidate.id)
        end)
      else
        []
      end

    %{
      can_add_custom_group_members?: can_add_members?,
      can_add_self_to_custom_group?: can_add_self?,
      custom_group_member_candidates: candidates
    }
  end

  defp load_permitted_surface(
         _discovered_group,
         participating_group,
         _selected_club,
         _current_member_can_manage_members?
       )
       when is_map(participating_group) do
    members = load_group_members(participating_group.group_id)
    messages = load_messages(participating_group.group_id)
    member_names_by_id = Map.new(members, &{&1.id, &1.name})

    {participating_group,
     %{
       selected_group_access: :participating_member,
       selected_group_participating?: true,
       members: members,
       active_member_count: Enum.count(members),
       member_names_by_id: member_names_by_id,
       messages: messages,
       message_rows: present_message_rows(messages, member_names_by_id)
     }}
  end

  defp load_permitted_surface(selected_group, nil, selected_club, true) do
    members = load_group_members(selected_group.group_id)
    member_names_by_id = Map.new(members, &{&1.id, &1.name})

    selected_group =
      selected_group
      |> Map.put(:active_member_count, Enum.count(members))
      |> Map.put(:email_address, managed_group_email_address(selected_club, selected_group))

    {selected_group,
     %{
       selected_group_access: :outside_admin,
       selected_group_participating?: false,
       members: members,
       active_member_count: Enum.count(members),
       member_names_by_id: member_names_by_id,
       messages: [],
       message_rows: []
     }}
  end

  defp load_permitted_surface(selected_group, nil, _selected_club, false) do
    selected_group =
      selected_group
      |> Map.put(:active_member_count, nil)
      |> Map.put(:email_address, nil)

    {selected_group,
     %{
       selected_group_access: :ordinary_non_member,
       selected_group_participating?: false,
       members: [],
       active_member_count: 0,
       member_names_by_id: %{},
       messages: [],
       message_rows: []
     }}
  end

  defp managed_group_email_address(selected_club, selected_group) do
    case Membership.get_group(selected_group.group_id) do
      %{club_id: club_id, email_slug: email_slug}
      when club_id == selected_group.club_id ->
        ClubInboundEmailAddress.address(selected_club.slug, email_slug)

      _missing_or_foreign_group ->
        nil
    end
  end

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

  defp cast_selected_group_id(group_id) do
    case ID.cast(:group, group_id) do
      {:ok, group_id} -> {:ok, group_id}
      :error -> {:error, :not_found}
    end
  end

  defp fetch_selected_group(groups, group_id) do
    case Enum.find(groups, &(&1.group_id == group_id)) do
      nil -> {:error, :not_found}
      selected_group -> {:ok, selected_group}
    end
  end

  defp load_club_members(club_id) do
    club_id
    |> Membership.list_active_members_of_club()
    |> Enum.map(&present_member/1)
  end

  defp load_group_members(group_id) do
    group_id
    |> Membership.list_active_members_of_group()
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

  defp load_messages(group_id), do: Messaging.list_conversations_for_group(group_id)

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
