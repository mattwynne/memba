defmodule Memba.Messaging.InboundClubMessageAcceptanceTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership
  alias Memba.Membership.App, as: MembershipApp
  alias Memba.Membership.Commands.AssignMemberRole
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging
  alias Memba.Messaging.EmailDeliveryDispatcher
  alias Memba.Messaging.EmailDeliveryProviders.Fake
  alias Memba.Messaging.EmailDeliveryProviders.Postmark
  alias Memba.Messaging.EmailDeliveryProviders.Resend
  alias Memba.Messaging.EmailDeliveryRequest
  alias Memba.Messaging.Events.ConversationAccessGrantedToGroup
  alias Memba.Messaging.Events.EmailDeliveryCreated
  alias Memba.Messaging.Events.InboundClubEmailAccepted
  alias Memba.Messaging.Events.InboundClubEmailRejected
  alias Memba.Messaging.Events.MessageSent
  alias Memba.Messaging.Projectors.EmailDelivery, as: EmailDeliveryProjector
  alias Memba.Messaging.Projections.InboundEmailSource, as: InboundEmailSourceProjection
  alias Memba.Membership.Projections.Membership, as: MembershipProjection

  setup do
    original_provider = Application.get_env(:memba, :messaging_email_delivery_provider)
    original_mailer_config = Application.get_env(:memba, Memba.Mailer)
    original_postmark_config = Application.get_env(:memba, Postmark)
    original_resend_config = Application.get_env(:memba, Resend)

    Application.put_env(:memba, :messaging_email_delivery_provider, Fake)
    Application.put_env(:memba, Memba.Mailer, adapter: Swoosh.Adapters.Test)

    Application.put_env(:memba, Postmark,
      from: {"Memba", "messages@mail.memba.test"},
      reply_to: {"Memba support", "support@memba.test"}
    )

    Fake.reset()

    on_exit(fn ->
      restore_env(:messaging_email_delivery_provider, original_provider)
      restore_env(Memba.Mailer, original_mailer_config)
      restore_env(Postmark, original_postmark_config)
      restore_env(Resend, original_resend_config)
      Fake.reset()
    end)

    :ok
  end

  test "accepted inbound email posts through the same club message and delivery flow as web compose" do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    npc = create_club!(name: "Nelson Paddling Club", slug: "npc")

    alice = create_person!(name: "Alice Example", email: "alice@example.com")
    bob = create_person!(name: "Bob Example", email: "bob@example.com")
    dana = create_person!(name: "Dana Example", email: "dana@example.com")
    pat = create_person!(name: "Pat Example", email: "pat@example.com")

    add_member!(kmc.club_id, alice.person_id)
    add_member!(kmc.club_id, bob.person_id)
    insert_active_membership_projection_without_group(kmc.club_id, dana.person_id)
    add_member!(npc.club_id, pat.person_id)
    everyone_group_id = SystemGroups.everyone_group_id(kmc.club_id)

    assert {:ok,
            %{
              inbound_email_id: _inbound_email_id,
              message_id: message_id,
              club_id: kmc_id,
              sender_id: alice_id,
              from_address: "alice@example.com",
              to_address: "everyone@kmc.clubs.memba.io"
            }} =
             Messaging.receive_inbound_club_email(
               %{
                 provider: "resend",
                 provider_message_id: "task-011-email",
                 provider_event_id: "task-011-event",
                 from_address: "alice@example.com",
                 recipient_addresses: ["everyone@kmc.clubs.memba.io"],
                 subject: "Trip planning night",
                 text_body: "Bring route ideas."
               },
               consistency: :strong
             )

    assert kmc_id == kmc.club_id
    assert alice_id == alice.person_id
    assert Messaging.group_has_conversation_access?(message_id, everyone_group_id, :write)
    assert Messaging.group_has_conversation_access?(message_id, everyone_group_id, :read)

    assert %{
             message_id: ^message_id,
             club_id: ^kmc_id,
             sender_id: ^alice_id,
             subject: "Trip planning night",
             body: "Bring route ideas."
           } = Messaging.get_message(message_id)

    assert [
             %{
               delivery_id: alice_delivery_id,
               message_id: ^message_id,
               recipient_id: ^alice_id,
               recipient_name: "Alice Example",
               recipient_address: "alice@example.com",
               channel: "email",
               status: "pending",
               attempt_count: 0,
               latest_error: nil,
               latest_detail: nil,
               last_dispatch_attempted_at: nil,
               sent_at: nil,
               failed_at: nil
             },
             %{
               delivery_id: bob_delivery_id,
               message_id: ^message_id,
               recipient_id: bob_id,
               recipient_name: "Bob Example",
               recipient_address: "bob@example.com",
               channel: "email",
               status: "pending",
               attempt_count: 0,
               latest_error: nil,
               latest_detail: nil,
               last_dispatch_attempted_at: nil,
               sent_at: nil,
               failed_at: nil
             }
           ] = Messaging.list_recipient_deliveries(message_id)

    assert bob_id == bob.person_id
    assert Fake.deliveries() == []

    assert [
             %{delivery_id: ^alice_delivery_id, status: "sent", sent_at: %DateTime{}},
             %{delivery_id: ^bob_delivery_id, status: "sent", sent_at: %DateTime{}}
           ] = EmailDeliveryDispatcher.dispatch_pending_email_deliveries()

    assert [
             %EmailDeliveryRequest{
               message_id: ^message_id,
               club_id: ^kmc_id,
               recipient_id: ^alice_id,
               recipient_name: "Alice Example",
               recipient_address: "alice@example.com",
               sender_name: "Alice Example",
               sender_address: "alice@example.com",
               channel: :email,
               subject: "Trip planning night",
               body: "Bring route ideas."
             },
             %EmailDeliveryRequest{
               message_id: ^message_id,
               club_id: ^kmc_id,
               recipient_id: ^bob_id,
               recipient_name: "Bob Example",
               recipient_address: "bob@example.com",
               sender_name: "Alice Example",
               sender_address: "alice@example.com",
               channel: :email,
               subject: "Trip planning night",
               body: "Bring route ideas."
             }
           ] = Fake.deliveries()

    delivered_recipient_ids = Enum.map(Fake.deliveries(), & &1.recipient_id)
    refute dana.person_id in delivered_recipient_ids
    refute pat.person_id in delivered_recipient_ids

    assert 1 == count_events(ConversationAccessGrantedToGroup)

    assert %InboundEmailSourceProjection{
             inbound_email_id: _inbound_email_id,
             provider: "resend",
             provider_message_id: "task-011-email",
             provider_event_id: "task-011-event",
             from_address: "alice@example.com",
             to_address: "everyone@kmc.clubs.memba.io",
             status: "accepted",
             club_id: ^kmc_id,
             sender_id: ^alice_id,
             message_id: ^message_id,
             rejection_reason: nil,
             rejection_email_delivery_reference: nil
           } = Messaging.get_inbound_email_source("resend", "task-011-email")
  end

  test "authorization accepts an active club member outside the addressed group" do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    dana = create_person!(name: "Dana Example", email: "dana@example.com")

    insert_active_membership_projection_without_group(kmc.club_id, dana.person_id)

    assert {:ok, destination} =
             Messaging.resolve_inbound_club_email_destination([
               "everyone@kmc.clubs.memba.io"
             ])

    assert {:ok, sender} = Messaging.resolve_inbound_club_email_sender("dana@example.com")
    refute Membership.active_member_of_group?(destination.group_id, sender.person_id)
    assert :ok = Messaging.authorize_inbound_club_email_sender(sender, destination)
  end

  test "an inbound root message carries the resolved Admin audience group into SendMessage" do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    alice = create_person!(name: "Alice Example", email: "alice@example.com")
    membership_id = add_member!(kmc.club_id, alice.person_id)
    assign_admin_role!(kmc.club_id, membership_id, alice.person_id)
    admin_group_id = SystemGroups.admin_group_id(kmc.club_id)
    everyone_group_id = SystemGroups.everyone_group_id(kmc.club_id)

    assert {:ok, %{message_id: message_id}} =
             Messaging.receive_inbound_club_email(
               %{
                 provider: "resend",
                 provider_message_id: "task-057-admin-audience",
                 provider_event_id: "task-057-admin-audience-event",
                 from_address: "alice@example.com",
                 recipient_addresses: ["admin@kmc.clubs.memba.io"],
                 subject: "Private Admin topic",
                 text_body: "Please discuss this with the Admin group."
               },
               consistency: :strong
             )

    assert Messaging.group_has_conversation_access?(message_id, admin_group_id, :write)
    refute Messaging.group_has_conversation_access?(message_id, everyone_group_id, :read)
  end

  test "recognized same-club reply headers post inbound email into the existing conversation" do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")

    alice = create_person!(name: "Alice Example", email: "alice@example.com")
    bob = create_person!(name: "Bob Example", email: "bob@example.com")
    carol = create_person!(name: "Carol Example", email: "carol@example.com")

    add_member!(kmc.club_id, alice.person_id)
    add_member!(kmc.club_id, bob.person_id)
    add_member!(kmc.club_id, carol.person_id)

    root_message_id =
      send_club_message!(
        club_id: kmc.club_id,
        sender_id: alice.person_id,
        subject: "Trip planning night",
        body: "Bring route ideas."
      )

    follow_conversation!(kmc.club_id, root_message_id, carol.person_id)

    bob_outbound_message_id = outbound_message_id_for_recipient!(root_message_id, bob.person_id)

    assert {:ok,
            %{
              inbound_email_id: _inbound_email_id,
              message_id: reply_message_id,
              club_id: kmc_id,
              sender_id: bob_id,
              from_address: "bob@example.com",
              to_address: "everyone@kmc.clubs.memba.io"
            }} =
             Messaging.receive_inbound_club_email(
               %{
                 provider: "resend",
                 provider_message_id: "task-041-reply-header-match",
                 provider_event_id: "task-041-reply-header-match-event",
                 from_address: "bob@example.com",
                 recipient_addresses: ["everyone@kmc.clubs.memba.io"],
                 subject: "Re: Trip planning night",
                 text_body: """
                 I can bring maps.

                 On Tue, Alice Example wrote:
                 > Bring route ideas.
                 """,
                 in_reply_to_message_ids: [bob_outbound_message_id]
               },
               consistency: :strong
             )

    assert kmc_id == kmc.club_id
    assert bob_id == bob.person_id
    refute reply_message_id == root_message_id

    assert %{
             message_id: ^reply_message_id,
             club_id: ^kmc_id,
             sender_id: ^bob_id,
             conversation_id: ^root_message_id,
             reply_to_message_id: ^root_message_id,
             subject: "Trip planning night",
             body: "I can bring maps."
           } = Messaging.get_message(reply_message_id)

    assert [
             %{
               message_id: ^reply_message_id,
               recipient_id: alice_id,
               recipient_name: "Alice Example",
               recipient_address: "alice@example.com",
               status: "pending"
             },
             %{
               message_id: ^reply_message_id,
               recipient_id: carol_id,
               recipient_name: "Carol Example",
               recipient_address: "carol@example.com",
               status: "pending"
             }
           ] = Messaging.list_recipient_deliveries(reply_message_id)

    assert alice_id == alice.person_id
    assert carol_id == carol.person_id
    assert Messaging.following_conversation?(root_message_id, bob.person_id)
    assert Fake.deliveries() == []

    assert %InboundEmailSourceProjection{
             provider: "resend",
             provider_message_id: "task-041-reply-header-match",
             provider_event_id: "task-041-reply-header-match-event",
             from_address: "bob@example.com",
             to_address: "everyone@kmc.clubs.memba.io",
             status: "accepted",
             club_id: ^kmc_id,
             sender_id: ^bob_id,
             message_id: ^reply_message_id,
             rejection_reason: nil,
             rejection_email_delivery_reference: nil
           } = Messaging.get_inbound_email_source("resend", "task-041-reply-header-match")
  end

  test "unrecognized reply headers still create a new club-wide inbound message" do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")

    alice = create_person!(name: "Alice Example", email: "alice@example.com")
    bob = create_person!(name: "Bob Example", email: "bob@example.com")

    add_member!(kmc.club_id, alice.person_id)
    add_member!(kmc.club_id, bob.person_id)

    root_message_id =
      send_club_message!(
        club_id: kmc.club_id,
        sender_id: alice.person_id,
        subject: "Trip planning night",
        body: "Bring route ideas."
      )

    assert {:ok,
            %{
              message_id: message_id,
              club_id: kmc_id,
              sender_id: bob_id,
              from_address: "bob@example.com",
              to_address: "everyone@kmc.clubs.memba.io"
            }} =
             Messaging.receive_inbound_club_email(
               %{
                 provider: "resend",
                 provider_message_id: "task-041-unknown-reply-header-fallback",
                 provider_event_id: "task-041-unknown-reply-header-fallback-event",
                 from_address: "bob@example.com",
                 recipient_addresses: ["everyone@kmc.clubs.memba.io"],
                 subject: "Re: Trip planning night",
                 text_body: "This should start a separate club-wide thread.",
                 in_reply_to_message_ids: ["<unknown-message@example.test>"],
                 references_message_ids: [
                   "<older-unknown-message@example.test>",
                   "<newer-unknown-message@example.test>"
                 ]
               },
               consistency: :strong
             )

    assert kmc_id == kmc.club_id
    assert bob_id == bob.person_id
    refute message_id == root_message_id

    assert %{
             message_id: ^message_id,
             club_id: ^kmc_id,
             sender_id: ^bob_id,
             conversation_id: ^message_id,
             reply_to_message_id: nil,
             subject: "Re: Trip planning night",
             body: "This should start a separate club-wide thread."
           } = Messaging.get_message(message_id)

    assert [
             %{message_id: ^root_message_id, conversation_id: ^root_message_id},
             %{message_id: ^message_id, conversation_id: ^message_id}
           ] = Messaging.list_messages_for_club(kmc.club_id)

    assert %InboundEmailSourceProjection{
             provider: "resend",
             provider_message_id: "task-041-unknown-reply-header-fallback",
             status: "accepted",
             club_id: ^kmc_id,
             sender_id: ^bob_id,
             message_id: ^message_id,
             rejection_reason: nil
           } =
             Messaging.get_inbound_email_source(
               "resend",
               "task-041-unknown-reply-header-fallback"
             )
  end

  test "different-club reply headers do not create cross-club replies" do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    npc = create_club!(name: "Nelson Paddling Club", slug: "npc")

    alice = create_person!(name: "Alice Example", email: "alice@example.com")
    bob = create_person!(name: "Bob Example", email: "bob@example.com")

    add_member!(kmc.club_id, alice.person_id)
    add_member!(kmc.club_id, bob.person_id)
    add_member!(npc.club_id, alice.person_id)

    npc_root_message_id =
      send_club_message!(
        club_id: npc.club_id,
        sender_id: alice.person_id,
        subject: "Paddle planning",
        body: "Bring PFDs."
      )

    npc_outbound_message_id =
      outbound_message_id_for_recipient!(npc_root_message_id, alice.person_id)

    assert {:ok, %{message_id: kmc_message_id, club_id: kmc_id, sender_id: alice_id}} =
             Messaging.receive_inbound_club_email(
               %{
                 provider: "resend",
                 provider_message_id: "task-041-other-club-reply-header-fallback",
                 provider_event_id: "task-041-other-club-reply-header-fallback-event",
                 from_address: "alice@example.com",
                 recipient_addresses: ["everyone@kmc.clubs.memba.io"],
                 subject: "Re: Paddle planning",
                 text_body: "This belongs to KMC, not the paddling club.",
                 in_reply_to_message_ids: [npc_outbound_message_id]
               },
               consistency: :strong
             )

    assert kmc_id == kmc.club_id
    assert alice_id == alice.person_id

    assert %{
             message_id: ^kmc_message_id,
             club_id: ^kmc_id,
             conversation_id: ^kmc_message_id,
             reply_to_message_id: nil,
             subject: "Re: Paddle planning",
             body: "This belongs to KMC, not the paddling club."
           } = Messaging.get_message(kmc_message_id)

    assert [%{message_id: ^npc_root_message_id, conversation_id: ^npc_root_message_id}] =
             Messaging.list_conversation_messages(npc_root_message_id)

    assert [%{message_id: ^npc_root_message_id}] = Messaging.list_messages_for_club(npc.club_id)

    assert [
             %{
               message_id: ^kmc_message_id,
               recipient_id: ^alice_id,
               status: "pending"
             },
             %{
               message_id: ^kmc_message_id,
               recipient_id: bob_id,
               status: "pending"
             }
           ] = Messaging.list_recipient_deliveries(kmc_message_id)

    assert bob_id == bob.person_id
  end

  test "recognized reply headers do not bypass current-member authorization" do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    npc = create_club!(name: "Nelson Paddling Club", slug: "npc")

    alice = create_person!(name: "Alice Example", email: "alice@example.com")
    bob = create_person!(name: "Bob Example", email: "bob@example.com")
    pat = create_person!(name: "Pat Example", email: "pat@example.com")

    add_member!(kmc.club_id, alice.person_id)
    add_member!(kmc.club_id, bob.person_id)
    add_member!(npc.club_id, pat.person_id)

    root_message_id =
      send_club_message!(
        club_id: kmc.club_id,
        sender_id: alice.person_id,
        subject: "Trip planning night",
        body: "Bring route ideas."
      )

    bob_outbound_message_id = outbound_message_id_for_recipient!(root_message_id, bob.person_id)

    assert {:ok,
            %{
              status: :rejected,
              rejection_reason: "sender_not_active_member",
              from_address: "pat@example.com",
              to_address: "everyone@kmc.clubs.memba.io"
            }} =
             Messaging.receive_inbound_club_email(
               %{
                 provider: "resend",
                 provider_message_id: "task-041-reply-header-non-member",
                 provider_event_id: "task-041-reply-header-non-member-event",
                 from_address: "pat@example.com",
                 recipient_addresses: ["everyone@kmc.clubs.memba.io"],
                 subject: "Re: Trip planning night",
                 text_body: "I should not be able to reply to this conversation.",
                 in_reply_to_message_ids: [bob_outbound_message_id]
               },
               consistency: :strong
             )

    assert [%{message_id: ^root_message_id, conversation_id: ^root_message_id}] =
             Messaging.list_conversation_messages(root_message_id)

    assert [%{message_id: ^root_message_id}] = Messaging.list_messages_for_club(kmc.club_id)
    assert [] = Fake.deliveries()
    assert 1 == count_events(MessageSent)
    assert 0 == count_events(InboundClubEmailAccepted)
    assert 1 == count_events(InboundClubEmailRejected)

    assert %InboundEmailSourceProjection{
             status: "rejected",
             message_id: nil,
             rejection_reason: "sender_not_active_member",
             rejection_email_delivery_reference: rejection_email_delivery_reference
           } = Messaging.get_inbound_email_source("resend", "task-041-reply-header-non-member")

    assert is_binary(rejection_email_delivery_reference)

    assert_rejection_email_received(
      to: "pat@example.com",
      reason: "This email address isn't an active member of Kootenay Mountaineering Club"
    )
  end

  test "recognized reply headers do not bypass unsupported-attachment rejection" do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")

    alice = create_person!(name: "Alice Example", email: "alice@example.com")
    bob = create_person!(name: "Bob Example", email: "bob@example.com")

    add_member!(kmc.club_id, alice.person_id)
    add_member!(kmc.club_id, bob.person_id)

    root_message_id =
      send_club_message!(
        club_id: kmc.club_id,
        sender_id: alice.person_id,
        subject: "Trip planning night",
        body: "Bring route ideas."
      )

    bob_outbound_message_id = outbound_message_id_for_recipient!(root_message_id, bob.person_id)

    assert {:ok,
            %{
              status: :rejected,
              rejection_reason: "attachments_not_supported",
              from_address: "bob@example.com",
              to_address: "everyone@kmc.clubs.memba.io"
            }} =
             Messaging.receive_inbound_club_email(
               %{
                 provider: "resend",
                 provider_message_id: "task-041-reply-header-attachment",
                 provider_event_id: "task-041-reply-header-attachment-event",
                 from_address: "bob@example.com",
                 recipient_addresses: ["everyone@kmc.clubs.memba.io"],
                 subject: "Re: Trip planning night",
                 text_body: "The GPX is attached.",
                 in_reply_to_message_ids: [bob_outbound_message_id],
                 attachments: [
                   %{
                     filename: "route.gpx",
                     content_type: "application/gpx+xml",
                     size: 1234
                   }
                 ]
               },
               consistency: :strong
             )

    assert [%{message_id: ^root_message_id, conversation_id: ^root_message_id}] =
             Messaging.list_conversation_messages(root_message_id)

    assert [%{message_id: ^root_message_id}] = Messaging.list_messages_for_club(kmc.club_id)
    assert [] = Fake.deliveries()
    assert 1 == count_events(MessageSent)
    assert 0 == count_events(InboundClubEmailAccepted)
    assert 1 == count_events(InboundClubEmailRejected)

    assert %InboundEmailSourceProjection{
             status: "rejected",
             message_id: nil,
             rejection_reason: "attachments_not_supported",
             rejection_email_delivery_reference: rejection_email_delivery_reference
           } = Messaging.get_inbound_email_source("resend", "task-041-reply-header-attachment")

    assert is_binary(rejection_email_delivery_reference)

    assert_rejection_email_received(
      to: "bob@example.com",
      reason: "Emails with attachments can't be posted yet"
    )
  end

  test "accepted inbound email is dispatched by the read-model-change dispatcher nudge" do
    name = :"#{__MODULE__}.inbound_dispatch_nudge"

    start_supervised!(
      {EmailDeliveryDispatcher, name: name, dispatch_enabled: true, dispatch_observer: self()}
    )

    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    alice = create_person!(name: "Alice Example", email: "alice@example.com")

    add_member!(kmc.club_id, alice.person_id)

    assert {:ok, %{message_id: message_id, club_id: kmc_id, sender_id: alice_id}} =
             Messaging.receive_inbound_club_email(
               %{
                 provider: "resend",
                 provider_message_id: "task-011-async-dispatch",
                 provider_event_id: "task-011-async-dispatch-event",
                 from_address: "alice@example.com",
                 recipient_addresses: ["everyone@kmc.clubs.memba.io"],
                 subject: "Dispatch me asynchronously",
                 text_body: "This should be handed off by the dispatcher nudge."
               },
               consistency: :strong
             )

    assert kmc_id == kmc.club_id
    assert alice_id == alice.person_id

    assert_receive {:email_delivery_dispatch_requested,
                    %{
                      source: :read_model_change,
                      projector: EmailDeliveryProjector,
                      source_event: %EmailDeliveryCreated{
                        message_id: ^message_id,
                        delivery_id: delivery_id
                      },
                      claimed_delivery_ids: [claimed_delivery_id]
                    }}

    assert claimed_delivery_id == delivery_id

    assert [
             %{
               delivery_id: ^delivery_id,
               recipient_id: ^alice_id,
               recipient_address: "alice@example.com",
               status: "sent",
               sent_at: %DateTime{}
             }
           ] = Messaging.list_recipient_deliveries(message_id)

    assert [
             %EmailDeliveryRequest{
               message_id: ^message_id,
               club_id: ^kmc_id,
               delivery_id: ^delivery_id,
               recipient_id: ^alice_id,
               recipient_address: "alice@example.com",
               sender_name: "Alice Example",
               sender_address: "alice@example.com",
               subject: "Dispatch me asynchronously",
               body: "This should be handed off by the dispatcher nudge."
             }
           ] = Fake.deliveries()
  end

  test "duplicate provider message ids return accepted without creating duplicate messages or outbound deliveries" do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")

    alice = create_person!(name: "Alice Example", email: "alice@example.com")
    bob = create_person!(name: "Bob Example", email: "bob@example.com")

    add_member!(kmc.club_id, alice.person_id)
    add_member!(kmc.club_id, bob.person_id)

    inbound_attrs = %{
      provider: "resend",
      provider_message_id: "task-012-duplicate-email",
      provider_event_id: "task-012-event-first",
      from_address: "alice@example.com",
      recipient_addresses: ["everyone@kmc.clubs.memba.io"],
      subject: "Trip planning night",
      text_body: "Bring route ideas."
    }

    assert {:ok, %{message_id: message_id}} =
             Messaging.receive_inbound_club_email(inbound_attrs, consistency: :strong)

    assert [%{status: "pending"}, %{status: "pending"}] =
             Messaging.list_recipient_deliveries(message_id)

    assert Fake.deliveries() == []

    assert [%{status: "sent"}, %{status: "sent"}] =
             EmailDeliveryDispatcher.dispatch_pending_email_deliveries()

    first_deliveries = Fake.deliveries()
    assert length(first_deliveries) == 2

    assert {:ok,
            %{
              inbound_email_id: _inbound_email_id,
              duplicate?: true,
              status: :accepted,
              message_id: ^message_id
            }} =
             inbound_attrs
             |> Map.merge(%{
               provider_event_id: "task-012-event-retry",
               subject: "Trip planning night retry",
               text_body: "This retry must not be posted."
             })
             |> Messaging.receive_inbound_club_email(consistency: :strong)

    assert [
             %{
               message_id: ^message_id,
               subject: "Trip planning night",
               body: "Bring route ideas."
             }
           ] =
             Messaging.list_messages_for_club(kmc.club_id)

    assert [] = EmailDeliveryDispatcher.dispatch_pending_email_deliveries()
    assert Fake.deliveries() == first_deliveries

    assert %InboundEmailSourceProjection{
             status: "accepted",
             provider_event_id: "task-012-event-first",
             message_id: ^message_id
           } = Messaging.get_inbound_email_source("resend", "task-012-duplicate-email")

    assert 1 == count_events(MessageSent)
    assert 1 == count_events(InboundClubEmailAccepted)
  end

  test "accepted inbound email uses normalized plain text and ignores HTML" do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    alice = create_person!(name: "Alice Example", email: "alice@example.com")

    add_member!(kmc.club_id, alice.person_id)

    assert {:ok, %{message_id: message_id}} =
             Messaging.receive_inbound_club_email(
               %{
                 provider: "resend",
                 provider_message_id: "task-013-normalized-body",
                 from_address: "alice@example.com",
                 recipient_addresses: ["everyone@kmc.clubs.memba.io"],
                 subject: "Trip planning night",
                 text_body: """
                 Bring route ideas.

                 Meet at 7.

                 -- 
                 Alice

                 On Tue, Bob wrote:
                 > Old message
                 """,
                 html_body: "<p>This HTML must not be converted or posted.</p>"
               },
               consistency: :strong
             )

    assert %{body: "Bring route ideas.\n\nMeet at 7."} = Messaging.get_message(message_id)

    assert [%{status: "pending"}] = Messaging.list_recipient_deliveries(message_id)
    assert Fake.deliveries() == []

    assert [%{status: "sent"}] = EmailDeliveryDispatcher.dispatch_pending_email_deliveries()

    assert [
             %EmailDeliveryRequest{
               body: "Bring route ideas.\n\nMeet at 7."
             }
           ] = Fake.deliveries()
  end

  test "accepted inbound email from an alternate sender address posts as the person" do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")

    alice =
      create_person!(
        name: "Alice Example",
        email: "alice@example.com",
        email_addresses: [
          %{email: "alice@example.com", is_primary: true},
          %{email: "Alice.Work@Example.COM", is_primary: false}
        ]
      )

    add_member!(kmc.club_id, alice.person_id)

    assert {:ok,
            %{
              message_id: message_id,
              club_id: kmc_id,
              sender_id: alice_id,
              from_address: "alice.work@example.com",
              to_address: "everyone@kmc.clubs.memba.io"
            }} =
             Messaging.receive_inbound_club_email(
               %{
                 provider: "resend",
                 provider_message_id: "task-020-alternate-sender",
                 provider_event_id: "task-020-alternate-sender-event",
                 from_address: " Alice.Work@Example.COM ",
                 recipient_addresses: ["everyone@kmc.clubs.memba.io"],
                 subject: "Alternate sender address",
                 text_body: "Posting from my work address."
               },
               consistency: :strong
             )

    assert kmc_id == kmc.club_id
    assert alice_id == alice.person_id

    assert %{
             message_id: ^message_id,
             club_id: ^kmc_id,
             sender_id: ^alice_id,
             subject: "Alternate sender address",
             body: "Posting from my work address."
           } = Messaging.get_message(message_id)

    assert [%{status: "pending"}] = Messaging.list_recipient_deliveries(message_id)
    assert Fake.deliveries() == []

    assert [%{status: "sent"}] = EmailDeliveryDispatcher.dispatch_pending_email_deliveries()

    assert [
             %EmailDeliveryRequest{
               message_id: ^message_id,
               club_id: ^kmc_id,
               recipient_id: ^alice_id,
               recipient_address: "alice@example.com",
               sender_name: "Alice Example",
               sender_address: "alice@example.com",
               subject: "Alternate sender address",
               body: "Posting from my work address."
             }
           ] = Fake.deliveries()

    assert %InboundEmailSourceProjection{
             status: "accepted",
             provider: "resend",
             provider_message_id: "task-020-alternate-sender",
             provider_event_id: "task-020-alternate-sender-event",
             from_address: "alice.work@example.com",
             to_address: "everyone@kmc.clubs.memba.io",
             club_id: ^kmc_id,
             sender_id: ^alice_id,
             message_id: ^message_id
           } = Messaging.get_inbound_email_source("resend", "task-020-alternate-sender")
  end

  test "inbound email from a pending known sender address is rejected" do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    alice = create_person!(name: "Alice Example", email: "alice@example.com")

    assert :ok =
             Membership.add_person_email_address(
               %{person_id: alice.person_id, email: "Alice.Pending@Example.COM"},
               consistency: :strong
             )

    add_member!(kmc.club_id, alice.person_id)

    assert {:ok,
            %{
              inbound_email_id: _inbound_email_id,
              status: :rejected,
              rejection_reason: "unknown_sender",
              from_address: "alice.pending@example.com",
              to_address: "everyone@kmc.clubs.memba.io",
              rejection_email_delivery_reference: rejection_email_delivery_reference
            }} =
             Messaging.receive_inbound_club_email(
               %{
                 provider: "resend",
                 provider_message_id: "task-053-pending-sender",
                 provider_event_id: "task-053-pending-sender-event",
                 from_address: " Alice.Pending@Example.COM ",
                 recipient_addresses: ["everyone@kmc.clubs.memba.io"],
                 subject: "Pending sender address",
                 text_body: "This should not post until verified."
               },
               consistency: :strong
             )

    assert is_binary(rejection_email_delivery_reference)

    assert %InboundEmailSourceProjection{
             status: "rejected",
             from_address: "alice.pending@example.com",
             to_address: "everyone@kmc.clubs.memba.io",
             message_id: nil,
             rejection_reason: "unknown_sender",
             rejection_email_delivery_reference: ^rejection_email_delivery_reference
           } = Messaging.get_inbound_email_source("resend", "task-053-pending-sender")

    assert_rejection_email_received(
      to: "alice.pending@example.com",
      reason: "We couldn't find a member account for this email address"
    )

    assert [] = Messaging.list_messages_for_club(kmc.club_id)
    assert [] = Fake.deliveries()
    assert 0 == count_events(MessageSent)
    assert 0 == count_events(InboundClubEmailAccepted)
    assert 1 == count_events(InboundClubEmailRejected)
  end

  test "inbound email without usable plain text is rejected without creating a club message" do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    alice = create_person!(name: "Alice Example", email: "alice@example.com")

    add_member!(kmc.club_id, alice.person_id)

    assert {:ok,
            %{
              inbound_email_id: _inbound_email_id,
              status: :rejected,
              rejection_reason: "plain_text_required",
              from_address: "alice@example.com",
              to_address: "everyone@kmc.clubs.memba.io"
            }} =
             Messaging.receive_inbound_club_email(
               %{
                 provider: "resend",
                 provider_message_id: "task-013-html-only",
                 from_address: "alice@example.com",
                 recipient_addresses: ["everyone@kmc.clubs.memba.io"],
                 subject: "Trip planning night",
                 text_body: "  \n> quoted prior content only\n",
                 html_body: "<p>This HTML must not be converted.</p>"
               },
               consistency: :strong
             )

    assert [] = Messaging.list_messages_for_club(kmc.club_id)
    assert [] = Fake.deliveries()
    assert 0 == count_events(MessageSent)
    assert 0 == count_events(InboundClubEmailAccepted)
    assert 1 == count_events(InboundClubEmailRejected)

    assert %InboundEmailSourceProjection{
             inbound_email_id: _inbound_email_id,
             provider: "resend",
             provider_message_id: "task-013-html-only",
             from_address: "alice@example.com",
             to_address: "everyone@kmc.clubs.memba.io",
             status: "rejected",
             message_id: nil,
             rejection_reason: "plain_text_required",
             rejection_email_delivery_reference: rejection_email_delivery_reference
           } = Messaging.get_inbound_email_source("resend", "task-013-html-only")

    assert is_binary(rejection_email_delivery_reference)

    assert_rejection_email_received(
      to: "alice@example.com",
      reason: "We couldn't read a plain-text message body"
    )
  end

  test "inbound email with blank plain text is rejected without creating a club message" do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    alice = create_person!(name: "Alice Example", email: "alice@example.com")

    add_member!(kmc.club_id, alice.person_id)

    assert {:ok,
            %{
              inbound_email_id: _inbound_email_id,
              status: :rejected,
              rejection_reason: "plain_text_required",
              from_address: "alice@example.com",
              to_address: "everyone@kmc.clubs.memba.io"
            }} =
             Messaging.receive_inbound_club_email(
               %{
                 provider: "resend",
                 provider_message_id: "task-020-blank-plain-text",
                 from_address: "alice@example.com",
                 recipient_addresses: ["everyone@kmc.clubs.memba.io"],
                 subject: "Trip planning night",
                 text_body: " \n\t "
               },
               consistency: :strong
             )

    assert [] = Messaging.list_messages_for_club(kmc.club_id)
    assert [] = Fake.deliveries()
    assert 0 == count_events(MessageSent)
    assert 0 == count_events(InboundClubEmailAccepted)
    assert 1 == count_events(InboundClubEmailRejected)

    assert %InboundEmailSourceProjection{
             status: "rejected",
             message_id: nil,
             rejection_reason: "plain_text_required",
             rejection_email_delivery_reference: rejection_email_delivery_reference
           } = Messaging.get_inbound_email_source("resend", "task-020-blank-plain-text")

    assert is_binary(rejection_email_delivery_reference)

    assert_rejection_email_received(
      to: "alice@example.com",
      reason: "We couldn't read a plain-text message body"
    )
  end

  test "HTML-only inbound email is rejected without converting HTML to text" do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    alice = create_person!(name: "Alice Example", email: "alice@example.com")

    add_member!(kmc.club_id, alice.person_id)

    assert {:ok,
            %{
              inbound_email_id: _inbound_email_id,
              status: :rejected,
              rejection_reason: "plain_text_required",
              from_address: "alice@example.com",
              to_address: "everyone@kmc.clubs.memba.io"
            }} =
             Messaging.receive_inbound_club_email(
               %{
                 provider: "resend",
                 provider_message_id: "task-020-html-only",
                 from_address: "alice@example.com",
                 recipient_addresses: ["everyone@kmc.clubs.memba.io"],
                 subject: "Trip planning night",
                 html_body: "<p>This HTML must not be converted to a posted message.</p>"
               },
               consistency: :strong
             )

    assert [] = Messaging.list_messages_for_club(kmc.club_id)
    assert [] = Fake.deliveries()
    assert 0 == count_events(MessageSent)
    assert 0 == count_events(InboundClubEmailAccepted)
    assert 1 == count_events(InboundClubEmailRejected)

    assert %InboundEmailSourceProjection{
             status: "rejected",
             message_id: nil,
             rejection_reason: "plain_text_required",
             rejection_email_delivery_reference: rejection_email_delivery_reference
           } = Messaging.get_inbound_email_source("resend", "task-020-html-only")

    assert is_binary(rejection_email_delivery_reference)

    assert_rejection_email_received(
      to: "alice@example.com",
      reason: "We couldn't read a plain-text message body"
    )
  end

  test "inbound email with attachments is rejected before creating a club message" do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    alice = create_person!(name: "Alice Example", email: "alice@example.com")

    add_member!(kmc.club_id, alice.person_id)

    assert {:ok,
            %{
              inbound_email_id: _inbound_email_id,
              status: :rejected,
              rejection_reason: "attachments_not_supported",
              from_address: "alice@example.com",
              to_address: "everyone@kmc.clubs.memba.io"
            }} =
             Messaging.receive_inbound_club_email(
               %{
                 provider: "resend",
                 provider_message_id: "task-014-attachments",
                 from_address: "alice@example.com",
                 recipient_addresses: ["everyone@kmc.clubs.memba.io"],
                 subject: "Trip planning night",
                 text_body: "Bring route ideas.",
                 attachments: [
                   %{
                     filename: "route.gpx",
                     content_type: "application/gpx+xml",
                     size: 1234
                   }
                 ]
               },
               consistency: :strong
             )

    assert [] = Messaging.list_messages_for_club(kmc.club_id)
    assert [] = Fake.deliveries()
    assert 0 == count_events(MessageSent)
    assert 0 == count_events(InboundClubEmailAccepted)
    assert 1 == count_events(InboundClubEmailRejected)

    assert %InboundEmailSourceProjection{
             inbound_email_id: _inbound_email_id,
             provider: "resend",
             provider_message_id: "task-014-attachments",
             from_address: "alice@example.com",
             to_address: "everyone@kmc.clubs.memba.io",
             status: "rejected",
             message_id: nil,
             rejection_reason: "attachments_not_supported",
             rejection_email_delivery_reference: rejection_email_delivery_reference
           } = Messaging.get_inbound_email_source("resend", "task-014-attachments")

    assert is_binary(rejection_email_delivery_reference)

    assert_rejection_email_received(
      to: "alice@example.com",
      reason: "Emails with attachments can't be posted yet"
    )
  end

  test "unknown sender is rejected and receives a concise rejection email" do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")

    assert {:ok,
            %{
              inbound_email_id: _inbound_email_id,
              status: :rejected,
              rejection_reason: "unknown_sender",
              from_address: "unknown@example.com",
              to_address: "everyone@kmc.clubs.memba.io"
            }} =
             Messaging.receive_inbound_club_email(
               %{
                 provider: "resend",
                 provider_message_id: "task-015-unknown-sender",
                 from_address: "unknown@example.com",
                 recipient_addresses: ["everyone@kmc.clubs.memba.io"],
                 subject: "Trip planning night",
                 text_body: "Bring route ideas.",
                 original_message_id: "<original-trip-planning@example.com>"
               },
               consistency: :strong
             )

    assert [] = Messaging.list_messages_for_club(kmc.club_id)
    assert [] = Fake.deliveries()
    assert 0 == count_events(MessageSent)
    assert 0 == count_events(InboundClubEmailAccepted)
    assert 1 == count_events(InboundClubEmailRejected)

    assert %InboundEmailSourceProjection{
             inbound_email_id: _inbound_email_id,
             provider: "resend",
             provider_message_id: "task-015-unknown-sender",
             from_address: "unknown@example.com",
             to_address: "everyone@kmc.clubs.memba.io",
             status: "rejected",
             message_id: nil,
             rejection_reason: "unknown_sender",
             rejection_email_delivery_reference: rejection_email_delivery_reference
           } = Messaging.get_inbound_email_source("resend", "task-015-unknown-sender")

    assert is_binary(rejection_email_delivery_reference)

    rejection_email =
      assert_rejection_email_received(
        to: "unknown@example.com",
        reason: "We couldn't find a member account for this email address",
        subject: "Re: Trip planning night",
        from: {"Kootenay Mountaineering Club via Memba", "messages@mail.memba.test"},
        support_copy: "Just reply to this email and a person will help."
      )

    assert rejection_email.text_body =~
             "Your email to Kootenay Mountaineering Club wasn't posted."

    assert rejection_email.text_body =~ "membership of Kootenay Mountaineering Club"

    assert rejection_email.text_body =~
             "Just reply to this email and a person will help."

    assert rejection_email.headers["In-Reply-To"] == "<original-trip-planning@example.com>"
    assert rejection_email.headers["References"] == "<original-trip-planning@example.com>"
  end

  test "rejection emails use Postmark mailer/provider configuration when Postmark is selected" do
    Application.put_env(:memba, :messaging_email_delivery_provider, Postmark)

    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")

    assert {:ok,
            %{
              inbound_email_id: inbound_email_id,
              status: :rejected,
              rejection_reason: "unknown_sender",
              from_address: "unknown@example.com",
              to_address: "everyone@kmc.clubs.memba.io"
            }} =
             Messaging.receive_inbound_club_email(
               %{
                 provider: "postmark",
                 provider_message_id: "task-020-postmark-selected-rejection",
                 from_address: "unknown@example.com",
                 recipient_addresses: ["everyone@kmc.clubs.memba.io"],
                 subject: "Trip planning night",
                 text_body: "Can I post through Postmark?"
               },
               consistency: :strong
             )

    assert [] = Messaging.list_messages_for_club(kmc.club_id)
    assert [] = Fake.deliveries()
    assert 0 == count_events(MessageSent)
    assert 0 == count_events(InboundClubEmailAccepted)
    assert 1 == count_events(InboundClubEmailRejected)

    assert %InboundEmailSourceProjection{
             status: "rejected",
             message_id: nil,
             rejection_reason: "unknown_sender",
             rejection_email_delivery_reference: rejection_email_delivery_reference
           } =
             Messaging.get_inbound_email_source(
               "postmark",
               "task-020-postmark-selected-rejection"
             )

    assert is_binary(rejection_email_delivery_reference)

    rejection_email =
      assert_rejection_email_received(
        to: "unknown@example.com",
        reason: "We couldn't find a member account for this email address"
      )

    assert rejection_email.provider_options[:metadata] == %{
             "memba_email_kind" => "inbound_club_rejection",
             "memba_inbound_id" => inbound_email_id,
             "memba_in_provider" => "postmark",
             "memba_in_msg_id" => "task-020-postmark-selected-rejection",
             "memba_in_to" => "everyone@kmc.clubs.memba.io",
             "memba_reject_reason" => "unknown_sender",
             "memba_reject_ref" => rejection_email_delivery_reference
           }
  end

  test "rejection emails use Resend-safe tag values when Resend is selected" do
    Application.put_env(:memba, :messaging_email_delivery_provider, Resend)

    Application.put_env(:memba, Resend,
      from: {"Memba", "messages@mail.memba.test"},
      reply_to: {"Memba support", "support@memba.test"}
    )

    _kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")

    assert {:ok,
            %{
              status: :rejected,
              rejection_reason: "unknown_sender",
              rejection_email_delivery_reference: rejection_email_delivery_reference
            }} =
             Messaging.receive_inbound_club_email(
               %{
                 provider: "resend",
                 provider_message_id: "1b700cb9-3a48-460d-a2d1-255fe01ed4e2",
                 from_address: "unknown@example.com",
                 recipient_addresses: ["everyone@kmc.clubs.memba.io"],
                 subject: "Trip planning night",
                 text_body: "Can I post through Resend?"
               },
               consistency: :strong
             )

    rejection_email =
      assert_rejection_email_received(
        to: "unknown@example.com",
        reason: "We couldn't find a member account for this email address",
        metadata?: false
      )

    assert rejection_email.provider_options[:tags] == [
             %{name: "memba_email_kind", value: "inbound_club_rejection"},
             %{
               name: "memba_inbound_provider_message_id",
               value: "1b700cb9-3a48-460d-a2d1-255fe01ed4e2"
             },
             %{name: "memba_rejection_reason", value: "unknown_sender"},
             %{
               name: "memba_rejection_delivery_reference",
               value: rejection_email_delivery_reference
             }
           ]

    assert Memba.ID.valid?(:inbound_email, rejection_email.headers["X-Memba-Inbound-Email-ID"])

    assert rejection_email.headers["X-Memba-Rejection-Delivery-Reference"] ==
             rejection_email_delivery_reference

    assert Enum.all?(rejection_email.provider_options[:tags], fn %{name: name, value: value} ->
             name =~ ~r/\A[A-Za-z0-9_-]+\z/ and value =~ ~r/\A[A-Za-z0-9_-]+\z/
           end)

    assert [] = Fake.deliveries()
  end

  test "known sender who is not a member of the destination club is rejected" do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    npc = create_club!(name: "Nelson Paddling Club", slug: "npc")
    pat = create_person!(name: "Pat Example", email: "pat@example.com")

    add_member!(npc.club_id, pat.person_id)

    assert {:ok,
            %{
              inbound_email_id: _inbound_email_id,
              status: :rejected,
              rejection_reason: "sender_not_active_member",
              from_address: "pat@example.com",
              to_address: "everyone@kmc.clubs.memba.io"
            }} =
             Messaging.receive_inbound_club_email(
               %{
                 provider: "resend",
                 provider_message_id: "task-020-non-member",
                 from_address: "pat@example.com",
                 recipient_addresses: ["everyone@kmc.clubs.memba.io"],
                 subject: "Trip planning night",
                 text_body: "Can I post to KMC?"
               },
               consistency: :strong
             )

    assert [] = Messaging.list_messages_for_club(kmc.club_id)
    assert [] = Messaging.list_messages_for_club(npc.club_id)
    assert [] = Fake.deliveries()
    assert 0 == count_events(MessageSent)
    assert 0 == count_events(InboundClubEmailAccepted)
    assert 1 == count_events(InboundClubEmailRejected)

    assert %InboundEmailSourceProjection{
             status: "rejected",
             message_id: nil,
             rejection_reason: "sender_not_active_member",
             rejection_email_delivery_reference: rejection_email_delivery_reference
           } = Messaging.get_inbound_email_source("resend", "task-020-non-member")

    assert is_binary(rejection_email_delivery_reference)

    assert_rejection_email_received(
      to: "pat@example.com",
      reason: "This email address isn't an active member of Kootenay Mountaineering Club"
    )
  end

  test "known sender with an inactive destination-club membership is rejected" do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    alice = create_person!(name: "Alice Example", email: "alice@example.com")

    insert_inactive_membership!(kmc.club_id, alice.person_id)

    assert {:ok,
            %{
              inbound_email_id: _inbound_email_id,
              status: :rejected,
              rejection_reason: "sender_not_active_member",
              from_address: "alice@example.com",
              to_address: "everyone@kmc.clubs.memba.io"
            }} =
             Messaging.receive_inbound_club_email(
               %{
                 provider: "resend",
                 provider_message_id: "task-020-inactive-member",
                 from_address: "alice@example.com",
                 recipient_addresses: ["everyone@kmc.clubs.memba.io"],
                 subject: "Trip planning night",
                 text_body: "Can I post while inactive?"
               },
               consistency: :strong
             )

    assert [] = Messaging.list_messages_for_club(kmc.club_id)
    assert [] = Fake.deliveries()
    assert 0 == count_events(MessageSent)
    assert 0 == count_events(InboundClubEmailAccepted)
    assert 1 == count_events(InboundClubEmailRejected)

    assert %InboundEmailSourceProjection{
             status: "rejected",
             message_id: nil,
             rejection_reason: "sender_not_active_member",
             rejection_email_delivery_reference: rejection_email_delivery_reference
           } = Messaging.get_inbound_email_source("resend", "task-020-inactive-member")

    assert is_binary(rejection_email_delivery_reference)

    assert_rejection_email_received(
      to: "alice@example.com",
      reason: "This email address isn't an active member of Kootenay Mountaineering Club"
    )
  end

  test "unknown club subdomain is rejected without creating a club message" do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    alice = create_person!(name: "Alice Example", email: "alice@example.com")

    add_member!(kmc.club_id, alice.person_id)

    assert {:ok,
            %{
              inbound_email_id: _inbound_email_id,
              status: :rejected,
              rejection_reason: "unknown_club_slug",
              from_address: "alice@example.com",
              to_address: "everyone@unknown.clubs.memba.io"
            }} =
             Messaging.receive_inbound_club_email(
               %{
                 provider: "resend",
                 provider_message_id: "task-020-unknown-club",
                 from_address: "alice@example.com",
                 recipient_addresses: ["everyone@unknown.clubs.memba.io"],
                 subject: "Trip planning night",
                 text_body: "Where did this go?"
               },
               consistency: :strong
             )

    assert [] = Messaging.list_messages_for_club(kmc.club_id)
    assert [] = Fake.deliveries()
    assert 0 == count_events(MessageSent)
    assert 0 == count_events(InboundClubEmailAccepted)
    assert 1 == count_events(InboundClubEmailRejected)

    assert %InboundEmailSourceProjection{
             status: "rejected",
             from_address: "alice@example.com",
             to_address: "everyone@unknown.clubs.memba.io",
             message_id: nil,
             rejection_reason: "unknown_club_slug",
             rejection_email_delivery_reference: rejection_email_delivery_reference
           } = Messaging.get_inbound_email_source("resend", "task-020-unknown-club")

    assert is_binary(rejection_email_delivery_reference)

    assert_rejection_email_received(
      to: "alice@example.com",
      reason: "We couldn't match the address you used to a Memba group"
    )
  end

  test "unsupported routes and unknown group or club slugs use the rejection pathway" do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    alice = create_person!(name: "Alice Example", email: "alice@example.com")

    add_member!(kmc.club_id, alice.person_id)

    cases = [
      %{
        provider_message_id: "task-057-unknown-group-slug",
        recipient_addresses: ["friend@example.org", "committee@kmc.clubs.memba.io"],
        rejected_to_address: "committee@kmc.clubs.memba.io",
        rejection_reason: "unsupported_recipient_address"
      },
      %{
        provider_message_id: "task-042-unsupported-domain",
        recipient_addresses: ["everyone@example.org"],
        rejected_to_address: "everyone@example.org",
        rejection_reason: "unsupported_recipient_address"
      },
      %{
        provider_message_id: "task-042-old-flat-address",
        recipient_addresses: ["kmc@clubs.memba.io"],
        rejected_to_address: "kmc@clubs.memba.io",
        rejection_reason: "unsupported_recipient_address"
      },
      %{
        provider_message_id: "task-042-unknown-club-subdomain",
        recipient_addresses: ["everyone@unknown.clubs.memba.io"],
        rejected_to_address: "everyone@unknown.clubs.memba.io",
        rejection_reason: "unknown_club_slug"
      }
    ]

    for %{provider_message_id: provider_message_id} = rejection_case <- cases do
      assert {:ok,
              %{
                inbound_email_id: _inbound_email_id,
                status: :rejected,
                rejection_reason: rejection_reason,
                from_address: "alice@example.com",
                to_address: recipient_address,
                rejection_email_delivery_reference: rejection_email_delivery_reference
              }} =
               Messaging.receive_inbound_club_email(
                 %{
                   provider: "resend",
                   provider_message_id: provider_message_id,
                   from_address: "alice@example.com",
                   recipient_addresses: rejection_case.recipient_addresses,
                   subject: "Unsupported recipient #{provider_message_id}",
                   text_body: "This should not post."
                 },
                 consistency: :strong
               )

      assert recipient_address == rejection_case.rejected_to_address
      assert rejection_reason == rejection_case.rejection_reason
      assert is_binary(rejection_email_delivery_reference)

      assert %InboundEmailSourceProjection{
               status: "rejected",
               from_address: "alice@example.com",
               to_address: ^recipient_address,
               message_id: nil,
               rejection_reason: ^rejection_reason,
               rejection_email_delivery_reference: ^rejection_email_delivery_reference
             } = Messaging.get_inbound_email_source("resend", provider_message_id)

      assert_rejection_email_received(
        to: "alice@example.com",
        reason: expected_rejection_copy(rejection_reason)
      )
    end

    assert [] = Messaging.list_messages_for_club(kmc.club_id)
    assert [] = Fake.deliveries()
    assert 0 == count_events(MessageSent)
    assert 0 == count_events(InboundClubEmailAccepted)
    assert length(cases) == count_events(InboundClubEmailRejected)
  end

  test "duplicate rejected inbound email does not send another rejection email" do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    alice = create_person!(name: "Alice Example", email: "alice@example.com")

    add_member!(kmc.club_id, alice.person_id)

    inbound_attrs = %{
      provider: "resend",
      provider_message_id: "task-015-duplicate-rejected",
      provider_event_id: "task-015-event-first",
      from_address: "alice@example.com",
      recipient_addresses: ["everyone@kmc.clubs.memba.io"],
      subject: "Trip planning night",
      text_body: "Bring route ideas.",
      attachments: [%{filename: "route.gpx", content_type: "application/gpx+xml"}]
    }

    assert {:ok,
            %{
              status: :rejected,
              rejection_reason: "attachments_not_supported"
            }} = Messaging.receive_inbound_club_email(inbound_attrs, consistency: :strong)

    assert_rejection_email_received(
      to: "alice@example.com",
      reason: "Emails with attachments can't be posted yet"
    )

    assert {:ok,
            %{
              inbound_email_id: _inbound_email_id,
              duplicate?: true,
              status: :rejected,
              rejection_reason: "attachments_not_supported"
            }} =
             inbound_attrs
             |> Map.merge(%{
               provider_event_id: "task-015-event-retry",
               subject: "Trip planning night retry"
             })
             |> Messaging.receive_inbound_club_email(consistency: :strong)

    assert [] = Messaging.list_messages_for_club(kmc.club_id)
    assert [] = Fake.deliveries()
    assert 0 == count_events(MessageSent)
    assert 0 == count_events(InboundClubEmailAccepted)
    assert 1 == count_events(InboundClubEmailRejected)
    refute_received {:email, %Swoosh.Email{}}
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

    create_attrs =
      attrs
      |> Keyword.take([:email, :email_addresses])
      |> Map.new()
      |> Map.merge(%{
        person_id: person_id,
        name: Keyword.fetch!(attrs, :name)
      })

    assert :ok = Membership.create_person(create_attrs, consistency: :strong)

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

  defp assign_admin_role!(club_id, membership_id, person_id) do
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

  defp send_club_message!(attrs) do
    message_id = Memba.ID.generate(:message)

    assert :ok =
             Messaging.send_club_message(
               %{
                 message_id: message_id,
                 club_id: Keyword.fetch!(attrs, :club_id),
                 sender_id: Keyword.fetch!(attrs, :sender_id),
                 subject: Keyword.fetch!(attrs, :subject),
                 body: Keyword.fetch!(attrs, :body)
               },
               consistency: :strong
             )

    message_id
  end

  defp follow_conversation!(club_id, conversation_id, member_id) do
    assert :ok =
             Messaging.follow_conversation(
               %{club_id: club_id, conversation_id: conversation_id, member_id: member_id},
               consistency: :strong
             )
  end

  defp outbound_message_id_for_recipient!(message_id, recipient_id) do
    message_id
    |> Messaging.list_recipient_deliveries()
    |> Enum.find(&(&1.recipient_id == recipient_id))
    |> case do
      %{outbound_message_id: outbound_message_id} when is_binary(outbound_message_id) ->
        outbound_message_id

      _missing ->
        flunk("missing outbound Message-ID for recipient #{recipient_id}")
    end
  end

  defp insert_inactive_membership!(club_id, person_id) do
    Repo.insert!(%MembershipProjection{
      membership_id: Memba.ID.generate(:membership),
      club_id: club_id,
      person_id: person_id,
      active: false
    })
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

  defp assert_rejection_email_received(opts) do
    to_address = Keyword.fetch!(opts, :to)
    reason = Keyword.fetch!(opts, :reason)

    assert_received {:email, %Swoosh.Email{} = email}

    case Keyword.fetch(opts, :from) do
      {:ok, from} ->
        assert email.from == from

      :error ->
        expected_from =
          if email.text_body =~ "Kootenay Mountaineering Club" do
            {"Kootenay Mountaineering Club via Memba", "messages@mail.memba.test"}
          else
            {"Memba", "messages@mail.memba.test"}
          end

        assert email.from == expected_from
    end

    assert email.reply_to == {"Memba support", "support@memba.test"}
    assert email.to == [{"", to_address}]

    case Keyword.fetch(opts, :subject) do
      {:ok, subject} ->
        assert email.subject == subject

      :error ->
        assert email.subject in [
                 "Your email wasn't posted",
                 "Your email to Kootenay Mountaineering Club wasn't posted"
               ]
    end

    assert email.text_body =~ reason

    assert email.text_body =~
             Keyword.get_lazy(opts, :support_copy, fn -> support_copy_for(reason) end)

    escaped_reason = reason |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    assert email.html_body =~ escaped_reason

    if Keyword.get(opts, :metadata?, true) do
      assert email.provider_options[:metadata]["memba_email_kind"] == "inbound_club_rejection"
    end

    email
  end

  defp expected_rejection_copy("unknown_club_slug"),
    do: "We couldn't match the address you used to a Memba group"

  defp expected_rejection_copy("unsupported_recipient_address"),
    do: "That recipient address isn't set up for member messages"

  defp support_copy_for(_reason), do: "Just reply to this email and a person will help."

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
