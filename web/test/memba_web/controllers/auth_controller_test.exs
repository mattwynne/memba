defmodule MembaWeb.AuthControllerTest do
  use MembaWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Swoosh.TestAssertions

  alias Memba.Accounts
  alias Memba.Accounts.AuthEmail
  alias Memba.Accounts.AuthEmailRequest
  alias Memba.Accounts.SignInToken
  alias Memba.Membership.Projections.Membership
  alias Memba.Repo
  alias MembaWeb.IdentityAuth

  setup do
    original_mailer_config = Application.get_env(:memba, Memba.Mailer)
    original_auth_email_config = Application.get_env(:memba, AuthEmail)

    on_exit(fn ->
      restore_env(Memba.Mailer, original_mailer_config)
      restore_env(AuthEmail, original_auth_email_config)
    end)

    :ok
  end

  describe "GET /auth" do
    test "shows the sign-in form", %{conn: conn} do
      conn = get(conn, ~p"/auth")
      response = html_response(conn, 200)
      html = LazyHTML.from_fragment(response)

      assert response =~ "Sign in with your email."

      assert response =~
               "Use the email address your club or group has for you. We’ll email you a private sign-in link."

      refute response =~ "magic link"
      refute response =~ "signs up anyone with a memba.io email as Memba staff"

      assert html
             |> LazyHTML.query("form#sign-in-link-form[phx-submit='request_sign_in_link']")
             |> Enum.any?()

      assert html
             |> LazyHTML.query("input#auth_email_input[name='auth[email]'][type='email']")
             |> Enum.any?()

      assert html |> LazyHTML.query("button#request-sign-in-link-button") |> Enum.any?()
    end
  end

  describe "auth LiveViews" do
    test "redirects known and unknown emails to the same neutral acknowledgement page", %{
      conn: conn
    } do
      configure_auth_email()
      create_active_member(email: "alice@example.com")

      assert submit_sign_in_link_request(conn, " ALICE@EXAMPLE.COM ") =~
               "Check your email for the sign-in link."

      assert conn
             |> Phoenix.ConnTest.recycle()
             |> submit_sign_in_link_request("unknown@example.com") =~
               "Check your email for the sign-in link."
    end

    test "shows the sign-in link request acknowledgement page", %{conn: conn} do
      {:ok, _view, response} = live(conn, ~p"/auth/check-email")
      html = LazyHTML.from_fragment(response)

      assert response =~ "Check your email for the sign-in link."
      assert response =~ neutral_notice()
      assert html |> LazyHTML.query("section#auth-sign-in-sent") |> Enum.any?()
      assert html |> LazyHTML.query("a#request-another-sign-in-link[href='/auth']") |> Enum.any?()
    end

    test "creates a sign-in token and sends a callback URL email for known member recipients", %{
      conn: conn
    } do
      configure_auth_email()
      create_active_member(email: "alice@example.com")

      assert submit_sign_in_link_request(conn, " ALICE@EXAMPLE.COM ") =~
               "Check your email for the sign-in link."

      assert [%SignInToken{email: "alice@example.com"}] = Repo.all(SignInToken)
      assert_received {:email, %Swoosh.Email{} = email}

      assert email.to == [{"", "alice@example.com"}]
      assert email.from == {"Memba", "auth@mail.memba.io"}
      assert email.subject == "Sign in to Memba"
      assert email.text_body =~ "http://localhost:4000/auth/sign-in/"
      assert email.html_body =~ "http://localhost:4000/auth/sign-in/"
    end

    test "correlates known auth email delivery while keeping unknown progress neutral", %{
      conn: conn
    } do
      configure_auth_email()
      create_active_member(email: "alice@example.com")

      assert submit_sign_in_link_request(conn, " ALICE@EXAMPLE.COM ") =~
               "Check your email for the sign-in link."

      assert [%AuthEmailRequest{} = known_request] = Repo.all(AuthEmailRequest)
      assert Memba.ID.valid?(:auth_email_request, known_request.request_id)
      assert known_request.status == AuthEmailRequest.status_sent()
      assert known_request.recipient_email == "alice@example.com"
      assert known_request.provider == "postmark"
      assert known_request.provider_message_stream == "outbound-authentication"
      assert known_request.sent_at

      assert_received {:email, %Swoosh.Email{} = email}

      assert email.provider_options[:metadata] == %{
               "memba_email_kind" => "auth_sign_in_link",
               "memba_auth_email_request_id" => known_request.request_id
             }

      assert conn
             |> Phoenix.ConnTest.recycle()
             |> submit_sign_in_link_request("unknown@example.com") =~
               "Check your email for the sign-in link."

      requests = Repo.all(AuthEmailRequest)

      assert length(requests) == 2
      assert Enum.all?(requests, &Memba.ID.valid?(:auth_email_request, &1.request_id))
      assert length(Enum.uniq_by(requests, & &1.request_id)) == 2

      assert [%AuthEmailRequest{} = unknown_request] =
               Enum.reject(requests, &(&1.request_id == known_request.request_id))

      assert unknown_request.status == AuthEmailRequest.status_created()
      assert unknown_request.recipient_email == nil
      assert unknown_request.provider == nil
      assert unknown_request.sent_at == nil
      assert_no_email_sent()
    end

    test "creates group-led club-subdomain callback URL emails when sign-in is requested on a known club host",
         %{conn: conn} do
      configure_auth_email()

      create_active_member(
        email: "alice@example.com",
        club_name: "Kootenay Mountaineering Club",
        slug: "kmc"
      )

      assert conn
             |> Map.put(:host, "kmc.lvh.me")
             |> submit_sign_in_link_request(" ALICE@EXAMPLE.COM ") =~
               "Check your email for the sign-in link."

      assert [%SignInToken{email: "alice@example.com"}] = Repo.all(SignInToken)
      assert_received {:email, %Swoosh.Email{} = email}

      assert email.to == [{"", "alice@example.com"}]
      assert email.from == {"Kootenay Mountaineering Club via Memba", "auth@mail.memba.io"}
      assert email.subject == "Sign in to Kootenay Mountaineering Club"
      assert email.text_body =~ "Use this link to sign in to Kootenay Mountaineering Club:"
      assert email.html_body =~ "Kootenay Mountaineering Club"
      assert email.text_body =~ "http://kmc.lvh.me/auth/sign-in/"
      assert email.html_body =~ "http://kmc.lvh.me/auth/sign-in/"
      refute email.text_body =~ "http://localhost:4000/auth/sign-in/"
    end

    test "creates a token and delivers the link to the requested alternate email, not the primary",
         %{conn: conn} do
      configure_auth_email()

      create_active_member(
        email_addresses: [
          %{email: "Alice.Primary@Example.COM", is_primary: true},
          %{email: "Alice.Work@Example.COM", is_primary: false}
        ]
      )

      assert submit_sign_in_link_request(conn, " ALICE.WORK@example.com ") =~
               "Check your email for the sign-in link."

      assert [%SignInToken{email: "alice.work@example.com"}] = Repo.all(SignInToken)
      assert_received {:email, %Swoosh.Email{} = email}

      assert email.to == [{"", "alice.work@example.com"}]
      refute email.to == [{"", "alice.primary@example.com"}]
      assert email.text_body =~ "http://localhost:4000/auth/sign-in/"
      assert email.html_body =~ "http://localhost:4000/auth/sign-in/"
    end

    test "creates a sign-in token and sends a callback URL email for new Memba staff", %{
      conn: conn
    } do
      configure_auth_email()

      assert submit_sign_in_link_request(conn, " New.Staff@Memba.IO ") =~
               "Check your email for the sign-in link."

      assert [%SignInToken{email: "new.staff@memba.io"}] = Repo.all(SignInToken)
      assert_received {:email, %Swoosh.Email{} = email}

      assert email.to == [{"", "new.staff@memba.io"}]
      assert email.text_body =~ "http://localhost:4000/auth/sign-in/"
      assert email.html_body =~ "http://localhost:4000/auth/sign-in/"
    end

    test "does not create a token or send email for unknown recipients", %{conn: conn} do
      configure_auth_email()

      assert submit_sign_in_link_request(conn, "unknown@example.com") =~
               "Check your email for the sign-in link."

      assert Repo.all(SignInToken) == []
      assert_no_email_sent()
    end
  end

  describe "GET /auth/sign-in/:token" do
    test "consumes a first-time Memba staff token, signs the browser in, and redirects to onboarding",
         %{
           conn: conn
         } do
      assert {:ok, %{token: token}} = Accounts.request_sign_in_link("Pat@Memba.IO")

      conn = get(conn, ~p"/auth/sign-in/#{token}")

      assert redirected_to(conn) == ~p"/auth/onboard"
      assert get_session(conn, IdentityAuth.identity_session_key()) == "pat@memba.io"

      assert get_session(conn, IdentityAuth.staff_onboarding_return_to_session_key()) ==
               ~p"/admin/clubs"

      assert [%SignInToken{consumed_at: %DateTime{}}] = Repo.all(SignInToken)
    end

    test "staff who already have a person record go straight to the Memba staff area", %{
      conn: conn
    } do
      insert_membership_person!(name: "Pat Staff", email: "pat@memba.io")
      assert {:ok, %{token: token}} = Accounts.request_sign_in_link("Pat@Memba.IO")

      conn = get(conn, ~p"/auth/sign-in/#{token}")

      assert redirected_to(conn) == ~p"/admin/clubs"
      assert get_session(conn, IdentityAuth.identity_session_key()) == "pat@memba.io"
      assert [%SignInToken{consumed_at: %DateTime{}}] = Repo.all(SignInToken)
    end

    test "redirects to a safe stored return path after sign-in" do
      assert {:ok, %{token: token}} = Accounts.request_sign_in_link("pat@memba.io")

      conn =
        build_conn(:get, "/auth/sign-in/#{token}")
        |> init_test_session(%{
          IdentityAuth.return_to_session_key() => "/admin/clubs?club_id=club-123"
        })
        |> get("/auth/sign-in/#{token}")

      assert redirected_to(conn) == ~p"/auth/onboard"
      assert get_session(conn, IdentityAuth.identity_session_key()) == "pat@memba.io"
      assert get_session(conn, IdentityAuth.return_to_session_key()) == nil

      assert get_session(conn, IdentityAuth.staff_onboarding_return_to_session_key()) ==
               "/admin/clubs?club_id=club-123"
    end

    test "same-host magic-link flow preserves a private club subdomain return URL", %{conn: conn} do
      configure_auth_email()

      create_active_member(
        email: "alice@example.com",
        club_name: "Kootenay Mountaineering Club",
        slug: "kmc"
      )

      conn =
        conn
        |> Map.put(:host, "kmc.lvh.me")
        |> get(~p"/messages/new")

      assert redirected_to(conn) == ~p"/auth"

      assert get_session(conn, IdentityAuth.return_to_session_key()) ==
               "http://kmc.lvh.me/messages/new"

      {:ok, view, _html} = live(conn, ~p"/auth")

      view
      |> form("#sign-in-link-form", auth: %{email: "alice@example.com"})
      |> render_submit()

      assert [%SignInToken{email: "alice@example.com"}] = Repo.all(SignInToken)
      assert_received {:email, %Swoosh.Email{} = email}
      assert [_, token] = Regex.run(~r{/auth/sign-in/([^\s"<]+)}, email.text_body)
      assert email.subject == "Sign in to Kootenay Mountaineering Club"
      assert email.text_body =~ "http://kmc.lvh.me/auth/sign-in/#{token}"

      conn = get(conn, ~p"/auth/sign-in/#{token}")

      assert redirected_to(conn) == "http://kmc.lvh.me/messages/new"
      assert get_session(conn, IdentityAuth.identity_session_key()) == "alice@example.com"
    end

    test "magic links can carry a safe post-auth destination without a stored session", %{
      conn: conn
    } do
      create_active_member(
        email: "alice@example.com",
        club_name: "Kootenay Mountaineering Club",
        slug: "kmc"
      )

      assert {:ok, %{token: token}} = Accounts.request_sign_in_link("alice@example.com")

      conn =
        get(
          conn,
          "/auth/sign-in/#{token}?return_to=#{URI.encode_www_form("http://kmc.lvh.me/")}"
        )

      assert redirected_to(conn) == "http://kmc.lvh.me/"
      assert get_session(conn, IdentityAuth.identity_session_key()) == "alice@example.com"
      assert get_session(conn, IdentityAuth.return_to_session_key()) == nil
    end

    test "rejects unknown tokens without signing in", %{conn: conn} do
      conn = get(conn, ~p"/auth/sign-in/unknown-token")

      assert redirected_to(conn) == ~p"/auth"

      assert flash(conn, :error) ==
               "That sign-in link is no longer valid. Please ask for a new sign-in link."

      assert get_session(conn, IdentityAuth.identity_session_key()) == nil
    end

    test "rejects expired tokens without signing in", %{conn: conn} do
      requested_at = ~U[2000-01-01 12:00:00.000000Z]
      expired_at = DateTime.add(requested_at, 16 * 60, :second)

      assert {:ok, %{token: token}} =
               Accounts.request_sign_in_link("pat@memba.io", now: requested_at)

      conn = get(conn, ~p"/auth/sign-in/#{token}")

      assert redirected_to(conn) == ~p"/auth"

      assert flash(conn, :error) ==
               "That sign-in link is no longer valid. Please ask for a new sign-in link."

      assert get_session(conn, IdentityAuth.identity_session_key()) == nil
      assert [%SignInToken{consumed_at: nil}] = Repo.all(SignInToken)
      assert {:error, :expired} = Accounts.consume_sign_in_token(token, now: expired_at)
    end

    test "rejects already-consumed tokens without signing in", %{conn: conn} do
      assert {:ok, %{token: token}} = Accounts.request_sign_in_link("pat@memba.io")
      assert {:ok, %{email: "pat@memba.io"}} = Accounts.consume_sign_in_token(token)

      conn = get(conn, ~p"/auth/sign-in/#{token}")

      assert redirected_to(conn) == ~p"/auth"

      assert flash(conn, :error) ==
               "That sign-in link is no longer valid. Please ask for a new sign-in link."

      assert get_session(conn, IdentityAuth.identity_session_key()) == nil
      assert [%SignInToken{consumed_at: %DateTime{}}] = Repo.all(SignInToken)
    end

    test "redirects already-signed-in browsers home when reopening an already-consumed link" do
      assert {:ok, %{token: token}} = Accounts.request_sign_in_link("pat@memba.io")
      assert {:ok, %{email: "pat@memba.io"}} = Accounts.consume_sign_in_token(token)

      conn =
        build_conn(:get, "/auth/sign-in/#{token}")
        |> init_test_session(%{IdentityAuth.identity_session_key() => "pat@memba.io"})
        |> get("/auth/sign-in/#{token}")

      assert redirected_to(conn) == ~p"/"
      assert flash(conn, :error) == nil
      assert get_session(conn, IdentityAuth.identity_session_key()) == "pat@memba.io"
      assert [%SignInToken{consumed_at: %DateTime{}}] = Repo.all(SignInToken)
    end
  end

  describe "GET /auth/onboard" do
    test "shows the staff onboarding form for signed-in staff without a person record", %{
      conn: conn
    } do
      conn =
        conn
        |> init_test_session(%{IdentityAuth.identity_session_key() => "pat@memba.io"})
        |> get(~p"/auth/onboard")

      response = html_response(conn, 200)
      html = LazyHTML.from_fragment(response)

      assert response =~ "Tell us your name"
      assert html |> LazyHTML.query("section#staff-onboarding") |> Enum.any?()

      assert html
             |> LazyHTML.query("form#staff-onboarding-form[phx-submit='finish_onboarding']")
             |> Enum.any?()

      assert html |> LazyHTML.query("input#staff-name-input[name='staff[name]']") |> Enum.any?()
    end

    test "redirects onboarded staff away from the onboarding form", %{conn: conn} do
      insert_membership_person!(name: "Pat Staff", email: "pat@memba.io")

      conn =
        conn
        |> init_test_session(%{IdentityAuth.identity_session_key() => "pat@memba.io"})
        |> get(~p"/auth/onboard")

      assert redirected_to(conn) == ~p"/admin/clubs"
    end
  end

  describe "staff onboarding LiveView" do
    test "first-time Memba staff can sign in, enter their name, and continue to Staff", %{
      conn: conn
    } do
      assert {:ok, %{token: token}} = Accounts.request_sign_in_link(" Pat@Memba.IO ")

      conn
      |> visit(~p"/auth/sign-in/#{token}")
      |> assert_path(~p"/auth/onboard")
      |> assert_has("section#staff-onboarding")
      |> fill_in("Your name", with: " Pat Staff ")
      |> click_button("Continue to Memba staff")
      |> assert_path(~p"/admin/clubs")
      |> assert_has("#clubs-index")

      assert %{name: "Pat Staff", email: "pat@memba.io"} =
               Memba.Membership.get_person_by_email("pat@memba.io")
    end

    test "creates a person record for first-time staff and redirects to the staff area", %{
      conn: conn
    } do
      {:ok, view, _html} =
        conn
        |> init_test_session(%{IdentityAuth.identity_session_key() => "pat@memba.io"})
        |> live(~p"/auth/onboard")

      assert {:error, {:live_redirect, %{to: "/admin/clubs"}}} =
               view
               |> form("#staff-onboarding-form", staff: %{name: " Pat Staff "})
               |> render_submit()

      assert %{name: "Pat Staff", email: "pat@memba.io"} =
               Memba.Membership.get_person_by_email("pat@memba.io")
    end

    test "keeps first-time staff on onboarding when the name is blank", %{conn: conn} do
      {:ok, view, _html} =
        conn
        |> init_test_session(%{IdentityAuth.identity_session_key() => "pat@memba.io"})
        |> live(~p"/auth/onboard")

      response =
        view
        |> form("#staff-onboarding-form", staff: %{name: " "})
        |> render_submit()

      assert response =~ "Tell us your name"
      assert response =~ "Please tell us your name."
      assert Memba.Membership.get_person_by_email("pat@memba.io") == nil
    end
  end

  describe "DELETE /auth" do
    test "signs the browser out", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{IdentityAuth.identity_session_key() => "pat@memba.io"})
        |> delete(~p"/auth")

      assert redirected_to(conn) == ~p"/"
      assert get_session(conn, IdentityAuth.identity_session_key()) == nil
      assert flash(conn, :info) == "Signed out."
    end
  end

  defp configure_auth_email do
    Application.put_env(:memba, Memba.Mailer,
      adapter: Swoosh.Adapters.Test,
      api_key: "server-token"
    )

    Application.put_env(:memba, AuthEmail,
      from: "auth@mail.memba.io",
      message_stream: "outbound-authentication"
    )
  end

  defp neutral_notice do
    "If that email address can sign in to Memba, the sign-in email is on its way."
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)

  defp flash(conn, key), do: Phoenix.Flash.get(conn.assigns.flash, key)

  defp submit_sign_in_link_request(conn, email) do
    {:ok, view, _html} = live(conn, ~p"/auth")

    view
    |> form("#sign-in-link-form", auth: %{email: email})
    |> render_submit()
  end

  defp create_active_member(attrs) do
    club_id = Memba.ID.generate(:club)
    person_id = Memba.ID.generate(:person)

    attrs
    |> club_attrs(club_id)
    |> insert_membership_club!()

    person =
      case Keyword.fetch(attrs, :email_addresses) do
        {:ok, email_addresses} ->
          primary_email_address = Enum.find(email_addresses, & &1.is_primary)

          person =
            insert_membership_person!(
              person_id: person_id,
              name: "Test Member",
              email: primary_email_address.email
            )

          for email_address <- email_addresses, email_address.is_primary == false do
            insert_membership_person_email_address!(
              person_id: person_id,
              email: email_address.email,
              is_primary: false
            )
          end

          person

        :error ->
          insert_membership_person!(
            person_id: person_id,
            name: "Test Member",
            email: Keyword.fetch!(attrs, :email)
          )
      end

    Repo.insert!(%Membership{
      membership_id: Memba.ID.generate(:membership),
      club_id: club_id,
      person_id: person.person_id,
      active: true
    })

    %{club_id: club_id, person_id: person.person_id}
  end

  defp club_attrs(attrs, club_id) do
    base = [
      club_id: club_id,
      name: Keyword.get(attrs, :club_name, "Kootenay Mountaineering Club")
    ]

    case Keyword.fetch(attrs, :slug) do
      {:ok, slug} -> Keyword.put(base, :slug, slug)
      :error -> base
    end
  end
end
