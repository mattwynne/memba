defmodule Memba.Membership.SystemGroupsTest do
  use ExUnit.Case, async: true

  alias Memba.ID
  alias Memba.Membership.SystemGroups

  test "defines stable keys, email slugs, and display names for built-in conversation groups" do
    assert SystemGroups.everyone_key() == "everyone"
    assert SystemGroups.everyone_email_slug() == "everyone"
    assert SystemGroups.everyone_name() == "Everyone"
    assert SystemGroups.admin_key() == "admin"
    assert SystemGroups.admin_email_slug() == "admin"
    assert SystemGroups.admin_name() == "Admin"
  end

  test "derives deterministic typed IDs for the Everyone and Admin groups in a club" do
    club_id = ID.generate(:club)

    everyone_group_id = SystemGroups.everyone_group_id(club_id)
    admin_group_id = SystemGroups.admin_group_id(club_id)

    assert everyone_group_id == SystemGroups.everyone_group_id(club_id)
    assert admin_group_id == SystemGroups.admin_group_id(club_id)
    assert everyone_group_id != admin_group_id

    assert String.starts_with?(everyone_group_id, "grp_")
    assert String.starts_with?(admin_group_id, "grp_")
    assert ID.valid?(:group, everyone_group_id)
    assert ID.valid?(:group, admin_group_id)
  end

  test "scopes system group IDs to the club identity" do
    first_club_id = ID.generate(:club)
    second_club_id = ID.generate(:club)

    assert SystemGroups.everyone_group_id(first_club_id) !=
             SystemGroups.everyone_group_id(second_club_id)

    assert SystemGroups.admin_group_id(first_club_id) !=
             SystemGroups.admin_group_id(second_club_id)
  end

  test "documents the deterministic ID source parts for backfill and policy callers" do
    club_id = ID.generate(:club)

    assert SystemGroups.everyone_group_id(club_id) ==
             ID.deterministic(:group, ["system-group", club_id, "everyone"])

    assert SystemGroups.admin_group_id(club_id) ==
             ID.deterministic(:group, ["system-group", club_id, "admin"])
  end
end
