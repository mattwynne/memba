defmodule MembaWeb.ClubMemberInvitationHTML do
  @moduledoc """
  Renders club member invitation journey pages.
  """
  use MembaWeb, :html

  embed_templates "club_member_invitation_html/*"

  defp club_name(%{name: name}) when is_binary(name), do: name
  defp club_name(_club), do: "your club"

  defp club_id(%{club_id: club_id}) when is_binary(club_id), do: club_id
  defp club_id(_club), do: nil
end
