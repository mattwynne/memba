defmodule Memba.Membership.EmailAddressesTest do
  use ExUnit.Case, async: true

  alias Memba.Membership.EmailAddresses

  describe "validate_set/1" do
    test "normalizes trimmed display email, lowercase lookup email, and primary flags" do
      assert {:ok,
              [
                %{
                  email: "Alice@Example.COM",
                  normalized_email: "alice@example.com",
                  is_primary: true
                },
                %{
                  email: "alice@work.example",
                  normalized_email: "alice@work.example",
                  is_primary: false
                }
              ]} =
               EmailAddresses.validate_set([
                 %{email: " Alice@Example.COM ", is_primary: true},
                 %{"email" => "alice@work.example", "is_primary" => "false"}
               ])
    end

    test "rejects an empty set before projection writes" do
      assert {:error, :email_address_required} = EmailAddresses.validate_set([])
    end

    test "rejects sets without exactly one primary email address" do
      assert {:error, :exactly_one_primary_email_required} =
               EmailAddresses.validate_set([
                 %{email: "alice@example.com", is_primary: false},
                 %{email: "alice@work.example", is_primary: false}
               ])

      assert {:error, :exactly_one_primary_email_required} =
               EmailAddresses.validate_set([
                 %{email: "alice@example.com", is_primary: true},
                 %{email: "alice@work.example", is_primary: true}
               ])
    end

    test "rejects blank, malformed, and duplicated normalized email addresses" do
      assert {:error, :invalid_email} =
               EmailAddresses.validate_set([%{email: "  ", is_primary: true}])

      assert {:error, :invalid_email} =
               EmailAddresses.validate_set([%{email: "alice.example.com", is_primary: true}])

      assert {:error, :invalid_email} =
               EmailAddresses.validate_set([%{email: "alice bob@example.com", is_primary: true}])

      assert {:error, :duplicate_email_address} =
               EmailAddresses.validate_set([
                 %{email: "Alice@Example.COM", is_primary: true},
                 %{email: " alice@example.com ", is_primary: false}
               ])
    end
  end

  test "normalize_primary_email/1 validates the legacy single-email CreatePerson command shape" do
    assert {:ok, "alice@example.com"} =
             EmailAddresses.normalize_primary_email(" Alice@Example.COM ")

    assert {:error, :invalid_email} = EmailAddresses.normalize_primary_email("alice.example.com")
  end

  describe "write-side address state transitions" do
    test "marks a legacy replace-all set as verified aggregate state" do
      verified_at = ~U[2026-07-13 17:00:00Z]

      assert {:ok,
              [
                %{
                  email: "Alice@Example.COM",
                  normalized_email: "alice@example.com",
                  is_primary: true,
                  verified_at: ^verified_at
                },
                %{
                  email: "alice@work.example",
                  normalized_email: "alice@work.example",
                  is_primary: false,
                  verified_at: ^verified_at
                }
              ]} =
               EmailAddresses.mark_all_verified(
                 [
                   %{email: " Alice@Example.COM ", is_primary: true},
                   %{email: "alice@work.example", is_primary: false}
                 ],
                 verified_at
               )
    end

    test "adds a new address as pending and non-primary" do
      verified_at = ~U[2026-07-13 17:00:00Z]
      {:ok, addresses} = verified_addresses(verified_at)

      assert {:ok,
              [
                %{
                  normalized_email: "alice@example.com",
                  is_primary: true,
                  verified_at: ^verified_at
                },
                %{
                  email: "Alice+New@Example.COM",
                  normalized_email: "alice+new@example.com",
                  is_primary: false,
                  verified_at: nil
                }
              ]} = EmailAddresses.add_pending(addresses, " Alice+New@Example.COM ")
    end

    test "rejects duplicate pending additions within the aggregate state" do
      {:ok, addresses} = verified_addresses()

      assert {:error, :duplicate_email_address} =
               EmailAddresses.add_pending(addresses, " ALICE@EXAMPLE.COM ")
    end

    test "verifies a still-pending address by normalized address" do
      verified_at = ~U[2026-07-13 17:00:00Z]
      {:ok, addresses} = verified_addresses()
      {:ok, addresses} = EmailAddresses.add_pending(addresses, "Alice+New@Example.COM")

      assert {:ok,
              [
                %{normalized_email: "alice@example.com", verified_at: %DateTime{}},
                %{
                  normalized_email: "alice+new@example.com",
                  is_primary: false,
                  verified_at: ^verified_at
                }
              ]} = EmailAddresses.verify(addresses, " alice+new@example.com ", verified_at)
    end

    test "only verified addresses can become primary" do
      verified_at = ~U[2026-07-13 17:00:00Z]
      {:ok, addresses} = verified_addresses(verified_at)
      {:ok, addresses} = EmailAddresses.add_pending(addresses, "alice+new@example.com")

      assert {:error, :email_address_not_verified} =
               EmailAddresses.make_primary(addresses, "alice+new@example.com")

      {:ok, addresses} = EmailAddresses.verify(addresses, "alice+new@example.com", verified_at)

      assert {:ok,
              [
                %{normalized_email: "alice@example.com", is_primary: false},
                %{normalized_email: "alice+new@example.com", is_primary: true}
              ]} = EmailAddresses.make_primary(addresses, "alice+new@example.com")
    end

    test "removes non-primary addresses but keeps the primary address" do
      {:ok, addresses} = verified_addresses()
      {:ok, addresses} = EmailAddresses.add_pending(addresses, "alice+new@example.com")

      assert {:error, :primary_email_address_cannot_be_removed} =
               EmailAddresses.remove_non_primary(addresses, "alice@example.com")

      assert {:ok, [%{normalized_email: "alice@example.com", is_primary: true}]} =
               EmailAddresses.remove_non_primary(addresses, "alice+new@example.com")
    end
  end

  defp verified_addresses(verified_at \\ ~U[2026-07-13 16:00:00Z]) do
    EmailAddresses.mark_all_verified(
      [%{email: "alice@example.com", is_primary: true}],
      verified_at
    )
  end
end
