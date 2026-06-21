defmodule Memba.Messaging.InboundEmailReplyHeadersTest do
  use ExUnit.Case, async: true

  alias Memba.Messaging.InboundEmailReplyHeaders

  describe "message_ids/1" do
    test "extracts angle-bracketed and bare Message-IDs in header order" do
      header =
        " <memba.root-delivery.root-message@messages.memba.io>\r\n\t" <>
          "<external-parent@example.net>, " <>
          "memba.latest-delivery.latest-message@messages.memba.io"

      assert InboundEmailReplyHeaders.message_ids(header) == [
               "<memba.root-delivery.root-message@messages.memba.io>",
               "<external-parent@example.net>",
               "<memba.latest-delivery.latest-message@messages.memba.io>"
             ]
    end

    test "combines multiple header values and ignores malformed tokens" do
      values = [
        "not-a-message-id <memba.parent-delivery.parent-message@messages.memba.io>",
        "still-not-an-id, memba.parent-delivery.parent-message@messages.memba.io",
        "<memba.trailing-delivery.trailing-message@messages.memba.io>"
      ]

      assert InboundEmailReplyHeaders.message_ids(values) == [
               "<memba.parent-delivery.parent-message@messages.memba.io>",
               "<memba.trailing-delivery.trailing-message@messages.memba.io>"
             ]
    end
  end
end
