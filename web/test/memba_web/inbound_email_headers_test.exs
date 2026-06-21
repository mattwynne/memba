defmodule MembaWeb.InboundEmailHeadersTest do
  use ExUnit.Case, async: true

  alias MembaWeb.InboundEmailHeaders

  describe "original_message_id/1" do
    test "extracts the first case-insensitive Message-ID from map and list header shapes" do
      assert InboundEmailHeaders.original_message_id(%{
               "Message-ID" => " <sender-message@example.test> "
             }) == "<sender-message@example.test>"

      assert InboundEmailHeaders.original_message_id([
               %{"name" => "X-Other", "value" => "ignored"},
               %{"Name" => "Message-ID", "Value" => " <postmark-message@example.test> "}
             ]) == "<postmark-message@example.test>"
    end
  end

  describe "reply_message_ids/2" do
    test "extracts normalized reply Message-IDs from provider header map shapes" do
      headers = %{
        "In-Reply-To" => " \n <memba.parent-delivery.parent-message@messages.memba.io> ",
        "References" =>
          "<memba.root-delivery.root-message@messages.memba.io>\n\t" <>
            "<external-parent@example.net>, " <>
            "memba.latest-delivery.latest-message@messages.memba.io"
      }

      assert InboundEmailHeaders.reply_message_ids(headers, "in-reply-to") == [
               "<memba.parent-delivery.parent-message@messages.memba.io>"
             ]

      assert InboundEmailHeaders.reply_message_ids(headers, "references") == [
               "<memba.root-delivery.root-message@messages.memba.io>",
               "<external-parent@example.net>",
               "<memba.latest-delivery.latest-message@messages.memba.io>"
             ]
    end

    test "combines duplicate list header values while preserving normalized order" do
      headers = [
        %{
          "Name" => "References",
          "Value" => "<memba.root-delivery.root-message@messages.memba.io>"
        },
        %{
          "name" => "references",
          "value" =>
            "<memba.root-delivery.root-message@messages.memba.io> " <>
              "<memba.latest-delivery.latest-message@messages.memba.io>"
        }
      ]

      assert InboundEmailHeaders.reply_message_ids(headers, "references") == [
               "<memba.root-delivery.root-message@messages.memba.io>",
               "<memba.latest-delivery.latest-message@messages.memba.io>"
             ]
    end
  end
end
