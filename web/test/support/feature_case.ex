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
      import Memba.MembershipFixtures
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
    normalized_email = Memba.Accounts.normalize_email(email)

    if is_nil(Memba.Membership.get_person_by_email(normalized_email)) do
      Memba.MembershipFixtures.insert_membership_person!(
        name: staff_name_from_email(normalized_email),
        email: normalized_email
      )
    end

    Plug.Test.init_test_session(conn, %{
      MembaWeb.IdentityAuth.identity_session_key() => normalized_email
    })
  end

  defp staff_name_from_email(email) do
    email
    |> String.split("@")
    |> List.first()
    |> String.replace(~r/[^a-z0-9]+/i, " ")
    |> String.trim()
    |> String.split(" ", trim: true)
    |> Enum.map_join(" ", &String.capitalize/1)
    |> case do
      "" -> "Memba Staff"
      name -> name
    end
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
