defmodule Memba.Membership.PersonEmailVerificationSignInTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.PersonCommands
  alias Memba.Membership.PersonEmailAddressCommands
  alias Memba.Membership.PersonEmailVerification
  alias Memba.Membership.PersonQueries
  alias Memba.Membership.Projections.Person, as: PersonProjection
  alias Memba.Membership.Projections.PersonEmailAddress

  test "verify_for_sign_in/2 verifies a pending known address without making it primary" do
    person_id = Memba.ID.generate(:person)

    assert {:ok, command} =
             PersonCommands.prepare_create(%{
               person_id: person_id,
               name: "Alice",
               email: "alice.primary@example.com"
             })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    assert {:ok, command} =
             PersonEmailAddressCommands.prepare_add(%{
               person_id: person_id,
               email: "Alice.Pending@Example.COM"
             })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    assert %PersonEmailAddress{verified_at: nil, is_primary: false} =
             Repo.get_by(PersonEmailAddress,
               person_id: person_id,
               normalized_email: "alice.pending@example.com"
             )

    assert :ok =
             PersonEmailVerification.verify_for_sign_in(
               " ALICE.PENDING@example.com ",
               consistency: :strong
             )

    assert %PersonEmailAddress{verified_at: %DateTime{}, is_primary: false} =
             Repo.get_by(PersonEmailAddress,
               person_id: person_id,
               normalized_email: "alice.pending@example.com"
             )

    assert %PersonEmailAddress{verified_at: %DateTime{}, is_primary: true} =
             Repo.get_by(PersonEmailAddress,
               person_id: person_id,
               normalized_email: "alice.primary@example.com"
             )

    assert %PersonProjection{email: "alice.primary@example.com"} =
             PersonQueries.get_person(person_id)

    %{rows: [[events_after_verification]]} =
      Repo.query!(~S|SELECT count(*) FROM "event_store"."events"|)

    assert :ok =
             PersonEmailVerification.verify_for_sign_in(
               "alice.pending@example.com",
               consistency: :strong
             )

    assert :ok =
             PersonEmailVerification.verify_for_sign_in(
               "unknown@example.com",
               consistency: :strong
             )

    assert %{rows: [[^events_after_verification]]} =
             Repo.query!(~S|SELECT count(*) FROM "event_store"."events"|)
  end
end
