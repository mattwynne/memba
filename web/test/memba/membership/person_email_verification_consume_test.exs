defmodule Memba.Membership.PersonEmailVerificationConsumeTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.EmailAddressVerificationToken
  alias Memba.Membership.PersonCommands
  alias Memba.Membership.PersonEmailAddressCommands
  alias Memba.Membership.PersonEmailVerification

  test "consume/2 rejects expired and non-pending tokens" do
    person_id = Memba.ID.generate(:person)
    issued_at = ~U[2026-07-13 21:30:00.000000Z]

    assert :ok =
             (with {:ok, command} <-
                     PersonCommands.prepare_create(%{
                       person_id: person_id,
                       name: "Alice",
                       email: "alice@example.com"
                     }) do
                CommandDispatch.dispatch(command, consistency: :strong)
              end)

    assert :ok =
             (with {:ok, command} <-
                     PersonEmailAddressCommands.prepare_add(%{
                       person_id: person_id,
                       email: "alice+new@example.com"
                     }) do
                CommandDispatch.dispatch(command, consistency: :strong)
              end)

    assert {:ok, %{issuer_result: %{token: expired_token}}} =
             PersonEmailVerification.resend(
               %{person_id: person_id, email: "alice+new@example.com"},
               now: issued_at
             )

    assert {:error, :expired} =
             PersonEmailVerification.consume(expired_token,
               now: DateTime.add(issued_at, 15 * 60, :second)
             )

    assert {:ok, %{issuer_result: %{token: verified_token}}} =
             PersonEmailVerification.resend(
               %{person_id: person_id, email: "alice+new@example.com"},
               now: issued_at
             )

    assert :ok =
             PersonEmailVerification.verify(
               %{person_id: person_id, email: "alice+new@example.com"},
               consistency: :strong
             )

    assert {:error, :email_address_already_verified} =
             PersonEmailVerification.consume(verified_token,
               now: DateTime.add(issued_at, 60, :second)
             )
  end

  test "old verification tokens cannot verify removed and re-added pending addresses" do
    person_id = Memba.ID.generate(:person)
    now = ~U[2026-07-13 22:00:00.000000Z]

    assert :ok =
             (with {:ok, command} <-
                     PersonCommands.prepare_create(%{
                       person_id: person_id,
                       name: "Alice",
                       email: "alice@example.com"
                     }) do
                CommandDispatch.dispatch(command, consistency: :strong)
              end)

    assert :ok =
             (with {:ok, command} <-
                     PersonEmailAddressCommands.prepare_add(%{
                       person_id: person_id,
                       email: "alice+stale@example.com"
                     }) do
                CommandDispatch.dispatch(command, consistency: :strong)
              end)

    assert {:ok, %{issuer_result: %{token: stale_token}}} =
             PersonEmailVerification.resend(
               %{person_id: person_id, email: "alice+stale@example.com"},
               now: now
             )

    stale_token_hash = :crypto.hash(:sha256, stale_token)

    assert :ok =
             PersonEmailVerification.remove(
               %{person_id: person_id, email: "alice+stale@example.com"},
               consistency: :strong
             )

    assert %EmailAddressVerificationToken{revoked_at: %DateTime{}} =
             Repo.get_by(EmailAddressVerificationToken, token_hash: stale_token_hash)

    assert :ok =
             (with {:ok, command} <-
                     PersonEmailAddressCommands.prepare_add(%{
                       person_id: person_id,
                       email: "alice+stale@example.com"
                     }) do
                CommandDispatch.dispatch(command, consistency: :strong)
              end)

    assert {:error, :revoked} =
             PersonEmailVerification.consume(stale_token,
               now: DateTime.add(now, 60, :second)
             )
  end
end
