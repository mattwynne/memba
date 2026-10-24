defmodule Memba.DevSeedsRepliesTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership.Authorization
  alias Memba.Membership.MembershipQueries
  alias Memba.Membership.PersonQueries
  alias Memba.Messaging.DeliveryQueries
  alias Memba.Messaging.LocalDeliveryFacts
  alias Memba.Messaging.MessageQueries

  @reply_one "msg_30000000-0000-0000-0000-000000000101"
  @reply_two "msg_30000000-0000-0000-0000-000000000102"

  test "seeding posts replies and dispatches their notification emails" do
    Memba.DevSeeds.run()

    club_id = "clb_11111111-1111-1111-1111-111111111111"
    message_ids = MessageQueries.list_messages_for_club(club_id) |> Enum.map(& &1.message_id)
    assert @reply_one in message_ids
    assert @reply_two in message_ids

    delivered_message_ids = LocalDeliveryFacts.list() |> Enum.map(& &1.message_id)
    assert @reply_one in delivered_message_ids

    assert %{person_id: "per_5ca11e2f-5ca1-5ca1-5ca1-5ca11e2f5ca1"} =
             PersonQueries.get_person_by_email("gallery-staff@memba.io")

    alice_id = "per_aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    benji_id = "per_bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
    carmen_id = "per_cccccccc-cccc-cccc-cccc-cccccccccccc"
    drew_id = "per_dddddddd-dddd-dddd-dddd-dddddddddddd"
    first_message = "msg_30000000-0000-0000-0000-000000000001"

    recipient_ids =
      first_message
      |> DeliveryQueries.list_recipient_deliveries()
      |> Enum.map(& &1.recipient_id)

    assert length(recipient_ids) == 3
    refute alice_id in recipient_ids
    assert MapSet.new(recipient_ids) == MapSet.new([benji_id, carmen_id, drew_id])

    assert DeliveryQueries.list_operator_email_deliveries(first_message)
           |> Enum.frequencies_by(& &1.status) ==
             %{"bounced" => 1, "sent" => 1, "delayed" => 1}

    assert DeliveryQueries.list_member_email_deliverys(first_message)
           |> Enum.frequencies_by(& &1.status) ==
             %{"delivery problem" => 2, "sent" => 1}

    assert MembershipQueries.active_member_of_club?(
             club_id,
             alice_id
           )

    assert Authorization.has_permission?(
             club_id,
             alice_id,
             "club.manage_members"
           )
  end
end
