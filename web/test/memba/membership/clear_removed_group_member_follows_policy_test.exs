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
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.AssignClubRoleToMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreateGroup
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Commands.RemoveClubMember
  alias Memba.Membership.Events.ClubMemberAdded
  alias Memba.Membership.Events.GroupMemberRemoved
  alias Memba.Membership.Events.MemberAdded, as: LegacyMemberAdded
  alias Memba.Membership.Policies.ClearRemovedGroupMemberFollows
  alias Memba.Membership.Policies.SystemGroupMembership
  alias Memba.Membership.Projectors.Membership, as: MembershipProjector
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging
  alias Memba.Messaging.App, as: MessagingApp
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Events.ConversationUnfollowed
  alias Memba.Messaging.Events.EmailDeliveryCreated
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

    assert :ok = ClearRemovedGroupMemberFollows.handle(event, %{})
    assert :ok = ClearRemovedGroupMemberFollows.handle(event, %{})

    refute Messaging.following_conversation?(conversation_id, person_id)
    assert count_unfollow_events(conversation_id, person_id) == 1
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
    assert :ok =
             MembershipApp.dispatch(
               %CreateGroup{
                 club_id: club_id,
                 group_id: group_id,
                 email_slug: "board",
                 name: "Board"
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

  defp create_followed_conversation(club_id, group_id, conversation_id, person_id) do
    assert :ok =
             MessagingApp.dispatch(
               %SendMessage{
                 message_id: conversation_id,
                 club_id: club_id,
                 sender_id: person_id,
                 audience_group_id: group_id,
                 subject: "Board plans",
                 body: "Private plans for the board.",
                 recipients: [
                   %Recipient{
                     delivery_id: Memba.ID.generate(:delivery),
                     person_id: person_id,
                     name: "Departing Member",
                     email: "departing@example.com"
                   }
                 ]
               },
               consistency: :strong
             )

    assert :ok =
             Messaging.follow_conversation(
               %{
                 club_id: club_id,
                 conversation_id: conversation_id,
                 member_id: person_id
               },
               consistency: :strong
             )
  end

  defp count_unfollow_events(conversation_id, person_id) do
    conversation_id
    |> then(&EventStore.stream_forward(MessagingApp, &1))
    |> Enum.count(fn recorded_event ->
      match?(%ConversationUnfollowed{member_id: ^person_id}, recorded_event.data)
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
