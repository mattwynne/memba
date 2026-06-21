defmodule Memba.ClubInboundEmailAddress do
  @moduledoc """
  Derives member-facing inbound email addresses for clubs.

  The current slice uses one implicit whole-club address per club subdomain:
  `everyone@<club-slug>.<configured-domain>`.
  """

  alias Memba.Membership.Slug

  @default_domain "clubs.memba.io"

  @doc """
  Build the inbound email address for a club or club slug.

  Returns `nil` when the slug is missing or not a valid public club slug.
  """
  def address(club_or_slug)

  def address(%{slug: slug}), do: address(slug)

  def address(slug) when is_binary(slug) do
    with {:ok, normalized_slug} <- Slug.normalize_for_lookup(slug) do
      "everyone@" <> normalized_slug <> "." <> domain()
    else
      {:error, _reason} -> nil
    end
  end

  def address(_club_or_slug), do: nil

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
