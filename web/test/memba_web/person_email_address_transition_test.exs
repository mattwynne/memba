defmodule MembaWeb.PersonEmailAddressTransitionTest do
  use ExUnit.Case, async: true

  alias MembaWeb.PersonEmailAddressTransition

  test "failed dispatch preserves error and never revokes pending tokens" do
    parent = self()
    command = %{person_id: "person"}
    request = %{email: "pending@example.com"}

    dispatcher = fn ^command, opts ->
      send(parent, {:dispatch_opts, opts})
      {:error, :email_address_not_found}
    end

    revoker = fn _request -> flunk("must not revoke after failed dispatch") end

    assert {:error, :email_address_not_found} =
             PersonEmailAddressTransition.dispatch_prepared(
               {:ok, command, [request]},
               [consistency: :strong, verification_revoker: revoker],
               dispatcher
             )

    assert_receive {:dispatch_opts, [consistency: :strong]}

    # A retry still has its pending token: only the successful attempt revokes it.
    assert :ok =
             PersonEmailAddressTransition.dispatch_prepared(
               {:ok, command, [request]},
               [
                 consistency: :strong,
                 verification_revoker: fn received ->
                   send(parent, {:revoked_on_retry, received})
                   :ok
                 end
               ],
               fn ^command, _opts -> :ok end
             )

    assert_receive {:revoked_on_retry, ^request}
  end

  test "successful dispatch revokes requests and preserves the original result" do
    parent = self()
    command = %{person_id: "person"}
    request = %{email: "pending@example.com"}
    result = {:ok, :aggregate_version}

    dispatcher = fn ^command, opts ->
      send(parent, {:dispatch_opts, opts})
      result
    end

    revoker = fn received ->
      send(parent, {:revoked, received})
      :ok
    end

    assert ^result =
             PersonEmailAddressTransition.dispatch_prepared(
               {:ok, command, [request]},
               [consistency: :strong, verification_revoker: revoker],
               dispatcher
             )

    assert_receive {:dispatch_opts, [consistency: :strong]}
    assert_receive {:revoked, ^request}
  end

  test "preparation failure neither dispatches nor revokes" do
    assert {:error, :invalid_person_id} =
             PersonEmailAddressTransition.dispatch_prepared(
               {:error, :invalid_person_id},
               [verification_revoker: fn _ -> flunk("must not revoke") end],
               fn _, _ -> flunk("must not dispatch") end
             )
  end

  test "revocation errors propagate after a successful dispatch" do
    assert {:error, :revocation_failed} =
             PersonEmailAddressTransition.dispatch_prepared(
               {:ok, :command, [%{email: "pending@example.com"}]},
               [verification_revoker: fn _ -> {:error, :revocation_failed} end],
               fn :command, _ -> :ok end
             )
  end
end
