defmodule Memba.Membership.InvitationIssuanceWorkflow do
  @moduledoc """
  Coordinate issue/resend preparation and a single command dispatch.

  Repeat invites may resolve to a resend of an existing pending invitation, so
  callers must not assume a prepared invite always targets their proposed ID.
  Delivery remains the caller's responsibility after a successful dispatch.
  """

  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.InvitationIssuance

  def invite(attrs, dispatch_opts) do
    with {:ok, command, token} <- InvitationIssuance.prepare_invite(attrs) do
      dispatch_with_token(command, token, dispatch_opts)
    end
  end

  def resend(attrs, dispatch_opts) do
    with {:ok, command, token} <- InvitationIssuance.prepare_resend(attrs) do
      dispatch_with_token(command, token, dispatch_opts)
    end
  end

  defp dispatch_with_token(command, token, dispatch_opts) do
    case CommandDispatch.dispatch(command, dispatch_opts) do
      :ok ->
        {:ok, %{invitation_id: command.invitation_id, invitation_token: token}}

      {:ok, result} ->
        {:ok,
         %{
           invitation_id: command.invitation_id,
           invitation_token: token,
           execution_result: result
         }}

      {:error, _reason} = error ->
        error
    end
  end
end
