defmodule Memba.Membership.InvitationTokenTest do
  use ExUnit.Case, async: true

  alias Memba.Membership.InvitationToken

  test "generate_token/0 returns an opaque URL-safe token" do
    token = InvitationToken.generate_token()

    assert is_binary(token)
    assert byte_size(token) >= 40
    refute token =~ "="
  end

  test "hash_token/1 returns a lower-case SHA-256 hex digest" do
    token_hash = InvitationToken.hash_token("one-use invitation token")

    assert byte_size(token_hash) == 64
    assert token_hash == String.downcase(token_hash)
    assert InvitationToken.valid_hash?(token_hash)
  end

  test "valid_hash?/1 rejects malformed values" do
    refute InvitationToken.valid_hash?(nil)
    refute InvitationToken.valid_hash?("")
    refute InvitationToken.valid_hash?("not-a-hash")
    refute InvitationToken.valid_hash?(String.duplicate("A", 64))
  end
end
