defmodule Memba.Repo.Migrations.AddVerifiedAtToMembershipPersonEmailAddresses do
  use Ecto.Migration

  def up do
    alter table(:membership_person_email_addresses) do
      add :verified_at, :utc_datetime_usec
    end

    execute(backfill_sql())
  end

  def down do
    alter table(:membership_person_email_addresses) do
      remove :verified_at
    end
  end

  def backfill_sql do
    """
    UPDATE membership_person_email_addresses
    SET verified_at = COALESCE(updated_at, inserted_at, now())
    WHERE verified_at IS NULL;
    """
  end
end
