defmodule Memba.Membership.PersonEmailVerificationResendTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.EmailAddressVerificationToken
  alias Memba.Membership.PersonCommands
  alias Memba.Membership.PersonEmailAddressCommands
  alias Memba.Membership.PersonEmailVerification
  alias Memba.Membership.PersonQueries

  test "resend/2 issues for pending address without appending a domain event" do
    person_id = Memba.ID.generate(:person)
    parent = self()

    assert {:ok, command} =
             PersonCommands.prepare_create(%{
               person_id: person_id,
               name: "Alice",
               email: "alice@example.com"
             })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    assert {:ok, command} =
             PersonEmailAddressCommands.prepare_add(%{
               person_id: person_id,
               email: " Alice+New@Example.COM "
             })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    %{rows: [[events_before]]} = Repo.query!(~S|SELECT count(*) FROM "event_store"."events"|)

    verification_issuer = fn request ->
      send(parent, {:verification_issued, request})
      {:ok, %{verification_token: "fresh-token"}}
    end

    assert {:ok,
            %{
              person_id: ^person_id,
              email: "Alice+New@Example.COM",
              normalized_email: "alice+new@example.com",
              issuer_result: %{verification_token: "fresh-token"}
            }} =
             PersonEmailVerification.resend(
               %{person_id: person_id, email: " alice+new@example.com "},
               verification_issuer: verification_issuer
             )

    assert_received {:verification_issued,
                     %{
                       person_id: ^person_id,
                       email: "Alice+New@Example.COM",
                       normalized_email: "alice+new@example.com"
                     }}

    assert %{rows: [[^events_before]]} =
             Repo.query!(~S|SELECT count(*) FROM "event_store"."events"|)

    assert %{normalized_email: "alice+new@example.com", verified_at: nil} =
             person_id
             |> PersonQueries.list_person_email_addresses()
             |> Enum.find(&(&1.normalized_email == "alice+new@example.com"))
  end

  test "resend/2 rejects non-pending addresses before issuing" do
    person_id = Memba.ID.generate(:person)

    assert {:ok, command} =
             PersonCommands.prepare_create(%{
               person_id: person_id,
               name: "Alice",
               email: "alice@example.com"
             })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    verification_issuer = fn _request ->
      flunk("verified primary addresses must not receive verification email")
    end

    assert {:error, :email_address_already_verified} =
             PersonEmailVerification.resend(
               %{person_id: person_id, email: "alice@example.com"},
               verification_issuer: verification_issuer
             )
  end

  test "verification issuer injection preserves result and error shapes without dispatch" do
    person_id = Memba.ID.generate(:person)

    assert {:ok, command} =
             PersonCommands.prepare_create(%{
               person_id: person_id,
               name: "Alice",
               email: "alice@example.com"
             })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    assert {:ok, command} =
             PersonEmailAddressCommands.prepare_add(%{
               person_id: person_id,
               email: "pending@example.com"
             })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    request = %{person_id: person_id, email: "pending@example.com"}
    %{rows: [[events_before]]} = Repo.query!(~S|SELECT count(*) FROM "event_store"."events"|)

    assert {:ok, %{person_id: ^person_id, normalized_email: "pending@example.com"}} =
             PersonEmailVerification.resend(request,
               verification_issuer: fn _ -> :ok end
             )

    assert {:error, :delivery_failed} =
             PersonEmailVerification.resend(request,
               verification_issuer: fn _ -> {:error, :delivery_failed} end
             )

    assert {:error, :invalid_email_address_verification_issuer} =
             PersonEmailVerification.resend(request,
               verification_issuer: :invalid
             )

    assert {:error, {:unexpected_email_address_verification_issuer_result, :unexpected}} =
             PersonEmailVerification.resend(request,
               verification_issuer: fn _ -> :unexpected end
             )

    assert %{rows: [[^events_before]]} =
             Repo.query!(~S|SELECT count(*) FROM "event_store"."events"|)
  end

  test "resend/2 stores a scoped 15-minute one-use token" do
    person_id = Memba.ID.generate(:person)
    now = ~U[2026-07-13 21:00:00.000000Z]
    consumed_at = DateTime.add(now, 60, :second)

    assert {:ok, command} =
             PersonCommands.prepare_create(%{
               person_id: person_id,
               name: "Alice",
               email: "alice@example.com"
             })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    assert {:ok, command} =
             PersonEmailAddressCommands.prepare_add(%{
               person_id: person_id,
               email: " Alice+New@Example.COM "
             })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    assert {:ok,
            %{
              person_id: ^person_id,
              email: "Alice+New@Example.COM",
              normalized_email: "alice+new@example.com",
              issuer_result: %{
                token: token,
                expires_at: expires_at
              }
            }} =
             PersonEmailVerification.resend(
               %{person_id: person_id, email: "alice+new@example.com"},
               now: now
             )

    assert is_binary(token)
    assert expires_at == DateTime.add(now, 15 * 60, :second)

    assert %EmailAddressVerificationToken{
             person_id: ^person_id,
             normalized_email: "alice+new@example.com",
             token_hash: token_hash,
             expires_at: ^expires_at,
             consumed_at: nil,
             revoked_at: nil
           } =
             Repo.get_by(EmailAddressVerificationToken,
               person_id: person_id,
               normalized_email: "alice+new@example.com"
             )

    assert token_hash == :crypto.hash(:sha256, token)
    refute token_hash == token

    assert {:ok,
            %{
              person_id: ^person_id,
              email: "Alice+New@Example.COM",
              normalized_email: "alice+new@example.com"
            }} =
             PersonEmailVerification.consume(token, now: consumed_at)

    assert %EmailAddressVerificationToken{consumed_at: ^consumed_at} =
             Repo.get_by(EmailAddressVerificationToken, token_hash: token_hash)

    assert {:error, :consumed} =
             PersonEmailVerification.consume(token,
               now: DateTime.add(consumed_at, 1, :second)
             )
  end
end
