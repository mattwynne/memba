defmodule MembaWeb.LiveQuery.MembaReadModelSource do
  @moduledoc """
  Provisional Memba adapter for committed read-model notifications.

  The adapter keeps projector and event knowledge outside the generic live-query
  lifecycle. Its invalidation tuples are deliberately app-private while the
  dashboard and conversation-detail integrations prove the eventual contract.
  """

  alias Memba.ReadModelChanges
  alias MembaWeb.LiveQuery.Source

  @club_projector Memba.Membership.Projectors.Club
  @membership_projector Memba.Membership.Projectors.Membership
  @person_projector Memba.Membership.Projectors.Person
  @group_projector Memba.Membership.Projectors.Group
  @group_membership_projector Memba.Membership.Projectors.GroupMembership
  @role_projector Memba.Membership.Projectors.Role
  @message_projector Memba.Messaging.Projectors.Message
  @conversation_access_projector Memba.Messaging.Projectors.ConversationGroupAccess

  @club_events ~w(ClubCreated ClubUpdated)
  @group_events ~w(GroupCreated GroupEmailSlugAssigned)
  @exact_role_events ~w(
    ClubRoleAssignedToMember
    ClubRoleRemovedFromMember
    MemberRoleAssigned
    MemberRoleRemoved
  )
  @role_definition_events ~w(ClubRoleDefined)
  @role_permission_events ~w(ClubRolePermissionGranted)
  @role_membership_removal_events ~w(ClubMemberRemoved MemberRemoved)

  @doc """
  Builds the shared ReadModelChanges source used by member live queries.
  """
  @spec new() :: Source.t()
  def new do
    Source.new!(
      subscribe: &subscribe/0,
      classify: &classify/1,
      matches?: &matches?/2
    )
  end

  @doc false
  def subscribe do
    Phoenix.PubSub.subscribe(Memba.PubSub, ReadModelChanges.topic())
  end

  @doc false
  def classify({:read_model_changed, %{projector: projector, source_event: event}})
      when is_atom(projector) and is_map(event) do
    case projector do
      @club_projector -> classify_club_projector(event)
      @membership_projector -> membership_invalidations(event)
      @person_projector -> person_invalidations(event)
      @group_projector -> group_invalidations(event)
      @group_membership_projector -> group_membership_invalidations(event)
      @role_projector -> role_invalidations(event)
      @message_projector -> message_invalidations(event)
      @conversation_access_projector -> conversation_access_invalidations(event)
      _other_projector -> :ignore
    end
  end

  def classify(_notification), do: :ignore

  @doc false
  def matches?(interest, invalidation), do: interest == invalidation

  defp classify_club_projector(event) do
    event_name = event_name(event)

    cond do
      event_name in @club_events ->
        scoped_or_fallback([{:club, field(event, :club_id)}], :club)

      event_name in @group_events ->
        group_invalidations(event)

      event_name in (@exact_role_events ++
                       @role_definition_events ++
                       @role_permission_events ++ @role_membership_removal_events) ->
        role_invalidations(event)

      club_id = field(event, :club_id) ->
        {:ok, [{:fallback, :club, club_id}]}

      true ->
        {:ok, [{:fallback, :club}]}
    end
  end

  defp membership_invalidations(event) do
    club_id = field(event, :club_id)
    membership_id = field(event, :membership_id)
    person_id = field(event, :person_id)

    invalidations =
      compact([
        tuple(:club_members, club_id),
        tuple(:membership, membership_id),
        tuple(:person, person_id),
        tuple(:person_clubs, person_id)
      ])

    case {club_id, person_id, invalidations} do
      {nil, nil, _invalidations} -> {:ok, [{:fallback, :membership}]}
      {_club_id, _person_id, []} -> {:ok, [{:fallback, :membership}]}
      _scoped -> {:ok, invalidations}
    end
  end

  defp person_invalidations(event) do
    case field(event, :person_id) do
      nil -> {:ok, [{:fallback, :person}]}
      person_id -> {:ok, [{:person, person_id}, {:person_emails, person_id}]}
    end
  end

  defp group_invalidations(event) do
    club_id = field(event, :club_id)
    group_id = field(event, :group_id)

    cond do
      club_id && group_id ->
        {:ok, [{:club_groups, club_id}, {:group, group_id}]}

      club_id ->
        {:ok, [{:club_groups, club_id}]}

      true ->
        {:ok, [{:fallback, :group}]}
    end
  end

  defp group_membership_invalidations(event) do
    club_id = field(event, :club_id)
    group_id = field(event, :group_id)
    person_id = field(event, :person_id)

    invalidations =
      compact([
        tuple(:group_members, group_id),
        tuple(:person_groups, club_id, person_id),
        tuple(:group_participation, club_id, group_id, person_id),
        missing_scope_fallback(:group_membership, club_id, person_id)
      ])

    case invalidations do
      [] when not is_nil(club_id) ->
        {:ok, [{:fallback, :group_membership, club_id}]}

      [] ->
        {:ok, [{:fallback, :group_membership}]}

      invalidations ->
        {:ok, invalidations}
    end
  end

  defp role_invalidations(event) do
    event_name = event_name(event)
    club_id = field(event, :club_id)
    membership_id = field(event, :membership_id)
    person_id = field(event, :person_id)
    role_id = field(event, :role_id)

    cond do
      event_name in @exact_role_events ->
        member_roles = tuple(:member_roles, club_id, membership_id, person_id)
        member_permissions = tuple(:member_permissions, club_id, membership_id, person_id)

        compact([
          member_roles,
          member_permissions,
          tuple(:role, role_id),
          missing_scope_fallback(:role, club_id, member_roles)
        ])
        |> scoped_or_role_fallback(club_id)

      event_name in @role_definition_events ->
        scoped_or_role_fallback(
          compact([tuple(:role, role_id), tuple(:club_roles, club_id)]),
          club_id
        )

      event_name in @role_permission_events ->
        scoped_or_role_fallback(
          compact([tuple(:role, role_id), tuple(:club_permissions, club_id)]),
          club_id
        )

      event_name in @role_membership_removal_events ->
        member_roles = tuple(:member_roles, club_id, membership_id, person_id)

        compact([
          member_roles,
          tuple(:member_permissions, club_id, membership_id, person_id),
          tuple(:club_permissions, club_id),
          missing_scope_fallback(:role, club_id, member_roles)
        ])
        |> scoped_or_role_fallback(club_id)

      club_id ->
        {:ok, [{:fallback, :role, club_id}]}

      true ->
        {:ok, [{:fallback, :role}]}
    end
  end

  defp message_invalidations(event) do
    club_id = field(event, :club_id)
    message_id = field(event, :message_id)
    conversation_id = field(event, :conversation_id) || message_id

    invalidations =
      compact([
        tuple(:message, message_id),
        tuple(:conversation, conversation_id),
        tuple(:conversation_messages, conversation_id),
        tuple(:club_conversations, club_id)
      ])

    cond do
      club_id || conversation_id -> {:ok, invalidations}
      true -> {:ok, [{:fallback, :message}]}
    end
  end

  defp conversation_access_invalidations(event) do
    club_id = field(event, :club_id)
    group_id = field(event, :group_id)
    conversation_id = field(event, :conversation_id)

    invalidations =
      compact([
        tuple(:group_conversations, group_id),
        tuple(:club_conversations, if(is_nil(group_id), do: club_id)),
        tuple(:conversation_access, group_id, conversation_id),
        tuple(:conversation, conversation_id),
        tuple(:group, group_id)
      ])

    cond do
      group_id || conversation_id ->
        {:ok, invalidations}

      club_id ->
        {:ok, [{:fallback, :conversation_access, club_id}]}

      true ->
        {:ok, [{:fallback, :conversation_access}]}
    end
  end

  defp scoped_or_fallback(invalidations, family) do
    case compact(invalidations) do
      [] -> {:ok, [{:fallback, family}]}
      invalidations -> {:ok, invalidations}
    end
  end

  defp scoped_or_role_fallback([], nil), do: {:ok, [{:fallback, :role}]}
  defp scoped_or_role_fallback([], club_id), do: {:ok, [{:fallback, :role, club_id}]}
  defp scoped_or_role_fallback(invalidations, _club_id), do: {:ok, invalidations}

  defp missing_scope_fallback(_family, _club_id, scoped) when not is_nil(scoped), do: nil
  defp missing_scope_fallback(family, nil, nil), do: {:fallback, family}
  defp missing_scope_fallback(family, club_id, nil), do: {:fallback, family, club_id}

  defp tuple(_name, nil), do: nil
  defp tuple(name, value), do: {name, value}

  defp tuple(_name, nil, _value), do: nil
  defp tuple(_name, _value, nil), do: nil
  defp tuple(name, first, second), do: {name, first, second}

  defp tuple(_name, nil, _second, _third), do: nil
  defp tuple(_name, _first, nil, _third), do: nil
  defp tuple(_name, _first, _second, nil), do: nil
  defp tuple(name, first, second, third), do: {name, first, second, third}

  defp compact(invalidations) do
    invalidations
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp field(event, name), do: Map.get(event, name)

  defp event_name(%{__struct__: module}) do
    module
    |> Module.split()
    |> List.last()
  end

  defp event_name(_event), do: nil
end
