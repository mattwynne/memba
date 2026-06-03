defmodule Memba.Messaging.EmailDeliveryProviderConfigTest do
  use ExUnit.Case, async: false

  alias Memba.Messaging.EmailDeliveryProviderConfig
  alias Memba.Messaging.EmailDeliveryProviders.Fake
  alias Memba.Messaging.EmailDeliveryProviders.Postmark
  alias Memba.Messaging.EmailDeliveryProviders.Resend

  @runtime_env_keys [
    "MEMBA_MESSAGING_DELIVERY_PROVIDER",
    "MEMBA_POSTMARK_SERVER_TOKEN",
    "MEMBA_POSTMARK_FROM_ADDRESS",
    "MEMBA_POSTMARK_REPLY_TO_ADDRESS",
    "MEMBA_AUTH_EMAIL_PROVIDER",
    "MEMBA_AUTH_EMAIL_FROM_ADDRESS",
    "MEMBA_AUTH_EMAIL_MESSAGE_STREAM",
    "MEMBA_RESEND_API_KEY",
    "MEMBA_RESEND_WEBHOOK_SIGNING_SECRET"
  ]

  test "does not override the configured provider when no explicit provider is named" do
    assert EmailDeliveryProviderConfig.provider_override(nil) == :default
    assert EmailDeliveryProviderConfig.provider_override("") == :default
    assert EmailDeliveryProviderConfig.provider_override("   ") == :default
  end

  test "selects the fake provider only when explicitly named" do
    assert EmailDeliveryProviderConfig.provider_override("fake") == {:ok, Fake}
  end

  test "selects the Postmark provider only when explicitly named" do
    assert EmailDeliveryProviderConfig.provider_override("postmark") == {:ok, Postmark}
  end

  test "selects the Resend provider only when explicitly named" do
    assert EmailDeliveryProviderConfig.provider_override("resend") == {:ok, Resend}
  end

  test "rejects unknown provider names" do
    assert {:error, message} = EmailDeliveryProviderConfig.provider_override("smtp")

    assert message =~ "Unsupported MEMBA_MESSAGING_DELIVERY_PROVIDER"
    assert message =~ "fake"
    assert message =~ "postmark"
    assert message =~ "resend"
  end

  test "runtime config selects Postmark messaging delivery and configures the shared mailer path" do
    runtime_config =
      read_runtime_config(%{
        "MEMBA_MESSAGING_DELIVERY_PROVIDER" => "postmark",
        "MEMBA_POSTMARK_SERVER_TOKEN" => "server-token",
        "MEMBA_POSTMARK_FROM_ADDRESS" => "messages@mail.memba.io",
        "MEMBA_POSTMARK_REPLY_TO_ADDRESS" => "help@memba.io"
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
