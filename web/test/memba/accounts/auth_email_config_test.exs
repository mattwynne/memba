defmodule Memba.Accounts.AuthEmailConfigTest do
  use ExUnit.Case, async: false

  alias Memba.Accounts.AuthEmailConfig

  @runtime_env_keys [
    "MEMBA_AUTH_EMAIL_PROVIDER",
    "MEMBA_POSTMARK_SERVER_TOKEN",
    "MEMBA_AUTH_EMAIL_FROM_ADDRESS",
    "MEMBA_AUTH_EMAIL_MESSAGE_STREAM",
    "MEMBA_MESSAGING_DELIVERY_PROVIDER",
    "MEMBA_RESEND_API_KEY",
    "MEMBA_RESEND_WEBHOOK_SIGNING_SECRET"
  ]

  test "reads required auth email Postmark settings from environment" do
    assert {:ok,
            %AuthEmailConfig{
              provider: :postmark,
              server_token: "server-token",
              from: "auth@mail.memba.io",
              message_stream: "outbound-authentication"
            }} =
             AuthEmailConfig.from_env(fn
               "MEMBA_POSTMARK_SERVER_TOKEN" -> "  server-token  "
               "MEMBA_AUTH_EMAIL_FROM_ADDRESS" -> " auth@mail.memba.io "
               "MEMBA_AUTH_EMAIL_MESSAGE_STREAM" -> " outbound-authentication "
               "MEMBA_RESEND_API_KEY" -> nil
             end)
  end

  test "reports missing required auth email Postmark settings clearly" do
    assert {:error, message} =
             AuthEmailConfig.from_env(fn
               "MEMBA_POSTMARK_SERVER_TOKEN" -> "  "
               "MEMBA_AUTH_EMAIL_FROM_ADDRESS" -> nil
               "MEMBA_AUTH_EMAIL_MESSAGE_STREAM" -> ""
               "MEMBA_RESEND_API_KEY" -> nil
             end)

    assert message =~ "Auth email delivery is enabled"
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

  test "reads required auth email Resend settings from environment" do
    assert {:ok,
            %AuthEmailConfig{
              provider: :resend,
              api_key: "resend-key",
              from: "auth@mail.memba.io",
              message_stream: "auth"
            }} =
             AuthEmailConfig.from_env(:resend, fn
               "MEMBA_RESEND_API_KEY" -> "  resend-key  "
               "MEMBA_AUTH_EMAIL_FROM_ADDRESS" -> " auth@mail.memba.io "
               "MEMBA_AUTH_EMAIL_MESSAGE_STREAM" -> " auth "
               "MEMBA_POSTMARK_SERVER_TOKEN" -> nil
             end)
  end

  test "selects auth email delivery provider only when explicitly configured" do
    assert AuthEmailConfig.provider_override(nil) == :default
    assert AuthEmailConfig.provider_override("") == :default
    assert AuthEmailConfig.provider_override("   ") == :default
    assert AuthEmailConfig.provider_override("postmark") == {:ok, :postmark}
    assert AuthEmailConfig.provider_override("POSTMARK") == {:ok, :postmark}
    assert AuthEmailConfig.provider_override("resend") == {:ok, :resend}
    assert AuthEmailConfig.provider_override("RESEND") == {:ok, :resend}

    assert {:error, message} = AuthEmailConfig.provider_override("smtp")
    assert message =~ "Unsupported MEMBA_AUTH_EMAIL_PROVIDER"
    assert message =~ "postmark"
    assert message =~ "resend"
  end

  test "runtime config selects Postmark auth email from MEMBA_AUTH_EMAIL_PROVIDER" do
    runtime_config =
      read_runtime_config(%{
        "MEMBA_AUTH_EMAIL_PROVIDER" => "postmark",
        "MEMBA_POSTMARK_SERVER_TOKEN" => "server-token",
        "MEMBA_AUTH_EMAIL_FROM_ADDRESS" => "auth@mail.memba.io",
        "MEMBA_AUTH_EMAIL_MESSAGE_STREAM" => "outbound-authentication"
      })

    memba_config = Keyword.fetch!(runtime_config, :memba)

    assert Keyword.fetch!(memba_config, Memba.Mailer) == [
             adapter: Swoosh.Adapters.Postmark,
             api_key: "server-token"
           ]

    assert Keyword.fetch!(memba_config, Memba.Accounts.AuthEmail) == [
             provider: :postmark,
             from: "auth@mail.memba.io",
             message_stream: "outbound-authentication"
           ]

    assert Keyword.fetch!(Keyword.fetch!(runtime_config, :swoosh), :api_client) ==
             Swoosh.ApiClient.Req
  end

  test "runtime config fails clearly when Postmark auth email is selected but incomplete" do
    error =
      assert_raise ArgumentError, fn ->
        read_runtime_config(%{
          "MEMBA_AUTH_EMAIL_PROVIDER" => "postmark",
          "MEMBA_POSTMARK_SERVER_TOKEN" => "",
          "MEMBA_AUTH_EMAIL_FROM_ADDRESS" => nil,
          "MEMBA_AUTH_EMAIL_MESSAGE_STREAM" => " "
        })
      end

    assert error.message =~ "Auth email delivery is enabled"
    assert error.message =~ "required environment configuration is missing"
    assert error.message =~ "MEMBA_POSTMARK_SERVER_TOKEN"
    assert error.message =~ "MEMBA_AUTH_EMAIL_FROM_ADDRESS"
    assert error.message =~ "MEMBA_AUTH_EMAIL_MESSAGE_STREAM"
    assert error.message =~ "MEMBA_AUTH_EMAIL_PROVIDER"
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

  defp read_runtime_config(env) do
    with_system_env(env, fn ->
      Config.Reader.read!("config/runtime.exs", env: :test)
    end)
  end

  defp with_system_env(env, fun) do
    env = with_default_runtime_env(env)

    original_env =
      Map.new(Map.keys(env), fn key ->
        {key, System.get_env(key)}
      end)

    set_system_env(env)

    try do
      fun.()
    after
      set_system_env(original_env)
    end
  end

  defp with_default_runtime_env(env) do
    Enum.reduce(@runtime_env_keys, env, fn key, env ->
      Map.put_new(env, key, nil)
    end)
  end

  defp set_system_env(env) do
    Enum.each(env, fn
      {key, nil} -> System.delete_env(key)
      {key, value} -> System.put_env(key, value)
    end)
  end
end
