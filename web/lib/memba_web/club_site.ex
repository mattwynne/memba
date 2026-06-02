defmodule MembaWeb.ClubSite do
  @moduledoc """
  Helpers for Memba-hosted club subdomain URLs.
  """

  alias MembaWeb.Endpoint

  @default_base_domain "lvh.me"

  def url(club, path \\ "/")

  def url(%{slug: slug}, path) when is_binary(slug) do
    %URI{
      scheme: scheme(),
      host: slug <> "." <> base_domain(),
      port: port(),
      path: normalize_path(path)
    }
    |> URI.to_string()
  end

  def url(slug, path) when is_binary(slug) do
    url(%{slug: slug}, path)
  end

  def url(_club, path), do: path

  def base_domain do
    :memba
    |> Application.get_env(:club_site, [])
    |> Keyword.get(:base_domain, @default_base_domain)
    |> to_string()
    |> String.downcase()
    |> String.trim_trailing(".")
  end

  def slug_from_host(host) when is_binary(host) do
    normalized_host = host |> String.downcase() |> String.trim_trailing(".")
    base_domain = base_domain()
    suffix = "." <> base_domain

    cond do
      normalized_host == base_domain ->
        :error

      String.ends_with?(normalized_host, suffix) ->
        normalized_host
        |> String.trim_trailing(suffix)
        |> String.split(".", parts: 2)
        |> case do
          [slug | _rest] when slug != "" -> {:ok, slug}
          _no_slug -> :error
        end

      true ->
        :error
    end
  end

  def slug_from_host(_host), do: :error

  def club_host?(host), do: match?({:ok, _slug}, slug_from_host(host))

  def safe_club_url?(url) when is_binary(url) do
    case URI.parse(url) do
      %URI{scheme: scheme, host: host} when scheme in ["http", "https"] and is_binary(host) ->
        club_host?(host)

      _uri ->
        false
    end
  end

  def safe_club_url?(_url), do: false

  def current_url(%Plug.Conn{} = conn) do
    %URI{
      scheme: Atom.to_string(conn.scheme),
      host: conn.host,
      port: conn.port,
      path: conn.request_path,
      query: if(conn.query_string == "", do: nil, else: conn.query_string)
    }
    |> URI.to_string()
  end

  defp normalize_path(path) when is_binary(path) do
    if String.starts_with?(path, "/"), do: path, else: "/" <> path
  end

  defp normalize_path(_path), do: "/"

  defp scheme do
    :memba
    |> Application.get_env(:club_site, [])
    |> Keyword.get(:scheme, endpoint_scheme())
    |> to_string()
  end

  defp port do
    configured_port =
      :memba
      |> Application.get_env(:club_site, [])
      |> Keyword.get(:port, endpoint_port())

    case {scheme(), configured_port} do
      {"http", 80} -> nil
      {"https", 443} -> nil
      {_scheme, nil} -> nil
      {_scheme, port} -> port
    end
  end

  defp endpoint_scheme do
    Endpoint.config(:url)
    |> Keyword.get(:scheme, "http")
  end

  defp endpoint_port do
    url_port = Endpoint.config(:url) |> Keyword.get(:port)
    http_port = Endpoint.config(:http, []) |> Keyword.get(:port)
    url_port || http_port
  end
end
