defmodule Memba.Membership.SystemGroupsBackfillTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Event.Mapper
  alias Memba.Membership
  alias Memba.Membership.App, as: MembershipApp
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.AssignMemberRole
  alias Memba.Membership.Events.ClubCreated
  alias Memba.Membership.Events.ClubRoleDefined
  alias Memba.Membership.Events.ClubRolePermissionGranted
  alias Memba.Membership.Events.GroupCreated
  alias Memba.Membership.Events.GroupEmailSlugAssigned
  alias Memba.Membership.Events.GroupMemberAdded
  alias Memba.Membership.Events.GroupMemberRemoved
  alias Memba.Membership.Permissions
  alias Memba.Membership.Projectors.Club, as: ClubProjector
  alias Memba.Membership.Projectors.Group, as: GroupProjector
  alias Memba.Membership.Projectors.Role, as: RoleProjector
  alias Memba.Membership.Projections.Group, as: GroupProjection
  alias Memba.Membership.Projections.GroupMembership, as: GroupMembershipProjection
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups
  alias Memba.Membership.SystemGroups.Backfill
  alias Memba.Messaging
  alias Memba.Messaging.App, as: MessagingApp
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Events.ConversationAccessGrantedToGroup
  alias Memba.Messaging.Events.ConversationAccessRevokedFromGroup
  alias Memba.Messaging.Projectors.ConversationGroupAccess, as: ConversationGroupAccessProjector
  alias Memba.Messaging.Recipient
  alias Memba.Release

  @repair_conversation_id "msg_ec4465c4-f306-4b4b-af68-53810f5a87e2"
  @repair_club_id "clb_9d87f308-9ccd-40a4-a613-0c11bb003cb9"
  @repair_everyone_group_id "grp_1f75d34f-2a18-3606-cd4d-6df61f989811"

  test "first run appends missing system-group, membership, and conversation-access facts" do
    club = seed_historic_club!()
    alice = add_active_member!(club.club_id)
    bob = add_active_member!(club.club_id)
    assign_admin_role!(club.club_id, alice)
    conversation_id = send_historic_root_conversation!(club.club_id, alice.person_id)

    assert %{
             system_group_definitions: %{dispatched_count: 2},
             everyone_group_memberships: %{dispatched_count: 2},
             admin_group_memberships: %{dispatched_count: 1},
             everyone_conversation_access: %{dispatched_count: 1}
           } = Backfill.run!(page_size: 2)

    everyone_group_id = SystemGroups.everyone_group_id(club.club_id)
    admin_group_id = SystemGroups.admin_group_id(club.club_id)

    assert %GroupProjection{
             email_slug: "everyone",
             group_key: "everyone",
             name: "Everyone"
           } =
             Repo.get(GroupProjection, everyone_group_id)

    assert %GroupProjection{email_slug: "admin", group_key: "admin", name: "Admin"} =
             Repo.get(GroupProjection, admin_group_id)

    assert active_group_membership?(everyone_group_id, alice.membership_id)
    assert active_group_membership?(everyone_group_id, bob.membership_id)
    assert active_group_membership?(admin_group_id, alice.membership_id)
    refute active_group_membership?(admin_group_id, bob.membership_id)

    assert Messaging.group_has_conversation_access?(conversation_id, everyone_group_id, :write)
    assert Messaging.group_has_conversation_access?(conversation_id, everyone_group_id, :read)
  end

  test "does not give Everyone access to a conversation that already has an Admin audience" do
    club = seed_historic_club!()
    member = add_active_member!(club.club_id)
    append_historic_system_groups!(club.club_id)
    admin_group_id = SystemGroups.admin_group_id(club.club_id)
    everyone_group_id = SystemGroups.everyone_group_id(club.club_id)

    conversation_id =
      send_group_root_conversation!(club.club_id, member.person_id, admin_group_id)

    assert Messaging.group_has_conversation_access?(conversation_id, admin_group_id, :write)
    refute Messaging.group_has_conversation_access?(conversation_id, everyone_group_id, :read)

    assert %{everyone_conversation_access: %{dispatched_count: 0}} =
             Backfill.run!(page_size: 10)

    assert Messaging.group_has_conversation_access?(conversation_id, admin_group_id, :write)
    refute Messaging.group_has_conversation_access?(conversation_id, everyone_group_id, :read)
  end

  test "appends the evidence-scoped compensating revocation for the production conversation" do
    club = seed_historic_club!(@repair_club_id)
    member = add_active_member!(club.club_id)
    append_historic_system_groups!(club.club_id)
    admin_group_id = SystemGroups.admin_group_id(club.club_id)
    everyone_group_id = SystemGroups.everyone_group_id(club.club_id)
    assert everyone_group_id == @repair_everyone_group_id

    conversation_id =
      send_group_root_conversation!(
        club.club_id,
        member.person_id,
        admin_group_id,
        @repair_conversation_id
      )

    assert :ok =
             Messaging.grant_conversation_access_to_group(%{
               conversation_id: conversation_id,
               club_id: club.club_id,
               group_id: everyone_group_id,
               access_level: :write
             })

    assert Messaging.group_has_conversation_access?(conversation_id, admin_group_id, :write)
    assert Messaging.group_has_conversation_access?(conversation_id, everyone_group_id, :write)

    assert %{
             known_erroneous_everyone_access_cleanup: %{dispatched_count: 1},
             everyone_conversation_access: %{dispatched_count: 0}
           } = Backfill.run!(page_size: 10)

    assert Messaging.group_has_conversation_access?(conversation_id, admin_group_id, :write)
    refute Messaging.group_has_conversation_access?(conversation_id, everyone_group_id, :read)
    assert messaging_event_count(conversation_id, ConversationAccessRevokedFromGroup) == 1

    assert %{known_erroneous_everyone_access_cleanup: %{dispatched_count: 0}} =
             Backfill.run!(page_size: 10)

    assert messaging_event_count(conversation_id, ConversationAccessRevokedFromGroup) == 1
  end

  test "recognizes the exact revocation event blocked behind the old live projector" do
    club = seed_historic_club!(@repair_club_id)
    member = add_active_member!(club.club_id)
    append_historic_system_groups!(club.club_id)
    admin_group_id = SystemGroups.admin_group_id(club.club_id)
    everyone_group_id = SystemGroups.everyone_group_id(club.club_id)

    conversation_id =
      send_group_root_conversation!(
        club.club_id,
        member.person_id,
        admin_group_id,
        @repair_conversation_id
      )

    assert :ok =
             Messaging.grant_conversation_access_to_group(%{
               conversation_id: conversation_id,
               club_id: club.club_id,
               group_id: everyone_group_id,
               access_level: :write
             })

    child_id = stop_projector!(ConversationGroupAccessProjector)

    on_exit(fn ->
      case Supervisor.restart_child(Memba.Supervisor, child_id) do
        {:ok, _pid} -> :ok
        {:ok, _pid, _info} -> :ok
        {:error, :running} -> :ok
      end
    end)

    assert :ok =
             Messaging.revoke_conversation_access_from_group(
               %{
                 conversation_id: conversation_id,
                 club_id: club.club_id,
                 group_id: everyone_group_id
               },
               consistency: :eventual
             )

    assert Backfill.known_revocation_pending_projection_upgrade?()
    assert Messaging.group_has_conversation_access?(conversation_id, everyone_group_id, :read)

    assert %{known_erroneous_everyone_access_cleanup: %{dispatched_count: 1}} =
             Backfill.run!(page_size: 10)
  end

  test "second run is idempotent and appends no duplicate facts" do
    club = seed_historic_club!()
    member = add_active_member!(club.club_id)
    assign_admin_role!(club.club_id, member)
    conversation_id = send_historic_root_conversation!(club.club_id, member.person_id)

    assert %{everyone_conversation_access: %{dispatched_count: 1}} = Backfill.run!(page_size: 2)

    event_counts = backfill_event_counts(club.club_id, conversation_id)

    assert %{
             system_group_definitions: %{dispatched_count: 0},
             everyone_group_memberships: %{dispatched_count: 0},
             admin_group_memberships: %{dispatched_count: 0},
             everyone_conversation_access: %{dispatched_count: 0}
           } = Backfill.run!(page_size: 2)

    assert ^event_counts = backfill_event_counts(club.club_id, conversation_id)
    assert event_counts.group_created == 2
    assert event_counts.group_email_slug_assigned == 2
    assert event_counts.group_member_added == 2
    assert event_counts.conversation_access_granted == 1
  end

  test "appends email-slug facts to historic system groups once across safe reruns" do
    club = seed_historic_club!()
    append_historic_system_groups!(club.club_id)

    assert membership_event_count(club.club_id, GroupCreated) == 2
    assert membership_event_count(club.club_id, GroupEmailSlugAssigned) == 0

    assert %{system_group_definitions: %{dispatched_count: 2}} =
             Backfill.run!(page_size: 2)

    assert membership_event_count(club.club_id, GroupCreated) == 2
    assert membership_event_count(club.club_id, GroupEmailSlugAssigned) == 2

    assert %{email_slug: "everyone"} =
             Membership.get_group_by_email_slug(club.club_id, "everyone")

    assert %{email_slug: "admin"} =
             Membership.get_group_by_email_slug(club.club_id, "admin")

    assert %{system_group_definitions: %{dispatched_count: 0}} =
             Backfill.run!(page_size: 2)

    assert membership_event_count(club.club_id, GroupCreated) == 2
    assert membership_event_count(club.club_id, GroupEmailSlugAssigned) == 2
  end

  test "backfill-seeded memberships follow later role and member lifecycle events" do
    club = seed_historic_club!()
    alice = add_active_member!(club.club_id)
    bob = add_active_member!(club.club_id)
    assign_admin_role!(club.club_id, alice)

    assert %{
             system_group_definitions: %{dispatched_count: 2},
             everyone_group_memberships: %{dispatched_count: 2},
             admin_group_memberships: %{dispatched_count: 1}
           } = Backfill.run!(page_size: 10)

    everyone_group_id = SystemGroups.everyone_group_id(club.club_id)
    admin_group_id = SystemGroups.admin_group_id(club.club_id)

    assert_group_membership_active?(everyone_group_id, alice.membership_id, true)
    assert_group_membership_active?(admin_group_id, alice.membership_id, true)
    assert_group_membership_active?(everyone_group_id, bob.membership_id, true)
    assert_group_membership_active?(admin_group_id, bob.membership_id, nil)

    assert :ok =
             Membership.assign_membership_administrator_as_club_member(
               %{
                 club_id: club.club_id,
                 membership_id: bob.membership_id,
                 person_id: bob.person_id,
                 actor_person_id: alice.person_id
               },
               consistency: :strong
             )

    assert_group_membership_active?(admin_group_id, bob.membership_id, true)

    assert :ok =
             Membership.remove_membership_administrator_as_club_member(
               %{
                 club_id: club.club_id,
                 membership_id: bob.membership_id,
                 person_id: bob.person_id,
                 actor_person_id: alice.person_id
               },
               consistency: :strong
             )

    assert_group_membership_active?(admin_group_id, bob.membership_id, false)

    assert :ok =
             Membership.assign_membership_administrator_as_club_member(
               %{
                 club_id: club.club_id,
                 membership_id: bob.membership_id,
                 person_id: bob.person_id,
                 actor_person_id: alice.person_id
               },
               consistency: :strong
             )

    assert_group_membership_active?(admin_group_id, bob.membership_id, true)

    assert :ok =
             Membership.remove_member(%{membership_id: alice.membership_id}, consistency: :strong)

    assert_group_membership_active?(everyone_group_id, alice.membership_id, false)
    assert_group_membership_active?(admin_group_id, alice.membership_id, false)
    assert_group_membership_active?(everyone_group_id, bob.membership_id, true)
    assert_group_membership_active?(admin_group_id, bob.membership_id, true)

    assert group_membership_event_count(
             club.club_id,
             GroupMemberAdded,
             everyone_group_id,
             alice.membership_id
           ) == 1

    assert group_membership_event_count(
             club.club_id,
             GroupMemberRemoved,
             everyone_group_id,
             alice.membership_id
           ) == 1

    assert group_membership_event_count(
             club.club_id,
             GroupMemberAdded,
             admin_group_id,
             alice.membership_id
           ) == 1

    assert group_membership_event_count(
             club.club_id,
             GroupMemberRemoved,
             admin_group_id,
             alice.membership_id
           ) == 1

    assert group_membership_event_count(
             club.club_id,
             GroupMemberAdded,
             admin_group_id,
             bob.membership_id
           ) == 2

    assert group_membership_event_count(
             club.club_id,
             GroupMemberRemoved,
             admin_group_id,
             bob.membership_id
           ) == 1
  end

  test "backfill traverses multiple keyset pages" do
    fixtures =
      for _index <- 1..3 do
        club = seed_historic_club!()
        member = add_active_member!(club.club_id)
        assign_admin_role!(club.club_id, member)
        conversation_id = send_historic_root_conversation!(club.club_id, member.person_id)

        %{club: club, member: member, conversation_id: conversation_id}
      end

    assert %{
             system_group_definitions: %{source_count: 3, dispatched_count: 6},
             everyone_group_memberships: %{source_count: 3, dispatched_count: 3},
             admin_group_memberships: %{source_count: 3, dispatched_count: 3},
             everyone_conversation_access: %{source_count: 3, dispatched_count: 3}
           } = Backfill.run!(page_size: 1)

    Enum.each(fixtures, fn %{club: club, member: member, conversation_id: conversation_id} ->
      everyone_group_id = SystemGroups.everyone_group_id(club.club_id)
      admin_group_id = SystemGroups.admin_group_id(club.club_id)

      assert Repo.get(GroupProjection, everyone_group_id)
      assert Repo.get(GroupProjection, admin_group_id)
      assert active_group_membership?(everyone_group_id, member.membership_id)
      assert active_group_membership?(admin_group_id, member.membership_id)
      assert Messaging.group_has_conversation_access?(conversation_id, everyone_group_id, :write)
    end)
  end

  test "a later run safely recovers after a mid-run failure" do
    club = seed_historic_club!()
    member = add_active_member!(club.club_id)
    assign_admin_role!(club.club_id, member)
    conversation_id = send_historic_root_conversation!(club.club_id, member.person_id)

    assert_raise RuntimeError, "simulated backfill failure", fn ->
      Backfill.run!(
        page_size: 10,
        after_command: fn _event ->
          raise "simulated backfill failure"
        end
      )
    end

    assert membership_event_count(club.club_id, GroupCreated) == 1
    assert membership_event_count(club.club_id, GroupEmailSlugAssigned) == 1

    assert %{
             system_group_definitions: %{dispatched_count: definition_dispatches},
             everyone_group_memberships: %{dispatched_count: 1},
             admin_group_memberships: %{dispatched_count: 1},
             everyone_conversation_access: %{dispatched_count: 1}
           } = Backfill.run!(page_size: 10)

    assert definition_dispatches in [1, 2]

    everyone_group_id = SystemGroups.everyone_group_id(club.club_id)
    admin_group_id = SystemGroups.admin_group_id(club.club_id)

    assert membership_event_count(club.club_id, GroupCreated) == 2
    assert membership_event_count(club.club_id, GroupEmailSlugAssigned) == 2
    assert membership_event_count(club.club_id, GroupMemberAdded) == 2
    assert messaging_event_count(conversation_id, ConversationAccessGrantedToGroup) == 1
    assert active_group_membership?(everyone_group_id, member.membership_id)
    assert active_group_membership?(admin_group_id, member.membership_id)
    assert Messaging.group_has_conversation_access?(conversation_id, everyone_group_id, :write)
  end

  test "rerunning release migration resumes interrupted system-group backfill without duplicates" do
    original_overrides = Application.get_env(:memba, :release_step_overrides)

    on_exit(fn ->
      case original_overrides do
        nil -> Application.delete_env(:memba, :release_step_overrides)
        overrides -> Application.put_env(:memba, :release_step_overrides, overrides)
      end
    end)

    club = seed_historic_club!()
    member = add_active_member!(club.club_id)
    assign_admin_role!(club.club_id, member)
    conversation_id = send_historic_root_conversation!(club.club_id, member.person_id)
    attempts = start_supervised!({Agent, fn -> 0 end})

    Application.put_env(:memba, :release_step_overrides, release_retry_overrides(attempts))

    assert_raise RuntimeError, "simulated release backfill interruption", fn ->
      Release.migrate()
    end

    assert membership_event_count(club.club_id, GroupCreated) == 1

    assert :ok = Release.migrate()

    assert %{
             group_created: 2,
             group_email_slug_assigned: 2,
             group_member_added: 2,
             conversation_access_granted: 1
           } = backfill_event_counts(club.club_id, conversation_id)

    event_counts = backfill_event_counts(club.club_id, conversation_id)

    assert :ok = Release.migrate()
    assert ^event_counts = backfill_event_counts(club.club_id, conversation_id)
  end

  defp seed_historic_club!(club_id \\ Memba.ID.generate(:club)) do
    name = "Kootenay Mountaineering Club #{System.unique_integer([:positive])}"
    slug = membership_club_slug(name, club_id)
    role_id = Roles.membership_administrator_role_id(club_id)

    events =
      [
        %ClubCreated{club_id: club_id, name: name, slug: slug},
        %ClubRoleDefined{
          club_id: club_id,
          role_id: role_id,
          role_key: Roles.membership_administrator_key(),
          name: Roles.membership_administrator_name()
        },
        %ClubRolePermissionGranted{
          club_id: club_id,
          role_id: role_id,
          permission: Permissions.club_manage_members()
        }
      ]
      |> Enum.map(&Mapper.map_to_event_data/1)

    assert :ok = Commanded.EventStore.append_to_stream(MembershipApp, club_id, 0, events)

    checkpoint = Memba.ProjectionBarrier.current_checkpoint()
    Memba.ProjectionBarrier.await!([ClubProjector, RoleProjector], checkpoint: checkpoint)

    %{club_id: club_id, name: name, slug: slug}
  end

  defp add_active_member!(club_id) do
    membership_id = Memba.ID.generate(:membership)
    person_id = Memba.ID.generate(:person)

    assert :ok =
             MembershipApp.dispatch(
               %AddMember{membership_id: membership_id, club_id: club_id, person_id: person_id},
               consistency: :strong
             )

    %{membership_id: membership_id, person_id: person_id}
  end

  defp append_historic_system_groups!(club_id) do
    events =
      [
        %GroupCreated{
          club_id: club_id,
          group_id: SystemGroups.everyone_group_id(club_id),
          group_key: SystemGroups.everyone_key(),
          name: SystemGroups.everyone_name()
        },
        %GroupCreated{
          club_id: club_id,
          group_id: SystemGroups.admin_group_id(club_id),
          group_key: SystemGroups.admin_key(),
          name: SystemGroups.admin_name()
        }
      ]
      |> Enum.map(&Mapper.map_to_event_data/1)

    assert :ok = Commanded.EventStore.append_to_stream(MembershipApp, club_id, 3, events)

    checkpoint = Memba.ProjectionBarrier.current_checkpoint()
    Memba.ProjectionBarrier.await!([GroupProjector], checkpoint: checkpoint)
  end

  defp assign_admin_role!(club_id, member) do
    assert :ok =
             MembershipApp.dispatch(
               %AssignMemberRole{
                 club_id: club_id,
                 membership_id: member.membership_id,
                 person_id: member.person_id,
                 role_id: Roles.membership_administrator_role_id(club_id)
               },
               consistency: :strong
             )
  end

  defp send_historic_root_conversation!(club_id, sender_id) do
    conversation_id = Memba.ID.generate(:message)

    assert :ok =
             MessagingApp.dispatch(
               %SendMessage{
                 message_id: conversation_id,
                 club_id: club_id,
                 sender_id: sender_id,
                 subject: "Trail day",
                 body: "Meet at 9am.",
                 recipients: [
                   %Recipient{
                     delivery_id: Memba.ID.generate(:delivery),
                     person_id: sender_id,
                     name: "Alice Sender",
                     email: "alice@example.com"
                   }
                 ]
               },
               consistency: :strong
             )

    conversation_id
  end

  defp send_group_root_conversation!(
         club_id,
         sender_id,
         audience_group_id,
         conversation_id \\ Memba.ID.generate(:message)
       ) do
    assert :ok =
             MessagingApp.dispatch(
               %SendMessage{
                 message_id: conversation_id,
                 club_id: club_id,
                 sender_id: sender_id,
                 audience_group_id: audience_group_id,
                 subject: "Private Admin topic",
                 body: "Please discuss this with the Admin group.",
                 recipients: [
                   %Recipient{
                     delivery_id: Memba.ID.generate(:delivery),
                     person_id: sender_id,
                     name: "Admin Sender",
                     email: "admin@example.com"
                   }
                 ]
               },
               consistency: :strong
             )

    conversation_id
  end

  defp stop_projector!(projector) do
    child_id =
      Supervisor.which_children(Memba.Supervisor)
      |> Enum.find_value(fn
        {child_id, _pid, :worker, [module]} when module == projector -> child_id
        _child -> nil
      end)

    assert child_id
    assert :ok = Supervisor.terminate_child(Memba.Supervisor, child_id)
    child_id
  end

  defp active_group_membership?(group_id, membership_id) do
    group_membership_active?(group_id, membership_id) == true
  end

  defp assert_group_membership_active?(group_id, membership_id, expected) do
    assert group_membership_active?(group_id, membership_id) == expected
  end

  defp group_membership_active?(group_id, membership_id) do
    GroupMembershipProjection
    |> where([group_membership], group_membership.group_id == ^group_id)
    |> where([group_membership], group_membership.membership_id == ^membership_id)
    |> select([group_membership], group_membership.active)
    |> Repo.one()
  end

  defp backfill_event_counts(club_id, conversation_id) do
    %{
      group_created: membership_event_count(club_id, GroupCreated),
      group_email_slug_assigned: membership_event_count(club_id, GroupEmailSlugAssigned),
      group_member_added: membership_event_count(club_id, GroupMemberAdded),
      conversation_access_granted:
        messaging_event_count(conversation_id, ConversationAccessGrantedToGroup)
    }
  end

  defp membership_event_count(club_id, event_module) do
    event_count(MembershipApp, club_id, event_module)
  end

  defp messaging_event_count(stream_id, event_module) do
    event_count(MessagingApp, stream_id, event_module)
  end

  defp group_membership_event_count(club_id, event_module, group_id, membership_id) do
    MembershipApp
    |> Commanded.EventStore.stream_forward(club_id)
    |> Enum.count(fn event ->
      match?(
        %{data: %^event_module{group_id: ^group_id, membership_id: ^membership_id}},
        event
      )
    end)
  end

  defp event_count(app, stream_id, event_module) do
    app
    |> Commanded.EventStore.stream_forward(stream_id)
    |> Enum.count(&match?(%{data: %^event_module{}}, &1))
  end

  defp release_retry_overrides(attempts) do
    no_op_steps = [
      :load_app,
      :init_event_stores,
      :migrate_repos,
      :ensure_release_services_started,
      :await_system_group_backfill_source_projections,
      :ensure_production_smoke_fixtures
    ]

    no_op_overrides = Enum.map(no_op_steps, &{&1, fn -> :ok end})

    Keyword.put(no_op_overrides, :run_system_groups_backfill, fn ->
      attempt = Agent.get_and_update(attempts, &{&1, &1 + 1})

      if attempt == 0 do
        Backfill.run!(
          page_size: 10,
          after_command: fn _event ->
            raise "simulated release backfill interruption"
          end
        )
      else
        Backfill.run!(page_size: 10)
      end

      :ok
    end)
  end
end
