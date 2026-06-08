defmodule Memba.Membership.InvitationToken do
  @moduledoc """
  Opaque token helpers for club member invitations.

  Invitation tokens are separate from ordinary sign-in-link tokens because they
  grant club membership. Plaintext tokens are delivered to invitees and are not
  persisted; Membership stores only the SHA-256 hash encoded as lowercase hex.
  """

  @token_bytes 32
  @hash_pattern ~r/\A[0-9a-f]{64}\z/

  @doc """
  Generate an opaque URL-safe invitation token.
  """
  def generate_token do
    @token_bytes
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  @doc """
  Hash a plaintext invitation token for Membership-owned storage and lookup.
  """
  def hash_token(token) when is_binary(token) do
    :crypto.hash(:sha256, token)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Return whether a value has the expected stored invitation token hash shape.
  """
  def valid_hash?(token_hash) when is_binary(token_hash) do
    Regex.match?(@hash_pattern, token_hash)
  end

  def valid_hash?(_token_hash), do: false
end
