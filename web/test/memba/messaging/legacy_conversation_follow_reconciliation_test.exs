defmodule Memba.Messaging.LegacyConversationFollowReconciliationTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Event.Mapper
  alias Commanded.EventStore
  alias Memba.ID
  alias Memba.Membership.App, as: MembershipApp
  alias Memba.Membership.Commands.AddClubMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreateGroup
  alias Memba.Membership.Commands.EndGroupMembership
  alias Memba.Membership.Commands.StartGroupMembership
  alias Memba.Membership.Policies.RevokeGroupMembershipConversationSubscriptions
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging.App, as: MessagingApp
  alias Memba.Messaging.Commands.EndPersonConversationSubscription
  alias Memba.Messaging.Events.ConversationAccessGrantedToGroup
  alias Memba.Messaging.Events.ConversationFollowed
  alias Memba.Messaging.Events.ConversationSubscriptionAuthorizationGranted
  alias Memba.Messaging.Events.ConversationSubscriptionEnded
  alias Memba.Messaging.Events.LegacyConversationFollowReconciled
  alias Memba.Messaging.Events.MessageSent
  alias Memba.Membership.Events.ConversationSubscriptionAuthorityDecided
  alias Memba.Messaging.LegacyConversationFollowDryRunCursor
  alias Memba.Messaging.LegacyConversationFollowReconciliation, as: Reconciliation
  alias Memba.Messaging.PersonConversationSubscriptions
  alias Memba.ProjectionBarrier

  @subscribers [
    Memba.Membership.Projectors.Club,
    Memba.Membership.Projectors.Membership,
    Memba.Membership.Projectors.Group,
    Memba.Membership.Projectors.GroupMembership,
    Memba.Membership.Projectors.FirstClassGroupMembershipV1,
    Memba.Membership.Projectors.Role,
    Memba.Messaging.Projectors.Message,
    Memba.Messaging.Projectors.ConversationGroupAccess,
    Memba.Messaging.Projectors.ConversationFollow,
    Memba.Messaging.Projectors.PersonConversationSubscriptionsV1,
    Memba.Membership.Policies.SystemGroupMembership,
    Memba.Membership.Policies.ClearRemovedGroupMemberFollows,
    Memba.Membership.Policies.RevokeGroupMembershipConversationSubscriptions,
    Memba.Membership.Policies.RevokeSystemConversationSubscriptions
  ]

  setup do
    on_exit(fn ->
      Application.delete_env(:memba, :legacy_follow_reconciliation_before_person_dispatch_hook)

      Application.delete_env(
        :memba,
        :legacy_follow_reconciliation_after_person_before_checkpoint_hook
      )

      Application.delete_env(:memba, :conversation_subscription_club_at_fence_hook)
    end)
  end

  test "fence requires the writer-drain acknowledgement and is idempotent" do
    assert {:error, :writers_stopped_acknowledgement_required} =
             Reconciliation.run(mode: :record_fence)

    assert {:ok, first} = record_fence()
    assert {:ok, second} = record_fence()
    assert first.fence_position == second.fence_position
    finish!()
  end

  test "recorded fence fails closed while the legacy projector is behind" do
    fixture = legacy_follow_fixture!(system: :everyone)

    {child_id, _pid, _type, _modules} =
      Enum.find(Supervisor.which_children(Memba.Supervisor), fn
        {_id, _pid, _type, [Memba.Messaging.Projectors.ConversationFollow]} -> true
        _child -> false
      end)

    :ok = Supervisor.terminate_child(Memba.Supervisor, child_id)

    version =
      MessagingApp
      |> EventStore.stream_forward(fixture.conversation_id)
      |> Enum.reduce(0, fn event, _version -> event.stream_version end)

    :ok =
      EventStore.append_to_stream(MessagingApp, fixture.conversation_id, version, [
        Mapper.map_to_event_data(%ConversationFollowed{
          follow_id: ID.generate(:conversation_follow),
          club_id: fixture.club_id,
          conversation_id: fixture.conversation_id,
          member_id: fixture.person_id
        })
      ])

    try do
      assert {:error, {:legacy_projector_lag, _result}} =
               Reconciliation.run(
                 mode: :record_fence,
                 projector_timeout: 0,
                 cutover_acknowledgement: Reconciliation.cutover_acknowledgement()
               )
    after
      assert {:ok, _pid} = Supervisor.restart_child(Memba.Supervisor, child_id)
    end

    finish!()
  end

  test "apply binds all custom grants at the fence, is deterministic, and retries once" do
    fixture = legacy_follow_fixture!(custom_group_count: 2)
    assert {:ok, _fence} = record_fence()

    assert {:ok, dry_run} = Reconciliation.run(mode: :dry_run, batch_size: 10)
    assert dry_run.granted == 1

    assert {:ok, applied} = apply_reconciliation(batch_size: 10)
    assert applied.granted == 1

    events = person_events(fixture.person_id)
    marker = Enum.find(events, &match?(%LegacyConversationFollowReconciled{}, &1))
    grants = Enum.filter(events, &match?(%ConversationSubscriptionAuthorizationGranted{}, &1))

    assert marker.reconciliation_key ==
             PersonConversationSubscriptions.reconciliation_key(
               fixture.person_id,
               fixture.conversation_id,
               applied.fence_position
             )

    assert Enum.map(grants, & &1.group_membership_id) == Enum.sort(fixture.group_membership_ids)

    authority_record =
      MembershipApp
      |> EventStore.stream_forward(fixture.club_id)
      |> Enum.find(&match?(%{data: %ConversationSubscriptionAuthorityDecided{}}, &1))

    conversation_version =
      MessagingApp
      |> EventStore.stream_forward(fixture.conversation_id)
      |> Enum.reduce(0, fn event, _version -> event.stream_version end)

    assert authority_record.data.source == "legacy_reconciliation"
    assert authority_record.data.conversation_stream_version == conversation_version

    club_version_at_fence =
      Memba.EventStoreHistory.stream_forward_at_global_position(
        MembershipApp,
        Memba.EventStore,
        fixture.club_id,
        applied.fence_position
      )
      |> Enum.reduce(0, fn event, _version -> event.stream_version end)

    assert authority_record.data.club_stream_version == club_version_at_fence
    assert authority_record.data.group_membership_ids == Enum.sort(fixture.group_membership_ids)
    assert authority_record.data.reconciliation_fence_position == applied.fence_position

    stop_event_sourced_aggregate_instances!()
    assert {:ok, retry} = apply_reconciliation(batch_size: 10)
    assert retry.attempted == 0
    assert retry.next_cursor == applied.next_cursor
    assert length(person_events(fixture.person_id)) == length(events)

    positions =
      event_sourced_projection_positions([
        Memba.Messaging.Projectors.ConversationFollow,
        Memba.Messaging.Projectors.PersonConversationSubscriptionsV1
      ])

    :ok = rebuild_event_sourced_projections!()
    await_event_sourced_projection_positions!(positions, timeout: 10_000)
    assert Memba.Messaging.following_conversation?(fixture.conversation_id, fixture.person_id)

    subscription_id =
      PersonConversationSubscriptions.subscription_id(fixture.person_id, fixture.conversation_id)

    assert %{effective: true, last_intent_id: last_intent_id} =
             Repo.get(Memba.Messaging.Projections.PersonConversationSubscription, subscription_id)

    assert last_intent_id == marker.subscription_intent_id
    finish!()
  end

  test "mixed custom, Everyone, and Admin authority is recorded and granted exactly" do
    fixture = legacy_follow_fixture!(custom_group_count: 1, system: :both, admin: true)
    assert {:ok, _fence} = record_fence()
    assert {:ok, %{granted: 1}} = apply_reconciliation(batch_size: 10)

    grants =
      person_events(fixture.person_id)
      |> Enum.filter(&match?(%ConversationSubscriptionAuthorizationGranted{}, &1))

    assert Enum.map(grants, &{&1.authority_kind, &1.group_membership_id}) ==
             [
               {"group_membership", hd(fixture.group_membership_ids)},
               {"admin", nil},
               {"everyone", nil}
             ]

    finish!()
  end

  test "one person reconciles independently across multiple Club authority histories" do
    person_id = ID.generate(:person)
    first = legacy_follow_fixture!(person_id: person_id, system: :everyone)
    second = legacy_follow_fixture!(person_id: person_id, system: :admin, admin: true)
    assert {:ok, _fence} = record_fence()
    assert {:ok, %{granted: 2}} = apply_reconciliation(batch_size: 10)

    decisions =
      for fixture <- [first, second] do
        MembershipApp
        |> EventStore.stream_forward(fixture.club_id)
        |> Enum.find(&match?(%{data: %ConversationSubscriptionAuthorityDecided{}}, &1))
        |> Map.fetch!(:data)
      end

    assert Enum.map(decisions, & &1.club_id) |> Enum.sort() ==
             Enum.sort([first.club_id, second.club_id])

    assert Enum.sort(Enum.flat_map(decisions, & &1.system_authority_kinds)) ==
             ["admin", "everyone"]

    finish!()
  end

  test "one batch caches one immutable Club fence across multiple conversations" do
    fixture = legacy_follow_fixture!(custom_group_count: 1)
    second_conversation_id = ID.generate(:message)

    append_legacy_conversation!(
      fixture.club_id,
      fixture.person_id,
      second_conversation_id,
      fixture.group_ids
    )

    assert {:ok, _fence} = record_fence()

    counter = start_supervised!({Agent, fn -> 0 end})

    Application.put_env(:memba, :conversation_subscription_club_at_fence_hook, fn _club_id ->
      Agent.update(counter, &(&1 + 1))
    end)

    assert {:ok, %{granted: 2}} = apply_reconciliation(batch_size: 10)
    assert Agent.get(counter, & &1) == 1

    decisions =
      MembershipApp
      |> EventStore.stream_forward(fixture.club_id)
      |> Enum.filter(&match?(%{data: %ConversationSubscriptionAuthorityDecided{}}, &1))

    assert length(decisions) == 2
    assert Enum.all?(decisions, &(hd(fixture.group_ids) in &1.data.conversation_group_ids))
    finish!()
  end

  test "system Everyone authority is reconstructed at the fence" do
    fixture = legacy_follow_fixture!(system: :everyone)
    assert {:ok, _fence} = record_fence()
    assert {:ok, %{granted: 1}} = apply_reconciliation(batch_size: 10)

    assert [%ConversationSubscriptionAuthorizationGranted{authority_kind: "everyone"}] =
             person_events(fixture.person_id)
             |> Enum.filter(&match?(%ConversationSubscriptionAuthorizationGranted{}, &1))

    finish!()
  end

  test "post-fence audience grants cannot authorize an old legacy follow" do
    fixture = legacy_follow_fixture!(custom_group_count: 0)
    assert {:ok, _fence} = record_fence()

    version =
      MessagingApp
      |> EventStore.stream_forward(fixture.conversation_id)
      |> Enum.reduce(0, fn event, _version -> event.stream_version end)

    :ok =
      EventStore.append_to_stream(MessagingApp, fixture.conversation_id, version, [
        Mapper.map_to_event_data(%ConversationAccessGrantedToGroup{
          conversation_id: fixture.conversation_id,
          club_id: fixture.club_id,
          group_id: SystemGroups.everyone_group_id(fixture.club_id),
          access_level: :read
        })
      ])

    assert {:ok, %{no_authority: 1}} = apply_reconciliation(batch_size: 10)
    finish!()
  end

  test "no authority creates a terminal marker without a grant" do
    fixture = legacy_follow_fixture!(custom_group_count: 0)
    assert {:ok, _fence} = record_fence()
    assert {:ok, %{no_authority: 1}} = apply_reconciliation(batch_size: 10)

    assert Enum.any?(person_events(fixture.person_id), fn
             %LegacyConversationFollowReconciled{outcome: "no_authority"} -> true
             _event -> false
           end)

    refute Enum.any?(
             person_events(fixture.person_id),
             &match?(%ConversationSubscriptionAuthorizationGranted{}, &1)
           )

    finish!()
  end

  test "an explicit unfollow before reconciliation prevents restoration" do
    fixture = legacy_follow_fixture!(system: :everyone)
    assert {:ok, _fence} = record_fence()

    :ok =
      MessagingApp.dispatch(%EndPersonConversationSubscription{
        person_id: fixture.person_id,
        conversation_id: fixture.conversation_id,
        unfollow_id: Ecto.UUID.generate()
      })

    assert {:ok, %{no_authority: 1}} = apply_reconciliation(batch_size: 10)

    refute Enum.any?(
             person_events(fixture.person_id),
             &match?(%ConversationSubscriptionAuthorizationGranted{}, &1)
           )

    finish!()
  end

  test "remove and re-add after the fence cannot satisfy the old authority" do
    fixture = legacy_follow_fixture!(custom_group_count: 1)
    assert {:ok, _fence} = record_fence()
    [old_group_membership_id] = fixture.group_membership_ids
    [group_id] = fixture.group_ids

    :ok =
      MembershipApp.dispatch(
        %EndGroupMembership{
          club_id: fixture.club_id,
          group_id: group_id,
          group_membership_id: old_group_membership_id,
          club_membership_id: fixture.membership_id,
          person_id: fixture.person_id,
          idempotency_key: "post-fence-remove",
          reason: "test"
        },
        consistency: [RevokeGroupMembershipConversationSubscriptions]
      )

    :ok =
      MembershipApp.dispatch(%StartGroupMembership{
        club_id: fixture.club_id,
        group_id: group_id,
        group_membership_id: ID.generate(:group_membership),
        club_membership_id: fixture.membership_id,
        person_id: fixture.person_id
      })

    assert {:ok, %{no_authority: 1}} = apply_reconciliation(batch_size: 10)

    refute Enum.any?(
             person_events(fixture.person_id),
             &match?(%ConversationSubscriptionAuthorizationGranted{}, &1)
           )

    finish!()
  end

  test "a post-fence legacy writer makes reconciliation fail closed" do
    fixture = legacy_follow_fixture!(system: :everyone)
    assert {:ok, _fence} = record_fence()

    version =
      MessagingApp
      |> EventStore.stream_forward(fixture.conversation_id)
      |> Enum.reduce(0, fn event, _version -> event.stream_version end)

    :ok =
      EventStore.append_to_stream(MessagingApp, fixture.conversation_id, version, [
        Mapper.map_to_event_data(%ConversationFollowed{
          follow_id: ID.generate(:conversation_follow),
          club_id: fixture.club_id,
          conversation_id: fixture.conversation_id,
          member_id: fixture.person_id
        })
      ])

    assert {:error, :legacy_follow_source_changed} = Reconciliation.run(mode: :dry_run)
    finish!()
  end

  test "an explicit unfollow after reconciliation revokes the fenced grant" do
    fixture = legacy_follow_fixture!(system: :everyone)
    assert {:ok, _fence} = record_fence()
    assert {:ok, %{granted: 1}} = apply_reconciliation(batch_size: 10)

    :ok =
      MessagingApp.dispatch(%EndPersonConversationSubscription{
        person_id: fixture.person_id,
        conversation_id: fixture.conversation_id,
        unfollow_id: Ecto.UUID.generate()
      })

    assert Enum.any?(
             person_events(fixture.person_id),
             &match?(%ConversationSubscriptionEnded{}, &1)
           )

    finish!()
  end

  test "bounded apply reports continuation in person and conversation order" do
    first = legacy_follow_fixture!(system: :everyone)
    second = legacy_follow_fixture!(system: :everyone)
    assert {:ok, _fence} = record_fence()

    assert {:error, %{reason: :incomplete_batch, report: page}} =
             apply_reconciliation(batch_size: 1)

    assert page.attempted == 1
    assert page.next_cursor == Enum.min([key(first), key(second)])

    assert {:ok, continuation} =
             apply_reconciliation(batch_size: 1, after: page.next_cursor)

    assert continuation.attempted == 1
    assert continuation.next_cursor == Enum.max([key(first), key(second)])
    finish!()
  end

  test "restart after person marker but before checkpoint retries the marker then advances" do
    fixture = legacy_follow_fixture!(system: :everyone)
    assert {:ok, _fence} = record_fence()

    Application.put_env(
      :memba,
      :legacy_follow_reconciliation_after_person_before_checkpoint_hook,
      fn _key ->
        raise "crash after marker"
      end
    )

    assert_raise RuntimeError, "crash after marker", fn ->
      apply_reconciliation(batch_size: 10)
    end

    Application.delete_env(
      :memba,
      :legacy_follow_reconciliation_after_person_before_checkpoint_hook
    )

    assert Enum.any?(
             person_events(fixture.person_id),
             &match?(%LegacyConversationFollowReconciled{}, &1)
           )

    assert cutover_state().checkpoint == nil

    assert {:ok, %{already_reconciled: 1, next_cursor: cursor}} =
             apply_reconciliation(batch_size: 10)

    assert cursor == key(fixture)
    finish!()
  end

  test "restart after authority decision but before person marker does not skip the item" do
    fixture = legacy_follow_fixture!(system: :everyone)
    assert {:ok, _fence} = record_fence()

    Application.put_env(
      :memba,
      :legacy_follow_reconciliation_before_person_dispatch_hook,
      fn _key ->
        raise "crash before marker"
      end
    )

    assert_raise RuntimeError, "crash before marker", fn ->
      apply_reconciliation(batch_size: 10)
    end

    Application.delete_env(:memba, :legacy_follow_reconciliation_before_person_dispatch_hook)

    refute Enum.any?(
             person_events(fixture.person_id),
             &match?(%LegacyConversationFollowReconciled{}, &1)
           )

    assert cutover_state().checkpoint == nil

    assert {:ok, %{granted: 1, next_cursor: cursor}} = apply_reconciliation(batch_size: 10)
    assert cursor == key(fixture)
    finish!()
  end

  test "dry-run paginates with signed tokens without moving apply state" do
    fixtures = for _index <- 1..3, do: legacy_follow_fixture!(system: :everyone)
    assert {:ok, fence_report} = record_fence()

    assert {:error, %{reason: :incomplete_batch, report: first}} =
             Reconciliation.run(mode: :dry_run, batch_size: 1)

    assert String.starts_with?(first.next_cursor, "lcfr1.")

    assert {:error, %{reason: :incomplete_batch, report: second}} =
             Reconciliation.run(mode: :dry_run, batch_size: 1, after: first.next_cursor)

    assert second.next_cursor != first.next_cursor

    assert {:ok, third} =
             Reconciliation.run(mode: :dry_run, batch_size: 1, after: second.next_cursor)

    assert third.attempted == 1
    assert cutover_state().checkpoint == nil

    for fixture <- fixtures do
      assert person_events(fixture.person_id) == []

      refute Enum.any?(
               MembershipApp |> EventStore.stream_forward(fixture.club_id) |> Enum.to_list(),
               &match?(%{data: %ConversationSubscriptionAuthorityDecided{}}, &1)
             )
    end

    assert {:ok, %{granted: 3, attempted: 3}} = apply_reconciliation(batch_size: 10)
    assert cutover_state().fence.event_store_position == fence_report.fence_position
    finish!()
  end

  test "dry-run cursor rejects forgery, cross-fence scope, mode misuse, and stale apply state" do
    _first = legacy_follow_fixture!(system: :everyone)
    _second = legacy_follow_fixture!(system: :everyone)
    assert {:ok, _fence} = record_fence()

    assert {:error, %{reason: :incomplete_batch, report: preview}} =
             Reconciliation.run(mode: :dry_run, batch_size: 1)

    token = preview.next_cursor
    forged = String.slice(token, 0, byte_size(token) - 1) <> "x"

    assert {:error, :invalid_dry_run_cursor} =
             Reconciliation.run(mode: :dry_run, batch_size: 1, after: forged)

    assert {:error, :invalid_cursor} =
             apply_reconciliation(batch_size: 1, after: token)

    fence = cutover_state().fence

    assert {:error, :invalid_dry_run_cursor} =
             LegacyConversationFollowDryRunCursor.verify(
               token,
               nil,
               %{fence | cutover_id: "different-cutover"},
               Reconciliation.namespace()
             )

    assert {:error, %{reason: :incomplete_batch}} = apply_reconciliation(batch_size: 1)

    assert {:error, :invalid_dry_run_cursor} =
             Reconciliation.run(mode: :dry_run, batch_size: 1, after: token)

    assert cutover_state().checkpoint != nil

    finish!()
  end

  test "apply supplied cursor cannot move ahead of the durable checkpoint" do
    first = legacy_follow_fixture!(system: :everyone)
    second = legacy_follow_fixture!(system: :everyone)
    assert {:ok, _fence} = record_fence()

    assert {:error, :reconciliation_cursor_conflict} =
             apply_reconciliation(batch_size: 10, after: Enum.max([key(first), key(second)]))

    finish!()
  end

  test "malformed options fail closed" do
    assert {:error, :invalid_mode} = Reconciliation.run(mode: :other)
    assert {:error, :invalid_batch_size} = Reconciliation.run(batch_size: 0)
    assert {:error, :invalid_cursor} = Reconciliation.run(after: ["bad"])
    assert {:error, :invalid_projector_timeout} = Reconciliation.run(projector_timeout: -1)
    finish!()
  end

  defp record_fence do
    Reconciliation.run(
      mode: :record_fence,
      cutover_acknowledgement: Reconciliation.cutover_acknowledgement()
    )
  end

  defp apply_reconciliation(opts) do
    Reconciliation.run(
      Keyword.merge(
        [mode: :apply, cutover_acknowledgement: Reconciliation.cutover_acknowledgement()],
        opts
      )
    )
  end

  defp legacy_follow_fixture!(opts) do
    club_id = ID.generate(:club)
    person_id = Keyword.get_lazy(opts, :person_id, fn -> ID.generate(:person) end)
    membership_id = ID.generate(:membership)
    conversation_id = ID.generate(:message)

    :ok =
      MembershipApp.dispatch(%CreateClub{
        club_id: club_id,
        name: "Club",
        slug: "club-#{String.slice(Ecto.UUID.generate(), 0, 8)}"
      })

    :ok =
      MembershipApp.dispatch(%AddClubMember{
        club_id: club_id,
        membership_id: membership_id,
        person_id: person_id
      })

    custom_count =
      Keyword.get(opts, :custom_group_count, if(Keyword.has_key?(opts, :system), do: 0, else: 1))

    custom =
      if custom_count == 0 do
        []
      else
        Enum.map(1..custom_count, fn index ->
          group_id = ID.generate(:group)
          group_membership_id = ID.generate(:group_membership)

          :ok =
            MembershipApp.dispatch(%CreateGroup{
              club_id: club_id,
              group_id: group_id,
              group_key: nil,
              email_slug: "group-#{index}-#{String.slice(Ecto.UUID.generate(), 0, 6)}",
              name: "Group #{index}"
            })

          :ok =
            MembershipApp.dispatch(%StartGroupMembership{
              club_id: club_id,
              group_id: group_id,
              group_membership_id: group_membership_id,
              club_membership_id: membership_id,
              person_id: person_id
            })

          {group_id, group_membership_id}
        end)
      end

    {custom_group_ids, group_membership_ids} = Enum.unzip(custom)

    system_group_ids =
      case Keyword.get(opts, :system) do
        :everyone -> [SystemGroups.everyone_group_id(club_id)]
        :admin -> [SystemGroups.admin_group_id(club_id)]
        :both -> [SystemGroups.admin_group_id(club_id), SystemGroups.everyone_group_id(club_id)]
        nil -> []
      end

    group_ids =
      case custom_group_ids ++ system_group_ids do
        [] -> [ID.generate(:group)]
        ids -> ids
      end

    events =
      [
        %MessageSent{
          message_id: conversation_id,
          club_id: club_id,
          sender_id: ID.generate(:person),
          subject: "Legacy",
          body: "Body",
          sender_follows_conversation: false
        }
      ] ++
        Enum.map(group_ids, fn group_id ->
          %ConversationAccessGrantedToGroup{
            conversation_id: conversation_id,
            club_id: club_id,
            group_id: group_id,
            access_level: :read
          }
        end) ++
        [
          %ConversationFollowed{
            follow_id: ID.generate(:conversation_follow),
            club_id: club_id,
            conversation_id: conversation_id,
            member_id: person_id
          }
        ]

    :ok =
      EventStore.append_to_stream(
        MessagingApp,
        conversation_id,
        0,
        Enum.map(events, &Mapper.map_to_event_data/1)
      )

    ProjectionBarrier.await!([Memba.Messaging.Projectors.ConversationFollow])

    %{
      club_id: club_id,
      membership_id: membership_id,
      person_id: person_id,
      conversation_id: conversation_id,
      group_ids: group_ids,
      group_membership_ids: group_membership_ids
    }
  end

  defp append_legacy_conversation!(club_id, person_id, conversation_id, group_ids) do
    events =
      [
        %MessageSent{
          message_id: conversation_id,
          club_id: club_id,
          sender_id: ID.generate(:person),
          subject: "Legacy",
          body: "Body",
          sender_follows_conversation: false
        }
      ] ++
        Enum.map(group_ids, fn group_id ->
          %ConversationAccessGrantedToGroup{
            conversation_id: conversation_id,
            club_id: club_id,
            group_id: group_id,
            access_level: :read
          }
        end) ++
        [
          %ConversationFollowed{
            follow_id: ID.generate(:conversation_follow),
            club_id: club_id,
            conversation_id: conversation_id,
            member_id: person_id
          }
        ]

    :ok =
      EventStore.append_to_stream(
        MessagingApp,
        conversation_id,
        0,
        Enum.map(events, &Mapper.map_to_event_data/1)
      )

    ProjectionBarrier.await!([Memba.Messaging.Projectors.ConversationFollow])
  end

  defp person_events(person_id) do
    case EventStore.stream_forward(
           MessagingApp,
           PersonConversationSubscriptions.stream_id(person_id)
         ) do
      {:error, :stream_not_found} -> []
      events -> Enum.map(events, & &1.data)
    end
  end

  defp key(fixture), do: [fixture.person_id, fixture.conversation_id]

  defp cutover_state do
    MessagingApp.aggregate_state(
      Memba.Messaging.ConversationSubscriptionCutover,
      Memba.Messaging.ConversationSubscriptionCutover.cutover_id()
    )
  end

  defp finish!, do: ProjectionBarrier.await!(@subscribers, timeout: 10_000)
end
