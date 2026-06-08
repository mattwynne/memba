defmodule Memba.Membership.Projectors.ClubInvitation do
  @moduledoc """
  Projects club member invitation events into the Membership read model.
  """

  use Commanded.Projections.Ecto,
    application: Memba.Membership.App,
    repo: Memba.Repo,
    name: "Memba.Membership.Projectors.ClubInvitation",
    consistency: :strong

  alias Memba.Membership.Events.ClubMemberInvitationAccepted
  alias Memba.Membership.Events.ClubMemberInvitationResent
  alias Memba.Membership.Events.ClubMemberInvited
  alias Memba.Membership.Projections.ClubInvitation, as: ClubInvitationProjection

  project(%ClubMemberInvited{} = event, fn multi ->
    Ecto.Multi.insert(multi, :membership_club_invitation, %ClubInvitationProjection{
      invitation_id: event.invitation_id,
      club_id: event.club_id,
      email: event.email,
      normalized_email: event.normalized_email,
      token_hash: event.token_hash,
      status: "pending",
      resend_count: 0
    })
  end)

  project(%ClubMemberInvitationResent{} = event, fn multi ->
    Ecto.Multi.update_all(
      multi,
      :membership_club_invitation,
      invitation_query(event.invitation_id),
      set: [token_hash: event.token_hash],
      inc: [resend_count: 1]
    )
  end)

  project(%ClubMemberInvitationAccepted{} = event, fn multi ->
    Ecto.Multi.update_all(
      multi,
      :membership_club_invitation,
      invitation_query(event.invitation_id),
      set: [
        status: "accepted",
        accepted_person_id: event.person_id,
        accepted_membership_id: event.membership_id
      ]
    )
  end)

  defp invitation_query(invitation_id) do
    import Ecto.Query

    from(invitation in ClubInvitationProjection,
      where: invitation.invitation_id == ^invitation_id
    )
  end

  @impl Commanded.Projections.Ecto
  def after_update(event, metadata, changes) do
    Memba.ReadModelChanges.publish(__MODULE__, event, metadata, changes)
  end
end
