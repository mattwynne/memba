defmodule MembaWeb.MemberReceiptPresentationTest do
  use ExUnit.Case, async: true

  alias MembaWeb.MemberReceiptPresentation

  describe "present_status/1" do
    test "maps internal member receipt statuses to member-facing labels and Heroicons" do
      assert MemberReceiptPresentation.present_status("sent") == %{
               status: "sent",
               label: "Sending",
               icon: "hero-clock"
             }

      assert MemberReceiptPresentation.present_status("delivered") == %{
               status: "delivered",
               label: "Delivered",
               icon: "hero-check-circle"
             }

      assert MemberReceiptPresentation.present_status("delivery problem") == %{
               status: "delivery problem",
               label: "Delivery problem",
               icon: "hero-exclamation-triangle"
             }

      assert MemberReceiptPresentation.present_status("opened") == %{
               status: "opened",
               label: "Opened",
               icon: "hero-envelope-open"
             }
    end

    test "treats blank or missing statuses as the initial sent status" do
      assert MemberReceiptPresentation.present_status(nil) == %{
               status: "sent",
               label: "Sending",
               icon: "hero-clock"
             }

      assert MemberReceiptPresentation.present_status("") == %{
               status: "sent",
               label: "Sending",
               icon: "hero-clock"
             }
    end
  end

  describe "present_receipt/1" do
    test "keeps the raw projection status while adding display label and icon" do
      receipt = %{
        recipient_id: "person-123",
        recipient_name: "Alice Adams",
        receipt_status: "delivered"
      }

      assert MemberReceiptPresentation.present_receipt(receipt) == %{
               recipient_id: "person-123",
               recipient_name: "Alice Adams",
               status: "delivered",
               status_label: "Delivered",
               status_icon: "hero-check-circle"
             }
    end
  end

  describe "present_receipts/1" do
    test "builds ordered summary and non-empty groups with descriptions, counts, and percentages" do
      receipts = [
        %{recipient_id: "sent-1", recipient_name: "Sending Member", receipt_status: "sent"},
        %{
          recipient_id: "delivered-1",
          recipient_name: "Delivered Member One",
          receipt_status: "delivered"
        },
        %{recipient_id: "opened-1", recipient_name: "Opened Member", receipt_status: "opened"},
        %{
          recipient_id: "delivered-2",
          recipient_name: "Delivered Member Two",
          receipt_status: "delivered"
        }
      ]

      assert %{
               total_count: 4,
               receipts: presented_receipts,
               summary: summary,
               groups: groups
             } = MemberReceiptPresentation.present_receipts(receipts)

      assert Enum.map(presented_receipts, & &1.status) == [
               "sent",
               "delivered",
               "opened",
               "delivered"
             ]

      assert summary == [
               %{
                 status: "opened",
                 status_label: "Opened",
                 status_icon: "hero-envelope-open",
                 description: "read it",
                 count: 1,
                 percentage: 25
               },
               %{
                 status: "delivered",
                 status_label: "Delivered",
                 status_icon: "hero-check-circle",
                 description: "arrived, not opened yet",
                 count: 2,
                 percentage: 50
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

      assert Enum.map(groups, & &1.status) == ["opened", "delivered", "sent"]
      refute Enum.any?(groups, &(&1.status == "delivery problem"))

      assert [
               %{recipient_name: "Opened Member", status_label: "Opened"}
             ] = Enum.find(groups, &(&1.status == "opened")).receipts

      assert [
               %{recipient_name: "Delivered Member One", status_label: "Delivered"},
               %{recipient_name: "Delivered Member Two", status_label: "Delivered"}
             ] = Enum.find(groups, &(&1.status == "delivered")).receipts
    end

    test "rounds percentages independently from the addressed receipt total" do
      receipts = [
        %{recipient_id: "opened-1", recipient_name: "Opened Member", receipt_status: "opened"},
        %{recipient_id: "sent-1", recipient_name: "Sending Member One", receipt_status: "sent"},
        %{recipient_id: "sent-2", recipient_name: "Sending Member Two", receipt_status: "sent"}
      ]

      model = MemberReceiptPresentation.present_receipts(receipts)

      assert Enum.map(model.summary, &{&1.status, &1.percentage}) == [
               {"opened", 33},
               {"delivered", 0},
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
                 %{status: "opened", count: 0, percentage: 0},
                 %{status: "delivered", count: 0, percentage: 0},
                 %{status: "sent", count: 0, percentage: 0},
                 %{status: "delivery problem", count: 0, percentage: 0}
               ]
             } = MemberReceiptPresentation.present_receipts([])
    end
  end
end
