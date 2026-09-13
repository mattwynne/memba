defmodule Memba.Membership.ClearRemovedGroupMemberFollowsPolicyTest do
  use Memba.EventSourcedCase, async: false

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
  alias Memba.Membership.Commands.RemoveClubMember
  alias Memba.Membership.Events.GroupMemberRemoved
  alias Memba.Membership.Policies.ClearRemovedGroupMemberFollows
  alias Memba.Membership.Policies.SystemGroupMembership
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging
  alias Memba.Messaging.App, as: MessagingApp
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Events.ConversationUnfollowed
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

    create_club(club_id)
    add_member(club_id, departing_membership_id, departing_person_id)
    add_member(club_id, replacement_membership_id, replacement_person_id)
    assign_admin(club_id, replacement_membership_id, replacement_person_id)
    create_custom_group(club_id, custom_group_id)
    add_group_member(club_id, custom_group_id, departing_membership_id, departing_person_id)
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
    after
      :ok = :sys.resume(clear_follows_handler)
    end

    assert :ok = Task.await(removal)

    assert :ok =
             Membership.add_member(%{
               club_id: club_id,
               membership_id: rejoined_membership_id,
               person_id: departing_person_id
             })

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

  defp latest_club_stream_version(club_id) do
    MembershipApp
    |> EventStore.stream_forward(club_id)
    |> Enum.to_list()
    |> List.last()
    |> Map.fetch!(:stream_version)
  end
end
