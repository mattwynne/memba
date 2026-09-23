defmodule Memba.Messaging.PersonConversationSubscriptionsTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Event.Mapper
  alias Memba.ConversationSubscriptionFixtures
  alias Memba.ID
  alias Memba.Membership
  alias Memba.Membership.App, as: MembershipApp
  alias Memba.Membership.Commands.DecideConversationSubscriptionAuthority
  alias Memba.Membership.Commands.EndGroupMembership
  alias Memba.Membership.Events.GroupCreated
  alias Memba.Membership.Events.GroupMembershipStarted
  alias Memba.Membership.ConversationSubscriptionAuthorityDecision
  alias Memba.Membership.Club
  alias Memba.Messaging
  alias Memba.Messaging.App
  alias Memba.Messaging.Commands.AuthorizePersonConversationSubscriptionIntent
  alias Memba.Messaging.ConversationAuthorityDescriptor
  alias Memba.Messaging.Commands.StartPersonConversationSubscriptionIntent
  alias Memba.Messaging.Events.ConversationAccessGrantedToGroup
  alias Memba.Messaging.Events.ConversationAccessRevokedFromGroup
  alias Memba.Messaging.Events.ConversationSubscriptionEnded
  alias Memba.Messaging.PersonConversationSubscriptions
  alias Memba.Messaging.Projections.EmailDelivery

  test "product boundary obtains and binds server-owned canonical authority" do
    ids = ConversationSubscriptionFixtures.canonical_subscription_fixture!()

    assert :ok =
             Messaging.begin_person_conversation_subscription(
               %{
                 person_id: ids.person_id,
                 conversation_id: ids.conversation_id,
                 subscription_intent_id: ids.intent_id,
                 source: :manual
               },
               consistency: [Memba.Messaging.Projectors.PersonConversationSubscriptionsV1]
             )

    assert %{effective: true} =
             Messaging.get_person_conversation_subscription(ids.person_id, ids.conversation_id)

    assert [grant] =
             Messaging.list_person_conversation_subscription_grants(
               ids.person_id,
               ids.conversation_id
             )

    assert grant.club_membership_id == ids.club_membership_id
    assert grant.group_membership_id == ids.group_membership_id

    Memba.EventSourcedCase.stop_event_sourced_aggregate_instances!()

    assert :ok =
             Messaging.begin_person_conversation_subscription(
               %{
                 person_id: ids.person_id,
                 conversation_id: ids.conversation_id,
                 subscription_intent_id: ids.intent_id,
                 source: :manual
               },
               consistency: [Memba.Messaging.Projectors.PersonConversationSubscriptionsV1]
             )

    assert [_one_grant] =
             Messaging.list_person_conversation_subscription_grants(
               ids.person_id,
               ids.conversation_id
             )
  end

  test "unfollow and refollow cannot revive a queued delivery bound to the old grant" do
    ids = ConversationSubscriptionFixtures.canonical_subscription_fixture!()
    assert :ok = subscribe(ids, :manual)

    assert [old_grant] =
             Messaging.list_person_conversation_subscription_grants(
               ids.person_id,
               ids.conversation_id
             )

    old_delivery = delivery_for_grant(ids.person_id, old_grant)
    assert Messaging.delivery_subscription_authorization_effective?(old_delivery)

    assert :ok =
             Messaging.unfollow_conversation(
               %{
                 person_id: ids.person_id,
                 conversation_id: ids.conversation_id,
                 unfollow_id: Ecto.UUID.generate()
               },
               consistency: :strong
             )

    assert :ok =
             Messaging.follow_conversation(
               %{
                 person_id: ids.person_id,
                 conversation_id: ids.conversation_id,
                 subscription_intent_id: ID.generate(:subscription_intent),
                 source: :manual
               },
               consistency: :strong
             )

    refute Messaging.delivery_subscription_authorization_effective?(old_delivery)
  end

  test "GroupMembership remove and re-add cannot revive a queued delivery's old grant" do
    ids = ConversationSubscriptionFixtures.canonical_subscription_fixture!()
    assert :ok = subscribe(ids, :manual)

    assert [old_grant] =
             Messaging.list_person_conversation_subscription_grants(
               ids.person_id,
               ids.conversation_id
             )

    old_delivery = delivery_for_grant(ids.person_id, old_grant)
    end_group_membership!(ids)
    readd_group_membership!(ids)

    assert :ok =
             Messaging.follow_conversation(
               %{
                 person_id: ids.person_id,
                 conversation_id: ids.conversation_id,
                 subscription_intent_id: ID.generate(:subscription_intent),
                 source: :manual
               },
               consistency: :strong
             )

    refute Messaging.delivery_subscription_authorization_effective?(old_delivery)
  end

  test "successful reply auto-follow is canonical, stable on retry, and rejected replies add no intent" do
    ids = ConversationSubscriptionFixtures.canonical_subscription_fixture!()
    reply_id = ID.generate(:message)

    attrs = %{
      message_id: reply_id,
      conversation_id: ids.conversation_id,
      sender_id: ids.person_id,
      body: "A canonical reply"
    }

    assert :ok = Messaging.post_message_reply(attrs, consistency: :strong)
    assert Messaging.following_conversation?(ids.conversation_id, ids.person_id)

    assert %PersonConversationSubscriptions{intents: intents} =
             App.aggregate_state(
               PersonConversationSubscriptions,
               PersonConversationSubscriptions.stream_id(ids.person_id)
             )

    assert [%{source: :reply}] = Map.values(intents)
    assert :ok = Messaging.post_message_reply(attrs, consistency: :strong)

    assert %PersonConversationSubscriptions{intents: retried_intents} =
             App.aggregate_state(
               PersonConversationSubscriptions,
               PersonConversationSubscriptions.stream_id(ids.person_id)
             )

    assert map_size(retried_intents) == 1

    rejected_reply_id = ID.generate(:message)

    assert {:error, :invalid_body} =
             Messaging.post_message_reply(%{
               attrs
               | message_id: rejected_reply_id,
                 body: " "
             })

    assert %PersonConversationSubscriptions{intents: after_rejection} =
             App.aggregate_state(
               PersonConversationSubscriptions,
               PersonConversationSubscriptions.stream_id(ids.person_id)
             )

    assert map_size(after_rejection) == 2
    assert Enum.count(after_rejection, fn {_id, intent} -> intent.status == :cancelled end) == 1
  end

  test "unfollow after send success defeats delayed finalization and restart retry" do
    ids = ConversationSubscriptionFixtures.canonical_subscription_fixture!()
    reply_id = ID.generate(:message)
    parent = self()

    Application.put_env(:memba, :auto_follow_send_succeeded_hook, fn _command, _decision ->
      send(parent, {:send_succeeded_before_follow, self()})

      receive do
        :finalize -> :ok
      end
    end)

    on_exit(fn -> Application.delete_env(:memba, :auto_follow_send_succeeded_hook) end)

    attrs = %{
      message_id: reply_id,
      conversation_id: ids.conversation_id,
      sender_id: ids.person_id,
      body: "Delayed follow finalization"
    }

    task = Task.async(fn -> Messaging.post_message_reply(attrs, consistency: :strong) end)
    assert_receive {:send_succeeded_before_follow, workflow_pid}

    assert :ok =
             Messaging.unfollow_conversation(
               %{
                 person_id: ids.person_id,
                 conversation_id: ids.conversation_id,
                 unfollow_id: Ecto.UUID.generate()
               },
               consistency: :strong
             )

    send(workflow_pid, :finalize)
    assert :ok = Task.await(task)
    refute Messaging.following_conversation?(ids.conversation_id, ids.person_id)

    Application.delete_env(:memba, :auto_follow_send_succeeded_hook)
    Memba.EventSourcedCase.stop_event_sourced_aggregate_instances!()

    assert :ok = Messaging.post_message_reply(attrs, consistency: :strong)
    refute Messaging.following_conversation?(ids.conversation_id, ids.person_id)
  end

  test "GroupMembershipEnded policy records one durable revocation receipt on retry" do
    ids = ConversationSubscriptionFixtures.canonical_subscription_fixture!()
    assert :ok = subscribe(ids, :manual)

    command = %EndGroupMembership{
      club_id: ids.club_id,
      group_id: ids.group_id,
      group_membership_id: ids.group_membership_id,
      club_membership_id: ids.club_membership_id,
      person_id: ids.person_id,
      idempotency_key: Ecto.UUID.generate(),
      reason: "policy_test"
    }

    assert :ok = MembershipApp.dispatch(command, consistency: :strong)

    revocation_id =
      PersonConversationSubscriptions.revocation_id(ids.group_membership_id)

    assert %{completed: true} =
             Messaging.get_group_membership_subscription_revocation_receipt(revocation_id)

    assert :ok = MembershipApp.dispatch(command, consistency: :strong)
    await_person_subscription_projection!(ids.person_id)
    refute Messaging.following_conversation?(ids.conversation_id, ids.person_id)

    assert %{completed: true} =
             Messaging.get_group_membership_subscription_revocation_receipt(revocation_id)
  end

  test "one intent records all independent current group-membership grants" do
    ids = ConversationSubscriptionFixtures.canonical_subscription_fixture!()
    second_group_id = ID.generate(:group)
    second_group_membership_id = ID.generate(:group_membership)
    club = MembershipApp.aggregate_state(Club, ids.club_id)

    :ok =
      Commanded.EventStore.append_to_stream(
        MembershipApp,
        ids.club_id,
        club.stream_version,
        Enum.map(
          [
            %GroupCreated{
              club_id: ids.club_id,
              group_id: second_group_id,
              group_key: "second-authority",
              name: "Second Authority"
            },
            %GroupMembershipStarted{
              club_id: ids.club_id,
              group_id: second_group_id,
              group_membership_id: second_group_membership_id,
              club_membership_id: ids.club_membership_id,
              person_id: ids.person_id
            }
          ],
          &Mapper.map_to_event_data/1
        )
      )

    append_conversation_access_event!(ids, %ConversationAccessGrantedToGroup{
      conversation_id: ids.conversation_id,
      club_id: ids.club_id,
      group_id: second_group_id,
      access_level: "read"
    })

    assert :ok = subscribe(ids, :manual)

    assert [first, second] =
             Messaging.list_person_conversation_subscription_grants(
               ids.person_id,
               ids.conversation_id
             )

    assert Enum.sort([first.group_membership_id, second.group_membership_id]) ==
             Enum.sort([ids.group_membership_id, second_group_membership_id])

    end_exact_group_membership!(ids, ids.group_id, ids.group_membership_id)
    assert Messaging.following_conversation?(ids.conversation_id, ids.person_id)

    assert [surviving] =
             Messaging.list_person_conversation_subscription_grants(
               ids.person_id,
               ids.conversation_id
             )
             |> Enum.filter(& &1.effective)

    assert surviving.group_membership_id == second_group_membership_id

    end_exact_group_membership!(ids, second_group_id, second_group_membership_id)
    refute Messaging.following_conversation?(ids.conversation_id, ids.person_id)

    revocation_id =
      PersonConversationSubscriptions.revocation_id(second_group_membership_id)

    assert :ok =
             App.dispatch(
               %Memba.Messaging.Commands.RevokeGroupMembershipConversationSubscriptions{
                 person_id: ids.person_id,
                 group_membership_id: second_group_membership_id,
                 revocation_id: revocation_id
               },
               consistency: [Memba.Messaging.Projectors.PersonConversationSubscriptionsV1]
             )

    assert %{completed: true} =
             Messaging.get_group_membership_subscription_revocation_receipt(revocation_id)
  end

  test "product boundary rejects caller-supplied trusted provenance" do
    ids = ConversationSubscriptionFixtures.canonical_subscription_fixture!()

    attrs = %{
      person_id: ids.person_id,
      conversation_id: ids.conversation_id,
      subscription_intent_id: ids.intent_id,
      source: :manual,
      group_membership_ids: [ids.group_membership_id]
    }

    assert {:error, :trusted_subscription_provenance_not_accepted} =
             Messaging.begin_person_conversation_subscription(attrs)
  end

  test "forged and altered authority proofs cannot authorize raw internal commands" do
    ids = ConversationSubscriptionFixtures.canonical_subscription_fixture!()
    {:ok, decision} = issue_decision(ids)

    forged = %{decision | group_membership_ids: [ID.generate(:group_membership)]}

    command = start_command(ids, forged)

    assert {:error, :invalid_conversation_subscription_authority} = App.dispatch(command)

    forged_signature = %{decision | signature: :crypto.strong_rand_bytes(32)}

    assert {:error, :invalid_conversation_subscription_authority} =
             App.dispatch(start_command(ids, forged_signature))

    unrelated_audience = [ID.generate(:group)]
    forged_audience = %{decision | conversation_group_ids: unrelated_audience}

    assert {:error, :invalid_conversation_subscription_authority} =
             App.dispatch(start_command(ids, forged_audience))

    valid_decision_wrong_audience = %{
      start_command(ids, decision)
      | conversation_group_ids: unrelated_audience
    }

    assert {:error, :invalid_conversation_subscription_authority} =
             App.dispatch(valid_decision_wrong_audience)

    assert {:error, :invalid_conversation_subscription_authority} =
             App.dispatch(%{start_command(ids, decision) | source: :reply})

    unrelated_ids = %{ids | conversation_id: ID.generate(:message)}

    assert {:error, :invalid_conversation_subscription_authority} =
             App.dispatch(start_command(unrelated_ids, decision))
  end

  test "ended authority and re-addition cannot satisfy an older decision" do
    ids = ConversationSubscriptionFixtures.canonical_subscription_fixture!()
    {:ok, decision} = issue_decision(ids)
    assert :ok = App.dispatch(start_command(ids, decision))
    end_group_membership!(ids)

    authorize = authorize_command(ids, decision)

    assert {:error, :conversation_subscription_authority_ended} =
             App.dispatch(authorize, retry_attempts: 0)

    readded_id = ID.generate(:group_membership)

    readded = %Memba.Membership.Events.GroupMembershipStarted{
      club_id: ids.club_id,
      group_id: ids.group_id,
      group_membership_id: readded_id,
      club_membership_id: ids.club_membership_id,
      person_id: ids.person_id
    }

    club = MembershipApp.aggregate_state(Club, ids.club_id)

    :ok =
      Commanded.EventStore.append_to_stream(
        MembershipApp,
        ids.club_id,
        club.stream_version,
        [Mapper.map_to_event_data(readded)]
      )

    :ok =
      Commanded.Subscriptions.wait_for(MembershipApp, ids.club_id, club.stream_version + 1,
        consistency: [Memba.Membership.Projectors.FirstClassGroupMembershipV1]
      )

    Memba.EventSourcedCase.stop_event_sourced_aggregate_instances!()

    assert {:error, :conversation_subscription_authority_ended} =
             App.dispatch(authorize, retry_attempts: 0)
  end

  test "direct Membership dispatch rejects fabricated audience and version" do
    ids = ConversationSubscriptionFixtures.canonical_subscription_fixture!()

    forged_descriptor = %ConversationAuthorityDescriptor{
      club_id: ids.club_id,
      person_id: ids.person_id,
      subscription_intent_id: ids.intent_id,
      source: :manual,
      conversation_id: ids.conversation_id,
      conversation_group_ids: [ID.generate(:group)],
      conversation_stream_version: 99_999,
      signature: :crypto.strong_rand_bytes(32)
    }

    command = %DecideConversationSubscriptionAuthority{
      conversation_authority_descriptor: forged_descriptor,
      club_id: ids.club_id,
      person_id: ids.person_id,
      subscription_intent_id: ids.intent_id,
      source: :manual,
      conversation_id: ids.conversation_id,
      conversation_group_ids: forged_descriptor.conversation_group_ids,
      conversation_stream_version: forged_descriptor.conversation_stream_version,
      authority_request_id: Ecto.UUID.generate(),
      authority_decision_id: ID.generate(:authority_decision)
    }

    assert {:error, :invalid_conversation_authority_descriptor} =
             MembershipApp.dispatch(command)
  end

  test "descriptor A cannot authorize intent B or altered person/source after audience change" do
    ids = ConversationSubscriptionFixtures.canonical_subscription_fixture!()
    {:ok, _decision, descriptor_a} = issue_decision_with_descriptor(ids)

    append_conversation_access_event!(ids, %ConversationAccessGrantedToGroup{
      conversation_id: ids.conversation_id,
      club_id: ids.club_id,
      group_id: ID.generate(:group),
      access_level: "read"
    })

    base = decision_command(ids, descriptor_a, :manual, [])

    assert {:error, :invalid_conversation_authority_descriptor} =
             MembershipApp.dispatch(%{
               base
               | subscription_intent_id: ID.generate(:subscription_intent)
             })

    assert {:error, :invalid_conversation_authority_descriptor} =
             MembershipApp.dispatch(%{base | person_id: ID.generate(:person)})

    assert {:error, :invalid_conversation_authority_descriptor} =
             MembershipApp.dispatch(%{base | source: :reply})
  end

  test "authority decision identity cannot be reused with different provenance" do
    ids = ConversationSubscriptionFixtures.canonical_subscription_fixture!()
    {:ok, decision, _descriptor_a} = issue_decision_with_descriptor(ids)

    descriptor_b =
      capture_descriptor_without_decision(
        ids,
        ID.generate(:subscription_intent),
        :manual
      )

    club = MembershipApp.aggregate_state(Club, ids.club_id)

    conflict =
      decision_command(ids, descriptor_b, :manual,
        authority_decision_id: decision.authority_decision_id
      )

    assert {:error, :authority_decision_id_conflict} = Club.execute(club, conflict)
  end

  test "retry returns decision A before rebuilding a changed audience descriptor" do
    ids = ConversationSubscriptionFixtures.canonical_subscription_fixture!()
    decision_a = record_decision_without_start!(ids, :manual)

    append_conversation_access_event!(ids, %ConversationAccessGrantedToGroup{
      conversation_id: ids.conversation_id,
      club_id: ids.club_id,
      group_id: ID.generate(:group),
      access_level: "read"
    })

    assert :ok = subscribe(ids, :manual)
    assert_original_decision(ids, decision_a)
  end

  test "retry returns decision A when the conversation currently has no subscription groups" do
    ids = ConversationSubscriptionFixtures.canonical_subscription_fixture!()
    decision_a = record_decision_without_start!(ids, :reply)

    append_conversation_access_event!(ids, %ConversationAccessRevokedFromGroup{
      conversation_id: ids.conversation_id,
      club_id: ids.club_id,
      group_id: ids.group_id,
      access_level: "read"
    })

    assert :ok = subscribe(ids, :reply)
    assert_original_decision(ids, decision_a)
  end

  test "crash after decision issuance reloads decision A after remove and re-add" do
    ids = ConversationSubscriptionFixtures.canonical_subscription_fixture!()
    parent = self()

    on_exit(fn ->
      Application.delete_env(:memba, :conversation_subscription_authority_issued_hook)
    end)

    Application.put_env(:memba, :conversation_subscription_authority_issued_hook, fn decision ->
      send(parent, {:decision_issued, decision})
      {:error, :simulated_crash}
    end)

    assert {:error, :simulated_crash} =
             Messaging.begin_person_conversation_subscription(%{
               person_id: ids.person_id,
               conversation_id: ids.conversation_id,
               subscription_intent_id: ids.intent_id,
               source: :root
             })

    assert_receive {:decision_issued, decision_a}

    assert %PersonConversationSubscriptions{intents: intents} =
             App.aggregate_state(
               PersonConversationSubscriptions,
               PersonConversationSubscriptions.stream_id(ids.person_id)
             )

    assert intents == %{}
    Application.delete_env(:memba, :conversation_subscription_authority_issued_hook)
    end_group_membership!(ids)
    readd_group_membership!(ids)

    assert {:error, :conversation_subscription_authority_ended} =
             Messaging.begin_person_conversation_subscription(
               %{
                 person_id: ids.person_id,
                 conversation_id: ids.conversation_id,
                 subscription_intent_id: ids.intent_id,
                 source: :root
               },
               consistency: [Memba.Messaging.Projectors.PersonConversationSubscriptionsV1]
             )

    assert {:ok, decision_after_retry} =
             Membership.conversation_subscription_authority_decision_for_intent(
               ids.club_id,
               ids.intent_id
             )

    assert decision_after_retry.authority_decision_id == decision_a.authority_decision_id
    assert decision_after_retry.group_membership_ids == [ids.group_membership_id]
  end

  test "append conflict surfaces, revalidates the same ended decision, and creates no grant" do
    ids = ConversationSubscriptionFixtures.canonical_subscription_fixture!()
    parent = self()

    Application.put_env(
      :memba,
      :conversation_subscription_authority_revalidation_hook,
      fn _decision ->
        send(parent, {:authority_validated, self()})

        receive do
          :continue -> :ok
        end
      end
    )

    on_exit(fn ->
      Application.delete_env(:memba, :conversation_subscription_authority_revalidation_hook)
    end)

    task =
      Task.async(fn ->
        Messaging.begin_person_conversation_subscription(%{
          person_id: ids.person_id,
          conversation_id: ids.conversation_id,
          subscription_intent_id: ids.intent_id,
          source: :reply
        })
      end)

    assert_receive {:authority_validated, aggregate_pid}
    end_group_membership!(ids, revoke?: false)

    competing_conversation_id = ID.generate(:message)

    competing_event = %ConversationSubscriptionEnded{
      person_id: ids.person_id,
      conversation_id: competing_conversation_id,
      subscription_id:
        PersonConversationSubscriptions.subscription_id(ids.person_id, competing_conversation_id),
      unfollow_id: Ecto.UUID.generate()
    }

    :ok =
      Commanded.EventStore.append_to_stream(
        App,
        PersonConversationSubscriptions.stream_id(ids.person_id),
        1,
        [Mapper.map_to_event_data(competing_event)]
      )

    send(aggregate_pid, :continue)

    assert {:error, :conversation_subscription_authority_ended} = Task.await(task)

    revocation_id =
      PersonConversationSubscriptions.revocation_id(ids.group_membership_id)

    assert :ok =
             App.dispatch(
               %Memba.Messaging.Commands.RevokeGroupMembershipConversationSubscriptions{
                 person_id: ids.person_id,
                 group_membership_id: ids.group_membership_id,
                 revocation_id: revocation_id
               },
               consistency: [Memba.Messaging.Projectors.PersonConversationSubscriptionsV1]
             )

    await_person_subscription_projection!(ids.person_id)

    assert [] ==
             Messaging.list_person_conversation_subscription_grants(
               ids.person_id,
               ids.conversation_id
             )
  end

  defp decision_command(_ids, descriptor, source, opts) do
    %DecideConversationSubscriptionAuthority{
      conversation_authority_descriptor: descriptor,
      club_id: descriptor.club_id,
      person_id: descriptor.person_id,
      subscription_intent_id: descriptor.subscription_intent_id,
      source: source,
      conversation_id: descriptor.conversation_id,
      conversation_group_ids: descriptor.conversation_group_ids,
      conversation_stream_version: descriptor.conversation_stream_version,
      authority_request_id: Ecto.UUID.generate(),
      authority_decision_id:
        Keyword.get_lazy(opts, :authority_decision_id, fn ->
          ID.generate(:authority_decision)
        end)
    }
  end

  defp record_decision_without_start!(ids, source) do
    parent = self()

    Application.put_env(:memba, :conversation_subscription_authority_issued_hook, fn decision ->
      send(parent, {:decision_recorded_without_start, decision})
      {:error, :simulated_crash}
    end)

    try do
      assert {:error, :simulated_crash} =
               Messaging.begin_person_conversation_subscription(%{
                 person_id: ids.person_id,
                 conversation_id: ids.conversation_id,
                 subscription_intent_id: ids.intent_id,
                 source: source
               })

      assert_receive {:decision_recorded_without_start, decision}
      decision
    after
      Application.delete_env(:memba, :conversation_subscription_authority_issued_hook)
    end
  end

  defp append_conversation_access_event!(ids, event) do
    version =
      App
      |> Commanded.EventStore.stream_forward(ids.conversation_id)
      |> Enum.reduce(0, fn recorded, _version -> recorded.stream_version end)

    :ok =
      Commanded.EventStore.append_to_stream(
        App,
        ids.conversation_id,
        version,
        [Mapper.map_to_event_data(event)]
      )

    :ok =
      Commanded.Subscriptions.wait_for(App, ids.conversation_id, version + 1,
        consistency: [
          Memba.Messaging.Projectors.Message,
          Memba.Messaging.Projectors.ConversationGroupAccess
        ]
      )

    Memba.EventSourcedCase.stop_event_sourced_aggregate_instances!()
  end

  defp subscribe(ids, source) do
    Messaging.begin_person_conversation_subscription(
      %{
        person_id: ids.person_id,
        conversation_id: ids.conversation_id,
        subscription_intent_id: ids.intent_id,
        source: source
      },
      consistency: [Memba.Messaging.Projectors.PersonConversationSubscriptionsV1]
    )
  end

  defp assert_original_decision(ids, decision_a) do
    assert {:ok, retried} =
             Membership.conversation_subscription_authority_decision_for_intent(
               ids.club_id,
               ids.intent_id
             )

    assert retried.authority_decision_id == decision_a.authority_decision_id
    assert retried.conversation_group_ids == decision_a.conversation_group_ids

    club = MembershipApp.aggregate_state(Club, ids.club_id)
    assert map_size(club.conversation_authority_decisions) == 1
  end

  defp issue_decision_with_descriptor(ids) do
    parent = self()

    Application.put_env(:memba, :conversation_authority_descriptor_issued_hook, fn descriptor ->
      send(parent, {:conversation_authority_descriptor, descriptor})
      :ok
    end)

    try do
      assert {:ok, decision} = issue_decision(ids)
      assert_receive {:conversation_authority_descriptor, descriptor}
      {:ok, decision, descriptor}
    after
      Application.delete_env(:memba, :conversation_authority_descriptor_issued_hook)
    end
  end

  defp capture_descriptor_without_decision(ids, intent_id, source) do
    parent = self()

    Application.put_env(:memba, :conversation_authority_descriptor_issued_hook, fn descriptor ->
      send(parent, {:captured_conversation_authority_descriptor, descriptor})
      {:error, :descriptor_captured}
    end)

    try do
      assert {:error, :descriptor_captured} =
               Messaging.begin_person_conversation_subscription(%{
                 person_id: ids.person_id,
                 conversation_id: ids.conversation_id,
                 subscription_intent_id: intent_id,
                 source: source
               })

      assert_receive {:captured_conversation_authority_descriptor, descriptor}
      descriptor
    after
      Application.delete_env(:memba, :conversation_authority_descriptor_issued_hook)
    end
  end

  defp delivery_for_grant(person_id, grant) do
    %EmailDelivery{
      recipient_id: person_id,
      subscription_authorization_id: grant.authorization_id,
      authority_decision_id: grant.authority_decision_id,
      authority_kind: grant.authority_kind,
      authority_club_id: grant.club_id,
      authority_club_membership_id: grant.club_membership_id,
      authority_group_membership_id: grant.group_membership_id,
      authority_club_stream_version: grant.club_stream_version
    }
  end

  defp issue_decision(ids) do
    :ok =
      Messaging.begin_person_conversation_subscription(
        %{
          person_id: ids.person_id,
          conversation_id: ids.conversation_id,
          subscription_intent_id: ids.intent_id,
          source: :manual
        },
        consistency: [Memba.Messaging.Projectors.PersonConversationSubscriptionsV1]
      )

    Membership.conversation_subscription_authority_decision_for_intent(
      ids.club_id,
      ids.intent_id
    )
  end

  defp start_command(ids, %ConversationSubscriptionAuthorityDecision{} = decision) do
    %StartPersonConversationSubscriptionIntent{
      person_id: ids.person_id,
      club_id: ids.club_id,
      conversation_id: ids.conversation_id,
      conversation_group_ids: decision.conversation_group_ids,
      conversation_stream_version: decision.conversation_stream_version,
      subscription_id:
        PersonConversationSubscriptions.subscription_id(ids.person_id, ids.conversation_id),
      subscription_intent_id: ids.intent_id,
      authority_decision_id: decision.authority_decision_id,
      source: :manual,
      club_membership_id: decision.club_membership_id,
      club_stream_version: decision.club_stream_version,
      group_membership_ids: decision.group_membership_ids,
      system_authority_kinds: decision.system_authority_kinds,
      authority_decision: decision
    }
  end

  defp authorize_command(ids, decision) do
    %AuthorizePersonConversationSubscriptionIntent{
      person_id: ids.person_id,
      subscription_intent_id: ids.intent_id,
      authority_decision_id: decision.authority_decision_id,
      current_group_membership_ids: decision.group_membership_ids,
      current_system_authority_kinds: decision.system_authority_kinds,
      authority_decision: decision
    }
  end

  defp readd_group_membership!(ids) do
    readded = %Memba.Membership.Events.GroupMembershipStarted{
      club_id: ids.club_id,
      group_id: ids.group_id,
      group_membership_id: ID.generate(:group_membership),
      club_membership_id: ids.club_membership_id,
      person_id: ids.person_id
    }

    club = MembershipApp.aggregate_state(Club, ids.club_id)

    :ok =
      Commanded.EventStore.append_to_stream(
        MembershipApp,
        ids.club_id,
        club.stream_version,
        [Mapper.map_to_event_data(readded)]
      )

    :ok =
      Commanded.Subscriptions.wait_for(MembershipApp, ids.club_id, club.stream_version + 1,
        consistency: [Memba.Membership.Projectors.FirstClassGroupMembershipV1]
      )

    Memba.EventSourcedCase.stop_event_sourced_aggregate_instances!()
    :ok
  end

  defp end_group_membership!(ids, opts \\ []) do
    end_exact_group_membership!(ids, ids.group_id, ids.group_membership_id, opts)
  end

  defp end_exact_group_membership!(ids, group_id, group_membership_id, opts \\ []) do
    assert :ok =
             MembershipApp.dispatch(
               %EndGroupMembership{
                 club_id: ids.club_id,
                 group_id: group_id,
                 group_membership_id: group_membership_id,
                 club_membership_id: ids.club_membership_id,
                 person_id: ids.person_id,
                 idempotency_key: Ecto.UUID.generate(),
                 reason: "test_departure"
               },
               consistency: [
                 Memba.Membership.Projectors.FirstClassGroupMembershipV1,
                 Memba.Membership.Policies.ClearRemovedGroupMemberFollows
               ]
             )

    if Keyword.get(opts, :revoke?, true) do
      revocation_id = PersonConversationSubscriptions.revocation_id(group_membership_id)

      assert :ok =
               App.dispatch(
                 %Memba.Messaging.Commands.RevokeGroupMembershipConversationSubscriptions{
                   person_id: ids.person_id,
                   group_membership_id: group_membership_id,
                   revocation_id: revocation_id
                 },
                 consistency: [Memba.Messaging.Projectors.PersonConversationSubscriptionsV1]
               )

      await_person_subscription_projection!(ids.person_id)
    end
  end

  defp await_person_subscription_projection!(person_id) do
    stream_id = PersonConversationSubscriptions.stream_id(person_id)

    version =
      App
      |> Commanded.EventStore.stream_forward(stream_id)
      |> Enum.reduce(0, fn event, _version -> event.stream_version end)

    :ok =
      Commanded.Subscriptions.wait_for(App, stream_id, version,
        consistency: [Memba.Messaging.Projectors.PersonConversationSubscriptionsV1]
      )
  end
end
