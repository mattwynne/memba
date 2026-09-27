defmodule Memba.Membership.AuthoritativeCustomGroupTargetTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership
  alias Memba.Membership.App
  alias Memba.Membership.Commands.AddClubMember
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreateGroup
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Commands.RemoveClubMember
  alias Memba.Membership.Projectors.Membership, as: MembershipProjector
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.SystemGroups

  describe "resolve_custom_group_target_authoritatively/3" do
    test "returns server-owned facts and an active membership for a person outside the group" do
      %{club: club, group_id: group_id, target: target} = setup_target()

      assert {:ok,
              %{
                club: %{
                  club_id: club_id,
                  name: "Kootenay Mountaineering Club",
                  slug: "kmc"
                },
                membership: %{
                  membership_id: membership_id,
                  person_id: person_id
                },
                person: %{
                  person_id: person_id,
                  name: "Eve Ekwueme"
                },
                group: %{
                  club_id: club_id,
                  group_id: ^group_id,
                  group_key: "board",
                  email_slug: "board",
                  name: "Board"
                },
                active_group_member?: false
              }} =
               Membership.resolve_custom_group_target_authoritatively(
                 club.club_id,
                 target.person_id,
                 group_id
               )

      assert club_id == club.club_id
      assert membership_id == target.membership_id
      assert person_id == target.person_id
    end

    test "reports current participation when the active person already belongs to the group" do
      %{club: club, group_id: group_id, target: target} = setup_target()
      add_group_member!(club.club_id, group_id, target)

      assert {:ok, %{active_group_member?: true, membership: %{membership_id: membership_id}}} =
               Membership.resolve_custom_group_target_authoritatively(
                 club.club_id,
                 target.person_id,
                 group_id
               )

      assert membership_id == target.membership_id
    end

    test "rejects invalid and missing typed identities" do
      %{club: club, group_id: group_id, target: target} = setup_target()

      assert {:error, :invalid_club_id} =
               Membership.resolve_custom_group_target_authoritatively(
                 "not-a-club-id",
                 target.person_id,
                 group_id
               )

      assert {:error, :invalid_person_id} =
               Membership.resolve_custom_group_target_authoritatively(
                 club.club_id,
                 nil,
                 group_id
               )

      assert {:error, :invalid_group_id} =
               Membership.resolve_custom_group_target_authoritatively(
                 club.club_id,
                 target.person_id,
                 Memba.ID.generate(:person)
               )

      assert {:error, :not_found} =
               Membership.resolve_custom_group_target_authoritatively(
                 Memba.ID.generate(:club),
                 target.person_id,
                 group_id
               )

      assert {:error, :member_not_active} =
               Membership.resolve_custom_group_target_authoritatively(
                 club.club_id,
                 Memba.ID.generate(:person),
                 group_id
               )

      assert {:error, :group_not_defined} =
               Membership.resolve_custom_group_target_authoritatively(
                 club.club_id,
                 target.person_id,
                 Memba.ID.generate(:group)
               )
    end

    test "rejects cross-club person and group combinations" do
      %{club: club, group_id: group_id, target: target} = setup_target()
      %{club: other_club, group_id: other_group_id, target: other_target} = setup_target("ncc")

      assert {:error, :member_not_active} =
               Membership.resolve_custom_group_target_authoritatively(
                 club.club_id,
                 other_target.person_id,
                 group_id
               )

      assert {:error, :group_not_defined} =
               Membership.resolve_custom_group_target_authoritatively(
                 club.club_id,
                 target.person_id,
                 other_group_id
               )

      assert {:error, :group_not_defined} =
               Membership.resolve_custom_group_target_authoritatively(
                 other_club.club_id,
                 other_target.person_id,
                 group_id
               )
    end

    test "rejects both deterministic built-in groups" do
      %{club: club, target: target} = setup_target()

      for group_id <- [
            SystemGroups.everyone_group_id(club.club_id),
            SystemGroups.admin_group_id(club.club_id)
          ] do
        assert {:error, :system_group_not_allowed} =
                 Membership.resolve_custom_group_target_authoritatively(
                   club.club_id,
                   target.person_id,
                   group_id
                 )
      end
    end

    test "rejects a committed departure while the membership projection is stale" do
      %{club: club, group_id: group_id, target: target} = setup_target()
      projector_child_id = stop_projector!(MembershipProjector)

      assert :ok =
               App.dispatch(
                 %RemoveClubMember{
                   club_id: club.club_id,
                   membership_id: target.membership_id,
                   person_id: target.person_id
                 },
                 consistency: :eventual
               )

      assert %MembershipProjection{active: true} =
               Repo.get!(MembershipProjection, target.membership_id)

      assert {:error, :member_not_active} =
               Membership.resolve_custom_group_target_authoritatively(
                 club.club_id,
                 target.person_id,
                 group_id
               )

      restart_projector!(projector_child_id)
    end
  end

  defp setup_target(slug \\ "kmc") do
    club = create_club!(slug)
    admin = create_person!("Alice Ahmed", "alice-#{slug}@example.com")
    target = create_person!("Eve Ekwueme", "eve-#{slug}@example.com")
    admin = Map.put(admin, :membership_id, add_club_member!(club.club_id, admin.person_id))
    target = Map.put(target, :membership_id, add_club_member!(club.club_id, target.person_id))
    group_id = create_group!(club.club_id)

    %{club: club, admin: admin, target: target, group_id: group_id}
  end

  defp create_club!(slug) do
    club = %{
      club_id: Memba.ID.generate(:club),
      name:
        if(slug == "kmc",
          do: "Kootenay Mountaineering Club",
          else: "Nelson Cycling Club"
        ),
      slug: slug
    }

    assert :ok =
             App.dispatch(
               %CreateClub{club_id: club.club_id, name: club.name, slug: club.slug},
               consistency: :strong
             )

    club
  end

  defp create_person!(name, email) do
    person = %{person_id: Memba.ID.generate(:person), name: name, email: email}

    assert :ok =
             App.dispatch(
               %CreatePerson{
                 person_id: person.person_id,
                 name: person.name,
                 email: person.email,
                 email_addresses: [%{email: person.email, is_primary: true}]
               },
               consistency: :strong
             )

    person
  end

  defp add_club_member!(club_id, person_id) do
    membership_id = Memba.ID.generate(:membership)

    assert :ok =
             App.dispatch(
               %AddClubMember{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id
               },
               consistency: :strong
             )

    membership_id
  end

  defp create_group!(club_id) do
    group_id = Memba.ID.generate(:group)

    assert :ok =
             App.dispatch(
               %CreateGroup{
                 club_id: club_id,
                 group_id: group_id,
                 group_key: "board",
                 email_slug: "board",
                 name: "Board"
               },
               consistency: :strong
             )

    group_id
  end

  defp add_group_member!(club_id, group_id, person) do
    assert :ok =
             App.dispatch(
               %AddGroupMember{
                 club_id: club_id,
                 group_id: group_id,
                 membership_id: person.membership_id,
                 person_id: person.person_id
               },
               consistency: :strong
             )
  end

  defp stop_projector!(projector) do
    child_id =
      Supervisor.which_children(Memba.Supervisor)
      |> Enum.find_value(fn
        {child_id, _pid, :worker, [^projector]} -> child_id
        _child -> nil
      end)

    assert child_id
    assert :ok = Supervisor.terminate_child(Memba.Supervisor, child_id)
    on_exit(fn -> restart_projector!(child_id) end)
    child_id
  end

  defp restart_projector!(child_id) do
    case Supervisor.restart_child(Memba.Supervisor, child_id) do
      {:ok, _pid} -> :ok
      {:ok, _pid, _info} -> :ok
      {:error, :running} -> :ok
    end
  end
end
