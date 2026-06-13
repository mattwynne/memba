defmodule Memba.Repo.Migrations.NormalizeLegacyProjectionIdColumns do
  use Ecto.Migration

  @legacy_uuid_regex "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"

  @id_columns [
    {"membership_clubs", "club_id", "clb"},
    {"membership_people", "person_id", "per"},
    {"membership_person_email_addresses", "id", "ead"},
    {"membership_person_email_addresses", "person_id", "per"},
    {"membership_memberships", "membership_id", "mem"},
    {"membership_memberships", "club_id", "clb"},
    {"membership_memberships", "person_id", "per"},
    {"membership_roles", "club_id", "clb"},
    {"membership_role_permissions", "club_id", "clb"},
    {"membership_role_assignments", "club_id", "clb"},
    {"membership_role_assignments", "membership_id", "mem"},
    {"membership_role_assignments", "person_id", "per"},
    {"membership_member_permissions", "club_id", "clb"},
    {"membership_member_permissions", "membership_id", "mem"},
    {"membership_member_permissions", "person_id", "per"},
    {"messaging_messages", "message_id", "msg"},
    {"messaging_messages", "club_id", "clb"},
    {"messaging_messages", "sender_id", "per"},
    {"messaging_email_deliveries", "delivery_id", "del"},
    {"messaging_email_deliveries", "message_id", "msg"},
    {"messaging_email_deliveries", "recipient_id", "per"},
    {"messaging_member_email_deliveries", "delivery_id", "del"},
    {"messaging_member_email_deliveries", "message_id", "msg"},
    {"messaging_member_email_deliveries", "recipient_id", "per"},
    {"messaging_memba_staff_email_deliveries", "delivery_id", "del"},
    {"messaging_memba_staff_email_deliveries", "message_id", "msg"},
    {"messaging_memba_staff_email_deliveries", "recipient_id", "per"}
  ]

  def up do
    drop_legacy_person_email_address_foreign_key()

    Enum.each(@id_columns, fn {table, column, prefix} ->
      normalize_column(table, column, prefix)
    end)

    recreate_person_email_address_foreign_key()
  end

  def down do
    :ok
  end

  defp drop_legacy_person_email_address_foreign_key do
    execute("""
    ALTER TABLE membership_person_email_addresses
    DROP CONSTRAINT IF EXISTS membership_person_email_addresses_person_id_fkey;
    """)
  end

  defp normalize_column(table, column, prefix) do
    execute("""
    DO $$
    BEGIN
      IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = '#{table}'
          AND column_name = '#{column}'
          AND udt_name = 'uuid'
      ) THEN
        EXECUTE 'ALTER TABLE #{table} ALTER COLUMN #{column} TYPE text USING ''#{prefix}_'' || #{column}::text';
      END IF;

      IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = '#{table}'
          AND column_name = '#{column}'
          AND udt_name = 'text'
      ) THEN
        EXECUTE 'UPDATE #{table} SET #{column} = ''#{prefix}_'' || #{column} WHERE #{column} ~ ''#{@legacy_uuid_regex}''';
      END IF;
    END $$;
    """)
  end

  defp recreate_person_email_address_foreign_key do
    execute("""
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'membership_person_email_addresses_person_id_fkey'
      ) THEN
        ALTER TABLE membership_person_email_addresses
        ADD CONSTRAINT membership_person_email_addresses_person_id_fkey
        FOREIGN KEY (person_id)
        REFERENCES membership_people(person_id)
        ON DELETE CASCADE;
      END IF;
    END $$;
    """)
  end
end
