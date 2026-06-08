defmodule MembaWeb.ClubMemberInvitationSender do
  @moduledoc """
  Shared web-facing sender for club member invitations.

  Staff and Membership Admin invitation surfaces both call this module so they
  create or resend invitations through the appropriate Membership application
  service, deliver the same one-use callback link, and keep the Membership-owned
  duplicate and acceptance lifecycle rules in one place.
  """

  alias Memba.Membership
  alias Memba.Membership.ClubMemberInvitationEmail
  alias Memba.Membership.EmailAddresses

  def send_invitation(%{club_id: club_id} = club, email, opts \\ [consistency: :strong])
      when is_binary(club_id) and is_list(opts) do
    {actor_person_id, dispatch_opts} = invitation_actor_and_dispatch_opts(opts)

    with {:ok, invited_email} <- EmailAddresses.normalize_email(email),
         resent? = pending_invitation?(club_id, invited_email.normalized_email),
         {:ok, invitation} <-
           invite_club_member(
             club_id,
             invited_email.normalized_email,
             actor_person_id,
             dispatch_opts
           ),
         :ok <- deliver_invitation(invitation, invited_email.normalized_email, club) do
      {:ok,
       %{
         email: invited_email.normalized_email,
         invitation: invitation,
         resent?: resent?
       }}
    end
  end

  defp invitation_actor_and_dispatch_opts(opts) do
    {Keyword.get(opts, :actor_person_id), Keyword.delete(opts, :actor_person_id)}
  end

  defp invite_club_member(club_id, email, nil, dispatch_opts) do
    Membership.invite_club_member(
      %{"club_id" => club_id, "email" => email},
      dispatch_opts
    )
  end

  defp invite_club_member(club_id, email, actor_person_id, dispatch_opts) do
    Membership.invite_club_member_as_club_member(
      %{"club_id" => club_id, "email" => email, "actor_person_id" => actor_person_id},
      dispatch_opts
    )
  end

  defp pending_invitation?(club_id, email) do
    not is_nil(Membership.get_pending_club_member_invitation_by_email(club_id, email))
  end

  defp deliver_invitation(invitation, email, club) do
    ClubMemberInvitationEmail.deliver(%{
      email: email,
      club: club,
      invitation_id: invitation.invitation_id,
      invitation_url: invitation_url(invitation.invitation_token)
    })
  end

  defp invitation_url(invitation_token) do
    MembaWeb.Endpoint.url() <>
      "/invitations/club-members/" <> URI.encode(invitation_token, &URI.char_unreserved?/1)
  end
end
