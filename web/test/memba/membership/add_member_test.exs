defmodule Memba.Membership.AddMemberTest do
  use ExUnit.Case, async: true

  alias Memba.Membership.AddMember
  alias Memba.Membership.Commands.AddClubMember

  test "prepares the caller's stable identities from atom or string keys" do
    assert {:ok,
            %AddClubMember{
              membership_id: "membership-1",
              club_id: "club-1",
              person_id: "person-1"
            }} =
             AddMember.prepare(%{
               "membership_id" => "membership-1",
               "person_id" => "person-1",
               club_id: "club-1"
             })

    assert {:ok, %AddClubMember{membership_id: nil}} =
             AddMember.prepare(%{membership_id: nil, club_id: "club-1", person_id: "person-1"})
  end

  test "reports the first missing identity without dispatching" do
    assert {:error, {:missing_required_attribute, :membership_id}} = AddMember.prepare(%{})

    assert {:error, {:missing_required_attribute, :club_id}} =
             AddMember.prepare(%{membership_id: "membership-1"})

    assert {:error, {:missing_required_attribute, :person_id}} =
             AddMember.prepare(%{membership_id: "membership-1", club_id: "club-1"})
  end
end
