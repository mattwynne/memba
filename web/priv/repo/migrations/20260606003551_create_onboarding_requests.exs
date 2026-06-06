defmodule Memba.Repo.Migrations.CreateOnboardingRequests do
  use Ecto.Migration

  def change do
    create table(:onboarding_requests, primary_key: false) do
      add :request_id, :text, primary_key: true
      add :requester_name, :text, null: false
      add :requester_email, :text, null: false
      add :normalized_requester_email, :text, null: false
      add :requester_person_id, :text
      add :requested_club_name, :text, null: false
      add :note, :text, null: false

      add :status, :text, null: false, default: "active"
      add :internal_rejection_notes, :text
      add :triaged_by_staff_email, :text
      add :triaged_at, :utc_datetime_usec
      add :converted_club_id, :text
      add :converted_person_id, :text
      add :converted_membership_id, :text

      timestamps(type: :utc_datetime_usec)
    end

    create index(:onboarding_requests, [:status, :inserted_at])
    create index(:onboarding_requests, [:normalized_requester_email])

    create constraint(:onboarding_requests, :onboarding_requests_status_check,
             check: "status IN ('active', 'converted', 'rejected')"
           )
  end
end
