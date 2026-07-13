defmodule Memba.Membership.EmailAddressVerificationTokenTest do
  use Memba.DataCase, async: true

  alias Memba.Membership.EmailAddressVerificationToken
  alias Memba.Membership.Projections.Person
  alias Memba.Repo

  test "uses a dedicated store instead of auth sign-in token storage" do
    assert EmailAddressVerificationToken.__schema__(:source) ==
             "membership_person_email_address_verification_tokens"

    refute EmailAddressVerificationToken.__schema__(:source) == "auth_sign_in_tokens"
  end

  test "verification token table stores only hashed token material and person email-address scope" do
    columns = verification_token_columns()

    assert columns["person_id"] == %{data_type: "text", nullable?: false}
    assert columns["normalized_email"] == %{data_type: "text", nullable?: false}
    assert columns["token_hash"] == %{data_type: "bytea", nullable?: false}
    assert columns["expires_at"].nullable? == false
    assert columns["consumed_at"].nullable? == true
    assert columns["revoked_at"].nullable? == true
    assert columns["inserted_at"].nullable? == false
    assert columns["updated_at"].nullable? == false

    refute Map.has_key?(columns, "token")
    refute Map.has_key?(columns, "plaintext_token")
    refute Map.has_key?(columns, "email")
  end

  test "verification token table indexes token hashes and person address scope" do
    index_definitions = verification_token_index_definitions()

    assert Enum.any?(index_definitions, fn definition ->
             definition =~ "UNIQUE INDEX" and definition =~ "(token_hash)"
           end)

    assert Enum.any?(index_definitions, &(&1 =~ "(person_id, normalized_email)"))
    assert Enum.any?(index_definitions, &(&1 =~ "(expires_at)"))
  end

  test "verification token rows can be persisted through the dedicated schema" do
    person_id = Memba.ID.generate(:person)
    expires_at = DateTime.utc_now() |> DateTime.add(15, :minute)
    token_hash = :crypto.hash(:sha256, "not stored as plaintext")

    Repo.insert!(%Person{person_id: person_id, name: "Alice", email: "alice@example.com"})

    assert {:ok,
            %EmailAddressVerificationToken{
              person_id: ^person_id,
              normalized_email: "alice@example.com",
              token_hash: ^token_hash,
              expires_at: ^expires_at,
              consumed_at: nil,
              revoked_at: nil
            }} =
             %{
               person_id: person_id,
               normalized_email: "alice@example.com",
               token_hash: token_hash,
               expires_at: expires_at
             }
             |> EmailAddressVerificationToken.create_changeset()
             |> Repo.insert()
  end

  defp verification_token_columns do
    result =
      Repo.query!("""
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'membership_person_email_address_verification_tokens'
      """)

    Map.new(result.rows, fn [name, data_type, is_nullable] ->
      {name, %{data_type: data_type, nullable?: is_nullable == "YES"}}
    end)
  end

  defp verification_token_index_definitions do
    result =
      Repo.query!("""
      SELECT indexdef
      FROM pg_indexes
      WHERE schemaname = 'public'
        AND tablename = 'membership_person_email_address_verification_tokens'
      """)

    Enum.map(result.rows, fn [definition] -> definition end)
  end
end
