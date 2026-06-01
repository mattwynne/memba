defmodule MembaWeb.UserAuth do
  @moduledoc """
  Browser authentication helpers for shared magic-link sign-in.

  The session stores only the signed-in email address. Current identity data such
  as staff status and active clubs is derived on each request from the Accounts
  context so authorization uses current membership projections.
  """

  import Plug.Conn

  alias Memba.Accounts

  @identity_session_key "current_identity_email"
  @return_to_session_key "identity_return_to"
  @auth_path "/auth"

  @doc """
  Return the session key used to store the signed-in email address.
  """
  def identity_session_key, do: @identity_session_key

  @doc """
  Return the session key used to preserve the original authenticated return path.
  """
  def return_to_session_key, do: @return_to_session_key

  @doc """
  Renew the browser session and store the normalized signed-in email address.

  Invalid or blank emails clear the signed-in session, matching the safe default
  of treating the browser as unauthenticated.
  """
  def log_in_identity(conn, email) do
    case Accounts.normalize_email(email) do
      nil ->
        log_out_identity(conn)

      normalized_email ->
        conn
        |> renew_session()
        |> put_session(@identity_session_key, normalized_email)
    end
  end

  @doc """
  Clear the browser session for sign out or invalid identity state.
  """
  def log_out_identity(conn) do
    renew_session(conn)
  end

  @doc """
  Fetch the current signed-in identity from the browser session.

  Assigns are always present so controllers and templates can branch safely:

    * `:current_identity` - `%{email:, staff?:, active_clubs:}` or `nil`
    * `:current_identity_email` - normalized email or `nil`
    * `:current_identity_staff?` - boolean staff authorization flag
    * `:current_identity_clubs` - active club read models for the email
  """
  def fetch_current_identity(conn, _opts) do
    conn
    |> get_session(@identity_session_key)
    |> current_identity_from_email()
    |> then(&assign_current_identity(conn, &1))
  end

  @doc """
  Require any signed-in identity for a browser request.

  Unauthenticated GET requests are redirected to `/auth` and their current path,
  including query string, is stored in the session for the future callback flow.
  """
  def require_authenticated_identity(conn, _opts) do
    conn = ensure_current_identity(conn)

    if conn.assigns.current_identity do
      conn
    else
      redirect_to_auth(conn)
    end
  end

  @doc """
  Require the signed-in identity to be a Memba staff email.
  """
  def require_staff_identity(conn, _opts) do
    conn = ensure_current_identity(conn)

    cond do
      is_nil(conn.assigns.current_identity) ->
        redirect_to_auth(conn)

      conn.assigns.current_identity.staff? ->
        conn

      true ->
        forbidden(conn)
    end
  end

  @doc """
  Require the signed-in identity to be an active member of the requested club.

  The club is read from the `club_id` query parameter. Missing, invalid, or
  unauthorized club IDs are forbidden for signed-in identities.
  """
  def require_active_club_member(conn, _opts) do
    conn = ensure_current_identity(conn)

    if conn.assigns.current_identity do
      conn = fetch_query_params(conn)
      club_id = Map.get(conn.query_params, "club_id")

      if Accounts.active_member_of_club?(club_id, conn.assigns.current_identity.email) do
        conn
      else
        forbidden(conn)
      end
    else
      redirect_to_auth(conn)
    end
  end

  @doc """
  Require active club membership only when a route carries a `club_id` query
  parameter.

  Public routes that also act as temporary club/member entry points can use this
  plug without blocking ordinary public requests that do not select a club.
  """
  def require_active_club_member_if_club_id_present(conn, _opts) do
    conn = fetch_query_params(conn)

    cond do
      not Map.has_key?(conn.query_params, "club_id") ->
        conn

      conn.method == "GET" and is_nil(ensure_current_identity(conn).assigns.current_identity) ->
        conn

      true ->
        require_active_club_member(conn, [])
    end
  end

  @doc """
  LiveView mount hooks for current identity assignment and auth gates.
  """
  def on_mount(:mount_current_identity, _params, session, socket) do
    {:cont, assign_current_identity(socket, current_identity_from_session(session))}
  end

  def on_mount(:require_authenticated_identity, _params, session, socket) do
    socket = assign_current_identity(socket, current_identity_from_session(session))

    if socket.assigns.current_identity do
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: @auth_path)}
    end
  end

  def on_mount(:require_staff_identity, _params, session, socket) do
    socket = assign_current_identity(socket, current_identity_from_session(session))

    cond do
      is_nil(socket.assigns.current_identity) ->
        {:halt, Phoenix.LiveView.redirect(socket, to: @auth_path)}

      socket.assigns.current_identity.staff? ->
        {:cont, socket}

      true ->
        {:halt, forbidden_redirect(socket)}
    end
  end

  def on_mount(:require_active_club_member, params, session, socket) do
    socket = assign_current_identity(socket, current_identity_from_session(session))

    cond do
      is_nil(socket.assigns.current_identity) ->
        {:halt, Phoenix.LiveView.redirect(socket, to: @auth_path)}

      Accounts.active_member_of_club?(
        Map.get(params, "club_id"),
        socket.assigns.current_identity.email
      ) ->
        {:cont, socket}

      true ->
        {:halt, forbidden_redirect(socket)}
    end
  end

  defp ensure_current_identity(conn) do
    if Map.has_key?(conn.assigns, :current_identity) do
      conn
    else
      fetch_current_identity(conn, [])
    end
  end

  defp current_identity_from_session(session) when is_map(session) do
    session
    |> Map.get(@identity_session_key)
    |> current_identity_from_email()
  end

  defp current_identity_from_email(email) do
    case Accounts.normalize_email(email) do
      nil ->
        nil

      normalized_email ->
        %{
          email: normalized_email,
          staff?: Accounts.staff_email?(normalized_email),
          active_clubs: Accounts.list_active_clubs_for_email(normalized_email)
        }
    end
  end

  defp assign_current_identity(%Plug.Conn{} = conn, identity) do
    assign(conn, :current_identity, identity)
    |> assign(:current_identity_email, identity_email(identity))
    |> assign(:current_identity_staff?, identity_staff?(identity))
    |> assign(:current_identity_clubs, identity_clubs(identity))
  end

  defp assign_current_identity(socket, identity) do
    Phoenix.Component.assign(socket,
      current_identity: identity,
      current_identity_email: identity_email(identity),
      current_identity_staff?: identity_staff?(identity),
      current_identity_clubs: identity_clubs(identity)
    )
  end

  defp identity_email(nil), do: nil
  defp identity_email(identity), do: identity.email

  defp identity_staff?(nil), do: false
  defp identity_staff?(identity), do: identity.staff?

  defp identity_clubs(nil), do: []
  defp identity_clubs(identity), do: identity.active_clubs

  defp redirect_to_auth(conn) do
    conn
    |> maybe_store_return_to()
    |> Phoenix.Controller.redirect(to: @auth_path)
    |> halt()
  end

  defp maybe_store_return_to(conn) do
    if conn.method == "GET" do
      put_session(conn, @return_to_session_key, current_return_path(conn))
    else
      conn
    end
  end

  defp current_return_path(%Plug.Conn{request_path: request_path, query_string: ""}) do
    request_path
  end

  defp current_return_path(%Plug.Conn{request_path: request_path, query_string: query_string}) do
    request_path <> "?" <> query_string
  end

  defp forbidden(conn) do
    conn
    |> send_resp(:forbidden, "Forbidden")
    |> halt()
  end

  defp forbidden_redirect(socket) do
    socket
    |> Phoenix.LiveView.put_flash(:error, "You are not authorized to access that page.")
    |> Phoenix.LiveView.redirect(to: "/")
  end

  defp renew_session(conn) do
    Plug.CSRFProtection.delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end
end
