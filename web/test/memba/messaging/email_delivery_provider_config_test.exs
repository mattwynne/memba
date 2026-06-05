defmodule Memba.Messaging.EmailDeliveryProviderConfigTest do
  use ExUnit.Case, async: false

  alias Memba.Messaging.EmailDeliveryProviderConfig
  alias Memba.Messaging.EmailDeliveryProviders.Fake
  alias Memba.Messaging.EmailDeliveryProviders.Local
  alias Memba.Messaging.EmailDeliveryProviders.Postmark
  alias Memba.Messaging.EmailDeliveryProviders.Resend

  @runtime_env_keys [
    "MEMBA_EMAIL_PROVIDER",
    "MEMBA_POSTMARK_SERVER_TOKEN",
    "MEMBA_MESSAGING_FROM_ADDRESS",
    "MEMBA_MESSAGING_REPLY_TO_ADDRESS",
    "MEMBA_AUTH_EMAIL_FROM_ADDRESS",
    "MEMBA_AUTH_EMAIL_MESSAGE_STREAM",
    "MEMBA_RESEND_API_KEY",
    "MEMBA_RESEND_WEBHOOK_SIGNING_SECRET"
  ]

  test "does not override configured defaults when no explicit provider is named" do
    assert EmailDeliveryProviderConfig.provider_override(nil) == :default
    assert EmailDeliveryProviderConfig.provider_override("") == :default
    assert EmailDeliveryProviderConfig.provider_override("   ") == :default
  end

  test "selects supported environment-wide email providers" do
    assert EmailDeliveryProviderConfig.provider_override("fake") == {:ok, Fake}
    assert EmailDeliveryProviderConfig.provider_override("local") == {:ok, Local}
    assert EmailDeliveryProviderConfig.provider_override("postmark") == {:ok, Postmark}
    assert EmailDeliveryProviderConfig.provider_override("resend") == {:ok, Resend}
  end

  test "rejects unknown provider names" do
    assert {:error, message} = EmailDeliveryProviderConfig.provider_override("smtp")

    assert message =~ "Unsupported MEMBA_EMAIL_PROVIDER"
    assert message =~ "fake"
    assert message =~ "local"
    assert message =~ "postmark"
    assert message =~ "resend"
  end

  test "runtime config selects Postmark once for messaging, auth, and the shared mailer" do
    runtime_config =
      read_runtime_config(%{
        "MEMBA_EMAIL_PROVIDER" => "postmark",
        "MEMBA_POSTMARK_SERVER_TOKEN" => "server-token",
        "MEMBA_MESSAGING_FROM_ADDRESS" => "messages@mail.memba.io",
        "MEMBA_MESSAGING_REPLY_TO_ADDRESS" => "help@memba.io",
        "MEMBA_AUTH_EMAIL_FROM_ADDRESS" => "auth@mail.memba.io",
        "MEMBA_AUTH_EMAIL_MESSAGE_STREAM" => "outbound-authentication"
      })

    memba_config = Keyword.fetch!(runtime_config, :memba)

    assert Keyword.fetch!(memba_config, :messaging_email_delivery_provider) == Postmark

    assert Keyword.fetch!(memba_config, Memba.Mailer) == [
             adapter: Swoosh.Adapters.Postmark,
             api_key: "server-token"
           ]

    assert Keyword.fetch!(memba_config, Postmark) == [
             from: "messages@mail.memba.io",
             reply_to: "help@memba.io"
           ]

    assert Keyword.fetch!(memba_config, Memba.Accounts.AuthEmail) == [
             provider: :postmark,
             from: "auth@mail.memba.io",
             message_stream: "outbound-authentication"
           ]

    assert Keyword.fetch!(Keyword.fetch!(runtime_config, :swoosh), :api_client) ==
             Swoosh.ApiClient.Req
  end

  test "runtime config selects Resend once for messaging, auth, and the shared mailer" do
    runtime_config =
      read_runtime_config(%{
        "MEMBA_EMAIL_PROVIDER" => "resend",
        "MEMBA_RESEND_API_KEY" => "resend-key",
        "MEMBA_MESSAGING_FROM_ADDRESS" => "messages@clubs-dev.memba.io",
        "MEMBA_MESSAGING_REPLY_TO_ADDRESS" => "support@memba.io",
        "MEMBA_AUTH_EMAIL_FROM_ADDRESS" => "auth@clubs-dev.memba.io",
        "MEMBA_AUTH_EMAIL_MESSAGE_STREAM" => "auth"
      })

    memba_config = Keyword.fetch!(runtime_config, :memba)

    assert Keyword.fetch!(memba_config, :messaging_email_delivery_provider) == Resend

    assert Keyword.fetch!(memba_config, Memba.Mailer) == [
             adapter: Memba.Messaging.EmailDeliveryProviders.ResendAdapter,
             api_key: "resend-key"
           ]

    assert Keyword.fetch!(memba_config, Resend) == [
             from: "messages@clubs-dev.memba.io",
             reply_to: "support@memba.io"
           ]

    assert Keyword.fetch!(memba_config, Memba.Accounts.AuthEmail) == [
             provider: :resend,
             from: "auth@clubs-dev.memba.io",
             message_stream: "auth"
           ]

    assert Keyword.fetch!(Keyword.fetch!(runtime_config, :swoosh), :api_client) ==
             Swoosh.ApiClient.Req
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
