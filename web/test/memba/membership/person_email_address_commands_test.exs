defmodule Memba.Membership.PersonEmailAddressCommandsTest do
  use ExUnit.Case, async: true

  alias Memba.Membership.PersonEmailAddressCommands
  alias Memba.Membership.Commands.{VerifyPersonEmailAddress, MakePersonEmailAddressPrimary}

  test "verify preparation preserves supplied timestamp and string-key attributes" do
    verified_at = DateTime.utc_now(:microsecond)

    assert {:ok,
            %VerifyPersonEmailAddress{
              person_id: "person",
              email: "a@example.com",
              verified_at: ^verified_at
            }} =
             PersonEmailAddressCommands.prepare_verify(%{
               "person_id" => "person",
               "email" => "a@example.com",
               "verified_at" => verified_at
             })

    assert {:error, :invalid_verified_at} =
             PersonEmailAddressCommands.prepare_verify(%{
               person_id: "person",
               email: "a@example.com",
               verified_at: "now"
             })
  end

  test "primary preparation does not preempt aggregate verification checks" do
    assert {:ok,
            %MakePersonEmailAddressPrimary{person_id: "person", email: "pending@example.com"}} =
             PersonEmailAddressCommands.prepare_make_primary(%{
               person_id: "person",
               email: "pending@example.com"
             })
  end

  test "missing attributes retain public API error shape before querying projections" do
    assert {:error, {:missing_required_attribute, :email}} =
             PersonEmailAddressCommands.prepare_add(%{person_id: "person"})

    assert {:error, {:missing_required_attribute, :email_addresses}} =
             PersonEmailAddressCommands.prepare_replace(%{"person_id" => "person"})

    assert {:error, {:missing_required_attribute, :person_id}} =
             PersonEmailAddressCommands.prepare_remove(%{email: "a@example.com"})
  end
end
