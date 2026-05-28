defmodule Memba.DependencyContractTest do
  use ExUnit.Case, async: true

  @expected_modules [
    Commanded,
    Commanded.EventStore.Adapters.EventStore,
    EventStore,
    Commanded.Projections.Ecto,
    Cucumber
  ]

  test "event-sourced foundation dependencies are available" do
    for module <- @expected_modules do
      assert Code.ensure_loaded?(module), "Expected #{inspect(module)} to be loadable"
    end
  end
end
