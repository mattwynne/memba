defmodule Memba.Messaging.GroupEmailPostingPolicyTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging
  alias Memba.Messaging.GroupEmailPostingPolicy
  alias Memba.Messaging.InboundClubDestination
  alias Memba.Messaging.InboundClubSender

  test "the fixed group-email posting policy is named club_members_only" do
    assert GroupEmailPostingPolicy.name() == :club_members_only
  end

  describe "authorize_inbound_club_email_sender/2" do
    test "authorizes a resolved sender who is an active member of the destination club's Everyone group" do
      club = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
      alice = create_person!(name: "Alice Example", email: "alice@example.com")
      add_member!(club.club_id, alice.person_id)

      assert :ok ==
               Messaging.authorize_inbound_club_email_sender(
                 sender(alice, "alice@example.com"),
                 destination(club, "kmc@clubs.memba.io")
               )
    end

    test "rejects a resolved sender who is only active in another club" do
      kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
      npc = create_club!(name: "Nelson Paddling Club", slug: "npc")
      pat = create_person!(name: "Pat Example", email: "pat@example.com")
      add_member!(npc.club_id, pat.person_id)

      assert {:error, :sender_not_active_member,
              %{
                sender_id: pat.person_id,
                club_id: kmc.club_id,
                from_address: "pat@example.com",
                to_address: "kmc@clubs.memba.io"
              }} ==
               Messaging.authorize_inbound_club_email_sender(
                 sender(pat, "pat@example.com"),
                 destination(kmc, "kmc@clubs.memba.io")
               )
    end

    test "authorizes an active destination-club member without membership of the addressed Admin group" do
      club = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
      bob = create_person!(name: "Bob Admin", email: "bob@example.com")
      alice = create_person!(name: "Alice Example", email: "alice@example.com")
      add_member!(club.club_id, bob.person_id)
      add_member!(club.club_id, alice.person_id)

      refute Membership.active_member_of_group?(
               SystemGroups.admin_group_id(club.club_id),
               alice.person_id
             )

      assert :ok ==
               Messaging.authorize_inbound_club_email_sender(
                 sender(alice, "alice@example.com"),
                 admin_destination(club, "admin@kmc.clubs.memba.io")
               )
    end

    test "custom-group roots require current participation while system-group semantics stay club-wide" do
      club = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
      alice = create_person!(name: "Alice Admin", email: "alice@example.com")
      eve = create_person!(name: "Eve Member", email: "eve@example.com")
      _alice_membership_id = add_member!(club.club_id, alice.person_id)
      eve_membership_id = add_member!(club.club_id, eve.person_id)
      group_id = Memba.ID.generate(:group)

      assert :ok =
               Membership.create_custom_group(
                 %{
                   club_id: club.club_id,
                   group_id: group_id,
                   actor_person_id: alice.person_id,
                   name: "Board"
                 },
                 consistency: :strong
               )

      custom_destination = %InboundClubDestination{
        club_id: club.club_id,
        club_slug: club.slug,
        club_name: club.name,
        group_id: group_id,
        group_email_slug: "board",
        group_name: "Board",
        to_address: "board@kmc.clubs.memba.io"
      }

      assert {:error, :sender_not_active_member, _details} =
               Messaging.authorize_inbound_club_email_sender(
                 sender(eve, "eve@example.com"),
                 custom_destination
               )

      assert {:ok, _admission} =
               Membership.add_custom_group_member(
                 %{
                   club_id: club.club_id,
                   group_id: group_id,
                   membership_id: eve_membership_id,
                   person_id: eve.person_id,
                   actor_person_id: alice.person_id
                 },
                 consistency: :strong
               )

      assert :ok =
               Messaging.authorize_inbound_club_email_sender(
                 sender(eve, "eve@example.com"),
                 custom_destination
               )
    end

    test "rejects a resolved sender with an inactive destination-club membership" do
      club = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
      bob = create_person!(name: "Bob Admin", email: "bob@example.com")
      alice = create_person!(name: "Alice Example", email: "alice@example.com")
      add_member!(club.club_id, bob.person_id)
      membership_id = add_member!(club.club_id, alice.person_id)

      assert :ok =
               Membership.remove_member(
                 %{
                   club_id: club.club_id,
                   membership_id: membership_id,
                   person_id: alice.person_id
                 },
                 consistency: :strong
               )

      assert {:error, :sender_not_active_member,
              %{
                sender_id: alice.person_id,
                club_id: club.club_id,
                from_address: "alice@example.com",
                to_address: "kmc@clubs.memba.io"
              }} ==
               Messaging.authorize_inbound_club_email_sender(
                 sender(alice, "alice@example.com"),
                 destination(club, "kmc@clubs.memba.io")
               )
    end
  end

  defp sender(person, from_address) do
    %InboundClubSender{
      person_id: person.person_id,
      name: person.name,
      from_address: from_address
    }
  end

  defp destination(club, to_address) do
    %InboundClubDestination{
      club_id: club.club_id,
      club_slug: club.slug,
      club_name: club.name,
      group_id: SystemGroups.everyone_group_id(club.club_id),
      group_email_slug: SystemGroups.everyone_email_slug(),
      group_name: SystemGroups.everyone_name(),
      to_address: to_address
    }
  end

  defp admin_destination(club, to_address) do
    %InboundClubDestination{
      club_id: club.club_id,
      club_slug: club.slug,
      club_name: club.name,
      group_id: SystemGroups.admin_group_id(club.club_id),
      group_email_slug: SystemGroups.admin_email_slug(),
      group_name: SystemGroups.admin_name(),
      to_address: to_address
    }
  end

  defp create_club!(attrs) do
    club_id = Memba.ID.generate(:club)

    assert :ok =
             Membership.create_club(
               %{
                 club_id: club_id,
                 name: Keyword.fetch!(attrs, :name),
                 slug: Keyword.fetch!(attrs, :slug)
               },
               consistency: :strong
             )

    Membership.get_club(club_id)
  end

  defp create_person!(attrs) do
    person_id = Memba.ID.generate(:person)

    assert :ok =
             Membership.create_person(
               %{
                 person_id: person_id,
                 name: Keyword.fetch!(attrs, :name),
                 email: Keyword.fetch!(attrs, :email)
               },
               consistency: :strong
             )

    Membership.get_person(person_id)
  end

  defp add_member!(club_id, person_id) do
    membership_id = Memba.ID.generate(:membership)

    assert :ok =
             Membership.add_member(
               %{
                 membership_id: membership_id,
                 club_id: club_id,
                 person_id: person_id
               },
               consistency: :strong
             )

    membership_id
  end
end
