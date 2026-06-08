defmodule Memba.Repo.Migrations.RenameMembershipAdministratorRoleToAdmin do
  use Ecto.Migration

  def up do
    execute("""
    UPDATE membership_roles
    SET
      role_key = 'admin',
      name = 'Admin',
      updated_at = CURRENT_TIMESTAMP
    WHERE role_key = 'membership_administrator';
    """)

    execute("""
    UPDATE membership_roles
    SET name = 'Admin', updated_at = CURRENT_TIMESTAMP
    WHERE role_key = 'admin'
      AND name = 'Membership Administrator';
    """)
  end

  def down do
    execute("""
    UPDATE membership_roles
    SET
      role_key = 'membership_administrator',
      name = 'Membership Administrator',
      updated_at = CURRENT_TIMESTAMP
    WHERE role_key = 'admin';
    """)
  end
end
