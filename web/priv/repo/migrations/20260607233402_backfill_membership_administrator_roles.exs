defmodule Memba.Repo.Migrations.BackfillMembershipAdministratorRoles do
  use Ecto.Migration

  def up do
    now = DateTime.utc_now(:microsecond)

    roles =
      "SELECT club_id::text FROM membership_clubs"
      |> query_rows()
      |> Enum.map(fn [club_id] ->
        %{
          role_id: membership_administrator_role_id(club_id),
          club_id: club_id,
          role_key: "admin",
          name: "Admin",
          inserted_at: now,
          updated_at: now
        }
      end)

    insert_all("membership_roles", roles,
      on_conflict: {:replace, [:club_id, :role_key, :name, :updated_at]},
      conflict_target: [:role_id]
    )

    role_permissions =
      Enum.map(roles, fn role ->
        %{
          club_id: role.club_id,
          role_id: role.role_id,
          permission: "club.manage_members",
          inserted_at: now,
          updated_at: now
        }
      end)

    insert_all("membership_role_permissions", role_permissions,
      on_conflict: :nothing,
      conflict_target: [:role_id, :permission]
    )

    role_by_club_id = Map.new(roles, fn role -> {role.club_id, role} end)

    assignments =
      """
      SELECT DISTINCT ON (club_id)
        club_id::text,
        membership_id::text,
        person_id::text
      FROM membership_memberships
      WHERE active = TRUE
      ORDER BY club_id, inserted_at, membership_id
      """
      |> query_rows()
      |> Enum.map(fn [club_id, membership_id, person_id] ->
        role = Map.fetch!(role_by_club_id, club_id)

        %{
          club_id: club_id,
          membership_id: membership_id,
          person_id: person_id,
          role_id: role.role_id,
          active: true,
          inserted_at: now,
          updated_at: now
        }
      end)

    insert_all("membership_role_assignments", assignments,
      on_conflict: {:replace, [:club_id, :person_id, :active, :updated_at]},
      conflict_target: [:membership_id, :role_id]
    )

    member_permissions =
      Enum.map(assignments, fn assignment ->
        %{
          club_id: assignment.club_id,
          membership_id: assignment.membership_id,
          person_id: assignment.person_id,
          permission: "club.manage_members",
          grant_count: 1,
          inserted_at: now,
          updated_at: now
        }
      end)

    insert_all("membership_member_permissions", member_permissions,
      on_conflict: [set: [grant_count: 1, updated_at: now]],
      conflict_target: [:club_id, :person_id, :membership_id, :permission]
    )
  end

  def down do
    execute("""
    WITH default_roles AS (
      SELECT
        role_id,
        club_id
      FROM membership_roles
      WHERE role_key = 'admin'
    ),
    active_default_assignments AS (
      SELECT
        assignment.club_id,
        assignment.membership_id,
        assignment.person_id
      FROM membership_role_assignments AS assignment
      JOIN default_roles AS role ON role.role_id = assignment.role_id
      WHERE assignment.active = TRUE
    )
    UPDATE membership_member_permissions AS member_permission
    SET
      grant_count = member_permission.grant_count - 1,
      updated_at = CURRENT_TIMESTAMP
    FROM active_default_assignments AS assignment
    WHERE member_permission.club_id = assignment.club_id
      AND member_permission.membership_id = assignment.membership_id
      AND member_permission.person_id = assignment.person_id
      AND member_permission.permission = 'club.manage_members';
    """)

    execute("""
    DELETE FROM membership_member_permissions
    WHERE permission = 'club.manage_members'
      AND grant_count <= 0;
    """)

    execute("""
    WITH default_roles AS (
      SELECT role_id
      FROM membership_roles
      WHERE role_key = 'admin'
    )
    DELETE FROM membership_role_assignments AS assignment
    USING default_roles AS role
    WHERE assignment.role_id = role.role_id;
    """)

    execute("""
    WITH default_roles AS (
      SELECT role_id
      FROM membership_roles
      WHERE role_key = 'admin'
    )
    DELETE FROM membership_role_permissions AS permission
    USING default_roles AS role
    WHERE permission.role_id = role.role_id
      AND permission.permission = 'club.manage_members';
    """)

    execute("""
    DELETE FROM membership_roles
    WHERE role_key = 'admin';
    """)
  end

  defp query_rows(sql) do
    repo().query!(sql, []).rows
  end

  defp insert_all(_table, [], _opts), do: {0, nil}

  defp insert_all(table, rows, opts) do
    repo().insert_all(table, rows, opts)
  end

  defp membership_administrator_role_id(club_id) when is_binary(club_id) do
    uuid =
      ["membership_administrator", club_id]
      |> Enum.join(<<0>>)
      |> then(&:crypto.hash(:md5, &1))
      |> Base.encode16(case: :lower)
      |> format_uuid()

    "rol_#{uuid}"
  end

  defp format_uuid(
         <<a::binary-size(8), b::binary-size(4), c::binary-size(4), d::binary-size(4),
           e::binary-size(12)>>
       ) do
    Enum.join([a, b, c, d, e], "-")
  end
end
