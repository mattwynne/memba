defmodule Memba.ReadModelChangesTest do
  use ExUnit.Case, async: true

  alias Memba.Messaging.Events.EmailDeliveryDelivered
  alias Memba.Messaging.Projectors.MemberEmailDelivery
  alias Memba.ReadModelChanges

  test "publishes committed read-model changes on the shared bus" do
    Phoenix.PubSub.subscribe(Memba.PubSub, ReadModelChanges.topic())

    event = %EmailDeliveryDelivered{message_id: "msg_123", delivery_id: "del_123"}
    changes = %{messaging_member_email_delivery: %{delivery_id: "del_123", status: "delivered"}}

    assert :ok = ReadModelChanges.publish(MemberEmailDelivery, event, %{}, changes)

    assert_receive {:read_model_changed,
                    %{
                      projector: MemberEmailDelivery,
                      source_event: ^event,
                      metadata: %{},
                      changes: ^changes
                    }}
  end

  test "projectors publish after their Ecto transaction has updated the read model" do
    Phoenix.PubSub.subscribe(Memba.PubSub, ReadModelChanges.topic())

    event = %EmailDeliveryDelivered{message_id: "msg_456", delivery_id: "del_456"}
    changes = %{messaging_member_email_delivery: %{delivery_id: "del_456", status: "delivered"}}

    assert :ok = MemberEmailDelivery.after_update(event, %{causation_id: "cause-1"}, changes)

    assert_receive {:read_model_changed,
                    %{
                      projector: MemberEmailDelivery,
                      source_event: ^event,
                      metadata: %{causation_id: "cause-1"},
                      changes: ^changes
                    }}
  end
end
