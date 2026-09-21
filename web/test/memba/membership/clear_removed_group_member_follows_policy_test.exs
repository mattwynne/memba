defmodule Memba.Membership.ClearRemovedGroupMemberFollowsPolicyTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Commanded.EventStore
  alias Commanded.Event.Handler
  alias Commanded.Registration
  alias Commanded.Subscriptions
  alias Memba.Membership
  alias Memba.Membership.App, as: MembershipApp
  alias Memba.Membership.Club
  alias Memba.Membership.Commands.AddClubMember
  alias Memba.Membership.Commands.AddCustomGroupMember
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.AssignClubRoleToMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreateGroup
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Commands.RemoveClubMember
  alias Memba.Membership.Commands.RemoveCustomGroupMember
  alias Memba.Membership.CustomGroupAdmission
  alias Memba.Membership.Events.ClubMemberAdded
  alias Memba.Membership.Events.GroupMemberAdded
  alias Memba.Membership.Events.GroupMemberRemoved
  alias Memba.Membership.Events.MemberAdded, as: LegacyMemberAdded
  alias Memba.Membership.Policies.ClearRemovedGroupMemberFollows
  alias Memba.Membership.Policies.SystemGroupMembership
  alias Memba.Membership.Projectors.Membership, as: MembershipProjector
  alias Memba.Membership.Projections.GroupMembership, as: GroupMembershipProjection
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging
  alias Memba.Messaging.App, as: MessagingApp
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Events.ConversationFollowed
  alias Memba.Messaging.Events.ConversationUnfollowed
  alias Memba.Messaging.Events.EmailDeliveryCreated
  alias Memba.Messaging.Events.MessageSent
  alias Memba.Messaging.Projectors.ConversationGroupAccess, as: ConversationGroupAccessProjector
  alias Memba.Messaging.Recipient

  test "is a strongly consistent Membership event handler that replays from origin" do
    assert %{
             id: {ClearRemovedGroupMemberFollows, opts},
             restart: :permanent,
             start: {ClearRemovedGroupMemberFollows, :start_link, [opts]},
             type: :worker
           } = ClearRemovedGroupMemberFollows.child_spec([])

    assert Keyword.fetch!(opts, :application) == MembershipApp

    assert Keyword.fetch!(opts, :name) ==
             "Memba.Membership.Policies.ClearRemovedGroupMemberFollows"

    assert Keyword.fetch!(opts, :consistency) == :strong
    assert Keyword.fetch!(opts, :start_from) == :origin
    refute Keyword.has_key?(opts, :state)
  end

  test "membership projection replay uses durable cleanup progress for legacy streams" do
    club_id = Memba.ID.generate(:club)
    membership_id = Memba.ID.generate(:membership)
    person_id = Memba.ID.generate(:person)

    create_club(club_id)
    checkpoint = Memba.ProjectionBarrier.current_checkpoint()

    assert {:ok, _result} =
             Memba.ProjectionBarrier.await(
               [ClearRemovedGroupMemberFollows],
               checkpoint: checkpoint
             )

    :ok = Subscriptions.reset(MembershipApp)

    event = %LegacyMemberAdded{
      club_id: club_id,
      membership_id: membership_id,
      person_id: person_id
    }

    metadata = %{
      event_number: checkpoint,
      handler_name: "legacy-membership-replay-#{Ecto.UUID.generate()}",
      stream_id: membership_id,
      # Historic MemberAdded facts used membership-ID streams. This deliberately
      # cannot be interpreted as a version on the Club stream.
      stream_version: checkpoint + 100
    }

    assert :ok = MembershipProjector.handle(event, metadata)

    assert %MembershipProjection{
             club_id: ^club_id,
             membership_id: ^membership_id,
             person_id: ^person_id,
             active: true
           } = Repo.get(MembershipProjection, membership_id)
  end

  test "membership projection can rebuild without replaying completed follow cleanup" do
    club_id = Memba.ID.generate(:club)
    membership_id = Memba.ID.generate(:membership)
    person_id = Memba.ID.generate(:person)

    create_club(club_id)
    add_member(club_id, membership_id, person_id)

    checkpoint = Memba.ProjectionBarrier.current_checkpoint()

    Memba.ProjectionBarrier.await!(
      [ClearRemovedGroupMemberFollows, MembershipProjector],
      checkpoint: checkpoint
    )

    assert %MembershipProjection{active: true} =
             Repo.get(MembershipProjection, membership_id)

    membership_projector_child_id = stop_membership_projector!()

    Repo.delete_all(MembershipProjection)

    MembershipProjector.ProjectionVersion
    |> where([version], version.projection_name == ^inspect(MembershipProjector))
    |> Repo.delete_all()

    assert :ok =
             EventStore.delete_subscription(
               MembershipApp,
               :all,
               inspect(MembershipProjector)
             )

    :ok = Subscriptions.reset(MembershipApp)
    restart_membership_projector!(membership_projector_child_id)

    Memba.ProjectionBarrier.await!(
      [MembershipProjector],
      checkpoint: checkpoint
    )

    assert %MembershipProjection{
             club_id: ^club_id,
             membership_id: ^membership_id,
             person_id: ^person_id,
             active: true
           } = Repo.get(MembershipProjection, membership_id)
  end

  test "club departure clears follows for conversations in the departed custom group" do
    club_id = Memba.ID.generate(:club)
    departing_membership_id = Memba.ID.generate(:membership)
    departing_person_id = Memba.ID.generate(:person)
    replacement_membership_id = Memba.ID.generate(:membership)
    replacement_person_id = Memba.ID.generate(:person)
    custom_group_id = Memba.ID.generate(:group)
    conversation_id = Memba.ID.generate(:message)

    create_club(club_id)
    add_member(club_id, departing_membership_id, departing_person_id)
    add_member(club_id, replacement_membership_id, replacement_person_id)
    assign_admin(club_id, replacement_membership_id, replacement_person_id)
    create_custom_group(club_id, custom_group_id)
    add_group_member(club_id, custom_group_id, departing_membership_id, departing_person_id)
    create_followed_conversation(club_id, custom_group_id, conversation_id, departing_person_id)

    assert Messaging.following_conversation?(conversation_id, departing_person_id)

    assert :ok =
             MembershipApp.dispatch(
               %RemoveClubMember{
                 club_id: club_id,
                 membership_id: departing_membership_id,
                 person_id: departing_person_id
               },
               consistency: :strong
             )

    refute Messaging.following_conversation?(conversation_id, departing_person_id)
    assert count_unfollow_events(conversation_id, departing_person_id) == 1
  end

  test "club departure completes follow clearing before a rapid re-add" do
    club_id = Memba.ID.generate(:club)
    departing_membership_id = Memba.ID.generate(:membership)
    departing_person_id = Memba.ID.generate(:person)
    replacement_membership_id = Memba.ID.generate(:membership)
    replacement_person_id = Memba.ID.generate(:person)
    rejoined_membership_id = Memba.ID.generate(:membership)
    custom_group_id = Memba.ID.generate(:group)
    conversation_id = Memba.ID.generate(:message)

    create_person(departing_person_id, "Departing Member", "departing@example.com")
    create_person(replacement_person_id, "Replacement Member", "replacement@example.com")
    create_club(club_id)
    add_member(club_id, departing_membership_id, departing_person_id)
    add_member(club_id, replacement_membership_id, replacement_person_id)
    assign_admin(club_id, replacement_membership_id, replacement_person_id)
    create_custom_group(club_id, custom_group_id)
    add_group_member(club_id, custom_group_id, departing_membership_id, departing_person_id)

    add_group_member(
      club_id,
      custom_group_id,
      replacement_membership_id,
      replacement_person_id
    )

    create_followed_conversation(club_id, custom_group_id, conversation_id, departing_person_id)

    clear_follows_handler = clear_follows_handler_pid()
    removal_target_version = latest_club_stream_version(club_id) + 2
    :ok = :sys.suspend(clear_follows_handler)

    removal =
      Task.async(fn ->
        Membership.remove_member(%{
          club_id: club_id,
          membership_id: departing_membership_id,
          person_id: departing_person_id
        })
      end)

    readdition =
      try do
        assert :ok =
                 Subscriptions.wait_for(
                   MembershipApp,
                   club_id,
                   removal_target_version,
                   [consistency: [SystemGroupMembership]],
                   1_000
                 )

        assert Task.yield(removal, 100) == nil

        assert :ok = EventStore.subscribe(MembershipApp, club_id)
        assert :ok = Phoenix.PubSub.subscribe(Memba.PubSub, Memba.ReadModelChanges.topic())

        readdition =
          Task.async(fn ->
            Membership.add_member(%{
              club_id: club_id,
              membership_id: rejoined_membership_id,
              person_id: departing_person_id
            })
          end)

        assert is_integer(await_club_member_added!(rejoined_membership_id))

        assert %Club{
                 active_memberships: %{
                   ^rejoined_membership_id => ^departing_person_id
                 }
               } = MembershipApp.aggregate_state(Club, club_id)

        assert Task.yield(readdition, 100) == nil

        refute Membership.active_member_of_club?(club_id, departing_person_id)

        reply_message_id = Memba.ID.generate(:message)

        assert {:ok, %ExecutionResult{events: reply_events}} =
                 Messaging.post_message_reply(
                   %{
                     message_id: reply_message_id,
                     conversation_id: conversation_id,
                     sender_id: replacement_person_id,
                     body: "Cleanup still has to finish."
                   },
                   returning: :execution_result,
                   consistency: :strong
                 )

        refute Enum.any?(reply_events, fn
                 %EmailDeliveryCreated{recipient_id: ^departing_person_id} -> true
                 _event -> false
               end)

        readdition
      after
        :ok = :sys.resume(clear_follows_handler)
      end

    assert :ok = Task.await(removal)
    assert :ok = Task.await(readdition)

    assert_receive {:read_model_changed,
                    %{
                      projector: MembershipProjector,
                      source_event: %ClubMemberAdded{membership_id: ^rejoined_membership_id}
                    }},
                   1_000

    assert %MembershipProjection{active: true} =
             Repo.get(MembershipProjection, rejoined_membership_id)

    assert Membership.active_member_of_club?(club_id, departing_person_id)
    refute Messaging.following_conversation?(conversation_id, departing_person_id)

    everyone_group_id = SystemGroups.everyone_group_id(club_id)

    assert %Club{
             group_memberships: %{
               {^custom_group_id, ^departing_membership_id} => %{active: false},
               {^everyone_group_id, ^rejoined_membership_id} => %{active: true}
             }
           } = MembershipApp.aggregate_state(Club, club_id)
  end

  test "explicit custom-group admission after club rejoin does not restore cleared follows" do
    club_id = Memba.ID.generate(:club)
    departing_membership_id = Memba.ID.generate(:membership)
    rejoined_membership_id = Memba.ID.generate(:membership)
    returning_person_id = Memba.ID.generate(:person)
    actor_membership_id = Memba.ID.generate(:membership)
    actor_person_id = Memba.ID.generate(:person)
    custom_group_id = Memba.ID.generate(:group)
    conversation_id = Memba.ID.generate(:message)

    create_person(returning_person_id, "Returning Member", "returning@example.com")
    create_person(actor_person_id, "Group Member", "group-member@example.com")
    create_club(club_id)
    add_member(club_id, departing_membership_id, returning_person_id)
    add_member(club_id, actor_membership_id, actor_person_id)
    assign_admin(club_id, actor_membership_id, actor_person_id)
    create_custom_group(club_id, custom_group_id)
    add_group_member(club_id, custom_group_id, departing_membership_id, returning_person_id)
    add_group_member(club_id, custom_group_id, actor_membership_id, actor_person_id)
    create_followed_conversation(club_id, custom_group_id, conversation_id, returning_person_id)

    assert Messaging.following_conversation?(conversation_id, returning_person_id)

    assert :ok =
             Membership.remove_member(%{
               club_id: club_id,
               membership_id: departing_membership_id,
               person_id: returning_person_id
             })

    refute Messaging.following_conversation?(conversation_id, returning_person_id)

    assert :ok =
             Membership.add_member(%{
               club_id: club_id,
               membership_id: rejoined_membership_id,
               person_id: returning_person_id
             })

    assert {:ok,
            %CustomGroupAdmission{
              membership_id: ^rejoined_membership_id,
              person_id: ^returning_person_id,
              transition: :member_added
            }} =
             Membership.add_custom_group_member(
               %{
                 club_id: club_id,
                 group_id: custom_group_id,
                 membership_id: rejoined_membership_id,
                 person_id: returning_person_id,
                 actor_person_id: actor_person_id
               },
               consistency: :strong
             )

    refute Messaging.following_conversation?(conversation_id, returning_person_id)

    assert %GroupMembershipProjection{active: false} =
             Repo.get_by(GroupMembershipProjection,
               group_id: custom_group_id,
               membership_id: departing_membership_id
             )

    assert %GroupMembershipProjection{active: true} =
             Repo.get_by(GroupMembershipProjection,
               group_id: custom_group_id,
               membership_id: rejoined_membership_id
             )

    assert [
             %GroupMemberAdded{membership_id: ^departing_membership_id},
             %GroupMemberRemoved{membership_id: ^departing_membership_id},
             %GroupMemberAdded{membership_id: ^rejoined_membership_id}
           ] =
             club_id
             |> then(&EventStore.stream_forward(MembershipApp, &1))
             |> Enum.map(& &1.data)
             |> Enum.filter(fn
               %event_module{group_id: ^custom_group_id, person_id: ^returning_person_id}
               when event_module in [GroupMemberAdded, GroupMemberRemoved] ->
                 true

               _event ->
                 false
             end)
  end

  test "handling the same custom-group removal repeatedly is idempotent" do
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    membership_id = Memba.ID.generate(:membership)
    person_id = Memba.ID.generate(:person)
    conversation_id = Memba.ID.generate(:message)

    create_followed_conversation(club_id, group_id, conversation_id, person_id)

    event = %GroupMemberRemoved{
      club_id: club_id,
      group_id: group_id,
      membership_id: membership_id,
      person_id: person_id
    }

    metadata = %{event_id: Ecto.UUID.generate(), event_number: current_checkpoint()}

    assert :ok = ClearRemovedGroupMemberFollows.handle(event, metadata)
    assert :ok = ClearRemovedGroupMemberFollows.handle(event, metadata)

    refute Messaging.following_conversation?(conversation_id, person_id)
    assert count_unfollow_events(conversation_id, person_id) == 1
  end

  test "cleanup accepts execution-result returns from public Messaging unfollows" do
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    person_id = Memba.ID.generate(:person)
    conversation_id = Memba.ID.generate(:message)

    create_followed_conversation(club_id, group_id, conversation_id, person_id)

    assert :ok =
             Messaging.clear_removed_group_member_follows(
               %{
                 club_id: club_id,
                 group_id: group_id,
                 member_id: person_id,
                 cleanup_id: Ecto.UUID.generate(),
                 membership_generation: 0,
                 checkpoint: current_checkpoint()
               },
               returning: :execution_result,
               consistency: :strong
             )

    refute Messaging.following_conversation?(conversation_id, person_id)
  end

  test "explicit custom-group removal durably clears manual, root, and reply auto-follows" do
    fixture = explicit_removal_fixture!()
    manual_conversation_id = Memba.ID.generate(:message)
    root_conversation_id = Memba.ID.generate(:message)
    reply_conversation_id = Memba.ID.generate(:message)

    create_conversation(
      fixture.club_id,
      fixture.group_id,
      manual_conversation_id,
      fixture.actor_person_id
    )

    assert :ok =
             Messaging.follow_conversation(
               %{
                 club_id: fixture.club_id,
                 conversation_id: manual_conversation_id,
                 member_id: fixture.target_person_id
               },
               consistency: :strong
             )

    create_conversation(
      fixture.club_id,
      fixture.group_id,
      root_conversation_id,
      fixture.target_person_id
    )

    create_conversation(
      fixture.club_id,
      fixture.group_id,
      reply_conversation_id,
      fixture.actor_person_id
    )

    assert {:ok, %ExecutionResult{events: [%MessageSent{}]}} =
             Messaging.post_message_reply(
               %{
                 message_id: Memba.ID.generate(:message),
                 sender_id: fixture.target_person_id,
                 conversation_id: reply_conversation_id,
                 body: "Reply auto-follow"
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert [
             %ConversationFollowed{
               member_id: target_person_id,
               membership_generation: reply_generation
             }
           ] = follow_events(reply_conversation_id, fixture.target_person_id)

    assert target_person_id == fixture.target_person_id
    assert is_integer(reply_generation)
    assert reply_generation > 0

    for conversation_id <- [
          manual_conversation_id,
          root_conversation_id,
          reply_conversation_id
        ] do
      assert Messaging.following_conversation?(conversation_id, fixture.target_person_id)
    end

    assert {:ok, %ExecutionResult{events: [%GroupMemberRemoved{}]}} =
             remove_custom_group_member(fixture, returning: :execution_result)

    for conversation_id <- [
          manual_conversation_id,
          root_conversation_id,
          reply_conversation_id
        ] do
      refute Messaging.following_conversation?(conversation_id, fixture.target_person_id)

      assert [
               %ConversationUnfollowed{
                 member_id: target_person_id,
                 cleanup_id: cleanup_id
               }
             ] = unfollow_events(conversation_id, fixture.target_person_id)

      assert target_person_id == fixture.target_person_id
      assert is_binary(cleanup_id)
    end
  end

  test "cleanup preserves unrelated follows and shared conversations with surviving access" do
    fixture = explicit_removal_fixture!()
    retained_group_id = Memba.ID.generate(:group)
    unrelated_conversation_id = Memba.ID.generate(:message)
    shared_conversation_id = Memba.ID.generate(:message)

    create_custom_group(fixture.club_id, retained_group_id, "Trips", "trips")

    add_group_member(
      fixture.club_id,
      retained_group_id,
      fixture.target_membership_id,
      fixture.target_person_id
    )

    create_followed_conversation(
      fixture.club_id,
      retained_group_id,
      unrelated_conversation_id,
      fixture.target_person_id
    )

    create_followed_conversation(
      fixture.club_id,
      fixture.group_id,
      shared_conversation_id,
      fixture.target_person_id
    )

    assert :ok =
             Messaging.grant_conversation_access_to_group(
               %{
                 conversation_id: shared_conversation_id,
                 club_id: fixture.club_id,
                 group_id: retained_group_id,
                 access_level: :write
               },
               consistency: :strong
             )

    assert :ok = remove_custom_group_member(fixture)

    assert Messaging.following_conversation?(
             unrelated_conversation_id,
             fixture.target_person_id
           )

    assert Messaging.following_conversation?(shared_conversation_id, fixture.target_person_id)
    assert count_unfollow_events(unrelated_conversation_id, fixture.target_person_id) == 0
    assert count_unfollow_events(shared_conversation_id, fixture.target_person_id) == 0

    recorded_removal =
      fixture.club_id
      |> then(&EventStore.stream_forward(MembershipApp, &1))
      |> Enum.find(fn
        %{data: %GroupMemberRemoved{group_id: group_id, membership_id: membership_id}} ->
          group_id == fixture.group_id and membership_id == fixture.target_membership_id

        _event ->
          false
      end)

    assert {:ok, %CustomGroupAdmission{transition: :member_added}} =
             Membership.add_custom_group_member(%{
               club_id: fixture.club_id,
               group_id: fixture.group_id,
               membership_id: fixture.target_membership_id,
               person_id: fixture.target_person_id,
               actor_person_id: fixture.actor_person_id
             })

    assert :ok =
             Messaging.follow_conversation(
               %{
                 club_id: fixture.club_id,
                 conversation_id: shared_conversation_id,
                 member_id: fixture.target_person_id
               },
               consistency: :strong
             )

    assert :ok =
             Messaging.revoke_conversation_access_from_group(
               %{
                 club_id: fixture.club_id,
                 conversation_id: shared_conversation_id,
                 group_id: retained_group_id
               },
               consistency: :strong
             )

    assert :ok =
             ClearRemovedGroupMemberFollows.handle(recorded_removal.data, %{
               event_id: recorded_removal.event_id,
               event_number: recorded_removal.event_number
             })

    assert Messaging.following_conversation?(shared_conversation_id, fixture.target_person_id)

    assert [
             %ConversationUnfollowed{
               member_id: target_person_id,
               follow_retained: true
             }
           ] = unfollow_events(shared_conversation_id, fixture.target_person_id)

    assert target_person_id == fixture.target_person_id
  end

  test "first delayed removal delivery cannot erase newer follows after a genuine re-add" do
    fixture = explicit_removal_fixture!()
    conversation_id = Memba.ID.generate(:message)
    later_conversation_id = Memba.ID.generate(:message)

    create_followed_conversation(
      fixture.club_id,
      fixture.group_id,
      conversation_id,
      fixture.target_person_id
    )

    clear_follows_handler = clear_follows_handler_pid()
    :ok = :sys.suspend(clear_follows_handler)

    recorded_removal =
      try do
        assert {:ok, %ExecutionResult{events: [%GroupMemberRemoved{}]}} =
                 MembershipApp.dispatch(
                   %RemoveCustomGroupMember{
                     club_id: fixture.club_id,
                     group_id: fixture.group_id,
                     membership_id: fixture.target_membership_id,
                     person_id: fixture.target_person_id,
                     actor_person_id: fixture.actor_person_id
                   },
                   returning: :execution_result
                 )

        recorded_removal =
          fixture.club_id
          |> then(&EventStore.stream_forward(MembershipApp, &1))
          |> Enum.find(fn recorded_event ->
            match?(
              %GroupMemberRemoved{
                group_id: group_id,
                membership_id: membership_id
              }
              when group_id == fixture.group_id and
                     membership_id == fixture.target_membership_id,
              recorded_event.data
            )
          end)

        assert %GroupMemberRemoved{
                 club_id: _club_id,
                 group_id: _group_id,
                 membership_id: _membership_id,
                 person_id: _person_id,
                 membership_generation: removed_generation
               } = recorded_removal.data

        assert is_integer(removed_generation)

        assert {:ok, %ExecutionResult{events: [%GroupMemberAdded{}]}} =
                 MembershipApp.dispatch(
                   %AddCustomGroupMember{
                     club_id: fixture.club_id,
                     group_id: fixture.group_id,
                     membership_id: fixture.target_membership_id,
                     person_id: fixture.target_person_id,
                     actor_person_id: fixture.actor_person_id
                   },
                   returning: :execution_result
                 )

        assert :ok =
                 Messaging.follow_conversation(
                   %{
                     club_id: fixture.club_id,
                     conversation_id: conversation_id,
                     member_id: fixture.target_person_id
                   },
                   consistency: :strong
                 )

        create_followed_conversation(
          fixture.club_id,
          fixture.group_id,
          later_conversation_id,
          fixture.target_person_id
        )

        assert :ok =
                 ClearRemovedGroupMemberFollows.handle(recorded_removal.data, %{
                   event_id: recorded_removal.event_id,
                   event_number: recorded_removal.event_number,
                   stream_version: recorded_removal.stream_version
                 })

        recorded_removal
      after
        :ok = :sys.resume(clear_follows_handler)
      end

    assert is_binary(recorded_removal.event_id)

    for current_conversation_id <- [conversation_id, later_conversation_id] do
      assert Messaging.following_conversation?(
               current_conversation_id,
               fixture.target_person_id
             )

      assert count_unfollow_events(current_conversation_id, fixture.target_person_id) == 1
    end

    assert [
             %ConversationFollowed{membership_generation: initial_generation},
             %ConversationFollowed{membership_generation: refreshed_generation}
           ] = follow_events(conversation_id, fixture.target_person_id)

    assert [%MessageSent{sender_membership_generation: ^initial_generation} | _events] =
             conversation_id
             |> then(&EventStore.stream_forward(MessagingApp, &1))
             |> Enum.map(& &1.data)

    assert refreshed_generation > initial_generation
  end

  test "cleanup acknowledged before a prepared root is dispatched blocks its stale auto-follow" do
    fixture = explicit_removal_fixture!()
    conversation_id = Memba.ID.generate(:message)
    prepared_generation = Membership.current_group_membership_generation(fixture.club_id)

    prepared_send = %SendMessage{
      message_id: conversation_id,
      club_id: fixture.club_id,
      sender_id: fixture.target_person_id,
      audience_group_id: fixture.group_id,
      subject: "Prepared before removal",
      body: "Dispatched only after cleanup acknowledgement.",
      sender_membership_generation: prepared_generation,
      recipients: [
        %Recipient{
          delivery_id: Memba.ID.generate(:delivery),
          person_id: fixture.target_person_id,
          name: "Departing Member",
          email: "departing@example.com"
        }
      ]
    }

    assert :ok = remove_custom_group_member(fixture)
    stop_event_sourced_aggregate_instances!()

    assert :ok = MessagingApp.dispatch(prepared_send, consistency: :strong)

    assert [] = follow_events(conversation_id, fixture.target_person_id)
    refute Messaging.following_conversation?(conversation_id, fixture.target_person_id)
  end

  test "public eventual removal, re-add, and exact retry await durable cleanup progress" do
    fixture = explicit_removal_fixture!()
    conversation_id = Memba.ID.generate(:message)

    create_followed_conversation(
      fixture.club_id,
      fixture.group_id,
      conversation_id,
      fixture.target_person_id
    )

    clear_follows_handler = clear_follows_handler_pid()
    assert :ok = EventStore.subscribe(MembershipApp, fixture.club_id)
    :ok = :sys.suspend(clear_follows_handler)

    removal =
      Task.async(fn ->
        remove_custom_group_member(fixture, consistency: :eventual)
      end)

    {readdition, retry} =
      try do
        removed_generation = await_group_member_removed!(fixture.target_membership_id)
        assert Task.yield(removal, 100) == nil

        retry =
          Task.async(fn ->
            remove_custom_group_member(fixture,
              consistency: :eventual,
              returning: :execution_result
            )
          end)

        assert Task.yield(retry, 100) == nil

        readdition =
          Task.async(fn ->
            Membership.add_custom_group_member(
              %{
                club_id: fixture.club_id,
                group_id: fixture.group_id,
                membership_id: fixture.target_membership_id,
                person_id: fixture.target_person_id,
                actor_person_id: fixture.actor_person_id
              },
              consistency: :eventual
            )
          end)

        added_generation = await_group_member_added_generation!(fixture.target_membership_id)
        assert added_generation > removed_generation
        assert Task.yield(readdition, 100) == nil

        assert :ok =
                 Messaging.follow_conversation(
                   %{
                     club_id: fixture.club_id,
                     conversation_id: conversation_id,
                     member_id: fixture.target_person_id
                   },
                   consistency: :strong
                 )

        {readdition, retry}
      after
        :ok = :sys.resume(clear_follows_handler)
      end

    assert :ok = Task.await(removal, 5_000)

    assert {:ok, %CustomGroupAdmission{transition: :member_added}} =
             Task.await(readdition, 5_000)

    assert {:ok, %ExecutionResult{events: []}} = Task.await(retry, 5_000)
    assert Messaging.following_conversation?(conversation_id, fixture.target_person_id)
  end

  test "explicit removal waits for lagging conversation access before acknowledging cleanup" do
    fixture = explicit_removal_fixture!()
    conversation_id = Memba.ID.generate(:message)
    projector_child_id = stop_projector!(ConversationGroupAccessProjector)

    create_followed_conversation(
      fixture.club_id,
      fixture.group_id,
      conversation_id,
      fixture.target_person_id,
      consistency: [
        Memba.Messaging.Projectors.Message,
        Memba.Messaging.Projectors.ConversationFollow
      ]
    )

    assert [] = Messaging.list_conversations_for_group(fixture.group_id)

    removal = Task.async(fn -> remove_custom_group_member(fixture) end)

    try do
      assert Task.yield(removal, 100) == nil
      restart_projector!(projector_child_id)

      assert :ok = Task.await(removal, 5_000)
      refute Messaging.following_conversation?(conversation_id, fixture.target_person_id)
    after
      if projector_child_id, do: restart_projector!(projector_child_id)
    end
  end

  test "system-group removal facts do not clear follows" do
    club_id = Memba.ID.generate(:club)
    person_id = Memba.ID.generate(:person)

    for group_id <- [
          SystemGroups.everyone_group_id(club_id),
          SystemGroups.admin_group_id(club_id)
        ] do
      conversation_id = Memba.ID.generate(:message)
      create_followed_conversation(club_id, group_id, conversation_id, person_id)

      assert :ok =
               ClearRemovedGroupMemberFollows.handle(
                 %GroupMemberRemoved{
                   club_id: club_id,
                   group_id: group_id,
                   membership_id: Memba.ID.generate(:membership),
                   person_id: person_id
                 },
                 %{event_id: Ecto.UUID.generate(), event_number: current_checkpoint()}
               )

      assert Messaging.following_conversation?(conversation_id, person_id)
      assert count_unfollow_events(conversation_id, person_id) == 0
    end
  end

  defp create_person(person_id, name, email) do
    assert :ok =
             MembershipApp.dispatch(
               %CreatePerson{
                 person_id: person_id,
                 name: name,
                 email: email
               },
               consistency: :strong
             )
  end

  defp create_club(club_id) do
    assert :ok =
             MembershipApp.dispatch(
               %CreateClub{
                 club_id: club_id,
                 name: "Kootenay Mountaineering Club",
                 slug: membership_club_slug("Kootenay Mountaineering Club", club_id)
               },
               consistency: :strong
             )
  end

  defp add_member(club_id, membership_id, person_id) do
    assert :ok =
             MembershipApp.dispatch(
               %AddClubMember{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id
               },
               consistency: :strong
             )
  end

  defp assign_admin(club_id, membership_id, person_id) do
    assert :ok =
             MembershipApp.dispatch(
               %AssignClubRoleToMember{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: Roles.membership_administrator_role_id(club_id)
               },
               consistency: :strong
             )
  end

  defp create_custom_group(club_id, group_id) do
    create_custom_group(club_id, group_id, "Board", "board")
  end

  defp create_custom_group(club_id, group_id, name, email_slug) do
    assert :ok =
             MembershipApp.dispatch(
               %CreateGroup{
                 club_id: club_id,
                 group_id: group_id,
                 email_slug: email_slug,
                 name: name
               },
               consistency: :strong
             )
  end

  defp add_group_member(club_id, group_id, membership_id, person_id) do
    assert :ok =
             MembershipApp.dispatch(
               %AddGroupMember{
                 club_id: club_id,
                 group_id: group_id,
                 membership_id: membership_id,
                 person_id: person_id
               },
               consistency: :strong
             )
  end

  defp create_followed_conversation(
         club_id,
         group_id,
         conversation_id,
         person_id,
         opts \\ []
       ) do
    create_conversation(club_id, group_id, conversation_id, person_id, opts)

    assert :ok =
             Messaging.follow_conversation(
               %{
                 club_id: club_id,
                 conversation_id: conversation_id,
                 member_id: person_id
               },
               consistency: Keyword.get(opts, :consistency, :strong)
             )
  end

  defp create_conversation(club_id, group_id, conversation_id, person_id, opts \\ []) do
    assert :ok =
             MessagingApp.dispatch(
               %SendMessage{
                 message_id: conversation_id,
                 club_id: club_id,
                 sender_id: person_id,
                 audience_group_id: group_id,
                 subject: "Board plans",
                 body: "Private plans for the board.",
                 sender_membership_generation:
                   Membership.current_group_membership_generation(club_id),
                 recipients: [
                   %Recipient{
                     delivery_id: Memba.ID.generate(:delivery),
                     person_id: person_id,
                     name: "Departing Member",
                     email: "departing@example.com"
                   }
                 ]
               },
               consistency: Keyword.get(opts, :consistency, :strong)
             )
  end

  defp explicit_removal_fixture! do
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    actor_membership_id = Memba.ID.generate(:membership)
    actor_person_id = Memba.ID.generate(:person)
    target_membership_id = Memba.ID.generate(:membership)
    target_person_id = Memba.ID.generate(:person)

    create_club(club_id)
    add_member(club_id, actor_membership_id, actor_person_id)
    add_member(club_id, target_membership_id, target_person_id)
    create_custom_group(club_id, group_id)
    add_group_member(club_id, group_id, actor_membership_id, actor_person_id)
    add_group_member(club_id, group_id, target_membership_id, target_person_id)

    %{
      club_id: club_id,
      group_id: group_id,
      actor_person_id: actor_person_id,
      target_person_id: target_person_id,
      target_membership_id: target_membership_id
    }
  end

  defp remove_custom_group_member(fixture, opts \\ []) do
    Membership.remove_custom_group_member(
      %{
        club_id: fixture.club_id,
        group_id: fixture.group_id,
        membership_id: fixture.target_membership_id,
        person_id: fixture.target_person_id,
        actor_person_id: fixture.actor_person_id
      },
      opts
    )
  end

  defp count_unfollow_events(conversation_id, person_id) do
    conversation_id
    |> unfollow_events(person_id)
    |> length()
  end

  defp follow_events(conversation_id, person_id) do
    conversation_id
    |> then(&EventStore.stream_forward(MessagingApp, &1))
    |> Enum.flat_map(fn recorded_event ->
      case recorded_event.data do
        %ConversationFollowed{member_id: ^person_id} = event -> [event]
        _event -> []
      end
    end)
  end

  defp unfollow_events(conversation_id, person_id) do
    conversation_id
    |> then(&EventStore.stream_forward(MessagingApp, &1))
    |> Enum.flat_map(fn recorded_event ->
      case recorded_event.data do
        %ConversationUnfollowed{member_id: ^person_id} = event -> [event]
        _event -> []
      end
    end)
  end

  defp clear_follows_handler_pid do
    handler_name =
      Handler.name(
        MembershipApp,
        inspect(ClearRemovedGroupMemberFollows)
      )

    assert pid = Registration.whereis_name(MembershipApp, handler_name)
    pid
  end

  defp stop_membership_projector! do
    child_id =
      Supervisor.which_children(Memba.Supervisor)
      |> Enum.find_value(fn
        {child_id, _pid, :worker, [MembershipProjector]} -> child_id
        _child -> nil
      end)

    assert child_id
    assert :ok = Supervisor.terminate_child(Memba.Supervisor, child_id)

    on_exit(fn ->
      restart_membership_projector!(child_id)
    end)

    child_id
  end

  defp restart_membership_projector!(child_id) do
    case Supervisor.restart_child(Memba.Supervisor, child_id) do
      {:ok, _pid} -> :ok
      {:ok, _pid, _info} -> :ok
      {:error, :running} -> :ok
    end
  end

  defp stop_projector!(projector) do
    child_id =
      Supervisor.which_children(Memba.Supervisor)
      |> Enum.find_value(fn
        {child_id, _pid, :worker, [^projector]} -> child_id
        _child -> nil
      end)

    assert child_id
    assert :ok = Supervisor.terminate_child(Memba.Supervisor, child_id)
    child_id
  end

  defp restart_projector!(child_id) do
    case Supervisor.restart_child(Memba.Supervisor, child_id) do
      {:ok, _pid} -> :ok
      {:ok, _pid, _info} -> :ok
      {:error, :running} -> :ok
    end
  end

  defp current_checkpoint, do: Memba.ProjectionBarrier.current_checkpoint()

  defp latest_club_stream_version(club_id) do
    MembershipApp
    |> EventStore.stream_forward(club_id)
    |> Enum.to_list()
    |> List.last()
    |> Map.fetch!(:stream_version)
  end

  defp await_club_member_added!(membership_id) do
    deadline = System.monotonic_time(:millisecond) + 1_000
    await_club_member_added!(membership_id, deadline)
  end

  defp await_group_member_removed!(membership_id) do
    deadline = System.monotonic_time(:millisecond) + 1_000
    await_group_membership_generation!(GroupMemberRemoved, membership_id, deadline)
  end

  defp await_group_member_added_generation!(membership_id) do
    deadline = System.monotonic_time(:millisecond) + 1_000
    await_group_membership_generation!(GroupMemberAdded, membership_id, deadline)
  end

  defp await_group_membership_generation!(event_module, membership_id, deadline) do
    timeout = max(deadline - System.monotonic_time(:millisecond), 0)

    receive do
      {:events, events} ->
        case Enum.find(events, fn
               %{data: %{__struct__: ^event_module, membership_id: ^membership_id}} -> true
               _event -> false
             end) do
          %{data: %{membership_generation: membership_generation}}
          when is_integer(membership_generation) ->
            membership_generation

          nil ->
            await_group_membership_generation!(event_module, membership_id, deadline)
        end
    after
      timeout ->
        flunk("#{inspect(event_module)} was not persisted for membership #{membership_id}")
    end
  end

  defp await_club_member_added!(membership_id, deadline) do
    timeout = max(deadline - System.monotonic_time(:millisecond), 0)

    receive do
      {:events, events} ->
        case Enum.find(events, fn
               %{data: %ClubMemberAdded{membership_id: ^membership_id}} ->
                 true

               _event ->
                 false
             end) do
          %{event_number: event_number} -> event_number
          nil -> await_club_member_added!(membership_id, deadline)
        end
    after
      timeout ->
        flunk("ClubMemberAdded was not persisted for membership #{membership_id}")
    end
  end
end
