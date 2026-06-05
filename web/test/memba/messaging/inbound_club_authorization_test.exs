defmodule Memba.Messaging.InboundClubAuthorizationTest do
  use Memba.DataCase, async: true

  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Messaging
  alias Memba.Messaging.InboundClubDestination
  alias Memba.Messaging.InboundClubSender

  describe "authorize_inbound_club_email_sender/2" do
    test "authorizes a resolved sender who is an active member of the destination club" do
      club = insert_membership_club!(slug: "kmc")
      alice = insert_membership_person!(name: "Alice Example", email: "alice@example.com")
      insert_membership!(club, alice, active: true)

      assert :ok ==
               Messaging.authorize_inbound_club_email_sender(
                 sender(alice, "alice@example.com"),
                 destination(club, "kmc@clubs.memba.io")
               )
    end

    test "rejects a resolved sender who is only active in another club" do
      kmc = insert_membership_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
      npc = insert_membership_club!(name: "Nelson Paddling Club", slug: "npc")
      pat = insert_membership_person!(name: "Pat Example", email: "pat@example.com")
      insert_membership!(npc, pat, active: true)

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

    test "rejects a resolved sender with an inactive destination-club membership" do
      club = insert_membership_club!(slug: "kmc")
      alice = insert_membership_person!(name: "Alice Example", email: "alice@example.com")
      insert_membership!(club, alice, active: false)

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
      to_address: to_address
    }
  end

  defp insert_membership!(club, person, attrs) do
    Repo.insert!(%MembershipProjection{
      membership_id: Memba.ID.generate(:membership),
      club_id: club.club_id,
      person_id: person.person_id,
      active: Keyword.fetch!(attrs, :active)
    })
  end
end
