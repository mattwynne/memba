defmodule Memba.Accounts.MagicTokenPersistenceTest do
  use Memba.DataCase, async: true

  alias Memba.Accounts.MagicToken

  describe "accounts_magic_tokens persistence" do
    test "persists a hashed magic token with expiry and optional consumption timestamp" do
      expires_at = DateTime.add(DateTime.utc_now(), 15, :minute)
      consumed_at = DateTime.utc_now()
      token_hash = :crypto.hash(:sha256, "opaque token")

      token =
        Repo.insert!(%MagicToken{
          email: "member@example.com",
          token_hash: token_hash,
          expires_at: expires_at,
          consumed_at: consumed_at
        })

      assert token.magic_token_id
      assert token.email == "member@example.com"
      assert token.token_hash == token_hash
      assert DateTime.compare(token.expires_at, expires_at) == :eq
      assert DateTime.compare(token.consumed_at, consumed_at) == :eq
      assert token.inserted_at
      assert token.updated_at
    end

    test "stores token hashes uniquely and has no plaintext token field" do
      fields = MagicToken.__schema__(:fields)

      assert :token_hash in fields
      refute :token in fields

      token_hash = :crypto.hash(:sha256, "single use token")
      expires_at = DateTime.add(DateTime.utc_now(), 15, :minute)

      Repo.insert!(%MagicToken{
        email: "first@example.com",
        token_hash: token_hash,
        expires_at: expires_at
      })

      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%MagicToken{
          email: "second@example.com",
          token_hash: token_hash,
          expires_at: expires_at
        })
      end
    end

    for {field, column} <- [
          {:email, "email"},
          {:token_hash, "token_hash"},
          {:expires_at, "expires_at"}
        ] do
      test "requires #{column}" do
        attrs = Map.delete(valid_magic_token_attrs(), unquote(field))

        assert_raise Postgrex.Error, ~r/null value in column "#{unquote(column)}"/, fn ->
          MagicToken
          |> struct!(attrs)
          |> Repo.insert!()
        end
      end
    end
  end

  defp valid_magic_token_attrs do
    %{
      email: "member@example.com",
      token_hash: :crypto.hash(:sha256, "required fields"),
      expires_at: DateTime.add(DateTime.utc_now(), 15, :minute)
    }
  end
end
