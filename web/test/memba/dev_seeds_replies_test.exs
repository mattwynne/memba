defmodule Memba.DevSeedsRepliesTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Messaging
  alias Memba.Messaging.LocalDeliveryFacts

  @reply_one "msg_30000000-0000-0000-0000-000000000101"
  @reply_two "msg_30000000-0000-0000-0000-000000000102"

  test "seeding posts replies and dispatches their notification emails" do
    Memba.DevSeeds.run()

    club_id = "clb_11111111-1111-1111-1111-111111111111"
    message_ids = Messaging.list_messages_for_club(club_id) |> Enum.map(& &1.message_id)
    assert @reply_one in message_ids
    assert @reply_two in message_ids

    delivered_message_ids = LocalDeliveryFacts.list() |> Enum.map(& &1.message_id)
    assert @reply_one in delivered_message_ids
  end
end
