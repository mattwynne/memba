defmodule MembaWeb.LiveQuery.MembaReadModelSource do
  @moduledoc """
  Memba adapter for committed read-model notifications.

  The adapter keeps projector and event knowledge outside the generic live-query
  lifecycle package. Its invalidation tuples remain deliberately app-private.
  """

  alias LiveQuery.Source
  alias Memba.ID

  alias Memba.Membership.Events.{
    ClubCreated,
    ClubMemberAdded,
    ClubMemberRemoved,
    ClubRoleAssignedToMember,
    ClubRoleDefined,
    ClubRolePermissionGranted,
    ClubRoleRemovedFromMember,
    ClubUpdated,
    GroupCreated,
    GroupEmailSlugAssigned,
    GroupMemberAdded,
    GroupMemberRemoved,
    MemberAdded,
    MemberRemoved,
    MemberRoleAssigned,
    MemberRoleRemoved,
    PersonCreated,
    PersonEmailAddressAdded,
    PersonEmailAddressRemoved,
    PersonEmailAddressVerified,
    PersonEmailAddressesReplaced,
    PersonPrimaryEmailAddressChanged
  }

  alias Memba.Membership.Projections.Membership, as: MembershipProjection

  alias Memba.Messaging.Events.{
    ConversationAccessGrantedToGroup,
    ConversationAccessRevokedFromGroup,
    ConversationFollowed,
    ConversationUnfollowed,
    EmailDeliveryBounced,
    EmailDeliveryCreated,
    EmailDeliveryDelayed,
    EmailDeliveryDelivered,
    EmailDeliveryOpened,
    EmailDeliverySpamComplaint,
    MessageSent
  }

  alias Memba.ReadModelChanges
  alias Memba.Repo
  alias MembaWeb.LiveQuery.ReadModelContractViolationError

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

  @person_events [
    PersonCreated,
    PersonEmailAddressAdded,
    PersonEmailAddressVerified,
    PersonEmailAddressesReplaced,
    PersonPrimaryEmailAddressChanged,
    PersonEmailAddressRemoved
  ]

  @delivery_change_events [
    EmailDeliveryCreated,
    EmailDeliveryDelivered,
    EmailDeliveryDelayed,
    EmailDeliveryBounced,
    EmailDeliverySpamComplaint
  ]

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
  def classify(
        {:read_model_changed,
         %{
           projector: projector,
           source_event: event,
           metadata: metadata,
           changes: changes
         }}
      )
      when is_atom(projector) and is_map(event) and is_map(metadata) and is_map(changes) do
    case projector do
      @club_projector -> classify_club_projector(event)
      @membership_projector -> classify_membership_projector(event)
      @person_projector -> classify_person_projector(event)
      @group_projector -> classify_group_projector(event, @group_projector)
      @group_membership_projector -> classify_group_membership_projector(event)
      @role_projector -> classify_role_projector(event, @role_projector)
      @message_projector -> classify_message_projector(event)
      @conversation_access_projector -> classify_conversation_access_projector(event)
      @conversation_follow_projector -> classify_conversation_follow_projector(event)
      @member_delivery_projector -> classify_delivery_projector(event, @member_delivery_projector)
      @staff_delivery_projector -> classify_delivery_projector(event, @staff_delivery_projector)
      _unrelated_projector -> :ignore
    end
  end

  def classify(_notification), do: :ignore

  @doc false
  def matches?(interest, invalidation), do: interest == invalidation

  defp classify_club_projector(%ClubCreated{} = event),
    do: club_invalidations(event, @club_projector)

  defp classify_club_projector(%ClubUpdated{} = event),
    do: club_invalidations(event, @club_projector)

  defp classify_club_projector(%GroupCreated{} = event),
    do: ignore_valid_noop(event, @club_projector, [:club_id, :group_id])

  defp classify_club_projector(%GroupEmailSlugAssigned{} = event),
    do: ignore_valid_noop(event, @club_projector, [:club_id, :group_id])

  defp classify_club_projector(%ClubRoleDefined{} = event),
    do: ignore_valid_noop(event, @club_projector, [:club_id, :role_id])

  defp classify_club_projector(%ClubRolePermissionGranted{} = event),
    do: ignore_valid_noop(event, @club_projector, [:club_id, :role_id])

  defp classify_club_projector(%ClubRoleAssignedToMember{} = event),
    do:
      ignore_valid_noop(
        event,
        @club_projector,
        [:club_id, :membership_id, :person_id, :role_id]
      )

  defp classify_club_projector(%ClubRoleRemovedFromMember{} = event),
    do:
      ignore_valid_noop(
        event,
        @club_projector,
        [:club_id, :membership_id, :person_id, :role_id]
      )

  defp classify_club_projector(%MemberRoleAssigned{} = event),
    do:
      ignore_valid_noop(
        event,
        @club_projector,
        [:club_id, :membership_id, :person_id, :role_id]
      )

  defp classify_club_projector(%MemberRoleRemoved{} = event),
    do:
      ignore_valid_noop(
        event,
        @club_projector,
        [:club_id, :membership_id, :person_id, :role_id]
      )

  defp classify_club_projector(event),
    do: contract_violation(@club_projector, event, :unsupported_projector_event)

  defp classify_membership_projector(%ClubMemberAdded{} = event),
    do: membership_invalidations(event, @membership_projector)

  defp classify_membership_projector(%ClubMemberRemoved{} = event),
    do: membership_invalidations(event, @membership_projector)

  defp classify_membership_projector(%MemberAdded{} = event),
    do: membership_invalidations(event, @membership_projector)

  defp classify_membership_projector(%MemberRemoved{} = event) do
    event
    |> recover_legacy_membership_scope()
    |> membership_invalidations(@membership_projector, event)
  end

  defp classify_membership_projector(event),
    do: contract_violation(@membership_projector, event, :unsupported_projector_event)

  defp classify_person_projector(event) do
    if event_module(event) in @person_events do
      with_required(@person_projector, event, [:person_id], fn %{person_id: person_id} ->
        [{:person, person_id}, {:person_emails, person_id}]
      end)
    else
      contract_violation(@person_projector, event, :unsupported_projector_event)
    end
  end

  defp classify_group_projector(%GroupCreated{} = event, projector),
    do: group_invalidations(event, projector)

  defp classify_group_projector(%GroupEmailSlugAssigned{} = event, projector),
    do: group_invalidations(event, projector)

  defp classify_group_projector(event, projector),
    do: contract_violation(projector, event, :unsupported_projector_event)

  defp classify_group_membership_projector(%GroupMemberAdded{} = event),
    do: group_membership_invalidations(event)

  defp classify_group_membership_projector(%GroupMemberRemoved{} = event),
    do: group_membership_invalidations(event)

  defp classify_group_membership_projector(event),
    do: contract_violation(@group_membership_projector, event, :unsupported_projector_event)

  defp classify_role_projector(%ClubRoleDefined{} = event, projector),
    do: role_definition_invalidations(event, projector)

  defp classify_role_projector(%ClubRolePermissionGranted{} = event, projector),
    do: role_permission_invalidations(event, projector)

  defp classify_role_projector(%ClubRoleAssignedToMember{} = event, projector),
    do: exact_role_invalidations(event, projector)

  defp classify_role_projector(%ClubRoleRemovedFromMember{} = event, projector),
    do: exact_role_invalidations(event, projector)

  defp classify_role_projector(%MemberRoleAssigned{} = event, projector),
    do: exact_role_invalidations(event, projector)

  defp classify_role_projector(%MemberRoleRemoved{} = event, projector),
    do: exact_role_invalidations(event, projector)

  defp classify_role_projector(%ClubMemberRemoved{} = event, projector),
    do: membership_role_invalidations(event, projector)

  defp classify_role_projector(%MemberRemoved{} = event, projector) do
    event
    |> recover_legacy_membership_scope()
    |> membership_role_invalidations(projector, event)
  end

  defp classify_role_projector(event, projector),
    do: contract_violation(projector, event, :unsupported_projector_event)

  defp classify_message_projector(%MessageSent{} = event) do
    with_required(@message_projector, event, [:club_id, :message_id], fn event ->
      conversation_id = event.conversation_id || event.message_id

      [
        {:message, event.message_id},
        {:conversation, conversation_id},
        {:conversation_messages, conversation_id},
        {:club_conversations, event.club_id}
      ]
    end)
  end

  defp classify_message_projector(event),
    do: contract_violation(@message_projector, event, :unsupported_projector_event)

  defp classify_conversation_access_projector(%ConversationAccessGrantedToGroup{} = event),
    do: conversation_access_invalidations(event)

  defp classify_conversation_access_projector(%ConversationAccessRevokedFromGroup{} = event),
    do: conversation_access_invalidations(event)

  defp classify_conversation_access_projector(event),
    do: contract_violation(@conversation_access_projector, event, :unsupported_projector_event)

  defp classify_conversation_follow_projector(%ConversationFollowed{} = event),
    do: explicit_follow_invalidations(event)

  defp classify_conversation_follow_projector(%ConversationUnfollowed{} = event),
    do: explicit_follow_invalidations(event)

  defp classify_conversation_follow_projector(%MessageSent{} = event) do
    event =
      require_fields(
        @conversation_follow_projector,
        event,
        [:club_id, :message_id, :sender_id]
      )

    if MessageSent.sender_follows_conversation?(event) do
      conversation_id = event.conversation_id || event.message_id

      {:ok, [{:conversation_follow, conversation_id, event.sender_id}]}
    else
      :ignore
    end
  end

  defp classify_conversation_follow_projector(event),
    do: contract_violation(@conversation_follow_projector, event, :unsupported_projector_event)

  defp classify_delivery_projector(%EmailDeliveryOpened{} = event, projector) do
    require_fields(projector, event, [:message_id, :delivery_id])
    :ignore
  end

  defp classify_delivery_projector(event, projector) do
    if event_module(event) in @delivery_change_events do
      with_required(projector, event, [:message_id, :delivery_id], fn event ->
        [
          {:message_deliveries, event.message_id},
          {:delivery, event.delivery_id}
        ]
      end)
    else
      contract_violation(projector, event, :unsupported_projector_event)
    end
  end

  defp club_invalidations(event, projector) do
    with_required(projector, event, [:club_id], fn %{club_id: club_id} ->
      [{:club, club_id}]
    end)
  end

  defp membership_invalidations(event, projector),
    do: membership_invalidations(event, projector, event)

  defp membership_invalidations(scope, projector, reported_event) do
    with_required(
      projector,
      scope,
      [:club_id, :membership_id, :person_id],
      fn scope ->
        [
          {:club_members, scope.club_id},
          {:membership, scope.membership_id},
          {:person_club, scope.club_id, scope.person_id},
          {:person_clubs, scope.person_id}
        ]
      end,
      reported_event
    )
  end

  defp group_invalidations(event, projector) do
    with_required(projector, event, [:club_id, :group_id], fn event ->
      [
        {:club_groups, event.club_id},
        {:group, event.group_id}
      ]
    end)
  end

  defp group_membership_invalidations(event) do
    with_required(
      @group_membership_projector,
      event,
      [:club_id, :group_id, :membership_id, :person_id],
      fn event ->
        [
          {:group_members, event.group_id},
          {:person_groups, event.club_id, event.person_id},
          {:group_participation, event.club_id, event.group_id, event.person_id}
        ]
      end
    )
  end

  defp role_definition_invalidations(event, projector) do
    with_required(projector, event, [:club_id, :role_id], fn event ->
      [
        {:role, event.role_id},
        {:club_roles, event.club_id}
      ]
    end)
  end

  defp role_permission_invalidations(event, projector) do
    with_required(projector, event, [:club_id, :role_id], fn event ->
      [{:club_permissions, event.club_id}]
    end)
  end

  defp exact_role_invalidations(event, projector) do
    with_required(
      projector,
      event,
      [:club_id, :membership_id, :person_id, :role_id],
      fn event ->
        [
          {:member_roles, event.club_id, event.membership_id, event.person_id},
          {:member_permissions, event.club_id, event.membership_id, event.person_id}
        ]
      end
    )
  end

  defp membership_role_invalidations(scope, projector),
    do: membership_role_invalidations(scope, projector, scope)

  defp membership_role_invalidations(scope, projector, reported_event) do
    with_required(
      projector,
      scope,
      [:club_id, :membership_id, :person_id],
      fn scope ->
        [
          {:member_roles, scope.club_id, scope.membership_id, scope.person_id},
          {:member_permissions, scope.club_id, scope.membership_id, scope.person_id}
        ]
      end,
      reported_event
    )
  end

  defp conversation_access_invalidations(event) do
    with_required(
      @conversation_access_projector,
      event,
      [:club_id, :group_id, :conversation_id],
      fn event ->
        [
          {:group_conversations, event.group_id},
          {:conversation_access, event.group_id, event.conversation_id},
          {:conversation, event.conversation_id}
        ]
      end
    )
  end

  defp explicit_follow_invalidations(event) do
    with_required(
      @conversation_follow_projector,
      event,
      [:club_id, :conversation_id, :member_id],
      fn event ->
        [{:conversation_follow, event.conversation_id, event.member_id}]
      end
    )
  end

  defp recover_legacy_membership_scope(%MemberRemoved{} = event) do
    if is_nil(event.club_id) || is_nil(event.person_id) do
      case membership_scope(event.membership_id) do
        %{club_id: club_id, person_id: person_id} ->
          %{
            membership_id: event.membership_id,
            club_id: event.club_id || club_id,
            person_id: event.person_id || person_id
          }

        %{} ->
          Map.from_struct(event)
      end
    else
      Map.from_struct(event)
    end
  end

  defp membership_scope(nil), do: %{}

  defp membership_scope(membership_id) do
    with {:ok, membership_id} <- ID.cast(:membership, membership_id),
         %MembershipProjection{club_id: club_id, person_id: person_id} <-
           Repo.get(MembershipProjection, membership_id) do
      %{club_id: club_id, person_id: person_id}
    else
      _missing_or_invalid_membership -> %{}
    end
  end

  defp ignore_valid_noop(event, projector, required_fields) do
    require_fields(projector, event, required_fields)
    :ignore
  end

  defp with_required(projector, values, required_fields, build, reported_event \\ nil) do
    values = require_fields(projector, values, required_fields, reported_event)

    {:ok, build.(values)}
  end

  defp require_fields(projector, values, required_fields, reported_event \\ nil) do
    missing_fields = Enum.filter(required_fields, &is_nil(Map.get(values, &1)))

    case missing_fields do
      [] ->
        values

      missing_fields ->
        contract_violation(
          projector,
          reported_event || values,
          {:missing_required_fields, missing_fields}
        )
    end
  end

  defp contract_violation(projector, event, reason) do
    raise ReadModelContractViolationError,
      projector: projector,
      source_event: event_module(event),
      reason: reason
  end

  defp event_module(%{__struct__: module}) when is_atom(module), do: module
  defp event_module(_event), do: :unstructured
end
