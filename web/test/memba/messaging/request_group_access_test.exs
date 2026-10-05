defmodule Memba.Messaging.RequestGroupAccessTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership
  alias Memba.Membership.App, as: MembershipApp
  alias Memba.Membership.Commands.AddClubMember
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.AssignClubRoleToMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreateGroup
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Commands.RemoveClubMember
  alias Memba.Membership.Policies.ClearRemovedGroupMemberFollows
  alias Memba.Membership.Policies.SystemGroupMembership
  alias Memba.Membership.Projectors.GroupMembership, as: GroupMembershipProjector
  alias Memba.Membership.Projectors.Membership, as: MembershipProjector
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.EmailDeliveryProviders.Fake
  alias Memba.Messaging.Events.ConversationAccessGrantedToGroup
  alias Memba.Messaging.Events.EmailDeliveryCreated
  alias Memba.Messaging.Events.MessageSent
  alias Memba.Messaging.RequestGroupAccess
  alias MembaWeb.ClubSite

  setup do
    dispatcher_was_running? = stop_email_delivery_dispatcher()
    Fake.reset()

    on_exit(fn ->
      Fake.reset()
      restart_email_delivery_dispatcher(dispatcher_was_running?)
    end)

    :ok
  end

  test "prepares a trusted Admin message without dispatching it" do
    %{club: club, board_id: board_id, alice: alice, dan: dan, eve: eve} =
      setup_requestable_group()

    message_id = Memba.ID.generate(:message)
    intent = Memba.ID.generate(:message)
    before_count = count_events(MessageSent)
    add_url = ClubSite.url(club, "/groups/#{board_id}/members/add/#{eve.person_id}")

    assert {:ok,
            %SendMessage{
              message_id: ^message_id,
              operation_intent: ^intent,
              sender_id: sender_id,
              audience_group_id: audience_group_id,
              subject: "Access request: Board",
              body: body,
              recipients: recipients
            }} =
             RequestGroupAccess.prepare(%{
               "message_id" => message_id,
               "operation_intent" => intent,
               "club_id" => club.club_id,
               "requester_person_id" => eve.person_id,
               "group_id" => board_id,
               "subject" => "Forged",
               "recipients" => []
             })

    assert sender_id == eve.person_id
    assert audience_group_id == SystemGroups.admin_group_id(club.club_id)
    assert body =~ add_url

    assert Enum.sort(Enum.map(recipients, & &1.person_id)) ==
             Enum.sort([alice.person_id, dan.person_id])

    assert count_events(MessageSent) == before_count
  end

  test "preparation preserves missing, unauthorized, and active-target errors" do
    %{club: club, board_id: board_id, eve: eve} = setup_requestable_group()

    attrs = %{
      message_id: Memba.ID.generate(:message),
      club_id: club.club_id,
      requester_person_id: eve.person_id,
      group_id: board_id
    }

    assert {:error, {:missing_required_attribute, :message_id}} =
             RequestGroupAccess.prepare(Map.delete(attrs, :message_id))

    assert {:error, :group_not_defined} =
             RequestGroupAccess.prepare(%{attrs | group_id: Memba.ID.generate(:group)})

    add_group_member!(club.club_id, board_id, eve)
    assert {:error, :already_member} = RequestGroupAccess.prepare(attrs)
  end

  test "sends one fixed ordinary Admin message from authoritative facts and leaves the requester outside the target group" do
    %{club: club, board_id: board_id, alice: alice, dan: dan, eve: eve} =
      setup_requestable_group()

    message_id = Memba.ID.generate(:message)
    club_id = club.club_id
    sender_id = eve.person_id
    alice_id = alice.person_id
    dan_id = dan.person_id
    admin_group_id = SystemGroups.admin_group_id(club.club_id)
    add_url = ClubSite.url(club, "/groups/#{board_id}/members/add/#{eve.person_id}")

    expected_body =
      """
      Eve Ekwueme would like to join Board.

      Eve Ekwueme asked from Board's page in Kootenay Mountaineering Club.

      Add Eve Ekwueme to Board:
      #{add_url}

      You'll confirm on the website before Eve Ekwueme is added.
      """
      |> String.trim_trailing()

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^message_id,
              aggregate_version: 4,
              events: [
                %MessageSent{
                  message_id: ^message_id,
                  club_id: ^club_id,
                  sender_id: ^sender_id,
                  subject: "Access request: Board",
                  body: ^expected_body,
                  sender_follows_conversation: false
                },
                %ConversationAccessGrantedToGroup{
                  conversation_id: ^message_id,
                  club_id: ^club_id,
                  group_id: ^admin_group_id,
                  access_level: "write"
                },
                %EmailDeliveryCreated{recipient_id: ^alice_id},
                %EmailDeliveryCreated{recipient_id: ^dan_id}
              ]
            }} =
             Messaging.request_group_access(
               %{
                 message_id: message_id,
                 club_id: club.club_id,
                 requester_person_id: eve.person_id,
                 group_id: board_id,
                 sender_id: Memba.ID.generate(:person),
                 audience_group_id: Memba.ID.generate(:group),
                 recipients: [],
                 subject: "Forged subject",
                 body: "Forged body",
                 club: %{name: "Forged club", slug: "forged"},
                 person: %{name: "Forged requester"},
                 group: %{name: "Forged group"}
               },
               returning: :execution_result,
               consistency: :strong
             )

    refute Membership.active_member_of_group_authoritatively?(
             club.club_id,
             board_id,
             eve.person_id
           )

    refute Messaging.member_has_conversation_access?(
             message_id,
             club.club_id,
             eve.person_id,
             :read
           )

    refute Messaging.following_conversation?(message_id, eve.person_id)
    assert Fake.deliveries() == []
  end

  test "uses only current Admin recipients" do
    %{club: club, board_id: board_id, alice: alice, eve: eve} = setup_requestable_group()
    former_admin = create_person!("Former Admin", "former-admin@example.com")
    former_membership_id = add_club_member!(club.club_id, former_admin.person_id)
    assign_admin!(club.club_id, former_membership_id, former_admin.person_id)

    assert :ok =
             MembershipApp.dispatch(
               %RemoveClubMember{
                 club_id: club.club_id,
                 membership_id: former_membership_id,
                 person_id: former_admin.person_id
               },
               consistency: :strong
             )

    message_id = Memba.ID.generate(:message)

    assert {:ok, %ExecutionResult{events: events}} =
             request_access(club, eve, board_id, message_id,
               returning: :execution_result,
               consistency: :strong
             )

    recipient_ids =
      for %EmailDeliveryCreated{recipient_id: recipient_id} <- events, do: recipient_id

    assert alice.person_id in recipient_ids
    refute former_admin.person_id in recipient_ids
  end

  test "rejects invalid, missing, cross-club, built-in, inactive, and already-participating targets without sending" do
    %{club: club, board_id: board_id, eve: eve} = setup_requestable_group()
    other_club = create_club!("nelson", "Nelson Paddling Club")
    other_board_id = create_group!(other_club.club_id, "Other Board", "other-board")
    sent_before = count_events(MessageSent)

    assert {:error, :invalid_message_id} =
             request_access(club, eve, board_id, "not-a-message-id")

    assert {:error, :invalid_club_id} =
             request_access(%{club | club_id: "not-a-club-id"}, eve, board_id)

    assert {:error, :invalid_person_id} =
             request_access(club, %{eve | person_id: "not-a-person-id"}, board_id)

    assert {:error, :invalid_group_id} =
             request_access(club, eve, "not-a-group-id")

    assert {:error, :group_not_defined} =
             request_access(club, eve, Memba.ID.generate(:group))

    assert {:error, :group_not_defined} =
             request_access(club, eve, other_board_id)

    for system_group_id <- [
          SystemGroups.everyone_group_id(club.club_id),
          SystemGroups.admin_group_id(club.club_id)
        ] do
      assert {:error, :system_group_not_allowed} =
               request_access(club, eve, system_group_id)
    end

    add_group_member!(club.club_id, board_id, eve)

    assert {:error, :already_member} =
             request_access(club, eve, board_id)

    inactive = create_person!("Inactive Member", "inactive@example.com")
    inactive_membership_id = add_club_member!(club.club_id, inactive.person_id)

    assert :ok =
             MembershipApp.dispatch(
               %RemoveClubMember{
                 club_id: club.club_id,
                 membership_id: inactive_membership_id,
                 person_id: inactive.person_id
               },
               consistency: :strong
             )

    assert {:error, :member_not_active} =
             request_access(club, inactive, board_id)

    assert count_events(MessageSent) == sent_before
  end

  test "rejects an authoritative departure while the membership projection is stale" do
    %{club: club, board_id: board_id, eve: eve} = setup_requestable_group()
    projector_child_id = stop_projector!(MembershipProjector)
    sent_before = count_events(MessageSent)

    assert :ok =
             MembershipApp.dispatch(
               %RemoveClubMember{
                 club_id: club.club_id,
                 membership_id: eve.membership_id,
                 person_id: eve.person_id
               },
               consistency: :eventual
             )

    assert Membership.active_member_of_club?(club.club_id, eve.person_id)

    assert {:error, :member_not_active} =
             request_access(club, eve, board_id)

    assert count_events(MessageSent) == sent_before

    await_restarted_subscribers!([
      ClearRemovedGroupMemberFollows,
      GroupMembershipProjector,
      SystemGroupMembership
    ])

    restart_projector!(projector_child_id)

    await_restarted_subscribers!([
      GroupMembershipProjector,
      MembershipProjector,
      SystemGroupMembership
    ])
  end

  test "preserves ordinary recipient access and follow behavior when the requester is already an Admin" do
    %{club: club, board_id: board_id, alice: alice} = setup_requestable_group()
    message_id = Memba.ID.generate(:message)
    admin_group_id = SystemGroups.admin_group_id(club.club_id)

    assert {:ok,
            %ExecutionResult{
              events: [
                %MessageSent{
                  sender_id: sender_id,
                  sender_follows_conversation: true
                },
                %ConversationAccessGrantedToGroup{group_id: ^admin_group_id}
                | delivery_events
              ]
            }} =
             request_access(club, alice, board_id, message_id,
               returning: :execution_result,
               consistency: :strong
             )

    assert sender_id == alice.person_id

    assert Enum.any?(
             delivery_events,
             &match?(
               %EmailDeliveryCreated{recipient_id: recipient_id} when recipient_id == sender_id,
               &1
             )
           )

    assert Messaging.member_has_conversation_access?(
             message_id,
             club.club_id,
             alice.person_id,
             :write
           )

    assert Messaging.following_conversation?(message_id, alice.person_id)
  end

  test "propagates ordinary :ok, execution-result, and dispatch-error outcomes" do
    %{club: club, board_id: board_id, eve: eve} = setup_requestable_group()
    message_id = Memba.ID.generate(:message)

    assert :ok =
             request_access(club, eve, board_id, message_id, consistency: :strong)

    assert {:error, :already_sent} =
             request_access(club, eve, board_id, message_id, consistency: :strong)

    execution_result_message_id = Memba.ID.generate(:message)

    assert {:ok, %ExecutionResult{aggregate_uuid: ^execution_result_message_id}} =
             request_access(club, eve, board_id, execution_result_message_id,
               returning: :execution_result,
               consistency: :strong
             )
  end

  defp setup_requestable_group do
    club = create_club!("kmc", "Kootenay Mountaineering Club")
    alice = create_person!("Alice Ahmed", "alice@example.com")
    dan = create_person!("Dan Davison", "dan@example.com")
    eve = create_person!("Eve Ekwueme", "eve@example.com")

    alice = Map.put(alice, :membership_id, add_club_member!(club.club_id, alice.person_id))
    dan = Map.put(dan, :membership_id, add_club_member!(club.club_id, dan.person_id))
    eve = Map.put(eve, :membership_id, add_club_member!(club.club_id, eve.person_id))
    assign_admin!(club.club_id, dan.membership_id, dan.person_id)
    board_id = create_group!(club.club_id, "Board", "board")

    %{club: club, board_id: board_id, alice: alice, dan: dan, eve: eve}
  end

  defp request_access(
         club,
         person,
         group_id,
         message_id \\ Memba.ID.generate(:message),
         opts \\ []
       ) do
    Messaging.request_group_access(
      %{
        message_id: message_id,
        club_id: club.club_id,
        requester_person_id: person.person_id,
        group_id: group_id
      },
      opts
    )
  end

  defp create_club!(slug, name) do
    club = %{club_id: Memba.ID.generate(:club), name: name, slug: slug}

    assert :ok =
             MembershipApp.dispatch(
               %CreateClub{club_id: club.club_id, name: club.name, slug: club.slug},
               consistency: :strong
             )

    club
  end

  defp create_person!(name, email) do
    person = %{person_id: Memba.ID.generate(:person), name: name, email: email}

    assert :ok =
             MembershipApp.dispatch(
               %CreatePerson{
                 person_id: person.person_id,
                 name: person.name,
                 email: person.email,
                 email_addresses: [%{email: person.email, is_primary: true}]
               },
               consistency: :strong
             )

    person
  end

  defp add_club_member!(club_id, person_id) do
    membership_id = Memba.ID.generate(:membership)

    assert :ok =
             MembershipApp.dispatch(
               %AddClubMember{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id
               },
               consistency: :strong
             )

    membership_id
  end

  defp create_group!(club_id, name, key) do
    group_id = Memba.ID.generate(:group)

    assert :ok =
             MembershipApp.dispatch(
               %CreateGroup{
                 club_id: club_id,
                 group_id: group_id,
                 group_key: key,
                 email_slug: key,
                 name: name
               },
               consistency: :strong
             )

    group_id
  end

  defp add_group_member!(club_id, group_id, person) do
    assert :ok =
             MembershipApp.dispatch(
               %AddGroupMember{
                 club_id: club_id,
                 group_id: group_id,
                 membership_id: person.membership_id,
                 person_id: person.person_id
               },
               consistency: :strong
             )
  end

  defp assign_admin!(club_id, membership_id, person_id) do
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

  defp count_events(event_module) do
    %{rows: [[count]]} =
      Repo.query!(
        ~S|SELECT count(*) FROM "event_store"."events" WHERE event_type = $1|,
        [Atom.to_string(event_module)]
      )

    count
  end
end
