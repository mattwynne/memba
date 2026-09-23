defmodule Memba.Membership.RemoveCustomGroupMemberRevocationIntegrationTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.ConversationSubscriptionFixtures
  alias Memba.Membership
  alias Memba.Membership.App, as: MembershipApp
  alias Memba.Membership.Club
  alias Memba.Membership.CustomGroupRemoval
  alias Memba.Membership.Policies.RevokeGroupMembershipConversationSubscriptions
  alias Memba.Messaging
  alias Memba.Messaging.App, as: MessagingApp
  alias Memba.Messaging.Events.ConversationSubscriptionAuthorizationGranted
  alias Memba.Messaging.Events.ConversationSubscriptionAuthorizationRevoked
  alias Memba.Messaging.Events.GroupMembershipSubscriptionRevocationCompleted
  alias Memba.Messaging.Events.GroupMembershipSubscriptionRevocationRecorded
  alias Memba.Messaging.PersonConversationSubscriptions
  alias Memba.Messaging.Projectors.PersonConversationSubscriptionsV1

  test "unavailable policy prevents success and durable retry completes once after restart" do
    ids = ConversationSubscriptionFixtures.canonical_subscription_fixture!()
    assert :ok = subscribe(ids)
    assert [grant] = grants(ids)
    assert grant.effective

    operation_id = Ecto.UUID.generate()
    attrs = removal_attrs(ids, operation_id)
    previous_timeout = Application.get_env(:commanded, :dispatch_consistency_timeout)

    Application.put_env(:commanded, :dispatch_consistency_timeout, 100)

    policy_pid = revocation_policy_pid!()
    :ok = :sys.suspend(policy_pid)

    on_exit(fn ->
      try do
        :sys.resume(policy_pid)
      catch
        :exit, _reason -> :ok
      end

      if previous_timeout do
        Application.put_env(:commanded, :dispatch_consistency_timeout, previous_timeout)
      else
        Application.delete_env(:commanded, :dispatch_consistency_timeout)
      end
    end)

    assert {:error, failure} =
             Membership.remove_custom_group_member(attrs, consistency: :strong)

    assert failure == :consistency_timeout
    revocation_id = PersonConversationSubscriptions.revocation_id(ids.group_membership_id)

    refute Messaging.group_membership_subscription_revocation_completed?(
             ids.person_id,
             ids.group_membership_id,
             revocation_id
           )

    :ok = :sys.resume(policy_pid)

    club = MembershipApp.aggregate_state(Club, ids.club_id)

    assert :ok =
             Commanded.Subscriptions.wait_for(
               MembershipApp,
               ids.club_id,
               club.stream_version,
               consistency: [RevokeGroupMembershipConversationSubscriptions]
             )

    Memba.EventSourcedCase.stop_event_sourced_aggregate_instances!()

    assert {:ok,
            %CustomGroupRemoval{
              removal_operation_id: ^operation_id,
              revocation_id: ^revocation_id,
              subscription_revocation_completed: true
            }} = Membership.remove_custom_group_member(attrs, consistency: :strong)

    refute Messaging.following_conversation?(ids.conversation_id, ids.person_id)
    assert [ended_grant] = grants(ids)
    refute ended_grant.effective

    assert [
             GroupMembershipSubscriptionRevocationRecorded,
             ConversationSubscriptionAuthorizationRevoked,
             GroupMembershipSubscriptionRevocationCompleted
           ] == revocation_fact_modules(ids)
  end

  test "authorization delayed until after public removal cannot pass the revocation tombstone" do
    ids = ConversationSubscriptionFixtures.canonical_subscription_fixture!()
    parent = self()

    Application.put_env(:memba, :conversation_subscription_authority_issued_hook, fn _decision ->
      send(parent, {:authority_issued, self()})

      receive do
        :continue -> :ok
      end
    end)

    on_exit(fn ->
      Application.delete_env(:memba, :conversation_subscription_authority_issued_hook)
    end)

    follow_task = Task.async(fn -> subscribe(ids) end)
    assert_receive {:authority_issued, follow_pid}

    assert {:ok, %CustomGroupRemoval{subscription_revocation_completed: true}} =
             Membership.remove_custom_group_member(
               removal_attrs(ids, Ecto.UUID.generate()),
               consistency: :strong
             )

    send(follow_pid, :continue)
    assert {:error, :conversation_subscription_authority_ended} = Task.await(follow_task)
    assert grants(ids) == []
    refute Messaging.following_conversation?(ids.conversation_id, ids.person_id)
  end

  test "old authorization granted before policy processing is revoked before removal succeeds" do
    ids = ConversationSubscriptionFixtures.canonical_subscription_fixture!()
    parent = self()

    Application.put_env(
      :memba,
      :conversation_subscription_authority_revalidation_hook,
      fn _decision ->
        send(parent, {:authority_revalidated, self()})

        receive do
          :continue -> :ok
        end
      end
    )

    policy_pid = revocation_policy_pid!()
    :ok = :sys.suspend(policy_pid)

    on_exit(fn ->
      Application.delete_env(:memba, :conversation_subscription_authority_revalidation_hook)

      try do
        :sys.resume(policy_pid)
      catch
        :exit, _reason -> :ok
      end
    end)

    follow_task = Task.async(fn -> subscribe(ids) end)
    assert_receive {:authority_revalidated, authorization_pid}
    club = MembershipApp.aggregate_state(Club, ids.club_id)

    removal_task =
      Task.async(fn ->
        Membership.remove_custom_group_member(
          removal_attrs(ids, Ecto.UUID.generate()),
          consistency: :strong
        )
      end)

    assert :ok =
             Commanded.Subscriptions.wait_for(
               MembershipApp,
               ids.club_id,
               club.stream_version + 2,
               consistency: [Memba.Membership.Projectors.FirstClassGroupMembershipV1]
             )

    send(authorization_pid, :continue)
    assert :ok = Task.await(follow_task)
    :ok = :sys.resume(policy_pid)

    assert {:ok, %CustomGroupRemoval{subscription_revocation_completed: true}} =
             Task.await(removal_task)

    refute Messaging.following_conversation?(ids.conversation_id, ids.person_id)
    assert [grant] = grants(ids)
    refute grant.effective

    assert [
             ConversationSubscriptionAuthorizationGranted,
             GroupMembershipSubscriptionRevocationRecorded,
             ConversationSubscriptionAuthorizationRevoked,
             GroupMembershipSubscriptionRevocationCompleted
           ] == subscription_fact_modules(ids)
  end

  defp revocation_policy_pid! do
    Enum.find_value(Supervisor.which_children(Memba.Supervisor), fn
      {{RevokeGroupMembershipConversationSubscriptions, _opts}, pid, :worker,
       [RevokeGroupMembershipConversationSubscriptions]} ->
        pid

      _child ->
        nil
    end) || raise "revocation policy is not supervised"
  end

  defp subscribe(ids) do
    Messaging.begin_person_conversation_subscription(
      %{
        person_id: ids.person_id,
        conversation_id: ids.conversation_id,
        subscription_intent_id: ids.intent_id,
        source: :manual
      },
      consistency: [PersonConversationSubscriptionsV1]
    )
  end

  defp removal_attrs(ids, operation_id) do
    %{
      club_id: ids.club_id,
      group_id: ids.group_id,
      group_membership_id: ids.group_membership_id,
      club_membership_id: ids.club_membership_id,
      person_id: ids.person_id,
      actor_person_id: ids.person_id,
      removal_operation_id: operation_id
    }
  end

  defp grants(ids) do
    Messaging.list_person_conversation_subscription_grants(ids.person_id, ids.conversation_id)
  end

  defp revocation_fact_modules(ids) do
    subscription_fact_modules(ids)
    |> Enum.filter(&(&1 != ConversationSubscriptionAuthorizationGranted))
  end

  defp subscription_fact_modules(ids) do
    MessagingApp
    |> Commanded.EventStore.stream_forward(
      PersonConversationSubscriptions.stream_id(ids.person_id)
    )
    |> Enum.map(& &1.data.__struct__)
    |> Enum.filter(
      &(&1 in [
          ConversationSubscriptionAuthorizationGranted,
          GroupMembershipSubscriptionRevocationRecorded,
          ConversationSubscriptionAuthorizationRevoked,
          GroupMembershipSubscriptionRevocationCompleted
        ])
    )
  end
end
