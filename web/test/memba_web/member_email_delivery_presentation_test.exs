defmodule MembaWeb.MemberEmailDeliveryPresentationTest do
  use ExUnit.Case, async: true

  alias MembaWeb.MemberEmailDeliveryPresentation

  describe "present_status/1" do
    test "maps internal member email delivery statuses to member-facing labels and Heroicons" do
      assert MemberEmailDeliveryPresentation.present_status("sent") == %{
               status: "sent",
               label: "Sending",
               icon: "hero-clock",
               tone: "warning"
             }

      assert MemberEmailDeliveryPresentation.present_status("delivered") == %{
               status: "delivered",
               label: "Delivered",
               icon: "hero-check-circle",
               tone: "success"
             }

      assert MemberEmailDeliveryPresentation.present_status("delivery problem") == %{
               status: "delivery problem",
               label: "Delivery problem",
               icon: "hero-exclamation-triangle",
               tone: "error"
             }
    end

    test "folds detailed provider and dispatch states into member-facing statuses" do
      for status <- ["pending", "dispatching", "failed"] do
        assert MemberEmailDeliveryPresentation.present_status(status) == %{
                 status: "sent",
                 label: "Sending",
                 icon: "hero-clock",
                 tone: "warning"
               }
      end

      for status <- ["delayed", "bounced", "spam_complaint", "spam complaint"] do
        assert MemberEmailDeliveryPresentation.present_status(status) == %{
                 status: "delivery problem",
                 label: "Delivery problem",
                 icon: "hero-exclamation-triangle",
                 tone: "error"
               }
      end
    end

    test "treats blank or missing statuses as the initial sent status" do
      assert MemberEmailDeliveryPresentation.present_status(nil) == %{
               status: "sent",
               label: "Sending",
               icon: "hero-clock",
               tone: "warning"
             }

      assert MemberEmailDeliveryPresentation.present_status("") == %{
               status: "sent",
               label: "Sending",
               icon: "hero-clock",
               tone: "warning"
             }
    end
  end

  describe "design-system status mapping" do
    test "maps member delivery statuses to sage, warning, and error visuals" do
      assert MemberEmailDeliveryPresentation.status_tone("delivered") == "success"
      assert MemberEmailDeliveryPresentation.status_bg_class("delivered") == "bg-sage-600"
      assert MemberEmailDeliveryPresentation.status_text_class("delivered") == "text-sage-700"

      assert MemberEmailDeliveryPresentation.status_tint_class("delivered") ==
               "bg-sage-50 text-sage-700 ring-sage-200"

      assert MemberEmailDeliveryPresentation.status_tone("sent") == "warning"
      assert MemberEmailDeliveryPresentation.status_bg_class("sent") == "bg-warning"
      assert MemberEmailDeliveryPresentation.status_text_class("sent") == "text-warning"

      assert MemberEmailDeliveryPresentation.status_tint_class("sent") ==
               "bg-warning-soft text-warning ring-warning/25"

      assert MemberEmailDeliveryPresentation.status_tone("delivery problem") == "error"
      assert MemberEmailDeliveryPresentation.status_bg_class("delivery problem") == "bg-error"
      assert MemberEmailDeliveryPresentation.status_text_class("delivery problem") == "text-error"

      assert MemberEmailDeliveryPresentation.status_tint_class("delivery problem") ==
               "bg-error-soft text-error ring-error/25"
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
               status_icon: "hero-check-circle",
               status_tone: "success",
               reason: nil
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
        %{
          recipient_id: "delivered-2",
          recipient_name: "Delivered Member Two",
          status: "delivered"
        },
        %{
          recipient_id: "problem-1",
          recipient_name: "Problem Member",
          status: "delivery problem"
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
               "delivery problem"
             ]

      assert summary == [
               %{
                 status: "delivered",
                 status_label: "Delivered",
                 status_icon: "hero-check-circle",
                 status_tone: "success",
                 description: "Email delivered",
                 count: 2,
                 percentage: 50
               },
               %{
                 status: "sent",
                 status_label: "Sending",
                 status_icon: "hero-clock",
                 status_tone: "warning",
                 description: "Email still sending",
                 count: 1,
                 percentage: 25
               },
               %{
                 status: "delivery problem",
                 status_label: "Delivery problem",
                 status_icon: "hero-exclamation-triangle",
                 status_tone: "error",
                 description: "Email not delivered",
                 count: 1,
                 percentage: 25
               }
             ]

      assert Enum.map(groups, & &1.status) == ["delivered", "sent", "delivery problem"]

      assert [
               %{recipient_name: "Delivered Member One", status_label: "Delivered"},
               %{recipient_name: "Delivered Member Two", status_label: "Delivered"}
             ] = Enum.find(groups, &(&1.status == "delivered")).receipts
    end

    test "rounds percentages independently from the addressed receipt total" do
      receipts = [
        %{recipient_id: "delivered-1", recipient_name: "Delivered Member", status: "delivered"},
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
