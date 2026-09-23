defmodule Memba.Messaging.SendClubMessageTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership.App, as: MembershipApp
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.AddClubMember
  alias Memba.Membership.Commands.AssignClubRoleToMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreateGroup
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Commands.RemoveGroupMember
  alias Memba.Membership.Commands.RemoveClubMember
  alias Memba.Membership.Projectors.GroupMembership, as: GroupMembershipProjector
  alias Memba.Membership.Projectors.Membership, as: MembershipProjector
  alias Memba.Membership.Policies.SystemGroupMembership
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging
  alias Memba.Messaging.EmailDeliveryDispatcher
  alias Memba.Messaging.EmailDeliveryProviders.Fake
  alias Memba.Messaging.EmailDeliveryProviders.Postmark
  alias Memba.Messaging.EmailDeliveryRequest
  alias Memba.Messaging.Events.ConversationAccessGrantedToGroup
  alias Memba.Messaging.Events.EmailDeliveryCreated
  alias Memba.Messaging.Events.MessageSent

  alias Memba.Messaging.Projectors.ConversationGroupAccess,
    as: ConversationGroupAccessProjector

  alias Memba.Messaging.Projectors.ConversationFollow,
    as: ConversationFollowProjector

  alias Memba.Messaging.Projectors.Message, as: MessageProjector
  alias Memba.Messaging.Projections.EmailDelivery, as: EmailDeliveryProjection
  alias Memba.Messaging.Projections.Message, as: MessageProjection

  @email_delivery_replay_projectors [
    Memba.Messaging.Projectors.EmailDelivery
  ]

  setup do
    original_provider = Application.get_env(:memba, :messaging_email_delivery_provider)

    original_projection_timeout =
      Application.get_env(:memba, :email_delivery_projection_timeout)

    original_authorization_stability_timeout =
      Application.get_env(:memba, :authorization_stability_timeout)

    original_mailer_config = Application.get_env(:memba, Memba.Mailer)
    original_postmark_config = Application.get_env(:memba, Postmark)
    dispatcher_was_running? = stop_email_delivery_dispatcher()

    Fake.reset()

    on_exit(fn ->
      restore_env(:messaging_email_delivery_provider, original_provider)
      restore_env(:email_delivery_projection_timeout, original_projection_timeout)
      restore_env(:authorization_stability_timeout, original_authorization_stability_timeout)
      restore_env(Memba.Mailer, original_mailer_config)
      restore_env(Postmark, original_postmark_config)
      Fake.reset()
      restart_email_delivery_dispatcher(dispatcher_was_running?)
    end)

    :ok
  end

  test "resolves active Everyone group members via Membership and records pending delivery work without provider handoff" do
    kootenay_club_id = Memba.ID.generate(:club)
    nelson_club_id = Memba.ID.generate(:club)
    create_club(kootenay_club_id, "Kootenay Mountaineering Club")
    create_club(nelson_club_id, "Nelson Cycling Club")
    everyone_group_id = SystemGroups.everyone_group_id(kootenay_club_id)

    alice = create_person(name: "Alice", email: "alice@example.com")
    bob = create_person(name: "Bob", email: "bob@example.com")
    carol = create_person(name: "Carol", email: "carol@example.com")
    dana = create_person(name: "Dana", email: "dana@example.com")
    pat = create_person(name: "Pat", email: "pat@example.com")

    add_member(kootenay_club_id, alice.person_id)
    add_member(kootenay_club_id, bob.person_id)
    add_member(kootenay_club_id, carol.person_id)
    insert_active_membership_projection_without_group(kootenay_club_id, dana.person_id)
    add_member(nelson_club_id, pat.person_id)

    message_id = Memba.ID.generate(:message)

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^message_id,
              aggregate_version: 5,
              events: [
                %MessageSent{
                  message_id: ^message_id,
                  club_id: ^kootenay_club_id,
                  sender_id: sender_id,
                  subject: "Trip planning night",
                  body: "Bring route ideas."
                },
                %ConversationAccessGrantedToGroup{
                  conversation_id: ^message_id,
                  club_id: ^kootenay_club_id,
                  group_id: ^everyone_group_id,
                  access_level: "write"
                }
                | delivery_events
              ]
            }} =
             Messaging.send_club_message(
               %{
                 message_id: message_id,
                 club_id: kootenay_club_id,
                 sender_id: alice.person_id,
                 subject: "Trip planning night",
                 body: "Bring route ideas."
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert sender_id == alice.person_id

    assert [
             %EmailDeliveryCreated{
               message_id: ^message_id,
               recipient_id: alice_id,
               recipient_name: "Alice",
               recipient_email: "alice@example.com"
             },
             %EmailDeliveryCreated{
               message_id: ^message_id,
               recipient_id: bob_id,
               recipient_name: "Bob",
               recipient_email: "bob@example.com"
             },
             %EmailDeliveryCreated{
               message_id: ^message_id,
               recipient_id: carol_id,
               recipient_name: "Carol",
               recipient_email: "carol@example.com"
             }
           ] = delivery_events

    assert [alice_id, bob_id, carol_id] == [alice.person_id, bob.person_id, carol.person_id]
    refute dana.person_id in Enum.map(delivery_events, & &1.recipient_id)
    refute pat.person_id in Enum.map(delivery_events, & &1.recipient_id)

    delivery_ids = Enum.map(delivery_events, & &1.delivery_id)

    assert Enum.all?(delivery_ids, &Memba.ID.valid?(:delivery, &1))
    assert Enum.uniq(delivery_ids) == delivery_ids

    assert Fake.deliveries() == []

    assert [
             %EmailDeliveryProjection{
               message_id: ^message_id,
               delivery_id: alice_delivery_id,
               recipient_id: ^alice_id,
               recipient_name: "Alice",
               recipient_address: "alice@example.com",
               channel: "email",
               status: "pending"
             },
             %EmailDeliveryProjection{
               message_id: ^message_id,
               delivery_id: bob_delivery_id,
               recipient_id: ^bob_id,
               recipient_name: "Bob",
               recipient_address: "bob@example.com",
               channel: "email",
               status: "pending"
             },
             %EmailDeliveryProjection{
               message_id: ^message_id,
               delivery_id: carol_delivery_id,
               recipient_id: ^carol_id,
               recipient_name: "Carol",
               recipient_address: "carol@example.com",
               channel: "email",
               status: "pending"
             }
           ] =
             pending_deliveries_for_message(message_id)

    assert [alice_delivery_id, bob_delivery_id, carol_delivery_id] == delivery_ids
  end

  test "resolves recipients from the selected audience group and grants it write access" do
    club_id = Memba.ID.generate(:club)
    create_club(club_id, "Kootenay Mountaineering Club")
    admin_group_id = SystemGroups.admin_group_id(club_id)

    alice = create_person(name: "Alice Admin", email: "alice@example.com")
    bob = create_person(name: "Bob Admin", email: "bob@example.com")
    carol = create_person(name: "Carol Member", email: "carol@example.com")
    dana = create_person(name: "Dana Former Admin", email: "dana@example.com")

    alice_membership_id = add_member(club_id, alice.person_id)
    bob_membership_id = add_member(club_id, bob.person_id)
    add_member(club_id, carol.person_id)
    dana_membership_id = add_member(club_id, dana.person_id)

    assign_admin_role(club_id, alice_membership_id, alice.person_id)
    assign_admin_role(club_id, bob_membership_id, bob.person_id)
    assign_admin_role(club_id, dana_membership_id, dana.person_id)

    assert :ok =
             MembershipApp.dispatch(
               %RemoveClubMember{
                 club_id: club_id,
                 membership_id: dana_membership_id,
                 person_id: dana.person_id
               },
               consistency: :strong
             )

    message_id = Memba.ID.generate(:message)

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^message_id,
              aggregate_version: 4,
              events: [
                %MessageSent{message_id: ^message_id},
                %ConversationAccessGrantedToGroup{
                  conversation_id: ^message_id,
                  club_id: ^club_id,
                  group_id: ^admin_group_id,
                  access_level: "write"
                }
                | delivery_events
              ]
            }} =
             Messaging.send_club_message(
               %{
                 message_id: message_id,
                 club_id: club_id,
                 sender_id: alice.person_id,
                 audience_group_id: admin_group_id,
                 subject: "Private Admin topic",
                 body: "Please discuss this with the Admin group."
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert [
             %EmailDeliveryCreated{recipient_id: alice_id},
             %EmailDeliveryCreated{recipient_id: bob_id}
           ] = delivery_events

    assert [alice_id, bob_id] == [alice.person_id, bob.person_id]
    refute carol.person_id in Enum.map(delivery_events, & &1.recipient_id)
    refute dana.person_id in Enum.map(delivery_events, & &1.recipient_id)
    assert is_nil(Messaging.get_member_email_delivery(message_id, dana.person_id))
    assert Messaging.group_has_conversation_access?(message_id, admin_group_id, :write)
  end

  test "resolves recipients from a future named group without system-group assumptions" do
    club_id = Memba.ID.generate(:club)
    create_club(club_id, "Kootenay Mountaineering Club")
    trips_group_id = create_group(club_id, "Trips committee")

    alice = create_person(name: "Alice", email: "alice@example.com")
    bob = create_person(name: "Bob", email: "bob@example.com")
    carol = create_person(name: "Carol", email: "carol@example.com")
    dana = create_person(name: "Dana", email: "dana@example.com")

    alice_membership_id = add_member(club_id, alice.person_id)
    bob_membership_id = add_member(club_id, bob.person_id)
    add_member(club_id, carol.person_id)
    dana_membership_id = add_member(club_id, dana.person_id)

    add_group_member(club_id, trips_group_id, alice_membership_id, alice.person_id)
    add_group_member(club_id, trips_group_id, bob_membership_id, bob.person_id)
    add_group_member(club_id, trips_group_id, dana_membership_id, dana.person_id)
    remove_group_member(club_id, trips_group_id, dana_membership_id, dana.person_id)

    message_id = Memba.ID.generate(:message)

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^message_id,
              aggregate_version: 4,
              events: [
                %MessageSent{message_id: ^message_id},
                %ConversationAccessGrantedToGroup{
                  conversation_id: ^message_id,
                  club_id: ^club_id,
                  group_id: ^trips_group_id,
                  access_level: "write"
                }
                | delivery_events
              ]
            }} =
             Messaging.send_club_message(
               %{
                 message_id: message_id,
                 club_id: club_id,
                 sender_id: alice.person_id,
                 audience_group_id: trips_group_id,
                 subject: "Summer objectives",
                 body: "Choose the committee's next trip."
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert [
             %EmailDeliveryCreated{recipient_id: alice_id},
             %EmailDeliveryCreated{recipient_id: bob_id}
           ] = delivery_events

    assert [alice_id, bob_id] == [alice.person_id, bob.person_id]
    refute carol.person_id in Enum.map(delivery_events, & &1.recipient_id)
    refute dana.person_id in Enum.map(delivery_events, & &1.recipient_id)
    assert Messaging.group_has_conversation_access?(message_id, trips_group_id, :write)
    assert [%{message_id: ^message_id}] = Messaging.list_conversations_for_group(trips_group_id)
  end

  test "does not hand private email to a departed member who has rejoined only Everyone" do
    club_id = Memba.ID.generate(:club)
    create_club(club_id, "Kootenay Mountaineering Club")

    alice = create_person(name: "Alice Admin", email: "alice@example.com")
    carol = create_person(name: "Carol Member", email: "carol@example.com")

    alice_membership_id = add_member(club_id, alice.person_id)
    carol_membership_id = add_member(club_id, carol.person_id)
    board_group_id = create_group(club_id, "Board")

    add_group_member(club_id, board_group_id, alice_membership_id, alice.person_id)
    add_group_member(club_id, board_group_id, carol_membership_id, carol.person_id)

    private_message_id = Memba.ID.generate(:message)

    assert :ok =
             Messaging.send_club_message(
               %{
                 message_id: private_message_id,
                 club_id: club_id,
                 sender_id: alice.person_id,
                 audience_group_id: board_group_id,
                 subject: "Private Board topic",
                 body: "Only current Board members should receive this."
               },
               consistency: :strong
             )

    assert [
             %EmailDeliveryProjection{recipient_id: alice_id},
             %EmailDeliveryProjection{
               delivery_id: carol_delivery_id,
               recipient_id: carol_id,
               status: "pending"
             }
           ] = pending_deliveries_for_message(private_message_id)

    assert [alice_id, carol_id] == [alice.person_id, carol.person_id]

    assert :ok =
             Messaging.follow_conversation(
               %{
                 club_id: club_id,
                 conversation_id: private_message_id,
                 member_id: carol.person_id
               },
               consistency: :strong
             )

    assert Messaging.following_conversation?(private_message_id, carol.person_id)

    assert :ok =
             Memba.Membership.remove_member(
               %{membership_id: carol_membership_id},
               consistency: :strong
             )

    assert :ok =
             Memba.Membership.add_member(
               %{
                 membership_id: Memba.ID.generate(:membership),
                 club_id: club_id,
                 person_id: carol.person_id
               },
               consistency: :strong
             )

    assert Memba.Membership.active_member_of_club?(club_id, carol.person_id)
    refute Memba.Membership.active_member_of_group?(board_group_id, carol.person_id)
    assert Messaging.following_conversation?(private_message_id, carol.person_id)

    departed_reply_id = Memba.ID.generate(:message)

    assert {:error, :not_current_member} =
             Messaging.post_message_reply(
               %{
                 message_id: departed_reply_id,
                 conversation_id: private_message_id,
                 sender_id: carol.person_id,
                 body: "Rejoining the club must not restore this private action."
               },
               consistency: :strong
             )

    refute Repo.get(MessageProjection, departed_reply_id)

    assert [
             %EmailDeliveryProjection{recipient_id: ^alice_id, status: "sent"},
             %EmailDeliveryProjection{
               delivery_id: ^carol_delivery_id,
               recipient_id: ^carol_id,
               status: "failed",
               latest_error: "recipient_access_ended",
               attempt_count: 1
             }
           ] = EmailDeliveryDispatcher.dispatch_pending_email_deliveries()

    assert [%EmailDeliveryRequest{recipient_id: ^alice_id}] = Fake.deliveries()

    later_message_id = Memba.ID.generate(:message)

    assert {:ok, %ExecutionResult{events: later_events}} =
             Messaging.send_club_message(
               %{
                 message_id: later_message_id,
                 club_id: club_id,
                 sender_id: alice.person_id,
                 audience_group_id: board_group_id,
                 subject: "Later Board topic",
                 body: "Carol should not be resolved as a recipient."
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert Enum.any?(later_events, &match?(%EmailDeliveryCreated{recipient_id: ^alice_id}, &1))
    refute Enum.any?(later_events, &match?(%EmailDeliveryCreated{recipient_id: ^carol_id}, &1))
  end

  test "startup recovers a projection-timeout deferral after dispatcher restart" do
    Application.put_env(:memba, :email_delivery_projection_timeout, 25)
    Application.put_env(:memba, :authorization_stability_timeout, 25)

    club_id = Memba.ID.generate(:club)
    create_club(club_id, "Kootenay Mountaineering Club")

    alice = create_person(name: "Alice Admin", email: "alice@example.com")
    carol = create_person(name: "Carol Member", email: "carol@example.com")

    alice_membership_id = add_member(club_id, alice.person_id)
    carol_membership_id = add_member(club_id, carol.person_id)
    board_group_id = create_group(club_id, "Board")

    add_group_member(club_id, board_group_id, alice_membership_id, alice.person_id)
    add_group_member(club_id, board_group_id, carol_membership_id, carol.person_id)

    message_id = Memba.ID.generate(:message)

    assert :ok =
             Messaging.send_club_message(
               %{
                 message_id: message_id,
                 club_id: club_id,
                 sender_id: alice.person_id,
                 audience_group_id: board_group_id,
                 subject: "Private Board topic",
                 body: "Do not hand this off using stale access."
               },
               consistency: :strong
             )

    carol_delivery =
      message_id
      |> pending_deliveries_for_message()
      |> Enum.find(&(&1.recipient_id == carol.person_id))

    carol_delivery_id = carol_delivery.delivery_id
    membership_projector_child_id = stop_projector!(MembershipProjector)
    group_membership_projector_child_id = stop_projector!(GroupMembershipProjector)
    conversation_access_projector_child_id = stop_projector!(ConversationGroupAccessProjector)

    assert :ok =
             MembershipApp.dispatch(
               %RemoveClubMember{
                 club_id: club_id,
                 membership_id: carol_membership_id,
                 person_id: carol.person_id
               },
               consistency: :eventual
             )

    assert Memba.Membership.active_member_of_group?(board_group_id, carol.person_id)

    reply_message_id = Memba.ID.generate(:message)

    assert {:error, :not_current_member} =
             Messaging.post_message_reply(
               %{
                 message_id: reply_message_id,
                 conversation_id: message_id,
                 sender_id: carol.person_id,
                 body: "A stale membership projection must not authorize this reply."
               },
               consistency: :strong
             )

    refute Repo.get(MessageProjection, reply_message_id)

    assert {:error, :not_current_member} =
             Messaging.follow_conversation_as_current_member(
               %{
                 club_id: club_id,
                 conversation_id: message_id,
                 member_id: carol.person_id
               },
               consistency: :strong
             )

    refute Messaging.following_conversation?(message_id, carol.person_id)

    new_message_id = Memba.ID.generate(:message)

    assert {:error, :not_current_member} =
             Messaging.send_club_message_as_current_member(
               %{
                 message_id: new_message_id,
                 club_id: club_id,
                 sender_id: carol.person_id,
                 audience_group_id: board_group_id,
                 subject: "Stale compose",
                 body: "A stale compose view must not authorize this message."
               },
               consistency: :strong
             )

    refute Repo.get(MessageProjection, new_message_id)

    assert Enum.any?(
             EmailDeliveryDispatcher.dispatch_pending_email_deliveries(),
             &match?(
               %EmailDeliveryProjection{
                 delivery_id: ^carol_delivery_id,
                 status: "pending",
                 attempt_count: 0,
                 latest_error: nil,
                 failed_at: nil
               },
               &1
             )
           )

    assert Fake.deliveries() == []

    dispatcher_name = :"#{__MODULE__}.lag_recovery"

    dispatcher_opts = [
      name: dispatcher_name,
      dispatch_enabled: true,
      dispatch_observer: self(),
      projection_catch_up_retry_interval: 60_000
    ]

    dispatcher_pid = start_supervised!({EmailDeliveryDispatcher, dispatcher_opts})

    assert_receive {:email_delivery_dispatch_requested,
                    %{
                      source: :startup,
                      claimed_delivery_ids: initially_claimed_delivery_ids
                    }},
                   1_000

    assert carol_delivery_id in initially_claimed_delivery_ids

    dispatcher_monitor = Process.monitor(dispatcher_pid)
    assert :ok = stop_supervised(EmailDeliveryDispatcher)
    assert_receive {:DOWN, ^dispatcher_monitor, :process, ^dispatcher_pid, :shutdown}

    restart_projector!(membership_projector_child_id)
    restart_projector!(group_membership_projector_child_id)
    restart_projector!(conversation_access_projector_child_id)

    checkpoint = Memba.ProjectionBarrier.current_checkpoint()

    Memba.ProjectionBarrier.await!(
      [MembershipProjector, GroupMembershipProjector, ConversationGroupAccessProjector],
      checkpoint: checkpoint,
      timeout: 1_000
    )

    refute Memba.Membership.active_member_of_group?(board_group_id, carol.person_id)

    start_supervised!({EmailDeliveryDispatcher, dispatcher_opts})

    assert_receive {:email_delivery_dispatch_requested,
                    %{
                      source: :startup,
                      claimed_delivery_ids: retried_delivery_ids
                    }},
                   1_000

    assert carol_delivery_id in retried_delivery_ids

    assert %EmailDeliveryProjection{
             delivery_id: ^carol_delivery_id,
             status: "failed",
             attempt_count: 1,
             latest_error: "recipient_access_ended"
           } = Repo.get!(EmailDeliveryProjection, carol_delivery_id)

    assert [%EmailDeliveryRequest{recipient_id: alice_id}] = Fake.deliveries()
    assert alice_id == alice.person_id
  end

  test "does not create a new-message delivery for a departure hidden by recipient projection lag" do
    club_id = Memba.ID.generate(:club)
    create_club(club_id, "Kootenay Mountaineering Club")

    alice = create_person(name: "Alice Admin", email: "alice@example.com")
    carol = create_person(name: "Carol Member", email: "carol@example.com")

    alice_membership_id = add_member(club_id, alice.person_id)
    carol_membership_id = add_member(club_id, carol.person_id)
    board_group_id = create_group(club_id, "Board")

    add_group_member(club_id, board_group_id, alice_membership_id, alice.person_id)
    add_group_member(club_id, board_group_id, carol_membership_id, carol.person_id)

    membership_projector_child_id = stop_projector!(MembershipProjector)
    group_membership_projector_child_id = stop_projector!(GroupMembershipProjector)
    system_group_policy_child_id = stop_projector!(SystemGroupMembership)

    assert :ok =
             MembershipApp.dispatch(
               %RemoveClubMember{
                 club_id: club_id,
                 membership_id: carol_membership_id,
                 person_id: carol.person_id
               },
               consistency: :eventual
             )

    assert Memba.Membership.active_member_of_group?(board_group_id, carol.person_id)

    message_id = Memba.ID.generate(:message)

    assert {:ok, %ExecutionResult{events: events}} =
             Messaging.send_club_message(
               %{
                 message_id: message_id,
                 club_id: club_id,
                 sender_id: alice.person_id,
                 audience_group_id: board_group_id,
                 subject: "Private Board topic after departure",
                 body: "A stale recipient projection must not create Carol's delivery."
               },
               returning: :execution_result,
               consistency: :strong
             )

    recipient_ids =
      for %EmailDeliveryCreated{recipient_id: recipient_id} <- events, do: recipient_id

    assert alice.person_id in recipient_ids
    refute carol.person_id in recipient_ids

    restart_projector!(membership_projector_child_id)
    restart_projector!(group_membership_projector_child_id)
    restart_projector!(system_group_policy_child_id)

    await_restarted_subscribers!([
      MembershipProjector,
      GroupMembershipProjector,
      SystemGroupMembership
    ])
  end

  test "a preserved follow does not create reply delivery without current group participation" do
    club_id = Memba.ID.generate(:club)
    create_club(club_id, "Kootenay Mountaineering Club")

    alice = create_person(name: "Alice Admin", email: "alice@example.com")
    carol = create_person(name: "Carol Member", email: "carol@example.com")

    alice_membership_id = add_member(club_id, alice.person_id)
    carol_membership_id = add_member(club_id, carol.person_id)
    board_group_id = create_group(club_id, "Board")

    add_group_member(club_id, board_group_id, alice_membership_id, alice.person_id)
    add_group_member(club_id, board_group_id, carol_membership_id, carol.person_id)

    conversation_id = Memba.ID.generate(:message)
    conversation_access_projector_child_id = stop_projector!(ConversationGroupAccessProjector)

    assert :ok =
             Messaging.send_club_message(
               %{
                 message_id: conversation_id,
                 club_id: club_id,
                 sender_id: alice.person_id,
                 audience_group_id: board_group_id,
                 subject: "Private Board topic",
                 body: "Carol initially has access."
               },
               consistency: [MessageProjector]
             )

    assert :ok =
             Messaging.follow_conversation(
               %{
                 club_id: club_id,
                 conversation_id: conversation_id,
                 member_id: carol.person_id
               },
               consistency: [ConversationFollowProjector]
             )

    assert [] = Messaging.list_conversations_for_group(board_group_id)

    assert :ok =
             MembershipApp.dispatch(
               %RemoveClubMember{
                 club_id: club_id,
                 membership_id: carol_membership_id,
                 person_id: carol.person_id
               },
               consistency: :eventual
             )

    await_restarted_subscribers!([
      MembershipProjector,
      GroupMembershipProjector,
      SystemGroupMembership
    ])

    assert :ok =
             MembershipApp.dispatch(
               %AddClubMember{
                 club_id: club_id,
                 membership_id: Memba.ID.generate(:membership),
                 person_id: carol.person_id
               },
               consistency: :eventual
             )

    await_restarted_subscribers!([
      MembershipProjector,
      GroupMembershipProjector,
      SystemGroupMembership
    ])

    assert Messaging.following_conversation?(conversation_id, carol.person_id)
    assert Memba.Membership.active_member_of_club_authoritatively?(club_id, carol.person_id)

    refute Memba.Membership.active_member_of_group_authoritatively?(
             club_id,
             board_group_id,
             carol.person_id
           )

    reply_message_id = Memba.ID.generate(:message)

    assert {:ok, %ExecutionResult{events: events}} =
             Messaging.post_message_reply(
               %{
                 message_id: reply_message_id,
                 conversation_id: conversation_id,
                 sender_id: alice.person_id,
                 body: "Carol must not receive this after rejoining only Everyone."
               },
               returning: :execution_result,
               consistency: [MessageProjector]
             )

    recipient_ids =
      for %EmailDeliveryCreated{recipient_id: recipient_id} <- events, do: recipient_id

    refute carol.person_id in recipient_ids

    restart_projector!(conversation_access_projector_child_id)
    await_restarted_subscribers!([ConversationGroupAccessProjector])
  end

  test "rejects an unknown audience group before dispatching the message command" do
    club_id = Memba.ID.generate(:club)
    create_club(club_id, "Kootenay Mountaineering Club")

    alice = create_person(name: "Alice", email: "alice@example.com")
    add_member(club_id, alice.person_id)

    assert {:error, :audience_group_not_found} =
             Messaging.send_club_message(%{
               message_id: Memba.ID.generate(:message),
               club_id: club_id,
               sender_id: alice.person_id,
               audience_group_id: Memba.ID.generate(:group),
               subject: "Private topic",
               body: "Please discuss this with the selected group."
             })

    assert count_events(MessageSent) == 0
  end

  test "rejects an audience group owned by another club without creating a conversation" do
    kootenay_club_id = Memba.ID.generate(:club)
    nelson_club_id = Memba.ID.generate(:club)
    create_club(kootenay_club_id, "Kootenay Mountaineering Club")
    create_club(nelson_club_id, "Nelson Cycling Club")

    alice = create_person(name: "Alice", email: "alice@example.com")
    bob = create_person(name: "Bob", email: "bob@example.com")
    add_member(kootenay_club_id, alice.person_id)
    add_member(nelson_club_id, bob.person_id)

    assert {:error, :audience_group_not_found} =
             Messaging.send_club_message(%{
               message_id: Memba.ID.generate(:message),
               club_id: kootenay_club_id,
               sender_id: alice.person_id,
               audience_group_id: SystemGroups.everyone_group_id(nelson_club_id),
               subject: "Cross-club topic",
               body: "This must not create a conversation."
             })

    assert count_events(MessageSent) == 0
  end

  test "sends each active member once at the person's primary email address" do
    club_id = Memba.ID.generate(:club)
    create_club(club_id, "Kootenay Mountaineering Club")
    everyone_group_id = SystemGroups.everyone_group_id(club_id)

    alice =
      create_person(
        name: "Alice",
        email: "alice@example.com",
        email_addresses: [
          %{email: "alice@example.com", is_primary: true},
          %{email: "alice@work.example", is_primary: false}
        ]
      )

    bob =
      create_person(
        name: "Bob",
        email: "bob@work.example",
        email_addresses: [
          %{email: "bob@example.com", is_primary: false},
          %{email: "bob@work.example", is_primary: true}
        ]
      )

    add_member(club_id, alice.person_id)
    add_member(club_id, bob.person_id)

    message_id = Memba.ID.generate(:message)
    alice_id = alice.person_id
    bob_id = bob.person_id

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^message_id,
              aggregate_version: 4,
              events: [
                %MessageSent{
                  message_id: ^message_id,
                  club_id: ^club_id,
                  sender_id: ^alice_id,
                  subject: "Trip planning night",
                  body: "Bring route ideas."
                },
                %ConversationAccessGrantedToGroup{
                  conversation_id: ^message_id,
                  club_id: ^club_id,
                  group_id: ^everyone_group_id,
                  access_level: "write"
                },
                %EmailDeliveryCreated{
                  message_id: ^message_id,
                  recipient_id: ^alice_id,
                  recipient_name: "Alice",
                  recipient_email: "alice@example.com"
                },
                %EmailDeliveryCreated{
                  message_id: ^message_id,
                  recipient_id: ^bob_id,
                  recipient_name: "Bob",
                  recipient_email: "bob@work.example"
                }
              ]
            }} =
             Messaging.send_club_message(
               %{
                 message_id: message_id,
                 club_id: club_id,
                 sender_id: alice.person_id,
                 subject: "Trip planning night",
                 body: "Bring route ideas."
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert [
             %EmailDeliveryProjection{
               recipient_id: ^alice_id,
               recipient_name: "Alice",
               recipient_address: "alice@example.com",
               status: "pending"
             },
             %EmailDeliveryProjection{
               recipient_id: ^bob_id,
               recipient_name: "Bob",
               recipient_address: "bob@work.example",
               status: "pending"
             }
           ] = pending_deliveries_for_message(message_id)

    recipient_addresses =
      message_id
      |> pending_deliveries_for_message()
      |> Enum.map(& &1.recipient_address)

    refute "alice@work.example" in recipient_addresses
    refute "bob@example.com" in recipient_addresses
    assert Fake.deliveries() == []
  end

  test "accepts the message without building provider requests inline when club context is available" do
    club_id = Memba.ID.generate(:club)
    create_club(club_id, "Kootenay Mountaineering Club")

    alice = create_person(name: "Alice", email: "alice@example.com")
    add_member(club_id, alice.person_id)

    message_id = Memba.ID.generate(:message)

    assert {:ok, %ExecutionResult{}} =
             Messaging.send_club_message(
               %{
                 message_id: message_id,
                 club_id: club_id,
                 sender_id: alice.person_id,
                 subject: "Trip planning night",
                 body: "Bring route ideas."
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert [%EmailDeliveryProjection{message_id: ^message_id, status: "pending"}] =
             pending_deliveries_for_message(message_id)

    assert Fake.deliveries() == []
  end

  test "does not call the provider when the send command is rejected" do
    club_id = Memba.ID.generate(:club)
    create_club(club_id, "Kootenay Mountaineering Club")
    alice = create_person(name: "Alice", email: "alice@example.com")
    add_member(club_id, alice.person_id)

    assert {:error, :invalid_subject} =
             Messaging.send_club_message(%{
               message_id: Memba.ID.generate(:message),
               club_id: club_id,
               sender_id: alice.person_id,
               subject: "  ",
               body: "Bring route ideas."
             })

    assert Fake.deliveries() == []
  end

  test "returns success after recording message work when the configured provider would fail" do
    Application.put_env(:memba, :messaging_email_delivery_provider, Postmark)

    Application.put_env(:memba, Memba.Mailer,
      adapter: Memba.TestSupport.FailingSwooshAdapter,
      api_key: "server-token",
      test_owner: self(),
      test_delivery_result: {:error, :timeout}
    )

    Application.put_env(:memba, Postmark, from: "messages@mail.memba.io")

    club_id = Memba.ID.generate(:club)
    alice = create_person(name: "Alice", email: "alice@example.com")
    add_member(club_id, alice.person_id)

    message_id = Memba.ID.generate(:message)

    assert :ok =
             Messaging.send_club_message(
               %{
                 message_id: message_id,
                 club_id: club_id,
                 sender_id: alice.person_id,
                 subject: "Trip planning night",
                 body: "Bring route ideas."
               },
               consistency: :strong
             )

    refute_received {:failing_swoosh_adapter_deliver, %Swoosh.Email{}}
    assert Fake.deliveries() == []

    assert [%EmailDeliveryProjection{status: "pending"}] =
             pending_deliveries_for_message(message_id)
  end

  test "manual retry of a failed delivery does not append duplicate message or delivery events" do
    Application.put_env(:memba, :messaging_email_delivery_provider, Fake)

    club_id = Memba.ID.generate(:club)
    create_club(club_id, "Kootenay Mountaineering Club")

    alice = create_person(name: "Alice", email: "alice@example.com")
    add_member(club_id, alice.person_id)

    message_id = Memba.ID.generate(:message)

    assert :ok =
             Messaging.send_club_message(
               %{
                 message_id: message_id,
                 club_id: club_id,
                 sender_id: alice.person_id,
                 subject: "Trip planning night",
                 body: "Bring route ideas."
               },
               consistency: :strong
             )

    assert [delivery] = pending_deliveries_for_message(message_id)
    assert count_events(MessageSent) == 1
    assert count_events(EmailDeliveryCreated) == 1

    failed_at =
      DateTime.utc_now() |> DateTime.add(-120, :second) |> DateTime.truncate(:microsecond)

    delivery
    |> Ecto.Changeset.change(
      status: "failed",
      attempt_count: 1,
      latest_error: "unavailable",
      latest_detail: ":unavailable",
      failed_at: failed_at
    )
    |> Repo.update!()

    assert {:ok,
            %EmailDeliveryProjection{
              delivery_id: delivery_id,
              status: "sent",
              attempt_count: 2
            }} = Messaging.retry_failed_email_delivery(delivery.delivery_id)

    assert delivery_id == delivery.delivery_id
    assert count_events(MessageSent) == 1
    assert count_events(EmailDeliveryCreated) == 1

    assert [%EmailDeliveryRequest{message_id: ^message_id, delivery_id: ^delivery_id}] =
             Fake.deliveries()
  end

  test "projector replay rebuilds pending delivery work without handing it to the provider" do
    Application.put_env(:memba, :messaging_email_delivery_provider, Fake)

    club_id = Memba.ID.generate(:club)
    create_club(club_id, "Kootenay Mountaineering Club")

    alice = create_person(name: "Alice", email: "alice@example.com")
    add_member(club_id, alice.person_id)

    message_id = Memba.ID.generate(:message)

    assert :ok =
             Messaging.send_club_message(
               %{
                 message_id: message_id,
                 club_id: club_id,
                 sender_id: alice.person_id,
                 subject: "Trip planning night",
                 body: "Bring route ideas."
               },
               consistency: :strong
             )

    assert [%EmailDeliveryProjection{status: "pending"}] =
             pending_deliveries_for_message(message_id)

    assert Fake.deliveries() == []

    checkpoint = Memba.ProjectionBarrier.current_checkpoint()

    Memba.EventSourcedCase.rebuild_event_sourced_projections!()
    Memba.ProjectionBarrier.await!(@email_delivery_replay_projectors, checkpoint: checkpoint)

    assert [%EmailDeliveryProjection{status: "pending"}] =
             pending_deliveries_for_message(message_id)

    assert Fake.deliveries() == []
  end

  defp pending_deliveries_for_message(message_id) do
    EmailDeliveryProjection
    |> where([delivery], delivery.message_id == ^message_id)
    |> order_by([delivery], asc: delivery.recipient_name)
    |> Repo.all()
  end

  defp stop_email_delivery_dispatcher do
    case Supervisor.terminate_child(Memba.Supervisor, Memba.Messaging.EmailDeliveryDispatcher) do
      :ok -> true
      {:error, :not_found} -> false
    end
  end

  defp restart_email_delivery_dispatcher(false), do: :ok

  defp restart_email_delivery_dispatcher(true) do
    case Supervisor.restart_child(Memba.Supervisor, Memba.Messaging.EmailDeliveryDispatcher) do
      {:ok, _pid} -> :ok
      {:ok, _pid, _info} -> :ok
      {:error, :running} -> :ok
      {:error, :not_found} -> :ok
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

    on_exit(fn -> restart_projector!(child_id) end)

    child_id
  end

  defp restart_projector!(child_id) do
    case Supervisor.restart_child(Memba.Supervisor, child_id) do
      {:ok, _pid} -> :ok
      {:ok, _pid, _info} -> :ok
      {:error, :running} -> :ok
    end
  end

  defp await_restarted_subscribers!(subscribers) do
    checkpoint = Memba.ProjectionBarrier.current_checkpoint()

    Memba.ProjectionBarrier.await!(
      subscribers,
      checkpoint: checkpoint,
      timeout: 5_000
    )

    final_checkpoint = Memba.ProjectionBarrier.current_checkpoint()

    Memba.ProjectionBarrier.await!(
      subscribers,
      checkpoint: final_checkpoint,
      timeout: 5_000
    )
  end

  defp create_club(club_id, name) do
    assert :ok =
             MembershipApp.dispatch(
               %CreateClub{
                 club_id: club_id,
                 name: name,
                 slug: membership_club_slug(name, club_id)
               },
               consistency: :strong
             )
  end

  defp create_person(attrs) do
    email = Keyword.fetch!(attrs, :email)
    email_addresses = Keyword.get(attrs, :email_addresses, [%{email: email, is_primary: true}])

    person = %{
      person_id: Memba.ID.generate(:person),
      name: Keyword.fetch!(attrs, :name),
      email: email,
      email_addresses: email_addresses
    }

    assert :ok =
             MembershipApp.dispatch(
               struct!(
                 CreatePerson,
                 %{
                   person_id: person.person_id,
                   name: person.name,
                   email: person.email,
                   email_addresses: person.email_addresses
                 }
                 |> Enum.reject(fn {_key, value} -> is_nil(value) end)
                 |> Map.new()
               ),
               consistency: :strong
             )

    person
  end

  defp add_member(club_id, person_id) do
    ensure_club(club_id)
    membership_id = Memba.ID.generate(:membership)

    assert :ok =
             MembershipApp.dispatch(
               %AddClubMember{
                 membership_id: membership_id,
                 club_id: club_id,
                 person_id: person_id
               },
               consistency: :strong
             )

    membership_id
  end

  defp create_group(club_id, name) do
    group_id = Memba.ID.generate(:group)

    assert :ok =
             MembershipApp.dispatch(
               %CreateGroup{
                 club_id: club_id,
                 group_id: group_id,
                 email_slug: name |> String.downcase() |> String.replace(" ", "-"),
                 name: name
               },
               consistency: :strong
             )

    group_id
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

  defp remove_group_member(club_id, group_id, membership_id, person_id) do
    assert :ok =
             MembershipApp.dispatch(
               %RemoveGroupMember{
                 club_id: club_id,
                 group_id: group_id,
                 membership_id: membership_id,
                 person_id: person_id
               },
               consistency: :strong
             )
  end

  defp assign_admin_role(club_id, membership_id, person_id) do
    assert MembershipApp.dispatch(
             %AssignClubRoleToMember{
               club_id: club_id,
               membership_id: membership_id,
               person_id: person_id,
               role_id: Roles.membership_administrator_role_id(club_id)
             },
             consistency: :strong
           ) in [:ok, {:error, :role_already_assigned}]
  end

  defp ensure_club(club_id) do
    if is_nil(Memba.Membership.get_club(club_id)) do
      create_club(club_id, "Kootenay Mountaineering Club")
    end
  end

  defp insert_active_membership_projection_without_group(club_id, person_id) do
    Repo.insert!(%MembershipProjection{
      membership_id: Memba.ID.generate(:membership),
      club_id: club_id,
      person_id: person_id,
      active: true
    })
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)

  defp count_events(event_module) when is_atom(event_module) do
    event_type = Atom.to_string(event_module)

    %{rows: [[count]]} =
      Repo.query!(
        ~S|SELECT count(*) FROM "event_store"."events" WHERE event_type = $1|,
        [event_type]
      )

    count
  end
end
