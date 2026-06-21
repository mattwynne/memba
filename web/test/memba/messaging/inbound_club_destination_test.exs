defmodule Memba.Messaging.InboundClubDestinationTest do
  use Memba.DataCase, async: false

  alias Memba.Messaging
  alias Memba.Messaging.InboundClubDestination
  alias Memba.Messaging.InboundEmail

  describe "resolve_inbound_club_email_destination/1" do
    test "resolves a whole-club inbound subdomain address to a club by slug" do
      club = insert_membership_club!(slug: "kmc")

      assert {:ok,
              %InboundClubDestination{
                club_id: club.club_id,
                club_slug: "kmc",
                club_name: club.name,
                to_address: "everyone@kmc.clubs.memba.io"
              }} ==
               Messaging.resolve_inbound_club_email_destination([
                 "everyone@kmc.clubs.memba.io"
               ])
    end

    test "normalizes recipient subdomain address casing and accepts unrelated copied recipients" do
      club = insert_membership_club!(slug: "kmc")

      inbound_email = %InboundEmail{
        provider: "resend",
        provider_message_id: "email-123",
        from_address: "alice@example.com",
        recipient_addresses: [" friend@example.org ", " EVERYONE@KMC.Clubs.Memba.IO "],
        subject: "Trip planning night"
      }

      assert {:ok,
              %InboundClubDestination{
                club_id: club.club_id,
                club_slug: "kmc",
                club_name: club.name,
                to_address: "everyone@kmc.clubs.memba.io"
              }} == Messaging.resolve_inbound_club_email_destination(inbound_email)
    end

    test "uses the configured inbound email domain" do
      club = insert_membership_club!(slug: "kmc")

      with_club_inbound_email_config([domain: " Example.Clubs.Memba.IO. "], fn ->
        assert {:ok,
                %InboundClubDestination{
                  club_id: club.club_id,
                  club_slug: "kmc",
                  club_name: club.name,
                  to_address: "everyone@kmc.example.clubs.memba.io"
                }} ==
                 Messaging.resolve_inbound_club_email_destination([
                   "everyone@kmc.example.clubs.memba.io"
                 ])
      end)
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
