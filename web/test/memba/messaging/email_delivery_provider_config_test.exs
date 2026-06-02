defmodule Memba.Messaging.EmailDeliveryProviderConfigTest do
  use ExUnit.Case, async: true

  alias Memba.Messaging.EmailDeliveryProviderConfig
  alias Memba.Messaging.EmailDeliveryProviders.Fake
  alias Memba.Messaging.EmailDeliveryProviders.Postmark
  alias Memba.Messaging.EmailDeliveryProviders.Resend

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
end
