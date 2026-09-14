defmodule Memba.Membership.CustomGroupSlug do
  @moduledoc """
  Allocates stable, address-safe email slugs for custom groups.

  Allocation is deterministic from the initial display name and the slugs
  already owned by the Club aggregate. The same function can therefore support
  non-authoritative previews without making those previews reservations.
  """

  alias Memba.Membership.Slug

  @fallback_stem "group"

  @spec allocate(term(), MapSet.t(String.t())) :: String.t()
  def allocate(name, occupied_slugs) when is_struct(occupied_slugs, MapSet) do
    stem =
      case Slug.default_from_name(name) do
        "" -> @fallback_stem
        generated_stem -> generated_stem
      end

    if MapSet.member?(occupied_slugs, stem) do
      first_available_suffixed_slug(stem, occupied_slugs)
    else
      stem
    end
  end

  defp first_available_suffixed_slug(stem, occupied_slugs) do
    Stream.iterate(2, &(&1 + 1))
    |> Stream.map(&with_suffix(stem, &1))
    |> Enum.find(&(not MapSet.member?(occupied_slugs, &1)))
  end

  defp with_suffix(stem, number) do
    suffix = "-#{number}"
    max_stem_length = Slug.max_length() - String.length(suffix)

    shortened_stem =
      stem
      |> String.slice(0, max_stem_length)
      |> String.trim("-")

    shortened_stem <> suffix
  end
end
