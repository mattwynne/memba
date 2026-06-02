defmodule Memba.Messaging.EmailDeliveryProviders.ResendConfigTest do
  use ExUnit.Case, async: true

  alias Memba.Messaging.EmailDeliveryProviders.ResendConfig

  test "reads required Resend provider settings from environment" do
    assert {:ok,
            %ResendConfig{
              api_key: "resend-key",
              from: "messages@mail.memba.io",
              reply_to: "help@memba.io"
            }} =
             ResendConfig.from_env(fn
               "MEMBA_RESEND_API_KEY" -> "  resend-key  "
               "MEMBA_RESEND_FROM_ADDRESS" -> " messages@mail.memba.io "
               "MEMBA_RESEND_REPLY_TO_ADDRESS" -> " help@memba.io "
             end)
  end

  test "reports missing required environment settings clearly" do
    assert {:error, message} =
             ResendConfig.from_env(fn
               "MEMBA_RESEND_API_KEY" -> "  "
               "MEMBA_RESEND_FROM_ADDRESS" -> nil
               "MEMBA_RESEND_REPLY_TO_ADDRESS" -> "  "
             end)

    assert message =~ "Resend email delivery provider is enabled"
    assert message =~ "required environment configuration is missing"
    assert message =~ "MEMBA_RESEND_API_KEY"
    assert message =~ "MEMBA_RESEND_FROM_ADDRESS"
    assert message =~ "MEMBA_MESSAGING_DELIVERY_PROVIDER"
  end

  test "raises clearly for missing required environment settings" do
    assert_raise ArgumentError, ~r/MEMBA_RESEND_FROM_ADDRESS/, fn ->
      ResendConfig.from_env!(fn
        "MEMBA_RESEND_API_KEY" -> "resend-key"
        "MEMBA_RESEND_FROM_ADDRESS" -> nil
        "MEMBA_RESEND_REPLY_TO_ADDRESS" -> nil
      end)
    end
  end
end
