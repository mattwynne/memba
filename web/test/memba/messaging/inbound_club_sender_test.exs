defmodule Memba.Messaging.InboundClubSenderTest do
  use Memba.DataCase, async: true

  alias Memba.Messaging
  alias Memba.Messaging.InboundClubSender
  alias Memba.Messaging.InboundEmail
  alias Memba.Membership.Projections.PersonEmailAddress

  describe "resolve_inbound_club_email_sender/1" do
    test "resolves a sender from a person's primary email address" do
      alice =
        insert_membership_person!(
          name: "Alice Example",
          email_addresses: [
            %{email: "Alice@Example.COM", is_primary: true},
            %{email: "alice@work.example", is_primary: false}
          ]
        )

      verify_all_email_addresses!()

      assert {:ok,
              %InboundClubSender{
                person_id: alice.person_id,
                name: "Alice Example",
                from_address: "alice@example.com"
              }} == Messaging.resolve_inbound_club_email_sender(" Alice@Example.COM ")
    end

    test "resolves a sender from any alternate email address" do
      alice =
        insert_membership_person!(
          name: "Alice Example",
          email_addresses: [
            %{email: "alice@example.com", is_primary: true},
            %{email: "Alice.Work@Example.COM", is_primary: false}
          ]
        )

      verify_all_email_addresses!()

      inbound_email = %InboundEmail{
        provider: "resend",
        provider_message_id: "email-123",
        from_address: " alice.work@example.com ",
        recipient_addresses: ["kmc@clubs.memba.io"],
        subject: "Trip planning night"
      }

      assert {:ok,
              %InboundClubSender{
                person_id: alice.person_id,
                name: "Alice Example",
                from_address: "alice.work@example.com"
              }} == Messaging.resolve_inbound_club_email_sender(inbound_email)
    end

    test "rejects unknown, blank, or missing sender addresses" do
      assert {:error, :unknown_sender, "unknown@example.com"} ==
               Messaging.resolve_inbound_club_email_sender("unknown@example.com")

      assert {:error, :unknown_sender, nil} ==
               Messaging.resolve_inbound_club_email_sender("   ")

      assert {:error, :unknown_sender, nil} ==
               Messaging.resolve_inbound_club_email_sender(nil)
    end

    test "rejects a pending known email address as an unknown sender" do
      insert_membership_person!(
        name: "Alice Example",
        email_addresses: [
          %{email: "alice@example.com", is_primary: true},
          %{email: "Alice.Pending@Example.COM", is_primary: false}
        ]
      )

      verify_email_address!("alice@example.com")

      assert {:error, :unknown_sender, "alice.pending@example.com"} ==
               Messaging.resolve_inbound_club_email_sender(" Alice.Pending@Example.COM ")
    end
  end

  defp verify_all_email_addresses! do
    Repo.update_all(PersonEmailAddress, set: [verified_at: DateTime.utc_now(:microsecond)])
  end

  defp verify_email_address!(email) do
    Repo.update_all(
      from(email_address in PersonEmailAddress,
        where: email_address.normalized_email == ^String.downcase(email)
      ),
      set: [verified_at: DateTime.utc_now(:microsecond)]
    )
  end
end
