defmodule Memba.SeedDataTest do
  use Memba.EventSourcedCase, async: false

  import ExUnit.CaptureIO

  alias Memba.Membership.Permissions
  alias Memba.Membership.Projections.MemberPermission
  alias Memba.Membership.Projections.Role
  alias Memba.Membership.Projections.RoleAssignment
  alias Memba.Membership.Projections.RolePermission
  alias Memba.Membership.Roles

  test "seeded clubs have an Admin role and active administrator permission" do
    capture_io(fn ->
      Code.eval_file(Path.expand("../../priv/repo/seeds.exs", __DIR__))
    end)

    kootenay_club_id = "clb_11111111-1111-1111-1111-111111111111"
    alice_person_id = "per_aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    alice_kootenay_membership_id = "mem_10000000-0000-0000-0000-000000000001"
    role_id = Roles.membership_administrator_role_id(kootenay_club_id)
    permission = Permissions.club_manage_members()

    assert %Role{
             club_id: ^kootenay_club_id,
             role_key: "admin",
             name: "Admin"
           } = Repo.get(Role, role_id)

    assert %RolePermission{
             club_id: ^kootenay_club_id,
             role_id: ^role_id,
             permission: ^permission
           } = role_permission(role_id, permission)

    assert %RoleAssignment{
             club_id: ^kootenay_club_id,
             membership_id: ^alice_kootenay_membership_id,
             person_id: ^alice_person_id,
             role_id: ^role_id,
             active: true
           } = role_assignment(alice_kootenay_membership_id, role_id)

    assert %MemberPermission{
             club_id: ^kootenay_club_id,
             membership_id: ^alice_kootenay_membership_id,
             person_id: ^alice_person_id,
             permission: ^permission,
             grant_count: 1
           } =
             member_permission(
               kootenay_club_id,
               alice_person_id,
               alice_kootenay_membership_id,
               permission
             )

    assert Repo.aggregate(Role, :count) == 3
    assert Repo.aggregate(RoleAssignment, :count) == 3
  end

  defp role_permission(role_id, permission) do
    Repo.one(
      from(role_permission in RolePermission,
        where: role_permission.role_id == ^role_id,
        where: role_permission.permission == ^permission
      )
    )
  end

  defp role_assignment(membership_id, role_id) do
    Repo.one(
      from(assignment in RoleAssignment,
        where: assignment.membership_id == ^membership_id,
        where: assignment.role_id == ^role_id
      )
    )
  end

  defp member_permission(club_id, person_id, membership_id, permission) do
    Repo.one(
      from(member_permission in MemberPermission,
        where: member_permission.club_id == ^club_id,
        where: member_permission.person_id == ^person_id,
        where: member_permission.membership_id == ^membership_id,
        where: member_permission.permission == ^permission
      )
    )
  end
end
