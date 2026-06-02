defmodule Memba.Repo.Migrations.AddSlugToMembershipClubs do
  use Ecto.Migration

  def up do
    execute("""
    CREATE FUNCTION memba_membership_club_slug_base(club_name text)
    RETURNS text
    LANGUAGE plpgsql
    IMMUTABLE
    AS $$
    DECLARE
      generated_slug text;
    BEGIN
      generated_slug :=
        btrim(
          substring(
            btrim(
              regexp_replace(lower(btrim(club_name)), '[^a-z0-9]+', '-', 'g'),
              '-'
            )
            from 1 for 32
          ),
          '-'
        );

      IF generated_slug IS NULL OR generated_slug = '' THEN
        RETURN 'club';
      END IF;

      RETURN generated_slug;
    END;
    $$;
    """)

    alter table(:membership_clubs) do
      add :slug, :text
    end

    execute("""
    WITH slug_sources AS (
      SELECT
        club_id,
        memba_membership_club_slug_base(name) AS base_slug
      FROM membership_clubs
    ),
    numbered_slugs AS (
      SELECT
        club_id,
        base_slug,
        row_number() OVER (PARTITION BY base_slug ORDER BY club_id) AS slug_number
      FROM slug_sources
    )
    UPDATE membership_clubs AS club
    SET slug =
      CASE
        WHEN numbered.slug_number = 1 THEN numbered.base_slug
        ELSE
          left(
            numbered.base_slug,
            32 - length('-' || numbered.slug_number::text)
          ) || '-' || numbered.slug_number::text
      END
    FROM numbered_slugs AS numbered
    WHERE club.club_id = numbered.club_id;
    """)

    alter table(:membership_clubs) do
      modify :slug, :text, null: false
    end

    create unique_index(:membership_clubs, [:slug], name: :membership_clubs_slug_index)

    execute("""
    CREATE FUNCTION memba_membership_clubs_set_slug()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
      base_slug text;
      candidate_slug text;
      suffix_number integer := 1;
      suffix text;
    BEGIN
      IF NEW.slug IS NULL OR NEW.slug = '' THEN
        base_slug := memba_membership_club_slug_base(NEW.name);
        candidate_slug := base_slug;

        WHILE EXISTS (
          SELECT 1
          FROM membership_clubs
          WHERE slug = candidate_slug
            AND club_id <> NEW.club_id
        ) LOOP
          suffix_number := suffix_number + 1;
          suffix := '-' || suffix_number::text;
          candidate_slug := left(base_slug, 32 - length(suffix)) || suffix;
        END LOOP;

        NEW.slug := candidate_slug;
      END IF;

      RETURN NEW;
    END;
    $$;
    """)

    execute("""
    CREATE TRIGGER membership_clubs_set_slug
    BEFORE INSERT OR UPDATE OF name, slug ON membership_clubs
    FOR EACH ROW
    EXECUTE FUNCTION memba_membership_clubs_set_slug();
    """)
  end

  def down do
    drop_if_exists index(:membership_clubs, [:slug], name: :membership_clubs_slug_index)

    execute("DROP TRIGGER IF EXISTS membership_clubs_set_slug ON membership_clubs;")
    execute("DROP FUNCTION IF EXISTS memba_membership_clubs_set_slug();")

    alter table(:membership_clubs) do
      remove :slug
    end

    execute("DROP FUNCTION IF EXISTS memba_membership_club_slug_base(text);")
  end
end
