defmodule MembaWeb.LiveQuery.MembaReadModelSourceTest do
  use MembaWeb.ConnCase, async: true

  alias Memba.Membership.Events.ClubMemberAdded
  alias Memba.Membership.Events.ClubRoleAssignedToMember
  alias Memba.Membership.Events.ClubUpdated
  alias Memba.Membership.Events.GroupEmailSlugAssigned
  alias Memba.Membership.Events.GroupMemberAdded
  alias Memba.Membership.Events.PersonEmailAddressAdded
  alias Memba.Messaging.Events.ConversationAccessGrantedToGroup
  alias Memba.Messaging.Events.MessageSent
  alias MembaWeb.LiveQuery.MembaReadModelSource
  alias MembaWeb.LiveQuery.Source

  test "subscribes to the shared committed read-model topic" do
    source = MembaReadModelSource.new()

    assert :ok = Source.subscribe(source)

    notification =
      {:read_model_changed,
       %{
         projector: Memba.Membership.Projectors.Person,
         source_event: %PersonEmailAddressAdded{
           person_id: "person-1",
           email: "alice@example.com",
           normalized_email: "alice@example.com"
         },
         metadata: %{},
         changes: %{}
       }}

    Phoenix.PubSub.broadcast(Memba.PubSub, Memba.ReadModelChanges.topic(), notification)

    assert_receive ^notification
  end

  test "classifies club-member collection entry and exact represented identities" do
    source = MembaReadModelSource.new()

    assert {:ok, invalidations} =
             Source.classify(
               source,
               notification(
                 Memba.Membership.Projectors.Membership,
                 %ClubMemberAdded{
                   club_id: "club-1",
                   membership_id: "membership-1",
                   person_id: "person-1"
                 }
               )
             )

    assert {:club_members, "club-1"} in invalidations
    assert {:membership, "membership-1"} in invalidations
    assert {:person, "person-1"} in invalidations
    assert {:person_clubs, "person-1"} in invalidations
  end

  test "matches Person changes only to the represented Person unless scope is unavailable" do
    source = MembaReadModelSource.new()

    assert {:ok, [{:person, "person-1"}, {:person_emails, "person-1"}]} =
             Source.classify(
               source,
               notification(
                 Memba.Membership.Projectors.Person,
                 %PersonEmailAddressAdded{
                   person_id: "person-1",
                   email: "alice@example.com",
                   normalized_email: "alice@example.com"
                 }
               )
             )

    assert Source.matches?(source, {:person, "person-1"}, {:person, "person-1"})
    refute Source.matches?(source, {:person, "person-2"}, {:person, "person-1"})

    assert {:ok, [{:fallback, :person}]} =
             Source.classify(
               source,
               notification(Memba.Membership.Projectors.Person, %{})
             )
  end

  test "keeps represented role badges distinct from current-actor permissions" do
    source = MembaReadModelSource.new()

    assert {:ok, invalidations} =
             Source.classify(
               source,
               notification(
                 Memba.Membership.Projectors.Role,
                 %ClubRoleAssignedToMember{
                   club_id: "club-1",
                   membership_id: "membership-1",
                   person_id: "person-1",
                   role_id: "role-1"
                 }
               )
             )

    assert {:member_roles, "club-1", "membership-1", "person-1"} in invalidations
    assert {:member_permissions, "club-1", "membership-1", "person-1"} in invalidations
    assert {:role, "role-1"} in invalidations
  end

  test "uses club-conversation invalidation for root messages and replies" do
    source = MembaReadModelSource.new()

    event = %MessageSent{
      message_id: "message-2",
      club_id: "club-1",
      sender_id: "person-1",
      conversation_id: "message-1",
      reply_to_message_id: "message-1",
      subject: "Re: Plans",
      body: "Count me in"
    }

    assert {:ok, invalidations} =
             Source.classify(
               source,
               notification(Memba.Messaging.Projectors.Message, event)
             )

    assert {:message, "message-2"} in invalidations
    assert {:conversation, "message-1"} in invalidations
    assert {:conversation_messages, "message-1"} in invalidations
    assert {:club_conversations, "club-1"} in invalidations
  end

  test "classifies Club, Group, GroupMembership and conversation access scopes" do
    source = MembaReadModelSource.new()

    assert {:ok, [{:club, "club-1"}]} =
             Source.classify(
               source,
               notification(
                 Memba.Membership.Projectors.Club,
                 %ClubUpdated{club_id: "club-1", name: "Updated", slug: "updated"}
               )
             )

    assert {:ok, group_invalidations} =
             Source.classify(
               source,
               notification(
                 Memba.Membership.Projectors.Group,
                 %GroupEmailSlugAssigned{
                   club_id: "club-1",
                   group_id: "group-1",
                   email_slug: "planning"
                 }
               )
             )

    assert {:club_groups, "club-1"} in group_invalidations
    assert {:group, "group-1"} in group_invalidations
    refute Source.matches?(source, {:club_groups, "club-2"}, {:club_groups, "club-1"})

    assert {:ok, membership_invalidations} =
             Source.classify(
               source,
               notification(
                 Memba.Membership.Projectors.GroupMembership,
                 %GroupMemberAdded{
                   club_id: "club-1",
                   group_id: "group-1",
                   membership_id: "membership-1",
                   person_id: "person-1"
                 }
               )
             )

    assert {:group_members, "group-1"} in membership_invalidations
    assert {:person_groups, "club-1", "person-1"} in membership_invalidations
    assert {:group_participation, "club-1", "group-1", "person-1"} in membership_invalidations

    assert {:ok, access_invalidations} =
             Source.classify(
               source,
               notification(
                 Memba.Messaging.Projectors.ConversationGroupAccess,
                 %ConversationAccessGrantedToGroup{
                   club_id: "club-1",
                   group_id: "group-1",
                   conversation_id: "conversation-1",
                   access_level: "write"
                 }
               )
             )

    assert {:group_conversations, "group-1"} in access_invalidations
    assert {:conversation_access, "group-1", "conversation-1"} in access_invalidations
  end

  test "uses club and global conservative fallbacks when exact scope is missing" do
    source = MembaReadModelSource.new()

    assert {:ok, membership_invalidations} =
             Source.classify(
               source,
               notification(
                 Memba.Membership.Projectors.GroupMembership,
                 %{club_id: "club-1", group_id: "group-1"}
               )
             )

    assert {:group_members, "group-1"} in membership_invalidations
    assert {:fallback, :group_membership, "club-1"} in membership_invalidations

    assert {:ok, [{:fallback, :role, "club-1"}]} =
             Source.classify(
               source,
               notification(Memba.Membership.Projectors.Role, %{club_id: "club-1"})
             )

    assert {:ok, [{:fallback, :conversation_access}]} =
             Source.classify(
               source,
               notification(Memba.Messaging.Projectors.ConversationGroupAccess, %{})
             )
  end

  test "ignores delivery notifications because dashboard delivery data was removed" do
    source = MembaReadModelSource.new()

    assert :ignore =
             Source.classify(
               source,
               notification(Memba.Messaging.Projectors.MemberEmailDelivery, %{})
             )
  end

  defp notification(projector, source_event) do
    {:read_model_changed,
     %{
       projector: projector,
       source_event: source_event,
       metadata: %{},
       changes: %{}
     }}
  end
end
