defmodule MembaWeb.PersonEmailAddressTransition do
  @moduledoc """
  Complete a prepared person email replacement or removal from a web workflow.

  Preparation remains in Membership; this boundary dispatches once and revokes
  pending verification tokens only after a successful command dispatch.
  """

  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.PersonEmailAddressVerificationRevocation, as: Revocation

  def dispatch_prepared(preparation, opts, dispatcher \\ &CommandDispatch.dispatch/2)

  def dispatch_prepared({:ok, command, requests}, opts, dispatcher) when is_list(opts) do
    {revoker, dispatch_opts} = Revocation.revoker(opts)

    command
    |> dispatcher.(dispatch_opts)
    |> Revocation.after_dispatch(requests, revoker)
  end

  def dispatch_prepared({:error, _reason} = error, _opts, _dispatcher), do: error
end
