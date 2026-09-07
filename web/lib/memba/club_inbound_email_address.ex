defmodule Memba.ClubInboundEmailAddress do
  @moduledoc """
  Derives member-facing inbound email addresses for clubs.

  Each address combines a group's email slug with its club subdomain:
  `<group-email-slug>@<club-slug>.<configured-domain>`.
  """

  alias Memba.Membership.Slug

  @default_domain "clubs.memba.io"

  @doc """
  Build the Everyone inbound email address for a club or club slug.

  Returns `nil` when the slug is missing or not a valid public club slug.
  """
  def address(club_or_slug), do: address(club_or_slug, "everyone")

  @doc """
  Build a group's inbound email address from its club and group email slugs.

  Returns `nil` when either slug is missing or invalid.
  """
  def address(club_or_slug, group_email_slug)

  def address(%{slug: club_slug}, group_email_slug),
    do: address(club_slug, group_email_slug)

  def address(club_slug, group_email_slug)
      when is_binary(club_slug) and is_binary(group_email_slug) do
    with {:ok, normalized_club_slug} <- Slug.normalize_for_lookup(club_slug),
         {:ok, normalized_group_email_slug} <- Slug.normalize_for_lookup(group_email_slug) do
      normalized_group_email_slug <> "@" <> normalized_club_slug <> "." <> domain()
    else
      {:error, _reason} -> nil
    end
  end

  def address(_club_or_slug, _group_email_slug), do: nil

  @doc """
  Return the configured inbound email domain.

  Defaults to `clubs.memba.io` for this iteration.
  """
  def domain do
    :memba
    |> Application.get_env(:club_inbound_email, [])
    |> Keyword.get(:domain, @default_domain)
    |> normalize_domain()
  end

  defp normalize_domain(domain) do
    domain
    |> to_string()
    |> String.trim()
    |> String.trim_leading("@")
    |> String.downcase()
    |> String.trim_trailing(".")
    |> case do
      "" -> @default_domain
      domain -> domain
    end
  end
end
