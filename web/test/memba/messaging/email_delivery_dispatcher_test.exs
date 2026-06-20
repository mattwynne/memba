defmodule Memba.Messaging.EmailDeliveryDispatcherTest do
  use ExUnit.Case, async: false

  alias Memba.Messaging.EmailDeliveryDispatcher
  alias Memba.Messaging.Events.EmailDeliveryCreated
  alias Memba.Messaging.Events.EmailDeliveryDelivered
  alias Memba.Messaging.Projectors.EmailDelivery, as: EmailDeliveryProjector
  alias Memba.Messaging.Projectors.MemberEmailDelivery, as: MemberEmailDeliveryProjector
  alias Memba.ReadModelChanges

  test "subscribes to read-model changes and nudges dispatch for committed email delivery creation" do
    name = :"#{__MODULE__}.email_delivery_created"

    start_supervised!({EmailDeliveryDispatcher, name: name, dispatch_observer: self()})

    event = %EmailDeliveryCreated{
      message_id: "msg_dispatch_nudge",
      delivery_id: "del_dispatch_nudge",
      recipient_id: "per_dispatch_nudge",
      recipient_name: "Ada Member",
      recipient_email: "ada@example.test"
    }

    changes = %{
      messaging_email_delivery: %{
        delivery_id: event.delivery_id,
        message_id: event.message_id,
        status: "pending"
      }
    }

    assert :ok = ReadModelChanges.publish(EmailDeliveryProjector, event, %{}, changes)

    assert_receive {:email_delivery_dispatch_requested,
                    %{
                      source: :read_model_change,
                      projector: EmailDeliveryProjector,
                      source_event: ^event,
                      changes: ^changes
                    }}
  end

  test "ignores unrelated read-model changes" do
    name = :"#{__MODULE__}.unrelated_changes"

    start_supervised!({EmailDeliveryDispatcher, name: name, dispatch_observer: self()})

    event = %EmailDeliveryDelivered{
      message_id: "msg_unrelated",
      delivery_id: "del_unrelated"
    }

    assert :ok =
             ReadModelChanges.publish(
               MemberEmailDeliveryProjector,
               event,
               %{},
               %{messaging_member_email_delivery: %{delivery_id: event.delivery_id}}
             )

    refute_receive {:email_delivery_dispatch_requested, _}
  end
end
