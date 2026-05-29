defmodule Memba.EventSourcedConfigTest do
  use ExUnit.Case, async: true

  test "EventStore is registered for mix event_store tasks" do
    assert Application.fetch_env!(:memba, :event_stores) == [Memba.EventStore]
  end

  test "Membership Commanded app is configured to use the Postgres EventStore adapter" do
    config = Application.fetch_env!(:memba, Memba.Membership.App)

    assert config[:event_store] == [
             adapter: Commanded.EventStore.Adapters.EventStore,
             event_store: Memba.EventStore
           ]

    assert config[:pubsub] == :local
    assert config[:registry] == :local
  end

  test "Messaging Commanded app is configured to use the Postgres EventStore adapter" do
    config = Application.fetch_env!(:memba, Memba.Messaging.App)

    assert config[:event_store] == [
             adapter: Commanded.EventStore.Adapters.EventStore,
             event_store: Memba.Messaging.EventStore
           ]

    assert config[:pubsub] == :local
    assert config[:registry] == :local
  end

  test "Membership EventStore uses the test database in a dedicated schema" do
    config = Memba.EventStore.config()

    assert config[:serializer] == Commanded.Serialization.JsonSerializer
    assert config[:database] == "memba_test#{System.get_env("MIX_TEST_PARTITION")}"
    assert config[:schema] == "event_store"
  end

  test "Messaging EventStore uses the test database in the dedicated EventStore schema" do
    config = Memba.Messaging.EventStore.config()

    assert config[:serializer] == Commanded.Serialization.JsonSerializer
    assert config[:database] == "memba_test#{System.get_env("MIX_TEST_PARTITION")}"
    assert config[:schema] == "event_store"
  end

  test "commanded_ecto_projections stays in the application schema" do
    assert Application.fetch_env!(:commanded_ecto_projections, :schema_prefix) == nil
  end
end
