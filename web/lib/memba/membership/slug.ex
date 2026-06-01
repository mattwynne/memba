defmodule Memba.Membership.Slug do
  @moduledoc """
  Helpers for generating and validating public club slugs.

  Generated defaults may kebab-case arbitrary club names. Staff-entered values
  must already be address-safe and are validated without silently converting
  spaces, punctuation, underscores, or uppercase letters.
  """

  @max_length 32
  @valid_slug_regex ~r/^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$/

  @doc """
  Returns the maximum supported slug length.
  """
  def max_length, do: @max_length

  @doc """
  Generate a default slug suggestion from a club display name.

  The result is lower-case kebab-case, contains only ASCII letters, numbers, and
  hyphens, has no leading or trailing hyphen, and is at most `max_length/0`
  characters. Inputs that cannot produce a slug return an empty string so the
  normal slug validator can reject them.
  """
  def default_from_name(name) when is_binary(name) do
    name
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
    |> String.slice(0, @max_length)
    |> String.trim("-")
  end

  def default_from_name(_name), do: ""

  @doc """
  Validate a staff-entered slug.

  Valid slugs contain only lowercase ASCII letters, numbers, and single or
  repeated interior hyphens. They cannot be blank, start or end with a hyphen,
  or exceed `max_length/0` characters.
  """
  def validate(slug) when is_binary(slug) do
    cond do
      slug == "" ->
        {:error, :blank}

      String.length(slug) > @max_length ->
        {:error, :too_long}

      not Regex.match?(@valid_slug_regex, slug) ->
        {:error, :invalid_format}

      true ->
        {:ok, slug}
    end
  end

  def validate(_slug), do: {:error, :invalid_format}

  @doc """
  Return whether a value is a valid staff-entered slug.
  """
  def valid?(slug), do: match?({:ok, _slug}, validate(slug))
end
