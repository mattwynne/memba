defmodule Memba.Messaging.InboundClubDestinationTest do
  use Memba.DataCase, async: false

  alias Memba.Membership.Projections.Group, as: GroupProjection
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging
  alias Memba.Messaging.InboundClubDestination
  alias Memba.Messaging.InboundEmail

  describe "resolve_inbound_club_email_destination/1" do
    test "resolves a whole-club inbound subdomain address to a club by slug" do
      club = insert_membership_club!(slug: "kmc")
      everyone_group = insert_addressable_system_group!(club, :everyone)

      assert {:ok,
              %InboundClubDestination{
                club_id: club.club_id,
                club_slug: "kmc",
                club_name: club.name,
                group_id: everyone_group.group_id,
                group_email_slug: "everyone",
                group_name: "Everyone",
                to_address: "everyone@kmc.clubs.memba.io"
              }} ==
               Messaging.resolve_inbound_club_email_destination([
                 "everyone@kmc.clubs.memba.io"
               ])
    end

    test "resolves the local part through the destination club's group email slug" do
      kmc = insert_membership_club!(slug: "kmc")
      npc = insert_membership_club!(name: "Nelson Paddling Club", slug: "npc")
      kmc_admin_group = insert_addressable_system_group!(kmc, :admin)
      npc_admin_group = insert_addressable_system_group!(npc, :admin)

      assert {:ok,
              %InboundClubDestination{
                club_id: kmc.club_id,
                club_slug: "kmc",
                club_name: kmc.name,
                group_id: kmc_admin_group.group_id,
                group_email_slug: "admin",
                group_name: "Admin",
                to_address: "admin@kmc.clubs.memba.io"
              }} ==
               Messaging.resolve_inbound_club_email_destination([
                 "admin@kmc.clubs.memba.io"
               ])

      refute kmc_admin_group.group_id == npc_admin_group.group_id
    end

    test "uses the extracted club subdomain as the Membership slug lookup value" do
      club =
        insert_membership_club!(
          name: "Kootenay Mountaineering Club",
          slug: "kmc-alpine"
        )

      everyone_group = insert_addressable_system_group!(club, :everyone)

      assert {:ok,
              %InboundClubDestination{
                club_id: club.club_id,
                club_slug: "kmc-alpine",
                club_name: "Kootenay Mountaineering Club",
                group_id: everyone_group.group_id,
                group_email_slug: "everyone",
                group_name: "Everyone",
                to_address: "everyone@kmc-alpine.clubs.memba.io"
              }} ==
               Messaging.resolve_inbound_club_email_destination([
                 "everyone@kmc-alpine.clubs.memba.io"
               ])

      assert {:error, :unknown_club_slug, "everyone@kmc.clubs.memba.io"} ==
               Messaging.resolve_inbound_club_email_destination([
                 "everyone@kmc.clubs.memba.io"
               ])
    end

    test "normalizes recipient subdomain address casing and accepts unrelated copied recipients" do
      club = insert_membership_club!(slug: "kmc")
      admin_group = insert_addressable_system_group!(club, :admin)

      inbound_email = %InboundEmail{
        provider: "resend",
        provider_message_id: "email-123",
        from_address: "alice@example.com",
        recipient_addresses: [" friend@example.org ", " ADMIN@KMC.Clubs.Memba.IO "],
        subject: "Trip planning night"
      }

      assert {:ok,
              %InboundClubDestination{
                club_id: club.club_id,
                club_slug: "kmc",
                club_name: club.name,
                group_id: admin_group.group_id,
                group_email_slug: "admin",
                group_name: "Admin",
                to_address: "admin@kmc.clubs.memba.io"
              }} == Messaging.resolve_inbound_club_email_destination(inbound_email)
    end

    test "uses the configured inbound email domain" do
      club = insert_membership_club!(slug: "kmc")
      everyone_group = insert_addressable_system_group!(club, :everyone)

      with_club_inbound_email_config([domain: " Example.Clubs.Memba.IO. "], fn ->
        assert {:ok,
                %InboundClubDestination{
                  club_id: club.club_id,
                  club_slug: "kmc",
                  club_name: club.name,
                  group_id: everyone_group.group_id,
                  group_email_slug: "everyone",
                  group_name: "Everyone",
                  to_address: "everyone@kmc.example.clubs.memba.io"
                }} ==
                 Messaging.resolve_inbound_club_email_destination([
                   "everyone@kmc.example.clubs.memba.io"
                 ])
      end)
    end

    test "rejects unsupported local parts at a known club subdomain" do
      insert_membership_club!(slug: "kmc")

      assert {:error, :unsupported_recipient_address, "committee@kmc.clubs.memba.io"} ==
               Messaging.resolve_inbound_club_email_destination([
                 "committee@kmc.clubs.memba.io"
               ])
    end

    test "rejects recipient addresses outside the inbound club domain" do
      insert_membership_club!(slug: "kmc")

      assert {:error, :unsupported_recipient_address, "everyone@example.org"} ==
               Messaging.resolve_inbound_club_email_destination(["everyone@example.org"])
    end

    test "rejects unknown club subdomains at the inbound club domain" do
      assert {:error, :unknown_club_slug, "everyone@unknown.clubs.memba.io"} ==
               Messaging.resolve_inbound_club_email_destination([
                 "everyone@unknown.clubs.memba.io"
               ])
    end

    test "rejects the old flat club address shape even when the club exists" do
      insert_membership_club!(slug: "kmc")

      assert {:error, :unsupported_recipient_address, "kmc@clubs.memba.io"} ==
               Messaging.resolve_inbound_club_email_destination(["kmc@clubs.memba.io"])
    end

    test "rejects malformed or missing recipient input as unsupported" do
      assert {:error, :unsupported_recipient_address, nil} ==
               Messaging.resolve_inbound_club_email_destination([])

      assert {:error, :unsupported_recipient_address, nil} ==
               Messaging.resolve_inbound_club_email_destination(nil)

      assert {:error, :unsupported_recipient_address, "not-an-email-address"} ==
               Messaging.resolve_inbound_club_email_destination(["not-an-email-address"])

      assert {:error, :unsupported_recipient_address, "not_safe@clubs.memba.io"} ==
               Messaging.resolve_inbound_club_email_destination(["not_safe@clubs.memba.io"])
    end
  end

  defp insert_addressable_system_group!(club, :everyone) do
    Repo.insert!(%GroupProjection{
      club_id: club.club_id,
      group_id: SystemGroups.everyone_group_id(club.club_id),
      email_slug: SystemGroups.everyone_email_slug(),
      group_key: SystemGroups.everyone_key(),
      name: SystemGroups.everyone_name()
    })
  end

  defp insert_addressable_system_group!(club, :admin) do
    Repo.insert!(%GroupProjection{
      club_id: club.club_id,
      group_id: SystemGroups.admin_group_id(club.club_id),
      email_slug: SystemGroups.admin_email_slug(),
      group_key: SystemGroups.admin_key(),
      name: SystemGroups.admin_name()
    })
  end

  defp with_club_inbound_email_config(config, fun) do
    original = Application.get_env(:memba, :club_inbound_email)

    try do
      Application.put_env(:memba, :club_inbound_email, config)
      fun.()
    after
      restore_club_inbound_email_config(original)
    end
  end

  defp restore_club_inbound_email_config(nil),
    do: Application.delete_env(:memba, :club_inbound_email)

  defp restore_club_inbound_email_config(config),
    do: Application.put_env(:memba, :club_inbound_email, config)
end
