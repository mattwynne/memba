defmodule MembaWeb.MemberDashboardQuery do
  @moduledoc """
  Loads the member dashboard from fresh authority for an authenticated email.

  The routed club and selected group are stable query inputs. Active-club
  authority is deliberately resolved again for every call so a dashboard
  refresh cannot be authorized by a mount-time club snapshot.
  """

  alias Memba.Accounts
  alias MembaWeb.MemberDashboardPresentation

  @doc """
  Returns one coherent dashboard view model or the presentation boundary's
  existing `:forbidden`/`:not_found` access result.
  """
  def load(club_id, authenticated_email, selected_group_id) do
    normalized_email = Accounts.normalize_email(authenticated_email)
    active_clubs = Accounts.list_active_clubs_for_email(normalized_email)
    identity = if normalized_email, do: %{email: normalized_email}

    MemberDashboardPresentation.load(
      club_id,
      identity,
      active_clubs,
      selected_group_id
    )
  end
end
