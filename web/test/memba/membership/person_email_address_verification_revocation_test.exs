defmodule Memba.Membership.PersonEmailAddressVerificationRevocationTest do
  use ExUnit.Case, async: true

  alias Memba.Membership.PersonEmailAddressVerificationRevocation, as: Revocation

  test "does not revoke on failed dispatch and preserves the error" do
    revoker = fn _request -> flunk("must not revoke after failed dispatch") end

    assert {:error, :email_address_not_found} =
             Revocation.after_dispatch({:error, :email_address_not_found}, [%{}], revoker)
  end

  test "returns original dispatch result after successful revocation" do
    parent = self()
    requests = [%{email: "first@example.com"}, %{email: "second@example.com"}]

    revoker = fn request ->
      send(parent, {:revoked, request.email})
      {:ok, :revoked}
    end

    result = {:ok, :aggregate_version}

    assert ^result = Revocation.after_dispatch(result, requests, revoker)
    assert_receive {:revoked, "first@example.com"}
    assert_receive {:revoked, "second@example.com"}
    assert :ok = Revocation.after_dispatch(:ok, [], :invalid_revoker)
  end

  test "propagates revocation failure after dispatch success" do
    assert {:error, :revocation_failed} =
             Revocation.after_dispatch(:ok, [%{}], fn _ -> {:error, :revocation_failed} end)

    assert {:error, :invalid_email_address_verification_revoker} =
             Revocation.after_dispatch(:ok, [%{}], :invalid_revoker)
  end

  test "removes revoker from command dispatch options" do
    revoker = fn _ -> :ok end

    assert {^revoker, [consistency: :strong]} =
             Revocation.revoker(verification_revoker: revoker, consistency: :strong)
  end
end
