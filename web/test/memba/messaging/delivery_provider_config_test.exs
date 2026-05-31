defmodule Memba.Messaging.DeliveryProviderConfigTest do
  use ExUnit.Case, async: true

  alias Memba.Messaging.DeliveryProviderConfig
  alias Memba.Messaging.DeliveryProviders.Fake
  alias Memba.Messaging.DeliveryProviders.Postmark

  test "does not override the configured provider when no explicit provider is named" do
    assert DeliveryProviderConfig.provider_override(nil) == :default
    assert DeliveryProviderConfig.provider_override("") == :default
    assert DeliveryProviderConfig.provider_override("   ") == :default
  end

  test "selects the fake provider only when explicitly named" do
    assert DeliveryProviderConfig.provider_override("fake") == {:ok, Fake}
  end

  test "selects the Postmark provider only when explicitly named" do
    assert DeliveryProviderConfig.provider_override("postmark") == {:ok, Postmark}
  end

  test "rejects unknown provider names" do
    assert {:error, message} = DeliveryProviderConfig.provider_override("smtp")

    assert message =~ "Unsupported MEMBA_MESSAGING_DELIVERY_PROVIDER"
    assert message =~ "fake"
    assert message =~ "postmark"
  end
end
