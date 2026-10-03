defmodule MembaWeb.LiveQuery.MembaReadModelSource do
  @moduledoc """
  Memba adapter for committed read-model notifications.

  The adapter keeps projector and event knowledge outside the generic live-query
  lifecycle package. Its invalidation tuples remain deliberately app-private.
  """

  alias LiveQuery.Source
  alias Memba.ID
  alias Memba.ReadModelChanges
  alias Memba.Messaging
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Repo

  @club_projector Memba.Membership.Projectors.Club
  @membership_projector Memba.Membership.Projectors.Membership
  @person_projector Memba.Membership.Projectors.Person
  @group_projector Memba.Membership.Projectors.Group
  @group_membership_projector Memba.Membership.Projectors.GroupMembership
  @role_projector Memba.Membership.Projectors.Role
  @message_projector Memba.Messaging.Projectors.Message
  @conversation_access_projector Memba.Messaging.Projectors.ConversationGroupAccess
  @conversation_follow_projector Memba.Messaging.Projectors.ConversationFollow
  @member_delivery_projector Memba.Messaging.Projectors.MemberEmailDelivery
  @staff_delivery_projector Memba.Messaging.Projectors.MembaStaffEmailDelivery

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
  def classify({:read_model_changed, %{projector: projector, source_event: event} = change})
      when is_atom(projector) and is_map(event) do
    changes = Map.get(change, :changes, %{})

    case projector do
      @club_projector -> classify_club_projector(event, changes)
      @membership_projector -> membership_invalidations(event, changes)
      @person_projector -> person_invalidations(event)
      @group_projector -> group_invalidations(event)
      @group_membership_projector -> group_membership_invalidations(event)
      @role_projector -> role_invalidations(event, changes)
      @message_projector -> message_invalidations(event)
      @conversation_access_projector -> conversation_access_invalidations(event)
      @conversation_follow_projector -> conversation_follow_invalidations(event)
      @member_delivery_projector -> delivery_invalidations(event, changes)
      @staff_delivery_projector -> delivery_invalidations(event, changes)
      _other_projector -> :ignore
    end
  end

  def classify(_notification), do: :ignore

  @doc false
  def matches?(interest, invalidation), do: interest == invalidation

  defp classify_club_projector(event, changes) do
    event_name = event_name(event)

    cond do
      event_name in @club_events ->
        scoped_or_fallback([{:club, field(event, :club_id)}], :club)

      event_name in @group_events ->
        group_invalidations(event)

      event_name in (@exact_role_events ++
                       @role_definition_events ++
                       @role_permission_events ++ @role_membership_removal_events) ->
        role_invalidations(event, changes)

      club_id = field(event, :club_id) ->
        {:ok, [{:fallback, :club, club_id}]}

      true ->
        {:ok, [{:fallback, :club}]}
    end
  end

  defp membership_invalidations(event, changes) do
    membership_id = field(event, :membership_id) || deep_field(changes, :membership_id)
    event_club_id = field(event, :club_id) || deep_field(changes, :club_id)
    event_person_id = field(event, :person_id) || deep_field(changes, :person_id)
    membership_scope = membership_scope(membership_id, event_club_id, event_person_id)

    club_id =
      event_club_id ||
        Map.get(membership_scope, :club_id)

    person_id =
      event_person_id ||
        Map.get(membership_scope, :person_id)

    invalidations =
      compact([
        tuple(:club_members, club_id),
        tuple(:membership, membership_id),
        tuple(:person, person_id),
        tuple(:person_clubs, person_id),
        if(is_nil(person_id), do: {:fallback, :membership})
      ])

    {:ok, invalidations}
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

    invalidations =
      compact([
        tuple(:club_groups, club_id),
        tuple(:group, group_id)
      ])

    cond do
      club_id ->
        {:ok, invalidations}

      group_id ->
        {:ok, invalidations ++ [{:fallback, :group}]}

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
        tuple(:person, person_id),
        tuple(:person_groups, club_id, person_id),
        tuple(:group_participation, club_id, group_id, person_id),
        if(is_nil(club_id) || is_nil(group_id) || is_nil(person_id),
          do: family_fallback(:group_membership, club_id)
        )
      ])

    {:ok, invalidations}
  end

  defp role_invalidations(event, changes) do
    event_name = event_name(event)
    membership_id = field(event, :membership_id) || deep_field(changes, :membership_id)
    event_club_id = field(event, :club_id) || deep_field(changes, :club_id)
    event_person_id = field(event, :person_id) || deep_field(changes, :person_id)
    membership_scope = membership_scope(membership_id, event_club_id, event_person_id)

    club_id =
      event_club_id ||
        Map.get(membership_scope, :club_id)

    person_id =
      event_person_id ||
        Map.get(membership_scope, :person_id)

    role_id = field(event, :role_id) || deep_field(changes, :role_id)

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
        compact([
          tuple(:role, role_id),
          tuple(:club_roles, club_id),
          if(is_nil(club_id), do: family_fallback(:role, club_id))
        ])
        |> scoped_or_role_fallback(club_id)

      event_name in @role_permission_events ->
        compact([
          tuple(:role, role_id),
          tuple(:club_permissions, club_id),
          if(is_nil(club_id), do: family_fallback(:role, club_id))
        ])
        |> scoped_or_role_fallback(club_id)

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
        tuple(:club_conversations, club_id),
        if(is_nil(club_id) || is_nil(conversation_id),
          do: family_fallback(:message, club_id)
        )
      ])

    {:ok, invalidations}
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
        fallback =
          if is_nil(group_id) && is_nil(club_id),
            do: {:fallback, :conversation_access}

        {:ok, compact(invalidations ++ [fallback])}

      club_id ->
        {:ok, [{:fallback, :conversation_access, club_id}]}

      true ->
        {:ok, [{:fallback, :conversation_access}]}
    end
  end

  defp conversation_follow_invalidations(event) do
    club_id = field(event, :club_id)
    conversation_id = field(event, :conversation_id) || field(event, :message_id)
    member_id = field(event, :member_id) || field(event, :sender_id)

    cond do
      conversation_id && member_id ->
        {:ok,
         [
           {:conversation_follow, conversation_id, member_id},
           {:conversation, conversation_id}
         ]}

      conversation_id ->
        {:ok, [{:conversation_follows, conversation_id}, {:conversation, conversation_id}]}

      member_id ->
        {:ok, [{:member_conversation_follows, member_id}]}

      club_id ->
        {:ok, [{:fallback, :conversation_follow, club_id}]}

      true ->
        {:ok, [{:fallback, :conversation_follow}]}
    end
  end

  defp delivery_invalidations(event, changes) do
    delivery_id = field(event, :delivery_id) || deep_field(changes, :delivery_id)

    message_id =
      field(event, :message_id) ||
        deep_field(changes, :message_id) ||
        delivery_message_id(delivery_id)

    invalidations =
      compact([
        tuple(:message_deliveries, message_id),
        tuple(:delivery, delivery_id),
        if(is_nil(message_id), do: {:fallback, :delivery})
      ])

    {:ok, invalidations}
  end

  defp delivery_message_id(nil), do: nil

  defp delivery_message_id(delivery_id) do
    case Messaging.get_member_email_delivery(delivery_id) ||
           Messaging.get_memba_staff_email_delivery(delivery_id) do
      %{message_id: message_id} -> message_id
      _missing_delivery -> nil
    end
  end

  defp membership_scope(_membership_id, club_id, person_id)
       when not is_nil(club_id) and not is_nil(person_id),
       do: %{}

  defp membership_scope(nil, _club_id, _person_id), do: %{}

  defp membership_scope(membership_id, _club_id, _person_id) do
    with {:ok, membership_id} <- ID.cast(:membership, membership_id),
         %MembershipProjection{club_id: club_id, person_id: person_id} <-
           Repo.get(MembershipProjection, membership_id) do
      %{club_id: club_id, person_id: person_id}
    else
      _missing_or_invalid_membership -> %{}
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

  defp family_fallback(family, nil), do: {:fallback, family}
  defp family_fallback(family, club_id), do: {:fallback, family, club_id}

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

  defp field(event, name), do: Map.get(event, name) || Map.get(event, Atom.to_string(name))

  defp deep_field(value, name) when is_map(value) do
    field(value, name) ||
      Enum.find_value(value, fn {_key, nested_value} ->
        deep_field(nested_value, name)
      end)
  end

  defp deep_field(value, name) when is_list(value) do
    Enum.find_value(value, &deep_field(&1, name))
  end

  defp deep_field(_value, _name), do: nil

  defp event_name(%{__struct__: module}) do
    module
    |> Module.split()
    |> List.last()
  end

  defp event_name(_event), do: nil
end
