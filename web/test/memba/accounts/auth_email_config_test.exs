defmodule Memba.Accounts.AuthEmailConfigTest do
  use ExUnit.Case, async: true

  alias Memba.Accounts.AuthEmailConfig

  test "reads required auth email Postmark settings from environment" do
    assert {:ok,
            %AuthEmailConfig{
              server_token: "server-token",
              from: "auth@mail.memba.io",
              message_stream: "outbound-authentication"
            }} =
             AuthEmailConfig.from_env(fn
               "MEMBA_POSTMARK_SERVER_TOKEN" -> "  server-token  "
               "MEMBA_AUTH_EMAIL_FROM_ADDRESS" -> " auth@mail.memba.io "
               "MEMBA_AUTH_EMAIL_MESSAGE_STREAM" -> " outbound-authentication "
             end)
  end

  test "reports missing required auth email Postmark settings clearly" do
    assert {:error, message} =
             AuthEmailConfig.from_env(fn
               "MEMBA_POSTMARK_SERVER_TOKEN" -> "  "
               "MEMBA_AUTH_EMAIL_FROM_ADDRESS" -> nil
               "MEMBA_AUTH_EMAIL_MESSAGE_STREAM" -> ""
             end)

    assert message =~ "Auth email Postmark delivery is enabled"
    assert message =~ "required environment configuration is missing"
    assert message =~ "MEMBA_POSTMARK_SERVER_TOKEN"
    assert message =~ "MEMBA_AUTH_EMAIL_FROM_ADDRESS"
    assert message =~ "MEMBA_AUTH_EMAIL_MESSAGE_STREAM"
    assert message =~ "MEMBA_AUTH_EMAIL_PROVIDER"
  end

  test "selects Postmark auth email delivery only when explicitly configured" do
    assert AuthEmailConfig.provider_override(nil) == :default
    assert AuthEmailConfig.provider_override("") == :default
    assert AuthEmailConfig.provider_override("   ") == :default
    assert AuthEmailConfig.provider_override("postmark") == {:ok, :postmark}
    assert AuthEmailConfig.provider_override("POSTMARK") == {:ok, :postmark}

    assert {:error, message} = AuthEmailConfig.provider_override("smtp")
    assert message =~ "Unsupported MEMBA_AUTH_EMAIL_PROVIDER"
    assert message =~ "postmark"
  end
end
