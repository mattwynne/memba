defmodule Memba.Membership.CustomGroupPreparationTest do
  use ExUnit.Case, async: true

  alias Memba.Membership.Commands.{
    AddCustomGroupMember,
    CreateCustomGroup,
    RemoveCustomGroupMember
  }

  alias Memba.Membership.CustomGroup.{Admit, Create, Remove}

  test "creation preserves caller-owned retry identity and actor, without authorizing from projections" do
    attrs = %{
      "club_id" => "club",
      "group_id" => "stable-group",
      "actor_person_id" => "actor",
      "name" => "New"
    }

    assert {:ok, %CreateCustomGroup{group_id: "stable-group", actor_person_id: "actor"} = command} =
             Create.prepare(attrs)

    assert {:ok, ^command} = Create.prepare(attrs)

    assert {:error, {:missing_required_attribute, :group_id}} =
             Create.prepare(Map.delete(attrs, "group_id"))
  end

  test "admission keeps target membership separate from actor" do
    attrs = %{
      club_id: "club",
      group_id: "group",
      membership_id: "member",
      person_id: "target",
      actor_person_id: "actor"
    }

    assert {:ok,
            %AddCustomGroupMember{
              membership_id: "member",
              person_id: "target",
              actor_person_id: "actor"
            }} = Admit.prepare(attrs)

    assert {:error, {:missing_required_attribute, :person_id}} =
             Admit.prepare(Map.delete(attrs, :person_id))
  end

  test "removal requires and retains the operation id for exact retries" do
    attrs = %{
      club_id: "club",
      group_id: "group",
      membership_id: "member",
      person_id: "target",
      actor_person_id: "actor",
      removal_operation_id: "stable-operation"
    }

    assert {:ok, %RemoveCustomGroupMember{removal_operation_id: "stable-operation"} = command} =
             Remove.prepare(attrs)

    assert {:ok, ^command} = Remove.prepare(attrs)

    assert {:error, {:missing_required_attribute, :removal_operation_id}} =
             Remove.prepare(Map.delete(attrs, :removal_operation_id))
  end
end
