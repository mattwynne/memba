defmodule MembaWeb.FeatureCase do
  @moduledoc """
  Test case for feature-style Phoenix web tests that exercise event-sourced flows.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint MembaWeb.Endpoint

      use MembaWeb, :verified_routes

      import Phoenix.ConnTest
      import PhoenixTest
      import MembaWeb.FeatureCase
    end
  end

  setup tags do
    Memba.EventSourcedCase.setup_event_sourced_sandbox(tags)

    {:ok, conn: Phoenix.ConnTest.build_conn() |> PhoenixTest.put_endpoint(MembaWeb.Endpoint)}
  end
end
