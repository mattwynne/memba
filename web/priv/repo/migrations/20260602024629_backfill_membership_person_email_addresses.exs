defmodule Memba.Repo.Migrations.BackfillMembershipPersonEmailAddresses do
  use Ecto.Migration

  def up do
    execute(backfill_sql())
  end

  def down do
    :ok
  end

  def backfill_sql do
    """
    INSERT INTO membership_person_email_addresses (
      id,
      person_id,
      email,
      normalized_email,
      is_primary,
      inserted_at,
      updated_at
    )
    SELECT
      gen_random_uuid(),
      person.person_id,
      btrim(person.email),
      lower(btrim(person.email)),
      TRUE,
      now(),
      now()
    FROM membership_people AS person
    WHERE NOT EXISTS (
      SELECT 1
      FROM membership_person_email_addresses AS existing_email_address
      WHERE existing_email_address.person_id = person.person_id
        AND existing_email_address.normalized_email = lower(btrim(person.email))
    );
    """
  end
end
