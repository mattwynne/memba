defmodule Memba.Repo.Migrations.CreateMembershipClubInvitationsProjection do
  use Ecto.Migration

  def change do
    create table(:membership_club_invitations, primary_key: false) do
      add :invitation_id, :text, primary_key: true
      add :club_id, :text, null: false
      add :email, :text, null: false
      add :normalized_email, :text, null: false
      add :token_hash, :text, null: false
      add :status, :text, null: false, default: "pending"
      add :accepted_person_id, :text
      add :accepted_membership_id, :text
      add :resend_count, :integer, null: false, default: 0

      timestamps(type: :utc_datetime_usec)
    end

    create constraint(:membership_club_invitations, :membership_club_invitations_status_check,
             check: "status IN ('pending', 'accepted')"
           )

    create index(:membership_club_invitations, [:club_id])
    create index(:membership_club_invitations, [:normalized_email])
    create unique_index(:membership_club_invitations, [:token_hash])

    create unique_index(:membership_club_invitations, [:club_id, :normalized_email],
             name: :membership_club_invitations_one_pending_per_email,
             where: "status = 'pending'"
           )
  end
end
