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
      'ead_' || gen_random_uuid()::text,
      source.person_id,
      source.email,
      source.normalized_email,
      TRUE,
      source.inserted_at,
      source.updated_at
    FROM (
      SELECT DISTINCT ON (lower(btrim(person.email)))
        person.person_id,
        btrim(person.email) AS email,
        lower(btrim(person.email)) AS normalized_email,
        person.inserted_at,
        person.updated_at
      FROM membership_people AS person
      WHERE btrim(person.email) <> ''
      ORDER BY lower(btrim(person.email)), person.inserted_at, person.person_id
    ) AS source
    WHERE NOT EXISTS (
      SELECT 1
      FROM membership_person_email_addresses AS existing_email_address
      WHERE existing_email_address.normalized_email = source.normalized_email
    )
    AND NOT EXISTS (
      SELECT 1
      FROM membership_person_email_addresses AS existing_primary_email_address
      WHERE existing_primary_email_address.person_id = source.person_id
        AND existing_primary_email_address.is_primary = TRUE
    );
    """
  end
end
