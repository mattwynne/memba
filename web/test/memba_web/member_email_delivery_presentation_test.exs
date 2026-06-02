defmodule MembaWeb.MemberEmailDeliveryPresentationTest do
  use ExUnit.Case, async: true

  alias MembaWeb.MemberEmailDeliveryPresentation

  describe "present_status/1" do
    test "maps internal member email delivery statuses to member-facing labels and Heroicons" do
      assert MemberEmailDeliveryPresentation.present_status("sent") == %{
               status: "sent",
               label: "Sending",
               icon: "hero-clock"
             }

      assert MemberEmailDeliveryPresentation.present_status("delivered") == %{
               status: "delivered",
               label: "Delivered",
               icon: "hero-check-circle"
             }

      assert MemberEmailDeliveryPresentation.present_status("delivery problem") == %{
               status: "delivery problem",
               label: "Delivery problem",
               icon: "hero-exclamation-triangle"
             }

      assert MemberEmailDeliveryPresentation.present_status("opened") == %{
               status: "delivered",
               label: "Delivered",
               icon: "hero-check-circle"
             }
    end

    test "treats blank or missing statuses as the initial sent status" do
      assert MemberEmailDeliveryPresentation.present_status(nil) == %{
               status: "sent",
               label: "Sending",
               icon: "hero-clock"
             }

      assert MemberEmailDeliveryPresentation.present_status("") == %{
               status: "sent",
               label: "Sending",
               icon: "hero-clock"
             }
    end
  end

  describe "present_receipt/1" do
    test "maps the projection status to current member-facing receipt data" do
      receipt = %{
        recipient_id: "person-123",
        recipient_name: "Alice Adams",
        status: "delivered"
      }

      assert MemberEmailDeliveryPresentation.present_receipt(receipt) == %{
               recipient_id: "person-123",
               recipient_name: "Alice Adams",
               status: "delivered",
               status_label: "Delivered",
               status_icon: "hero-check-circle"
             }
    end

    test "folds historic opened receipts into Delivered instead of exposing opened" do
      receipt = %{
        recipient_id: "person-456",
        recipient_name: "Historic Recipient",
        status: "opened"
      }

      assert MemberEmailDeliveryPresentation.present_receipt(receipt) == %{
               recipient_id: "person-456",
               recipient_name: "Historic Recipient",
               status: "delivered",
               status_label: "Delivered",
               status_icon: "hero-check-circle"
             }
    end
  end

  describe "present_receipts/1" do
    test "builds ordered summary and non-empty groups with descriptions, counts, and percentages" do
      receipts = [
        %{recipient_id: "sent-1", recipient_name: "Sending Member", status: "sent"},
        %{
          recipient_id: "delivered-1",
          recipient_name: "Delivered Member One",
          status: "delivered"
        },
        %{recipient_id: "opened-1", recipient_name: "Historic Opened Member", status: "opened"},
        %{
          recipient_id: "delivered-2",
          recipient_name: "Delivered Member Two",
          status: "delivered"
        }
      ]

      assert %{
               total_count: 4,
               receipts: presented_receipts,
               summary: summary,
               groups: groups
             } = MemberEmailDeliveryPresentation.present_receipts(receipts)

      assert Enum.map(presented_receipts, & &1.status) == [
               "sent",
               "delivered",
               "delivered",
               "delivered"
             ]

      assert summary == [
               %{
                 status: "delivered",
                 status_label: "Delivered",
                 status_icon: "hero-check-circle",
                 description: "delivered to their inbox",
                 count: 3,
                 percentage: 75
               },
               %{
                 status: "sent",
                 status_label: "Sending",
                 status_icon: "hero-clock",
                 description: "on its way",
                 count: 1,
                 percentage: 25
               },
               %{
                 status: "delivery problem",
                 status_label: "Delivery problem",
                 status_icon: "hero-exclamation-triangle",
                 description: "we couldn't reach them",
                 count: 0,
                 percentage: 0
               }
             ]

      assert Enum.map(groups, & &1.status) == ["delivered", "sent"]
      refute Enum.any?(groups, &(&1.status == "delivery problem"))

      assert [
               %{recipient_name: "Delivered Member One", status_label: "Delivered"},
               %{recipient_name: "Historic Opened Member", status_label: "Delivered"},
               %{recipient_name: "Delivered Member Two", status_label: "Delivered"}
             ] = Enum.find(groups, &(&1.status == "delivered")).receipts
    end

    test "rounds percentages independently from the addressed receipt total" do
      receipts = [
        %{recipient_id: "opened-1", recipient_name: "Opened Member", status: "opened"},
        %{recipient_id: "sent-1", recipient_name: "Sending Member One", status: "sent"},
        %{recipient_id: "sent-2", recipient_name: "Sending Member Two", status: "sent"}
      ]

      model = MemberEmailDeliveryPresentation.present_receipts(receipts)

      assert Enum.map(model.summary, &{&1.status, &1.percentage}) == [
               {"delivered", 33},
               {"sent", 67},
               {"delivery problem", 0}
             ]
    end

    test "shows zero counts and percentages for every summary status when there are no receipts" do
      assert %{
               total_count: 0,
               receipts: [],
               groups: [],
               summary: [
                 %{status: "delivered", count: 0, percentage: 0},
                 %{status: "sent", count: 0, percentage: 0},
                 %{status: "delivery problem", count: 0, percentage: 0}
               ]
             } = MemberEmailDeliveryPresentation.present_receipts([])
    end
  end
end
