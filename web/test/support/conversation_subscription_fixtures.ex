defmodule Memba.ConversationSubscriptionFixtures do
  @moduledoc false

  alias Commanded.Event.Mapper
  alias Memba.ID
  alias Memba.Membership.Events.ClubCreated
  alias Memba.Membership.Events.ClubMemberAdded
  alias Memba.Membership.Events.GroupCreated
  alias Memba.Membership.Events.GroupMembershipStarted
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging.Events.ConversationAccessGrantedToGroup
  alias Memba.Messaging.Events.MessageSent

  def canonical_subscription_fixture!(overrides \\ %{}) do
    ids =
      Map.merge(
        %{
          club_id: ID.generate(:club),
          person_id: ID.generate(:person),
          conversation_id: ID.generate(:message),
          club_membership_id: ID.generate(:membership),
          group_id: ID.generate(:group),
          group_membership_id: ID.generate(:group_membership),
          intent_id: ID.generate(:subscription_intent)
        },
        overrides
      )

    membership_events = [
      %ClubCreated{club_id: ids.club_id, name: "Authority Club", slug: "authority-club"},
      %GroupCreated{
        club_id: ids.club_id,
        group_id: SystemGroups.everyone_group_id(ids.club_id),
        group_key: SystemGroups.everyone_key(),
        name: SystemGroups.everyone_name()
      },
      %GroupCreated{
        club_id: ids.club_id,
        group_id: SystemGroups.admin_group_id(ids.club_id),
        group_key: SystemGroups.admin_key(),
        name: SystemGroups.admin_name()
      },
      %GroupCreated{
        club_id: ids.club_id,
        group_id: ids.group_id,
        group_key: "authority-group",
        name: "Authority Group"
      },
      %ClubMemberAdded{
        club_id: ids.club_id,
        membership_id: ids.club_membership_id,
        person_id: ids.person_id
      },
      %GroupMembershipStarted{
        club_id: ids.club_id,
        group_id: ids.group_id,
        group_membership_id: ids.group_membership_id,
        club_membership_id: ids.club_membership_id,
        person_id: ids.person_id
      }
    ]

    :ok =
      Commanded.EventStore.append_to_stream(
        Memba.Membership.App,
        ids.club_id,
        0,
        Enum.map(membership_events, &Mapper.map_to_event_data/1)
      )

    messaging_events = [
      %MessageSent{
        message_id: ids.conversation_id,
        conversation_id: ids.conversation_id,
        club_id: ids.club_id,
        sender_id: ids.person_id,
        subject: "Authority",
        body: "Canonical conversation",
        sender_follows_conversation: false
      },
      %ConversationAccessGrantedToGroup{
        conversation_id: ids.conversation_id,
        club_id: ids.club_id,
        group_id: ids.group_id,
        access_level: "write"
      }
    ]

    :ok =
      Commanded.EventStore.append_to_stream(
        Memba.Messaging.App,
        ids.conversation_id,
        0,
        Enum.map(messaging_events, &Mapper.map_to_event_data/1)
      )

    :ok =
      Commanded.Subscriptions.wait_for(Memba.Membership.App, ids.club_id, 6,
        consistency: [
          Memba.Membership.Projectors.Club,
          Memba.Membership.Projectors.Group,
          Memba.Membership.Projectors.GroupMembership,
          Memba.Membership.Projectors.FirstClassGroupMembershipV1,
          Memba.Membership.Projectors.Membership,
          Memba.Membership.Policies.SystemGroupMembership
        ]
      )

    :ok =
      Commanded.Subscriptions.wait_for(Memba.Messaging.App, ids.conversation_id, 2,
        consistency: [
          Memba.Messaging.Projectors.Message,
          Memba.Messaging.Projectors.ConversationGroupAccess,
          Memba.Messaging.Projectors.ConversationFollow
        ]
      )

    Memba.EventSourcedCase.stop_event_sourced_aggregate_instances!()
    ids
  end
end
