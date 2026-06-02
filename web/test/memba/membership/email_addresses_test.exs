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
end
