defmodule Memba.Messaging.RequestGroupAccessTest do
  use Memba.EventSourcedCase, async: false

  import Memba.MembershipFixtures, only: [membership_club_slug: 2]

  alias Memba.Membership
  alias Memba.Membership.App, as: MembershipApp
  alias Memba.Membership.Commands.AssignClubRoleToMember
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging
  alias MembaWeb.ClubSite

  test "sends a fixed Admin Group message naming the requester and group, without granting access" do
    club_id = create_club("Kootenay Mountaineering Club")
    admin_group_id = SystemGroups.admin_group_id(club_id)

    alice = create_person("Alice")
    dan = create_person("Dan")
    eve = create_person("Eve")

    alice_membership_id = add_member(club_id, alice.person_id)
    dan_membership_id = add_member(club_id, dan.person_id)
    add_member(club_id, eve.person_id)
    assign_admin(club_id, alice_membership_id, alice.person_id)
    assign_admin(club_id, dan_membership_id, dan.person_id)

    board_group_id = create_custom_group(club_id, alice.person_id, "Board")

    message_id = Memba.ID.generate(:message)

    assert :ok =
             Messaging.request_group_access(
               %{
                 message_id: message_id,
                 club_id: club_id,
                 requester_person_id: eve.person_id,
                 group_id: board_group_id
               },
               consistency: :strong
             )

    message = Messaging.get_message(message_id)

    assert message.club_id == club_id
    assert message.conversation_id == message_id
    assert message.sender_id == eve.person_id
    assert message.subject == "Access request: Board"
    assert message.body =~ "Eve would like to join Board."
    assert message.body =~ "Eve asked from Board's page in Kootenay Mountaineering Club."
    assert message.body =~ "You'll confirm on the website before Eve is added."

    expected_url =
      ClubSite.url(
        Membership.get_club(club_id),
        "/groups/#{board_group_id}/members/add/#{eve.person_id}"
      )

    assert message.body =~ "Add Eve to Board:\n#{expected_url}"

    recipient_ids =
      message_id
      |> Messaging.list_recipient_deliveries()
      |> Enum.map(& &1.recipient_id)
      |> Enum.sort()

    assert recipient_ids == Enum.sort([alice.person_id, dan.person_id])
    assert Messaging.group_has_conversation_access?(message_id, admin_group_id, :write)

    refute Membership.active_member_of_group_authoritatively?(
             club_id,
             board_group_id,
             eve.person_id
           )

    refute Messaging.following_conversation?(message_id, eve.person_id)
  end

  test "rejects a requester who is not currently an active club member" do
    club_id = create_club("Kootenay Mountaineering Club")
    alice = create_person("Alice")
    eve = create_person("Eve")
    add_member(club_id, alice.person_id)
    board_group_id = create_custom_group(club_id, alice.person_id, "Board")

    message_id = Memba.ID.generate(:message)

    assert {:error, :member_not_active} =
             Messaging.request_group_access(
               %{
                 message_id: message_id,
                 club_id: club_id,
                 requester_person_id: eve.person_id,
                 group_id: board_group_id
               },
               consistency: :strong
             )

    refute Messaging.get_message(message_id)
  end

  test "rejects a request for a built-in group" do
    club_id = create_club("Kootenay Mountaineering Club")
    alice = create_person("Alice")
    eve = create_person("Eve")
    add_member(club_id, alice.person_id)
    add_member(club_id, eve.person_id)

    message_id = Memba.ID.generate(:message)

    assert {:error, :built_in_group} =
             Messaging.request_group_access(
               %{
                 message_id: message_id,
                 club_id: club_id,
                 requester_person_id: eve.person_id,
                 group_id: SystemGroups.everyone_group_id(club_id)
               },
               consistency: :strong
             )

    refute Messaging.get_message(message_id)
  end

  test "rejects a group owned by another club" do
    kmc_id = create_club("Kootenay Mountaineering Club")
    npc_id = create_club("Nelson Paddling Club")

    alice = create_person("Alice")
    eve = create_person("Eve")
    add_member(npc_id, alice.person_id)
    add_member(kmc_id, eve.person_id)

    foreign_board_group_id = create_custom_group(npc_id, alice.person_id, "Board")

    message_id = Memba.ID.generate(:message)

    assert {:error, :group_not_found} =
             Messaging.request_group_access(
               %{
                 message_id: message_id,
                 club_id: kmc_id,
                 requester_person_id: eve.person_id,
                 group_id: foreign_board_group_id
               },
               consistency: :strong
             )

    refute Messaging.get_message(message_id)
  end

  test "ignores client-supplied sender, subject and body" do
    club_id = create_club("Kootenay Mountaineering Club")
    admin_group_id = SystemGroups.admin_group_id(club_id)
    alice = create_person("Alice")
    eve = create_person("Eve")
    mallory = create_person("Mallory")
    alice_membership_id = add_member(club_id, alice.person_id)
    add_member(club_id, eve.person_id)
    assign_admin(club_id, alice_membership_id, alice.person_id)
    board_group_id = create_custom_group(club_id, alice.person_id, "Board")

    message_id = Memba.ID.generate(:message)

    assert :ok =
             Messaging.request_group_access(
               %{
                 message_id: message_id,
                 club_id: club_id,
                 requester_person_id: eve.person_id,
                 group_id: board_group_id,
                 sender_id: mallory.person_id,
                 audience_group_id: Memba.ID.generate(:group),
                 subject: "Let me into Admin",
                 body: "Arbitrary attacker body"
               },
               consistency: :strong
             )

    message = Messaging.get_message(message_id)

    assert message.sender_id == eve.person_id
    assert message.subject == "Access request: Board"
    refute message.body =~ "Arbitrary attacker body"
    assert Messaging.group_has_conversation_access?(message_id, admin_group_id, :write)
  end

  defp create_club(name) do
    club_id = Memba.ID.generate(:club)

    assert :ok =
             Membership.create_club(
               %{club_id: club_id, name: name, slug: membership_club_slug(name, club_id)},
               consistency: :strong
             )

    club_id
  end

  defp create_person(name) do
    person_id = Memba.ID.generate(:person)
    email = "#{String.downcase(name)}-#{Ecto.UUID.generate()}@example.test"

    assert :ok =
             Membership.create_person(
               %{
                 person_id: person_id,
                 name: name,
                 email_addresses: [%{email: email, is_primary: true}]
               },
               consistency: :strong
             )

    %{person_id: person_id, name: name, email: email}
  end

  defp add_member(club_id, person_id) do
    membership_id = Memba.ID.generate(:membership)

    assert :ok =
             Membership.add_member(
               %{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id
               },
               consistency: :strong
             )

    membership_id
  end

  defp assign_admin(club_id, membership_id, person_id) do
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

  defp create_custom_group(club_id, actor_person_id, name) do
    group_id = Memba.ID.generate(:group)

    assert :ok =
             Membership.create_custom_group(
               %{
                 club_id: club_id,
                 group_id: group_id,
                 actor_person_id: actor_person_id,
                 name: name
               },
               consistency: :strong
             )

    group_id
  end
end
