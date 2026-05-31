defmodule Memba.Messaging.DeliveryProviders.PostmarkConfigTest do
  use ExUnit.Case, async: true

  alias Memba.Messaging.DeliveryProviders.PostmarkConfig

  test "reads required Postmark provider settings from environment" do
    assert {:ok,
            %PostmarkConfig{
              server_token: "server-token",
              from: "messages@mail.memba.io"
            }} =
             PostmarkConfig.from_env(fn
               "MEMBA_POSTMARK_SERVER_TOKEN" -> "  server-token  "
               "MEMBA_POSTMARK_FROM_ADDRESS" -> " messages@mail.memba.io "
             end)
  end

  test "reports missing required environment settings clearly" do
    assert {:error, message} =
             PostmarkConfig.from_env(fn
               "MEMBA_POSTMARK_SERVER_TOKEN" -> "  "
               "MEMBA_POSTMARK_FROM_ADDRESS" -> nil
             end)

    assert message =~ "Postmark delivery provider is enabled"
    assert message =~ "required environment configuration is missing"
    assert message =~ "MEMBA_POSTMARK_SERVER_TOKEN"
    assert message =~ "MEMBA_POSTMARK_FROM_ADDRESS"
    assert message =~ "MEMBA_MESSAGING_DELIVERY_PROVIDER"
  end

  test "raises clearly for missing required environment settings" do
    assert_raise ArgumentError, ~r/MEMBA_POSTMARK_FROM_ADDRESS/, fn ->
      PostmarkConfig.from_env!(fn
        "MEMBA_POSTMARK_SERVER_TOKEN" -> "server-token"
        "MEMBA_POSTMARK_FROM_ADDRESS" -> nil
      end)
    end
  end
end
