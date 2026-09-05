defmodule Memba.Messaging.SendClubMessageTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership.App, as: MembershipApp
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.AssignMemberRole
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging
  alias Memba.Messaging.EmailDeliveryProviders.Fake
  alias Memba.Messaging.EmailDeliveryProviders.Postmark
  alias Memba.Messaging.EmailDeliveryRequest
  alias Memba.Messaging.Events.ConversationAccessGrantedToGroup
  alias Memba.Messaging.Events.EmailDeliveryCreated
  alias Memba.Messaging.Events.MessageSent
  alias Memba.Messaging.Projections.EmailDelivery, as: EmailDeliveryProjection

  @email_delivery_replay_projectors [
    Memba.Messaging.Projectors.EmailDelivery
  ]

  setup do
    original_provider = Application.get_env(:memba, :messaging_email_delivery_provider)
    original_mailer_config = Application.get_env(:memba, Memba.Mailer)
    original_postmark_config = Application.get_env(:memba, Postmark)
    dispatcher_was_running? = stop_email_delivery_dispatcher()

    Fake.reset()

    on_exit(fn ->
      restore_env(:messaging_email_delivery_provider, original_provider)
      restore_env(Memba.Mailer, original_mailer_config)
      restore_env(Postmark, original_postmark_config)
      Fake.reset()
      restart_email_delivery_dispatcher(dispatcher_was_running?)
    end)

    :ok
  end

  test "resolves active Everyone group members via Membership and records pending delivery work without provider handoff" do
    kootenay_club_id = Memba.ID.generate(:club)
    nelson_club_id = Memba.ID.generate(:club)
    create_club(kootenay_club_id, "Kootenay Mountaineering Club")
    create_club(nelson_club_id, "Nelson Cycling Club")
    everyone_group_id = SystemGroups.everyone_group_id(kootenay_club_id)

    alice = create_person(name: "Alice", email: "alice@example.com")
    bob = create_person(name: "Bob", email: "bob@example.com")
    carol = create_person(name: "Carol", email: "carol@example.com")
    dana = create_person(name: "Dana", email: "dana@example.com")
    pat = create_person(name: "Pat", email: "pat@example.com")

    add_member(kootenay_club_id, alice.person_id)
    add_member(kootenay_club_id, bob.person_id)
    add_member(kootenay_club_id, carol.person_id)
    insert_active_membership_projection_without_group(kootenay_club_id, dana.person_id)
    add_member(nelson_club_id, pat.person_id)

    message_id = Memba.ID.generate(:message)

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^message_id,
              aggregate_version: 5,
              events: [
                %MessageSent{
                  message_id: ^message_id,
                  club_id: ^kootenay_club_id,
                  sender_id: sender_id,
                  subject: "Trip planning night",
                  body: "Bring route ideas."
                },
                %ConversationAccessGrantedToGroup{
                  conversation_id: ^message_id,
                  club_id: ^kootenay_club_id,
                  group_id: ^everyone_group_id,
                  access_level: "write"
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
    refute dana.person_id in Enum.map(delivery_events, & &1.recipient_id)
    refute pat.person_id in Enum.map(delivery_events, & &1.recipient_id)

    delivery_ids = Enum.map(delivery_events, & &1.delivery_id)

    assert Enum.all?(delivery_ids, &Memba.ID.valid?(:delivery, &1))
    assert Enum.uniq(delivery_ids) == delivery_ids

    assert Fake.deliveries() == []

    assert [
             %EmailDeliveryProjection{
               message_id: ^message_id,
               delivery_id: alice_delivery_id,
               recipient_id: ^alice_id,
               recipient_name: "Alice",
               recipient_address: "alice@example.com",
               channel: "email",
               status: "pending"
             },
             %EmailDeliveryProjection{
               message_id: ^message_id,
               delivery_id: bob_delivery_id,
               recipient_id: ^bob_id,
               recipient_name: "Bob",
               recipient_address: "bob@example.com",
               channel: "email",
               status: "pending"
             },
             %EmailDeliveryProjection{
               message_id: ^message_id,
               delivery_id: carol_delivery_id,
               recipient_id: ^carol_id,
               recipient_name: "Carol",
               recipient_address: "carol@example.com",
               channel: "email",
               status: "pending"
             }
           ] =
             pending_deliveries_for_message(message_id)

    assert [alice_delivery_id, bob_delivery_id, carol_delivery_id] == delivery_ids
  end

  test "resolves recipients from the selected audience group and grants it write access" do
    club_id = Memba.ID.generate(:club)
    create_club(club_id, "Kootenay Mountaineering Club")
    admin_group_id = SystemGroups.admin_group_id(club_id)

    alice = create_person(name: "Alice Admin", email: "alice@example.com")
    bob = create_person(name: "Bob Admin", email: "bob@example.com")
    carol = create_person(name: "Carol Member", email: "carol@example.com")

    alice_membership_id = add_member(club_id, alice.person_id)
    bob_membership_id = add_member(club_id, bob.person_id)
    add_member(club_id, carol.person_id)

    assign_admin_role(club_id, alice_membership_id, alice.person_id)
    assign_admin_role(club_id, bob_membership_id, bob.person_id)

    message_id = Memba.ID.generate(:message)

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^message_id,
              aggregate_version: 4,
              events: [
                %MessageSent{message_id: ^message_id},
                %ConversationAccessGrantedToGroup{
                  conversation_id: ^message_id,
                  club_id: ^club_id,
                  group_id: ^admin_group_id,
                  access_level: "write"
                }
                | delivery_events
              ]
            }} =
             Messaging.send_club_message(
               %{
                 message_id: message_id,
                 club_id: club_id,
                 sender_id: alice.person_id,
                 audience_group_id: admin_group_id,
                 subject: "Private Admin topic",
                 body: "Please discuss this with the Admin group."
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert [
             %EmailDeliveryCreated{recipient_id: alice_id},
             %EmailDeliveryCreated{recipient_id: bob_id}
           ] = delivery_events

    assert [alice_id, bob_id] == [alice.person_id, bob.person_id]
    refute carol.person_id in Enum.map(delivery_events, & &1.recipient_id)
    assert Messaging.group_has_conversation_access?(message_id, admin_group_id, :write)
  end

  test "sends each active member once at the person's primary email address" do
    club_id = Memba.ID.generate(:club)
    create_club(club_id, "Kootenay Mountaineering Club")
    everyone_group_id = SystemGroups.everyone_group_id(club_id)

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

    message_id = Memba.ID.generate(:message)
    alice_id = alice.person_id
    bob_id = bob.person_id

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^message_id,
              aggregate_version: 4,
              events: [
                %MessageSent{
                  message_id: ^message_id,
                  club_id: ^club_id,
                  sender_id: ^alice_id,
                  subject: "Trip planning night",
                  body: "Bring route ideas."
                },
                %ConversationAccessGrantedToGroup{
                  conversation_id: ^message_id,
                  club_id: ^club_id,
                  group_id: ^everyone_group_id,
                  access_level: "write"
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
             %EmailDeliveryProjection{
               recipient_id: ^alice_id,
               recipient_name: "Alice",
               recipient_address: "alice@example.com",
               status: "pending"
             },
             %EmailDeliveryProjection{
               recipient_id: ^bob_id,
               recipient_name: "Bob",
               recipient_address: "bob@work.example",
               status: "pending"
             }
           ] = pending_deliveries_for_message(message_id)

    recipient_addresses =
      message_id
      |> pending_deliveries_for_message()
      |> Enum.map(& &1.recipient_address)

    refute "alice@work.example" in recipient_addresses
    refute "bob@example.com" in recipient_addresses
    assert Fake.deliveries() == []
  end

  test "accepts the message without building provider requests inline when club context is available" do
    club_id = Memba.ID.generate(:club)
    create_club(club_id, "Kootenay Mountaineering Club")

    alice = create_person(name: "Alice", email: "alice@example.com")
    add_member(club_id, alice.person_id)

    message_id = Memba.ID.generate(:message)

    assert {:ok, %ExecutionResult{}} =
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

    assert [%EmailDeliveryProjection{message_id: ^message_id, status: "pending"}] =
             pending_deliveries_for_message(message_id)

    assert Fake.deliveries() == []
  end

  test "does not call the provider when the send command is rejected" do
    club_id = Memba.ID.generate(:club)
    create_club(club_id, "Kootenay Mountaineering Club")
    alice = create_person(name: "Alice", email: "alice@example.com")
    add_member(club_id, alice.person_id)

    assert {:error, :invalid_subject} =
             Messaging.send_club_message(%{
               message_id: Memba.ID.generate(:message),
               club_id: club_id,
               sender_id: alice.person_id,
               subject: "  ",
               body: "Bring route ideas."
             })

    assert Fake.deliveries() == []
  end

  test "returns success after recording message work when the configured provider would fail" do
    Application.put_env(:memba, :messaging_email_delivery_provider, Postmark)

    Application.put_env(:memba, Memba.Mailer,
      adapter: Memba.TestSupport.FailingSwooshAdapter,
      api_key: "server-token",
      test_owner: self(),
      test_delivery_result: {:error, :timeout}
    )

    Application.put_env(:memba, Postmark, from: "messages@mail.memba.io")

    club_id = Memba.ID.generate(:club)
    alice = create_person(name: "Alice", email: "alice@example.com")
    add_member(club_id, alice.person_id)

    message_id = Memba.ID.generate(:message)

    assert :ok =
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

    refute_received {:failing_swoosh_adapter_deliver, %Swoosh.Email{}}
    assert Fake.deliveries() == []

    assert [%EmailDeliveryProjection{status: "pending"}] =
             pending_deliveries_for_message(message_id)
  end

  test "manual retry of a failed delivery does not append duplicate message or delivery events" do
    Application.put_env(:memba, :messaging_email_delivery_provider, Fake)

    club_id = Memba.ID.generate(:club)
    create_club(club_id, "Kootenay Mountaineering Club")

    alice = create_person(name: "Alice", email: "alice@example.com")
    add_member(club_id, alice.person_id)

    message_id = Memba.ID.generate(:message)

    assert :ok =
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

    assert [delivery] = pending_deliveries_for_message(message_id)
    assert count_events(MessageSent) == 1
    assert count_events(EmailDeliveryCreated) == 1

    failed_at =
      DateTime.utc_now() |> DateTime.add(-120, :second) |> DateTime.truncate(:microsecond)

    delivery
    |> Ecto.Changeset.change(
      status: "failed",
      attempt_count: 1,
      latest_error: "unavailable",
      latest_detail: ":unavailable",
      failed_at: failed_at
    )
    |> Repo.update!()

    assert {:ok,
            %EmailDeliveryProjection{
              delivery_id: delivery_id,
              status: "sent",
              attempt_count: 2
            }} = Messaging.retry_failed_email_delivery(delivery.delivery_id)

    assert delivery_id == delivery.delivery_id
    assert count_events(MessageSent) == 1
    assert count_events(EmailDeliveryCreated) == 1

    assert [%EmailDeliveryRequest{message_id: ^message_id, delivery_id: ^delivery_id}] =
             Fake.deliveries()
  end

  test "projector replay rebuilds pending delivery work without handing it to the provider" do
    Application.put_env(:memba, :messaging_email_delivery_provider, Fake)

    club_id = Memba.ID.generate(:club)
    create_club(club_id, "Kootenay Mountaineering Club")

    alice = create_person(name: "Alice", email: "alice@example.com")
    add_member(club_id, alice.person_id)

    message_id = Memba.ID.generate(:message)

    assert :ok =
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

    assert [%EmailDeliveryProjection{status: "pending"}] =
             pending_deliveries_for_message(message_id)

    assert Fake.deliveries() == []

    checkpoint = Memba.ProjectionBarrier.current_checkpoint()

    Memba.EventSourcedCase.rebuild_event_sourced_projections!()
    Memba.ProjectionBarrier.await!(@email_delivery_replay_projectors, checkpoint: checkpoint)

    assert [%EmailDeliveryProjection{status: "pending"}] =
             pending_deliveries_for_message(message_id)

    assert Fake.deliveries() == []
  end

  defp pending_deliveries_for_message(message_id) do
    EmailDeliveryProjection
    |> where([delivery], delivery.message_id == ^message_id)
    |> order_by([delivery], asc: delivery.recipient_name)
    |> Repo.all()
  end

  defp stop_email_delivery_dispatcher do
    case Supervisor.terminate_child(Memba.Supervisor, Memba.Messaging.EmailDeliveryDispatcher) do
      :ok -> true
      {:error, :not_found} -> false
    end
  end

  defp restart_email_delivery_dispatcher(false), do: :ok

  defp restart_email_delivery_dispatcher(true) do
    case Supervisor.restart_child(Memba.Supervisor, Memba.Messaging.EmailDeliveryDispatcher) do
      {:ok, _pid} -> :ok
      {:ok, _pid, _info} -> :ok
      {:error, :running} -> :ok
      {:error, :not_found} -> :ok
    end
  end

  defp create_club(club_id, name) do
    assert :ok =
             MembershipApp.dispatch(
               %CreateClub{
                 club_id: club_id,
                 name: name,
                 slug: membership_club_slug(name, club_id)
               },
               consistency: :strong
             )
  end

  defp create_person(attrs) do
    email = Keyword.fetch!(attrs, :email)
    email_addresses = Keyword.get(attrs, :email_addresses, [%{email: email, is_primary: true}])

    person = %{
      person_id: Memba.ID.generate(:person),
      name: Keyword.fetch!(attrs, :name),
      email: email,
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
    ensure_club(club_id)
    membership_id = Memba.ID.generate(:membership)

    assert :ok =
             MembershipApp.dispatch(
               %AddMember{
                 membership_id: membership_id,
                 club_id: club_id,
                 person_id: person_id
               },
               consistency: :strong
             )

    membership_id
  end

  defp assign_admin_role(club_id, membership_id, person_id) do
    assert :ok =
             MembershipApp.dispatch(
               %AssignMemberRole{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: Roles.membership_administrator_role_id(club_id)
               },
               consistency: :strong
             )
  end

  defp ensure_club(club_id) do
    if is_nil(Memba.Membership.get_club(club_id)) do
      create_club(club_id, "Kootenay Mountaineering Club")
    end
  end

  defp insert_active_membership_projection_without_group(club_id, person_id) do
    Repo.insert!(%MembershipProjection{
      membership_id: Memba.ID.generate(:membership),
      club_id: club_id,
      person_id: person_id,
      active: true
    })
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)

  defp count_events(event_module) when is_atom(event_module) do
    event_type = Atom.to_string(event_module)

    %{rows: [[count]]} =
      Repo.query!(
        ~S|SELECT count(*) FROM "event_store"."events" WHERE event_type = $1|,
        [event_type]
      )

    count
  end
end
