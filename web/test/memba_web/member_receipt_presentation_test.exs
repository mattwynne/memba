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
end
