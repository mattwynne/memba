defmodule Memba.Membership.ClearRemovedGroupMemberFollowsPolicyTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.EventStore
  alias Memba.Membership
  alias Memba.Membership.App, as: MembershipApp
  alias Memba.Membership.Commands.AddClubMember
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreateGroup
  alias Memba.Membership.Events.GroupMemberRemoved
  alias Memba.Membership.Policies.ClearRemovedGroupMemberFollows
  alias Memba.Messaging
  alias Memba.Messaging.App, as: MessagingApp
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Events.ConversationUnfollowed
  alias Memba.Messaging.Recipient

  test "retains the deployed strong subscription name and checkpoint" do
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
  end

  test "club-departure group removal idempotently clears follows" do
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

  test "custom-group removal preserves a dormant follow while ending participation" do
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    actor_membership_id = Memba.ID.generate(:membership)
    actor_person_id = Memba.ID.generate(:person)
    target_membership_id = Memba.ID.generate(:membership)
    target_person_id = Memba.ID.generate(:person)
    conversation_id = Memba.ID.generate(:message)

    create_club(club_id)
    add_member(club_id, actor_membership_id, actor_person_id)
    add_member(club_id, target_membership_id, target_person_id)
    create_custom_group(club_id, group_id)
    add_group_member(club_id, group_id, actor_membership_id, actor_person_id)
    add_group_member(club_id, group_id, target_membership_id, target_person_id)
    create_followed_conversation(club_id, group_id, conversation_id, target_person_id)

    assert {:ok, _outcome} =
             Membership.remove_custom_group_member(
               %{
                 club_id: club_id,
                 group_id: group_id,
                 membership_id: target_membership_id,
                 person_id: target_person_id,
                 actor_person_id: actor_person_id,
                 removal_operation_id: Ecto.UUID.generate()
               },
               consistency: :strong
             )

    refute Membership.active_member_of_group?(group_id, target_person_id)
    assert Messaging.following_conversation?(conversation_id, target_person_id)
    assert count_unfollow_events(conversation_id, target_person_id) == 0
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
                     name: "Group member",
                     email: "member@example.com"
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
end
