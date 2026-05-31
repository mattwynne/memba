defmodule Memba.Accounts.AuthEmailConfigTest do
  use ExUnit.Case, async: false

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

  test "reads local auth email settings from application config without requiring a Postmark token" do
    with_application_env(Memba.Mailer, adapter: Swoosh.Adapters.Local)

    with_application_env(Memba.Accounts.AuthEmail,
      from: "auth@mail.memba.local",
      message_stream: "development-auth"
    )

    assert {:ok,
            %AuthEmailConfig{
              server_token: nil,
              from: "auth@mail.memba.local",
              message_stream: "development-auth"
            }} = AuthEmailConfig.from_application_env()
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

  defp with_application_env(key, value) do
    original_value = Application.get_env(:memba, key)
    Application.put_env(:memba, key, value)

    on_exit(fn ->
      if is_nil(original_value) do
        Application.delete_env(:memba, key)
      else
        Application.put_env(:memba, key, original_value)
      end
    end)
  end
end
