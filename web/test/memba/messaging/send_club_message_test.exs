defmodule Memba.Messaging.SendClubMessageTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership.App, as: MembershipApp
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Messaging
  alias Memba.Messaging.EmailDeliveryProviders.Fake
  alias Memba.Messaging.EmailDeliveryProviders.Postmark
  alias Memba.Messaging.EmailDeliveryRequest
  alias Memba.Messaging.Events.MessageSent
  alias Memba.Messaging.Events.EmailDeliveryCreated

  setup do
    original_provider = Application.get_env(:memba, :messaging_email_delivery_provider)
    original_mailer_config = Application.get_env(:memba, Memba.Mailer)
    original_postmark_config = Application.get_env(:memba, Postmark)

    Fake.reset()

    on_exit(fn ->
      restore_env(:messaging_email_delivery_provider, original_provider)
      restore_env(Memba.Mailer, original_mailer_config)
      restore_env(Postmark, original_postmark_config)
      Fake.reset()
    end)

    :ok
  end

  test "resolves active club members via Membership and dispatches SendMessage" do
    kootenay_club_id = Ecto.UUID.generate()
    nelson_club_id = Ecto.UUID.generate()

    alice = create_person(name: "Alice", email: "alice@example.com")
    bob = create_person(name: "Bob", email: "bob@example.com")
    carol = create_person(name: "Carol", email: "carol@example.com")
    pat = create_person(name: "Pat", email: "pat@example.com")

    add_member(kootenay_club_id, alice.person_id)
    add_member(kootenay_club_id, bob.person_id)
    add_member(kootenay_club_id, carol.person_id)
    add_member(nelson_club_id, pat.person_id)

    message_id = Ecto.UUID.generate()

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^message_id,
              aggregate_version: 4,
              events: [
                %MessageSent{
                  message_id: ^message_id,
                  club_id: ^kootenay_club_id,
                  sender_id: sender_id,
                  subject: "Trip planning night",
                  body: "Bring route ideas."
                }
                | delivery_events
              ]
            }} =
             Messaging.send_club_message(
               %{
                 message_id: message_id,
                 club_id: kootenay_club_id,
                 sender_id: alice.person_id,
                 subject: "Trip planning night",
                 body: "Bring route ideas."
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert sender_id == alice.person_id

    assert [
             %EmailDeliveryCreated{
               message_id: ^message_id,
               recipient_id: alice_id,
               recipient_name: "Alice",
               recipient_email: "alice@example.com"
             },
             %EmailDeliveryCreated{
               message_id: ^message_id,
               recipient_id: bob_id,
               recipient_name: "Bob",
               recipient_email: "bob@example.com"
             },
             %EmailDeliveryCreated{
               message_id: ^message_id,
               recipient_id: carol_id,
               recipient_name: "Carol",
               recipient_email: "carol@example.com"
             }
           ] = delivery_events

    assert [alice_id, bob_id, carol_id] == [alice.person_id, bob.person_id, carol.person_id]
    refute pat.person_id in Enum.map(delivery_events, & &1.recipient_id)

    delivery_ids = Enum.map(delivery_events, & &1.delivery_id)

    assert Enum.all?(delivery_ids, &(Ecto.UUID.cast(&1) != :error))
    assert Enum.uniq(delivery_ids) == delivery_ids

    assert [
             %EmailDeliveryRequest{
               message_id: ^message_id,
               club_id: ^kootenay_club_id,
               delivery_id: alice_delivery_id,
               recipient_id: ^alice_id,
               recipient_name: "Alice",
               recipient_address: "alice@example.com",
               channel: :email,
               subject: "Trip planning night",
               body: "Bring route ideas."
             },
             %EmailDeliveryRequest{
               message_id: ^message_id,
               club_id: ^kootenay_club_id,
               delivery_id: bob_delivery_id,
               recipient_id: ^bob_id,
               recipient_name: "Bob",
               recipient_address: "bob@example.com",
               channel: :email,
               subject: "Trip planning night",
               body: "Bring route ideas."
             },
             %EmailDeliveryRequest{
               message_id: ^message_id,
               club_id: ^kootenay_club_id,
               delivery_id: carol_delivery_id,
               recipient_id: ^carol_id,
               recipient_name: "Carol",
               recipient_address: "carol@example.com",
               channel: :email,
               subject: "Trip planning night",
               body: "Bring route ideas."
             }
           ] = Fake.deliveries()

    assert [alice_delivery_id, bob_delivery_id, carol_delivery_id] == delivery_ids
  end

  test "sends each active member once at the person's primary email address" do
    club_id = Ecto.UUID.generate()

    alice =
      create_person(
        name: "Alice",
        email: "alice@example.com",
        email_addresses: [
          %{email: "alice@example.com", is_primary: true},
          %{email: "alice@work.example", is_primary: false}
        ]
      )

    bob =
      create_person(
        name: "Bob",
        email: "bob@work.example",
        email_addresses: [
          %{email: "bob@example.com", is_primary: false},
          %{email: "bob@work.example", is_primary: true}
        ]
      )

    add_member(club_id, alice.person_id)
    add_member(club_id, bob.person_id)

    message_id = Ecto.UUID.generate()
    alice_id = alice.person_id
    bob_id = bob.person_id

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^message_id,
              aggregate_version: 3,
              events: [
                %MessageSent{
                  message_id: ^message_id,
                  club_id: ^club_id,
                  sender_id: ^alice_id,
                  subject: "Trip planning night",
                  body: "Bring route ideas."
                },
                %EmailDeliveryCreated{
                  message_id: ^message_id,
                  recipient_id: ^alice_id,
                  recipient_name: "Alice",
                  recipient_email: "alice@example.com"
                },
                %EmailDeliveryCreated{
                  message_id: ^message_id,
                  recipient_id: ^bob_id,
                  recipient_name: "Bob",
                  recipient_email: "bob@work.example"
                }
              ]
            }} =
             Messaging.send_club_message(
               %{
                 message_id: message_id,
                 club_id: club_id,
                 sender_id: alice.person_id,
                 subject: "Trip planning night",
                 body: "Bring route ideas."
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert [
             %EmailDeliveryRequest{
               recipient_id: ^alice_id,
               recipient_name: "Alice",
               recipient_address: "alice@example.com"
             },
             %EmailDeliveryRequest{
               recipient_id: ^bob_id,
               recipient_name: "Bob",
               recipient_address: "bob@work.example"
             }
           ] = Fake.deliveries()

    delivered_addresses =
      Fake.deliveries()
      |> Enum.map(& &1.recipient_address)

    refute "alice@work.example" in delivered_addresses
    refute "bob@example.com" in delivered_addresses
  end

  test "does not call the provider when the send command is rejected" do
    club_id = Ecto.UUID.generate()
    alice = create_person(name: "Alice", email: "alice@example.com")
    add_member(club_id, alice.person_id)

    assert {:error, :invalid_subject} =
             Messaging.send_club_message(%{
               message_id: Ecto.UUID.generate(),
               club_id: club_id,
               sender_id: alice.person_id,
               subject: "  ",
               body: "Bring route ideas."
             })

    assert Fake.deliveries() == []
  end

  test "surfaces Postmark handoff failures without treating them as recipient outcomes" do
    Application.put_env(:memba, :messaging_email_delivery_provider, Postmark)

    Application.put_env(:memba, Memba.Mailer,
      adapter: Memba.TestSupport.FailingSwooshAdapter,
      api_key: "server-token",
      test_owner: self(),
      test_delivery_result: {:error, :timeout}
    )

    Application.put_env(:memba, Postmark, from: "messages@mail.memba.io")

    club_id = Ecto.UUID.generate()
    alice = create_person(name: "Alice", email: "alice@example.com")
    add_member(club_id, alice.person_id)

    message_id = Ecto.UUID.generate()

    assert {:error, {:postmark_delivery_error, :timeout}} =
             Messaging.send_club_message(
               %{
                 message_id: message_id,
                 club_id: club_id,
                 sender_id: alice.person_id,
                 subject: "Trip planning night",
                 body: "Bring route ideas."
               },
               consistency: :strong
             )

    assert_received {:failing_swoosh_adapter_deliver, %Swoosh.Email{}}
    assert Fake.deliveries() == []

    assert Messaging.get_member_email_delivery(message_id, alice.person_id).status == "sent"
    assert Messaging.get_memba_staff_email_delivery(message_id, alice.person_id).status == "sent"
  end

  defp create_person(attrs) do
    email_addresses = Keyword.get(attrs, :email_addresses)

    person = %{
      person_id: Ecto.UUID.generate(),
      name: Keyword.fetch!(attrs, :name),
      email: Keyword.fetch!(attrs, :email),
      email_addresses: email_addresses
    }

    assert :ok =
             MembershipApp.dispatch(
               struct!(
                 CreatePerson,
                 %{
                   person_id: person.person_id,
                   name: person.name,
                   email: person.email,
                   email_addresses: person.email_addresses
                 }
                 |> Enum.reject(fn {_key, value} -> is_nil(value) end)
                 |> Map.new()
               ),
               consistency: :strong
             )

    person
  end

  defp add_member(club_id, person_id) do
    assert :ok =
             MembershipApp.dispatch(
               %AddMember{
                 membership_id: Ecto.UUID.generate(),
                 club_id: club_id,
                 person_id: person_id
               },
               consistency: :strong
             )
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
