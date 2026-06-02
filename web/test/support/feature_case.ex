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

  def assert_eventually(assertion, opts \\ []) when is_function(assertion, 0) do
    timeout = Keyword.get(opts, :timeout, 1_000)
    interval = Keyword.get(opts, :interval, 10)
    deadline = System.monotonic_time(:millisecond) + timeout

    assert_eventually(assertion, deadline, interval)
  end

  def sign_in_staff(conn, email \\ "pat@memba.io") do
    Plug.Test.init_test_session(conn, %{
      MembaWeb.IdentityAuth.identity_session_key() => email
    })
  end

  defp assert_eventually(assertion, deadline, interval) do
    assertion.()
  rescue
    error in [ExUnit.AssertionError, KeyError] ->
      if System.monotonic_time(:millisecond) >= deadline do
        reraise error, __STACKTRACE__
      else
        Process.sleep(interval)
        assert_eventually(assertion, deadline, interval)
      end
  end
end
