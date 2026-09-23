defmodule Memba.Messaging.PersonConversationSubscriptionProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.ConversationSubscriptionFixtures
  alias Memba.Messaging
  alias Memba.Messaging.App
  alias Memba.Messaging.Commands.EndPersonConversationSubscription
  alias Memba.Messaging.Commands.RevokeGroupMembershipConversationSubscriptions
  alias Memba.Messaging.PersonConversationSubscriptions
  alias Memba.Messaging.Projections.ConversationFollow
  alias Memba.Messaging.Projections.GroupMembershipSubscriptionRevocationReceipt
  alias Memba.Messaging.Projectors.PersonConversationSubscriptionsV1

  test "versioned projector starts at origin without owning the legacy follow table" do
    assert %{start: {PersonConversationSubscriptionsV1, :start_link, [opts]}} =
             PersonConversationSubscriptionsV1.child_spec([])

    assert Keyword.fetch!(opts, :name) ==
             "Memba.Messaging.Projectors.PersonConversationSubscriptionsV1"

    assert Keyword.fetch!(opts, :start_from) == :origin
    assert Keyword.fetch!(opts, :consistency) == :strong
  end

  test "projects canonical grant, revocation receipt, unfollow, and replay parity" do
    ids = ConversationSubscriptionFixtures.canonical_subscription_fixture!()

    assert :ok =
             Messaging.begin_person_conversation_subscription(
               %{
                 person_id: ids.person_id,
                 conversation_id: ids.conversation_id,
                 subscription_intent_id: ids.intent_id,
                 source: :reply
               },
               consistency: [PersonConversationSubscriptionsV1]
             )

    assert %{effective: true} =
             Messaging.get_person_conversation_subscription(ids.person_id, ids.conversation_id)

    revocation_id =
      PersonConversationSubscriptions.revocation_id(ids.group_membership_id)

    assert :ok =
             App.dispatch(
               %RevokeGroupMembershipConversationSubscriptions{
                 person_id: ids.person_id,
                 group_membership_id: ids.group_membership_id,
                 revocation_id: revocation_id
               },
               consistency: [PersonConversationSubscriptionsV1]
             )

    assert %GroupMembershipSubscriptionRevocationReceipt{completed: true} =
             Messaging.get_group_membership_subscription_revocation_receipt(revocation_id)

    assert %{effective: false} =
             Messaging.get_person_conversation_subscription(ids.person_id, ids.conversation_id)

    unfollow_id = Ecto.UUID.generate()

    assert :ok =
             App.dispatch(
               %EndPersonConversationSubscription{
                 person_id: ids.person_id,
                 conversation_id: ids.conversation_id,
                 unfollow_id: unfollow_id
               },
               consistency: [PersonConversationSubscriptionsV1]
             )

    assert %{effective: false, last_unfollow_id: ^unfollow_id} =
             Messaging.get_person_conversation_subscription(ids.person_id, ids.conversation_id)

    assert [] == Messaging.list_effective_person_conversation_subscriptions(ids.person_id)
    assert 0 == Repo.aggregate(ConversationFollow, :count)

    snapshot = snapshot(ids, revocation_id)
    positions = event_sourced_projection_positions([PersonConversationSubscriptionsV1])

    Memba.EventSourcedCase.rebuild_event_sourced_projections!()
    await_event_sourced_projection_positions!(positions)

    assert ^snapshot = snapshot(ids, revocation_id)
    assert 0 == Repo.aggregate(ConversationFollow, :count)
  end

  defp snapshot(ids, revocation_id) do
    %{
      subscription:
        Messaging.get_person_conversation_subscription(ids.person_id, ids.conversation_id)
        |> schema_values(),
      grants:
        ids.person_id
        |> Messaging.list_person_conversation_subscription_grants(ids.conversation_id)
        |> Enum.map(&schema_values/1),
      receipt:
        revocation_id
        |> Messaging.get_group_membership_subscription_revocation_receipt()
        |> schema_values()
    }
  end

  defp schema_values(nil), do: nil

  defp schema_values(struct) do
    Map.take(struct, struct.__struct__.__schema__(:fields) -- [:inserted_at, :updated_at])
  end
end
