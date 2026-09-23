defmodule Memba.Messaging.Projectors.PersonConversationSubscriptionsV1 do
  @moduledoc """
  Builds the canonical person-owned conversation subscription read model.

  The versioned subscription starts at origin and owns only additive canonical
  tables. Historical replay therefore cannot mutate the legacy
  `messaging_conversation_follows` projection used by current product callers.
  """

  use Commanded.Projections.Ecto,
    application: Memba.Messaging.App,
    repo: Memba.Repo,
    name: "Memba.Messaging.Projectors.PersonConversationSubscriptionsV1",
    consistency: :strong,
    start_from: :origin

  import Ecto.Query

  alias Memba.Messaging.Events.ConversationSubscriptionAuthorizationGranted
  alias Memba.Messaging.Events.ConversationSubscriptionAuthorizationRevoked
  alias Memba.Messaging.Events.ConversationSubscriptionEnded
  alias Memba.Messaging.Events.ConversationSubscriptionIntentStarted
  alias Memba.Messaging.Events.GroupMembershipSubscriptionRevocationCompleted
  alias Memba.Messaging.Events.GroupMembershipSubscriptionRevocationRecorded
  alias Memba.Messaging.Events.SystemAuthoritySubscriptionRevocationCompleted
  alias Memba.Messaging.Events.SystemAuthoritySubscriptionRevocationRecorded
  alias Memba.Messaging.Projections.ConversationSubscriptionAuthorization
  alias Memba.Messaging.Projections.GroupMembershipSubscriptionRevocationReceipt
  alias Memba.Messaging.Projections.PersonConversationSubscription
  alias Memba.Messaging.Projections.SystemAuthoritySubscriptionRevocationReceipt

  project(%ConversationSubscriptionIntentStarted{} = event, fn multi ->
    now = DateTime.utc_now(:microsecond)

    Ecto.Multi.insert(
      multi,
      {:person_conversation_subscription, event.subscription_id},
      %PersonConversationSubscription{
        subscription_id: event.subscription_id,
        person_id: event.person_id,
        conversation_id: event.conversation_id,
        effective: false,
        last_intent_id: event.subscription_intent_id,
        inserted_at: now,
        updated_at: now
      },
      on_conflict: [set: [last_intent_id: event.subscription_intent_id, updated_at: now]],
      conflict_target: :subscription_id
    )
  end)

  project(%ConversationSubscriptionAuthorizationGranted{} = event, fn multi ->
    now = DateTime.utc_now(:microsecond)

    multi
    |> Ecto.Multi.insert(
      {:conversation_subscription_authorization, event.authorization_id},
      %ConversationSubscriptionAuthorization{
        authorization_id: event.authorization_id,
        person_id: event.person_id,
        conversation_id: event.conversation_id,
        subscription_id: event.subscription_id,
        subscription_intent_id: event.subscription_intent_id,
        authority_decision_id: event.authority_decision_id,
        club_id: event.club_id,
        club_membership_id: event.club_membership_id,
        club_stream_version: event.club_stream_version,
        group_membership_id: event.group_membership_id,
        authority_kind: event.authority_kind || "group_membership",
        effective: true,
        inserted_at: now,
        updated_at: now
      },
      on_conflict: :nothing,
      conflict_target: :authorization_id
    )
    |> Ecto.Multi.update_all(
      {:activate_person_conversation_subscription, event.authorization_id},
      from(subscription in PersonConversationSubscription,
        where: subscription.subscription_id == ^event.subscription_id
      ),
      set: [effective: true, updated_at: now]
    )
  end)

  project(%ConversationSubscriptionAuthorizationRevoked{} = event, fn multi ->
    now = DateTime.utc_now(:microsecond)

    multi
    |> Ecto.Multi.update_all(
      {:revoke_conversation_subscription_authorization, event.authorization_id},
      from(authorization in ConversationSubscriptionAuthorization,
        where: authorization.authorization_id == ^event.authorization_id
      ),
      set: [
        effective: false,
        revocation_id: event.revocation_id,
        unfollow_id: event.unfollow_id,
        revocation_reason: event.reason,
        updated_at: now
      ]
    )
    |> refresh_subscription_effectiveness(event.subscription_id, event.authorization_id, now)
  end)

  project(%ConversationSubscriptionEnded{} = event, fn multi ->
    now = DateTime.utc_now(:microsecond)

    multi
    |> Ecto.Multi.update_all(
      {:end_subscription_grants, event.unfollow_id},
      from(authorization in ConversationSubscriptionAuthorization,
        where: authorization.subscription_id == ^event.subscription_id and authorization.effective
      ),
      set: [
        effective: false,
        unfollow_id: event.unfollow_id,
        revocation_reason: "unfollowed",
        updated_at: now
      ]
    )
    |> Ecto.Multi.insert(
      {:end_person_conversation_subscription, event.unfollow_id},
      %PersonConversationSubscription{
        subscription_id: event.subscription_id,
        person_id: event.person_id,
        conversation_id: event.conversation_id,
        effective: false,
        last_unfollow_id: event.unfollow_id,
        inserted_at: now,
        updated_at: now
      },
      on_conflict: [
        set: [effective: false, last_unfollow_id: event.unfollow_id, updated_at: now]
      ],
      conflict_target: :subscription_id
    )
  end)

  project(%GroupMembershipSubscriptionRevocationRecorded{} = event, fn multi ->
    now = DateTime.utc_now(:microsecond)

    Ecto.Multi.insert(
      multi,
      {:group_membership_subscription_revocation, event.revocation_id},
      %GroupMembershipSubscriptionRevocationReceipt{
        revocation_id: event.revocation_id,
        person_id: event.person_id,
        group_membership_id: event.group_membership_id,
        completed: false,
        inserted_at: now,
        updated_at: now
      },
      on_conflict: :nothing,
      conflict_target: :revocation_id
    )
  end)

  project(%GroupMembershipSubscriptionRevocationCompleted{} = event, fn multi ->
    now = DateTime.utc_now(:microsecond)

    Ecto.Multi.insert(
      multi,
      {:complete_group_membership_subscription_revocation, event.revocation_id},
      %GroupMembershipSubscriptionRevocationReceipt{
        revocation_id: event.revocation_id,
        person_id: event.person_id,
        group_membership_id: event.group_membership_id,
        completed: true,
        inserted_at: now,
        updated_at: now
      },
      on_conflict: [set: [completed: true, updated_at: now]],
      conflict_target: :revocation_id
    )
  end)

  project(%SystemAuthoritySubscriptionRevocationRecorded{} = event, fn multi ->
    now = DateTime.utc_now(:microsecond)

    Ecto.Multi.insert(
      multi,
      {:system_authority_subscription_revocation, event.revocation_id},
      %SystemAuthoritySubscriptionRevocationReceipt{
        revocation_id: event.revocation_id,
        person_id: event.person_id,
        club_id: event.club_id,
        club_membership_id: event.club_membership_id,
        authority_kind: event.authority_kind,
        authority_through_club_stream_version: event.authority_through_club_stream_version,
        completed: false,
        inserted_at: now,
        updated_at: now
      },
      on_conflict: :nothing,
      conflict_target: :revocation_id
    )
  end)

  project(%SystemAuthoritySubscriptionRevocationCompleted{} = event, fn multi ->
    now = DateTime.utc_now(:microsecond)

    Ecto.Multi.insert(
      multi,
      {:complete_system_authority_subscription_revocation, event.revocation_id},
      %SystemAuthoritySubscriptionRevocationReceipt{
        revocation_id: event.revocation_id,
        person_id: event.person_id,
        club_id: event.club_id,
        club_membership_id: event.club_membership_id,
        authority_kind: event.authority_kind,
        authority_through_club_stream_version: event.authority_through_club_stream_version,
        completed: true,
        inserted_at: now,
        updated_at: now
      },
      on_conflict: [set: [completed: true, updated_at: now]],
      conflict_target: :revocation_id
    )
  end)

  @impl Commanded.Projections.Ecto
  def after_update(event, metadata, changes) do
    Memba.ReadModelChanges.publish(__MODULE__, event, metadata, changes)
  end

  defp refresh_subscription_effectiveness(multi, subscription_id, operation_id, now) do
    Ecto.Multi.run(multi, {:refresh_subscription_effectiveness, operation_id}, fn repo,
                                                                                  _changes ->
      effective? =
        repo.exists?(
          from(authorization in ConversationSubscriptionAuthorization,
            where: authorization.subscription_id == ^subscription_id and authorization.effective
          )
        )

      {count, _rows} =
        repo.update_all(
          from(subscription in PersonConversationSubscription,
            where: subscription.subscription_id == ^subscription_id
          ),
          set: [effective: effective?, updated_at: now]
        )

      {:ok, count}
    end)
  end
end
