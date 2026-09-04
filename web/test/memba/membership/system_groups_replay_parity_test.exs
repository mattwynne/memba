defmodule Memba.Membership.SystemGroupsReplayParityTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Event.Mapper
  alias Memba.Membership
  alias Memba.Membership.App, as: MembershipApp
  alias Memba.Membership.Commands.AssignMemberRole
  alias Memba.Membership.Events.ClubCreated
  alias Memba.Membership.Events.ClubRoleDefined
  alias Memba.Membership.Events.ClubRolePermissionGranted
  alias Memba.Membership.Events.GroupCreated
  alias Memba.Membership.Events.GroupMemberAdded
  alias Memba.Membership.Permissions
  alias Memba.Membership.Projectors.Club, as: ClubProjector
  alias Memba.Membership.Projectors.Group, as: GroupProjector
  alias Memba.Membership.Projectors.GroupMembership, as: GroupMembershipProjector
  alias Memba.Membership.Projectors.Membership, as: MembershipProjector
  alias Memba.Membership.Projectors.Person, as: PersonProjector
  alias Memba.Membership.Projectors.Role, as: RoleProjector
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups
  alias Memba.Membership.SystemGroups.Backfill
  alias Memba.Messaging
  alias Memba.Messaging.App, as: MessagingApp
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Events.ConversationAccessGrantedToGroup
  alias Memba.Messaging.Projectors.ConversationGroupAccess, as: ConversationGroupAccessProjector
  alias Memba.Messaging.Projectors.Message, as: MessageProjector
  alias Memba.Messaging.Recipient

  @replay_projectors [
    ClubProjector,
    MembershipProjector,
    PersonProjector,
    RoleProjector,
    GroupProjector,
    GroupMembershipProjector,
    MessageProjector,
    ConversationGroupAccessProjector
  ]

  test "system group and conversation access query state survives projection replay" do
    historic_club = seed_historic_club!()
    modern_club = create_modern_club!()

    alice = create_member!(historic_club.club_id, "Alice Admin", "alice.admin@example.com")
    bob = create_member!(historic_club.club_id, "Bob Member", "bob.member@example.com")
    assign_admin_role_directly!(historic_club.club_id, alice)

    historic_conversation_id = send_historic_root_conversation!(historic_club.club_id, alice)

    assert %{
             system_group_definitions: %{dispatched_count: 2},
             everyone_group_memberships: %{dispatched_count: 2},
             admin_group_memberships: %{dispatched_count: 1},
             everyone_conversation_access: %{dispatched_count: 1}
           } = Backfill.run!(page_size: 1)

    charlie =
      create_member!(historic_club.club_id, "Charlie New", "charlie.new@example.com")

    :ok = assign_admin_role_as_member!(historic_club.club_id, bob, alice)

    dana = create_member!(modern_club.club_id, "Dana Modern", "dana.modern@example.com")
    modern_conversation_id = send_current_root_conversation!(modern_club.club_id, dana)

    assert :ok =
             Messaging.grant_conversation_access_to_group(
               %{
                 conversation_id: historic_conversation_id,
                 club_id: historic_club.club_id,
                 group_id: SystemGroups.admin_group_id(historic_club.club_id),
                 access_level: :read
               },
               consistency: :strong
             )

    fixture = %{
      historic_club: historic_club,
      modern_club: modern_club,
      historic_members: %{alice: alice, bob: bob, charlie: charlie},
      modern_members: %{dana: dana},
      historic_conversation_id: historic_conversation_id,
      modern_conversation_id: modern_conversation_id
    }

    assert_zero_backfill_dispatches!()
    before_replay = public_query_snapshot(fixture)
    event_counts_before_replay = replay_parity_event_counts(fixture)
    projection_positions = event_sourced_projection_positions(@replay_projectors)

    Memba.EventSourcedCase.stop_event_sourced_aggregate_instances!()
    Memba.EventSourcedCase.rebuild_event_sourced_projections!()
    await_event_sourced_projection_positions!(projection_positions)

    assert ^before_replay = public_query_snapshot(fixture)
    assert ^event_counts_before_replay = replay_parity_event_counts(fixture)
    assert_zero_backfill_dispatches!()
    assert ^event_counts_before_replay = replay_parity_event_counts(fixture)
  end

  defp seed_historic_club! do
    club_id = Memba.ID.generate(:club)
    name = "Historic Mountaineering Club #{System.unique_integer([:positive])}"
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

  defp create_modern_club! do
    club_id = Memba.ID.generate(:club)
    name = "Modern Sailing Club #{System.unique_integer([:positive])}"
    slug = membership_club_slug(name, club_id)

    assert :ok =
             Membership.create_club(
               %{club_id: club_id, name: name, slug: slug},
               consistency: :strong
             )

    %{club_id: club_id, name: name, slug: slug}
  end

  defp create_member!(club_id, name, email) do
    person_id = Memba.ID.generate(:person)
    membership_id = Memba.ID.generate(:membership)

    assert :ok =
             Membership.create_person(
               %{person_id: person_id, name: name, email: email},
               consistency: :strong
             )

    assert :ok =
             Membership.add_member(
               %{membership_id: membership_id, club_id: club_id, person_id: person_id},
               consistency: :strong
             )

    %{membership_id: membership_id, person_id: person_id, name: name, email: email}
  end

  defp assign_admin_role_directly!(club_id, member) do
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

  defp assign_admin_role_as_member!(club_id, target_member, actor_member) do
    Membership.assign_membership_administrator_as_club_member(
      %{
        club_id: club_id,
        membership_id: target_member.membership_id,
        person_id: target_member.person_id,
        actor_person_id: actor_member.person_id
      },
      consistency: :strong
    )
  end

  defp send_historic_root_conversation!(club_id, sender) do
    conversation_id = Memba.ID.generate(:message)

    assert :ok =
             MessagingApp.dispatch(
               %SendMessage{
                 message_id: conversation_id,
                 club_id: club_id,
                 sender_id: sender.person_id,
                 subject: "Historic trail day",
                 body: "Meet at 9am.",
                 recipients: [recipient(sender)]
               },
               consistency: :strong
             )

    conversation_id
  end

  defp send_current_root_conversation!(club_id, sender) do
    conversation_id = Memba.ID.generate(:message)

    assert :ok =
             Messaging.send_club_message(
               %{
                 message_id: conversation_id,
                 club_id: club_id,
                 sender_id: sender.person_id,
                 subject: "Modern race night",
                 body: "Bring your life jacket."
               },
               consistency: :strong
             )

    conversation_id
  end

  defp recipient(member) do
    %Recipient{
      delivery_id: Memba.ID.generate(:delivery),
      person_id: member.person_id,
      name: member.name,
      email: member.email
    }
  end

  defp public_query_snapshot(fixture) do
    historic_everyone_group_id = SystemGroups.everyone_group_id(fixture.historic_club.club_id)
    historic_admin_group_id = SystemGroups.admin_group_id(fixture.historic_club.club_id)
    modern_everyone_group_id = SystemGroups.everyone_group_id(fixture.modern_club.club_id)
    modern_admin_group_id = SystemGroups.admin_group_id(fixture.modern_club.club_id)

    %{
      backfill_pages: %{
        system_group_definitions: Membership.list_system_group_definition_backfill_page(nil, 100),
        everyone_group_memberships:
          Membership.list_everyone_group_membership_backfill_page(nil, 100),
        admin_group_memberships: Membership.list_admin_group_membership_backfill_page(nil, 100),
        everyone_conversation_access:
          Messaging.list_everyone_conversation_access_backfill_page(nil, 100)
      },
      group_members: %{
        historic_everyone: Membership.list_active_members_of_group(historic_everyone_group_id),
        historic_admin: Membership.list_active_members_of_group(historic_admin_group_id),
        modern_everyone: Membership.list_active_members_of_group(modern_everyone_group_id),
        modern_admin: Membership.list_active_members_of_group(modern_admin_group_id)
      },
      group_membership_checks: %{
        alice_everyone:
          Membership.active_member_of_group?(
            historic_everyone_group_id,
            fixture.historic_members.alice.person_id
          ),
        alice_admin:
          Membership.active_member_of_group?(
            historic_admin_group_id,
            fixture.historic_members.alice.person_id
          ),
        bob_everyone:
          Membership.active_member_of_group?(
            historic_everyone_group_id,
            fixture.historic_members.bob.person_id
          ),
        bob_admin:
          Membership.active_member_of_group?(
            historic_admin_group_id,
            fixture.historic_members.bob.person_id
          ),
        charlie_everyone:
          Membership.active_member_of_group?(
            historic_everyone_group_id,
            fixture.historic_members.charlie.person_id
          ),
        charlie_admin:
          Membership.active_member_of_group?(
            historic_admin_group_id,
            fixture.historic_members.charlie.person_id
          ),
        dana_everyone:
          Membership.active_member_of_group?(
            modern_everyone_group_id,
            fixture.modern_members.dana.person_id
          ),
        dana_admin:
          Membership.active_member_of_group?(
            modern_admin_group_id,
            fixture.modern_members.dana.person_id
          )
      },
      conversation_access: %{
        historic_everyone_write:
          Messaging.group_has_conversation_access?(
            fixture.historic_conversation_id,
            historic_everyone_group_id,
            :write
          ),
        historic_everyone_read:
          Messaging.group_has_conversation_access?(
            fixture.historic_conversation_id,
            historic_everyone_group_id,
            :read
          ),
        historic_admin_read:
          Messaging.group_has_conversation_access?(
            fixture.historic_conversation_id,
            historic_admin_group_id,
            :read
          ),
        historic_admin_write:
          Messaging.group_has_conversation_access?(
            fixture.historic_conversation_id,
            historic_admin_group_id,
            :write
          ),
        modern_everyone_write:
          Messaging.group_has_conversation_access?(
            fixture.modern_conversation_id,
            modern_everyone_group_id,
            :write
          ),
        modern_everyone_read:
          Messaging.group_has_conversation_access?(
            fixture.modern_conversation_id,
            modern_everyone_group_id,
            :read
          )
      }
    }
  end

  defp assert_zero_backfill_dispatches! do
    assert %{
             system_group_definitions: %{dispatched_count: 0},
             everyone_group_memberships: %{dispatched_count: 0},
             admin_group_memberships: %{dispatched_count: 0},
             everyone_conversation_access: %{dispatched_count: 0}
           } = Backfill.run!(page_size: 1)
  end

  defp replay_parity_event_counts(fixture) do
    %{
      historic_club: group_fact_counts(fixture.historic_club.club_id),
      modern_club: group_fact_counts(fixture.modern_club.club_id),
      historic_conversation: conversation_access_fact_count(fixture.historic_conversation_id),
      modern_conversation: conversation_access_fact_count(fixture.modern_conversation_id)
    }
  end

  defp group_fact_counts(club_id) do
    %{
      groups_created: event_count(MembershipApp, club_id, GroupCreated),
      group_members_added: event_count(MembershipApp, club_id, GroupMemberAdded)
    }
  end

  defp conversation_access_fact_count(conversation_id) do
    event_count(MessagingApp, conversation_id, ConversationAccessGrantedToGroup)
  end

  defp event_count(app, stream_id, event_module) do
    app
    |> Commanded.EventStore.stream_forward(stream_id)
    |> Enum.count(&match?(%{data: %^event_module{}}, &1))
  end
end
