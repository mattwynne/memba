defmodule MembaWeb.PageController do
  use MembaWeb, :controller

  require Logger

  alias Memba.Accounts
  alias Memba.Accounts.AuthEmail
  alias Memba.Membership
  alias Memba.Membership.EmailAddresses
  alias Memba.Onboarding
  alias Memba.Onboarding.NewRequestEmail
  alias MembaWeb.ClubSite

  @publicly_hidden_club_slugs MapSet.new(["test"])

  def home(conn, params) do
    case ClubSite.slug_from_host(conn.host) do
      {:ok, slug} -> home_for_public_club_slug(conn, slug)
      :error -> home_for_params(conn, params)
    end
  end

  defp home_for_params(conn, %{"club_id" => club_id}) do
    case Membership.get_club(club_id) do
      nil -> not_found(conn)
      club -> redirect(conn, external: ClubSite.url(club))
    end
  end

  defp home_for_params(conn, _params) do
    page_title =
      if conn.assigns.current_identity do
        "Your clubs"
      else
        "A simpler way to keep your group members informed"
      end

    conn
    |> assign(:page_title, page_title)
    |> render(:home)
  end

  defp home_for_public_club_slug(conn, slug) do
    case Membership.get_club_by_slug(slug) do
      nil ->
        not_found(conn)

      club ->
        if signed_in_active_member?(conn, club.club_id) do
          redirect(conn, to: ~p"/conversations")
        else
          render_public_club_page_or_not_found(conn, club)
        end
    end
  end

  defp signed_in_active_member?(%{assigns: %{current_identity: nil}}, _club_id), do: false

  defp signed_in_active_member?(%{assigns: %{current_identity: identity}}, club_id) do
    Membership.active_member_of_club_by_email?(club_id, identity.email)
  end

  def about(conn, _params) do
    conn
    |> assign(:page_title, "About")
    |> render(:about)
  end

  def get_started(conn, params) do
    conn
    |> assign(:request_submitted?, Map.get(params, "submitted") == "true")
    |> render_get_started(Onboarding.change_request(%{}))
  end

  def submit_get_started(conn, params) do
    cond do
      signed_out_verification_request?(conn, params) ->
        request_get_started_verification(conn, Map.get(params, "verification", %{}))

      not signed_in_get_started?(conn) ->
        require_get_started_verification(conn)

      true ->
        request_params = Map.get(params, "request", %{})

        {request_attrs, request_opts} = get_started_request_attrs(conn, request_params)

        case Onboarding.create_request(request_attrs, request_opts) do
          {:ok, request} ->
            deliver_new_request_notification(request)
            redirect(conn, to: ~p"/get-started?submitted=true")

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> assign(:request_submitted?, false)
            |> render_get_started(changeset)
        end
    end
  end

  defp require_get_started_verification(conn) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_flash(:error, "Verify your email before completing your request.")
    |> assign(:request_submitted?, false)
    |> render_get_started(Onboarding.change_request(%{}))
  end

  defp signed_out_verification_request?(conn, params) do
    not signed_in_get_started?(conn) and Map.has_key?(params, "verification")
  end

  defp request_get_started_verification(conn, verification_params) do
    case verified_get_started_email(verification_params) do
      {:ok, email} ->
        request_id = create_and_deliver_get_started_sign_in_link(email)
        redirect(conn, to: check_email_path(request_id))

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_flash(:error, "Enter a valid email address.")
        |> assign(:request_submitted?, false)
        |> render_get_started(
          Onboarding.change_request(%{}),
          Phoenix.Component.to_form(%{changeset | action: :validate}, as: :verification)
        )
    end
  end

  defp verified_get_started_email(verification_params) do
    changeset = verification_changeset(verification_params)

    if changeset.valid? do
      changeset
      |> Ecto.Changeset.get_field(:email)
      |> EmailAddresses.normalize_email()
      |> case do
        {:ok, %{normalized_email: normalized_email}} -> {:ok, normalized_email}
        {:error, :invalid_email} -> {:error, changeset}
      end
    else
      {:error, changeset}
    end
  end

  defp verification_changeset(params) when is_map(params) do
    {%{}, %{email: :string}}
    |> Ecto.Changeset.cast(params, [:email])
    |> Ecto.Changeset.validate_required([:email])
    |> Ecto.Changeset.validate_change(:email, fn :email, email ->
      case EmailAddresses.normalize_email(email) do
        {:ok, _email} -> []
        {:error, :invalid_email} -> [email: "must be a valid email address"]
      end
    end)
  end

  defp verification_changeset(_params), do: verification_changeset(%{})

  defp check_email_path(nil), do: ~p"/auth/check-email"
  defp check_email_path(request_id), do: ~p"/auth/check-email/#{request_id}"

  defp create_and_deliver_get_started_sign_in_link(email) do
    auth_email_request = create_get_started_auth_email_request(email)

    case Accounts.create_sign_in_token(email) do
      {:ok, %{email: recipient_email, token: token}} ->
        deliver_get_started_sign_in_link(recipient_email, token, auth_email_request)
        auth_email_request_id(auth_email_request)

      {:error, reason} ->
        Logger.warning("Could not create get-started sign-in link: #{inspect(reason)}")
        auth_email_request_id(auth_email_request)
    end
  end

  defp create_get_started_auth_email_request(email) do
    case Accounts.create_auth_email_request(%{recipient_email: email}) do
      {:ok, request} ->
        request

      {:error, reason} ->
        Logger.warning(
          "Could not create get-started auth email progress request: #{inspect(reason)}"
        )

        nil
    end
  end

  defp auth_email_request_id(%{request_id: request_id}), do: request_id
  defp auth_email_request_id(nil), do: nil

  defp deliver_get_started_sign_in_link(recipient_email, token, auth_email_request) do
    callback_url = get_started_sign_in_callback_url(token)

    case AuthEmail.deliver_sign_in_link(
           recipient_email,
           callback_url,
           auth_email_context(auth_email_request)
         ) do
      :ok ->
        mark_get_started_auth_email_sent(auth_email_request, recipient_email)

      {:error, reason} ->
        Logger.warning("Could not deliver get-started sign-in link email: #{inspect(reason)}")
    end
  end

  defp auth_email_context(%{request_id: request_id}), do: %{auth_email_request_id: request_id}
  defp auth_email_context(nil), do: %{}

  defp mark_get_started_auth_email_sent(nil, _recipient_email), do: :ok

  defp mark_get_started_auth_email_sent(auth_email_request, recipient_email) do
    attrs = %{
      recipient_email: recipient_email,
      provider: auth_email_provider(),
      provider_message_stream: auth_email_message_stream()
    }

    case Accounts.mark_auth_email_sent(auth_email_request.request_id, attrs) do
      {:ok, _request} ->
        :ok

      {:error, reason} ->
        Logger.warning(
          "Could not mark get-started auth email progress request sent: #{inspect(reason)}"
        )
    end
  end

  defp auth_email_provider do
    case Keyword.get(auth_email_config(), :provider, :postmark) do
      :resend -> "resend"
      _provider -> "postmark"
    end
  end

  defp auth_email_message_stream do
    Keyword.get(auth_email_config(), :message_stream)
  end

  defp auth_email_config do
    Application.get_env(:memba, AuthEmail, [])
  end

  defp get_started_sign_in_callback_url(token) do
    MembaWeb.Endpoint.url() <> ~p"/auth/sign-in/#{token}?#{[return_to: ~p"/get-started"]}"
  end

  defp deliver_new_request_notification(request) do
    case NewRequestEmail.deliver(request) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.warning(
          "Could not deliver onboarding request notification email: #{inspect(reason)}"
        )
    end
  end

  def terms(conn, _params) do
    conn
    |> assign(:page_title, "Terms of Service")
    |> render(:terms)
  end

  def privacy(conn, _params) do
    conn
    |> assign(:page_title, "Privacy Policy")
    |> render(:privacy)
  end

  defp render_get_started(conn, changeset, verification_form \\ nil) do
    conn
    |> assign(:page_title, "Request access")
    |> assign(:signed_in_requester, signed_in_get_started_requester(conn))
    |> assign(:signed_in_get_started?, signed_in_get_started?(conn))
    |> assign(
      :verification_form,
      verification_form || Phoenix.Component.to_form(%{}, as: :verification)
    )
    |> assign(:request_form, Phoenix.Component.to_form(changeset, as: :request))
    |> render(:get_started)
  end

  defp signed_in_get_started?(%{assigns: %{current_identity: identity}}), do: not is_nil(identity)
  defp signed_in_get_started?(_conn), do: false

  defp get_started_request_attrs(conn, request_params) do
    case {Map.get(conn.assigns, :current_identity), signed_in_get_started_requester(conn)} do
      {%{email: identity_email}, nil} ->
        attrs =
          request_params
          |> verified_identity_request_details()
          |> Map.put("requester_email", identity_email)

        {attrs, [verified_identity_email: identity_email]}

      {nil, _requester} ->
        {%{}, []}

      {_identity, requester} ->
        attrs =
          request_params
          |> club_request_details()
          |> Map.merge(verified_requester_details(requester))

        {attrs,
         [verified_identity_email: requester.email, requester_person_id: requester.person_id]}
    end
  end

  defp signed_in_get_started_requester(%{assigns: %{current_identity: %{email: email}}}) do
    case Membership.get_person_by_email(email) do
      nil ->
        nil

      person ->
        %{
          name: person.name,
          email: email,
          person_id: person.person_id
        }
    end
  end

  defp signed_in_get_started_requester(_conn), do: nil

  defp verified_identity_request_details(request_params) do
    %{
      "requester_name" => request_param(request_params, "requester_name"),
      "requested_club_name" => request_param(request_params, "requested_club_name"),
      "note" => request_param(request_params, "note")
    }
  end

  defp club_request_details(request_params) do
    %{
      "requested_club_name" => request_param(request_params, "requested_club_name"),
      "note" => request_param(request_params, "note")
    }
  end

  defp verified_requester_details(requester) do
    %{
      "requester_name" => requester.name,
      "requester_email" => requester.email
    }
  end

  defp request_param(request_params, key) when is_map(request_params) do
    atom_key =
      case key do
        "requester_name" -> :requester_name
        "requested_club_name" -> :requested_club_name
        "note" -> :note
      end

    Map.get(request_params, key) || Map.get(request_params, atom_key)
  end

  defp request_param(_request_params, _key), do: nil

  defp render_public_club_page_or_not_found(conn, nil), do: not_found(conn)

  defp render_public_club_page_or_not_found(conn, club) do
    if public_club_page_visible?(club) do
      render_public_club_page(conn, club.club_id)
    else
      not_found(conn)
    end
  end

  defp public_club_page_visible?(club) do
    not MapSet.member?(@publicly_hidden_club_slugs, club.slug)
  end

  defp render_public_club_page(conn, club_id) do
    Phoenix.LiveView.Controller.live_render(conn, MembaWeb.PublicClubPageLive,
      session: %{"club_id" => club_id}
    )
  end

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_view(html: MembaWeb.ErrorHTML)
    |> render(:"404")
  end
end
