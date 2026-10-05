defmodule Memba.Membership.CustomGroupPreviewTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.ClubInboundEmailAddress
  alias Memba.ID
  alias Memba.Membership
  alias Memba.Membership.CustomGroup.Preview
  alias Memba.Membership.Projections.Club

  test "preview normalizes the name, reports same-club slug collisions and duplicate names" do
    {club_id, actor_id} = club_with_admin!()
    {other_club_id, other_actor_id} = club_with_admin!()

    assert :ok = create_group!(club_id, actor_id, "Board!")
    assert :ok = create_group!(club_id, actor_id, "Board?")
    assert :ok = create_group!(other_club_id, other_actor_id, "Budget!")

    attrs = %{"club_id" => club_id, "actor_person_id" => actor_id, "name" => "  Board +  "}
    club = Repo.get!(Club, club_id)

    expected = %{
      name: "Board +",
      email_slug: "board-3",
      email_address: ClubInboundEmailAddress.address(club, "board-3"),
      unsuffixed_email_slug: "board",
      collision_group_name: "Board!"
    }

    assert {:ok, ^expected} = Preview.call(attrs)
    assert {:ok, ^expected} = Membership.preview_custom_group(attrs)
    assert {:ok, ^expected} = Preview.call(attrs)

    assert {:error, {:group_name_already_defined, "Board!"}} =
             Preview.call(%{club_id: club_id, actor_person_id: actor_id, name: " board! "})

    assert {:ok, %{email_slug: "budget", collision_group_name: nil}} =
             Preview.call(%{club_id: club_id, actor_person_id: actor_id, name: "Budget +"})
  end

  test "preview checks projected club permission before name and scopes authority to the club" do
    {club_id, admin_id} = club_with_admin!()
    {other_club_id, other_admin_id} = club_with_admin!()
    person_id = ID.generate(:person)
    membership_id = ID.generate(:membership)

    assert :ok =
             Membership.create_person(
               %{person_id: person_id, name: "Member", email: "#{person_id}@example.com"},
               consistency: :strong
             )

    assert :ok =
             Membership.add_member(
               %{club_id: club_id, membership_id: membership_id, person_id: person_id},
               consistency: :strong
             )

    attrs = %{club_id: club_id, actor_person_id: person_id, name: ""}
    assert {:error, :unauthorized} = Preview.call(attrs)
    assert {:error, :unauthorized} = Preview.call(%{attrs | actor_person_id: other_admin_id})
    assert {:error, :unauthorized} = Preview.call(%{attrs | actor_person_id: "bad-id"})
    assert {:error, :not_found} = Preview.call(%{attrs | club_id: "bad-id"})

    assert {:error, {:missing_required_attribute, :actor_person_id}} =
             Preview.call(Map.delete(attrs, :actor_person_id))

    assert {:error, {:missing_required_attribute, :name}} =
             Preview.call(%{club_id: club_id, actor_person_id: admin_id})

    assert {:error, :unauthorized} =
             Preview.call(%{club_id: ID.generate(:club), actor_person_id: admin_id, name: "New"})

    assert {:ok, %{name: "New", email_slug: "new", collision_group_name: nil}} =
             Preview.call(%{
               club_id: other_club_id,
               actor_person_id: other_admin_id,
               name: " New "
             })
  end

  defp club_with_admin! do
    club_id = ID.generate(:club)
    person_id = ID.generate(:person)
    membership_id = ID.generate(:membership)

    assert :ok =
             Membership.create_club(
               membership_club_attrs(club_id: club_id, name: "Preview Club"),
               consistency: :strong
             )

    assert :ok =
             Membership.create_person(
               %{person_id: person_id, name: "Admin", email: "#{person_id}@example.com"},
               consistency: :strong
             )

    assert :ok =
             Membership.add_member(
               %{club_id: club_id, membership_id: membership_id, person_id: person_id},
               consistency: :strong
             )

    {club_id, person_id}
  end

  defp create_group!(club_id, actor_id, name) do
    Membership.create_custom_group(
      %{club_id: club_id, group_id: ID.generate(:group), actor_person_id: actor_id, name: name},
      consistency: :strong
    )
  end
end
