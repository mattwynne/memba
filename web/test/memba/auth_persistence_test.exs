defmodule Memba.AuthPersistenceTest do
  use Memba.DataCase, async: true

  alias Memba.Repo

  test "magic token table stores only token hashes with expiry and consumption timestamps" do
    columns = auth_magic_token_columns()

    assert columns["email"] == %{data_type: "text", nullable?: false}
    assert columns["token_hash"] == %{data_type: "bytea", nullable?: false}
    assert columns["expires_at"].nullable? == false
    assert columns["consumed_at"].nullable? == true
    assert columns["inserted_at"].nullable? == false
    assert columns["updated_at"].nullable? == false

    refute Map.has_key?(columns, "token")
    refute Map.has_key?(columns, "plaintext_token")
  end

  test "magic token table indexes hashes uniquely and supports email and expiry lookups" do
    index_definitions = auth_magic_token_index_definitions()

    assert Enum.any?(index_definitions, fn definition ->
             definition =~ "UNIQUE INDEX" and definition =~ "(token_hash)"
           end)

    assert Enum.any?(index_definitions, &(&1 =~ "(email)"))
    assert Enum.any?(index_definitions, &(&1 =~ "(expires_at)"))
  end

  test "magic token rows can be consumed after being inserted" do
    token_hash = :crypto.hash(:sha256, "not stored as plaintext")
    expires_at = NaiveDateTime.utc_now() |> NaiveDateTime.add(15, :minute)

    result =
      Repo.query!(
        """
        INSERT INTO auth_magic_tokens (email, token_hash, expires_at, inserted_at, updated_at)
        VALUES ($1, $2, $3, now(), now())
        RETURNING id
        """,
        ["alice@example.com", token_hash, expires_at]
      )

    [[token_id]] = result.rows
    consumed_at = NaiveDateTime.utc_now()

    Repo.query!(
      """
      UPDATE auth_magic_tokens
      SET consumed_at = $1, updated_at = now()
      WHERE id = $2
      """,
      [consumed_at, token_id]
    )

    assert %{rows: [[^consumed_at]]} =
             Repo.query!(
               "SELECT consumed_at FROM auth_magic_tokens WHERE id = $1",
               [token_id]
             )
  end

  defp auth_magic_token_columns do
    result =
      Repo.query!("""
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'auth_magic_tokens'
      """)

    Map.new(result.rows, fn [name, data_type, is_nullable] ->
      {name, %{data_type: data_type, nullable?: is_nullable == "YES"}}
    end)
  end

  defp auth_magic_token_index_definitions do
    result =
      Repo.query!("""
      SELECT indexdef
      FROM pg_indexes
      WHERE schemaname = 'public' AND tablename = 'auth_magic_tokens'
      """)

    Enum.map(result.rows, fn [definition] -> definition end)
  end
end
