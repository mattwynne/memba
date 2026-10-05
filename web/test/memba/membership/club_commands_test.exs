defmodule Memba.Membership.ClubCommandsTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership
  alias Memba.Membership.ClubCommands
  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.Commands.{CreateClub, ReconcileLegacyAdminHistory, UpdateClub}

  test "create preparation accepts atom/string keys, derives a slug, and does not dispatch" do
    club_id = Memba.ID.generate(:club)

    assert {:ok,
            %CreateClub{club_id: ^club_id, name: " Alpine Club ", slug: "alpine-club"} = command} =
             ClubCommands.prepare_create(%{"club_id" => club_id, "name" => " Alpine Club "})

    assert is_nil(Membership.get_club(club_id))
    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)
    assert Membership.get_club(club_id).slug == "alpine-club"

    assert {:ok, %CreateClub{slug: "another-club"}} =
             ClubCommands.prepare_create(%{
               club_id: Memba.ID.generate(:club),
               name: "Some Club",
               slug: "another-club"
             })
  end

  test "preparation preserves missing and invalid slug errors" do
    club_id = Memba.ID.generate(:club)

    assert {:error, {:missing_required_attribute, :club_id}} =
             ClubCommands.prepare_create(%{name: "Club"})

    assert {:error, :invalid_format} =
             ClubCommands.prepare_create(%{club_id: club_id, name: "Club", slug: "Bad Slug"})

    assert {:error, :blank} =
             ClubCommands.prepare_create(%{club_id: club_id, name: "!!!", slug: ""})

    assert {:error, :invalid_club_id} =
             ClubCommands.prepare_update(%{club_id: "invalid", name: "Club", slug: "club"})

    assert {:error, {:missing_required_attribute, :slug}} =
             ClubCommands.prepare_update(%{club_id: club_id, name: "Club"})
  end

  test "prepared commands retain adapter return shape and aggregate errors" do
    club_id = Memba.ID.generate(:club)

    assert {:ok, %UpdateClub{} = update} =
             ClubCommands.prepare_update(%{club_id: club_id, name: "Missing", slug: "missing"})

    assert {:error, :not_created} = CommandDispatch.dispatch(update)

    assert {:ok, %CreateClub{} = create} =
             ClubCommands.prepare_create(%{club_id: club_id, name: "Alpine", slug: "alpine"})

    assert {:ok, %Commanded.Commands.ExecutionResult{aggregate_uuid: ^club_id}} =
             CommandDispatch.dispatch(create, returning: :execution_result, consistency: :strong)

    # The projected create guard is deliberately unchanged: even the same ID
    # cannot be prepared again after its slug has been projected.
    assert {:error, :slug_taken} =
             ClubCommands.prepare_create(%{club_id: club_id, name: "Alpine", slug: "alpine"})
  end

  test "reconciliation command preserves raw errors with explicit repair dispatch options" do
    command = %ReconcileLegacyAdminHistory{
      club_id: Memba.ID.generate(:club),
      membership_id: Memba.ID.generate(:membership),
      person_id: Memba.ID.generate(:person)
    }

    assert {:error, :not_created} =
             CommandDispatch.dispatch(command,
               consistency: [Memba.Membership.Projectors.Role],
               metadata: %{"operation_id" => "test-repair"},
               returning: :execution_result
             )
  end

  test "projected duplicate guard rejects another club but allows own slug for update" do
    club_id = Memba.ID.generate(:club)
    other_id = Memba.ID.generate(:club)

    assert :ok =
             Membership.create_club(%{club_id: club_id, name: "Alpine", slug: "alpine"},
               consistency: :strong
             )

    assert {:error, :slug_taken} =
             ClubCommands.prepare_create(%{club_id: other_id, name: "Other", slug: "alpine"})

    assert {:error, :slug_taken} =
             ClubCommands.prepare_update(%{club_id: other_id, name: "Other", slug: "alpine"})

    assert {:ok, %UpdateClub{club_id: ^club_id, slug: "alpine"} = command} =
             ClubCommands.prepare_update(%{
               "club_id" => club_id,
               "name" => " Alpine Again ",
               "slug" => "alpine"
             })

    assert is_nil(Membership.get_club(other_id))
    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)
    assert Membership.get_club(club_id).name == "Alpine Again"
  end
end
