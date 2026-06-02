defmodule MembaWeb.AuthControllerTest do
  use MembaWeb.ConnCase, async: false

  import Swoosh.TestAssertions

  alias Memba.Accounts
  alias Memba.Accounts.AuthEmail
  alias Memba.Accounts.SignInToken
  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Membership
  alias Memba.Membership.Projections.Person
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

      assert response =~ "Sign in to your club"
      assert response =~ "Enter your email address and we’ll send you a link to sign in."
      refute response =~ "sign-in link"
      refute response =~ "signs up anyone with a memba.io email as Memba staff"

      assert html
             |> LazyHTML.query("form#sign-in-link-form[action='/auth'][method='post']")
             |> Enum.any?()

      assert html
             |> LazyHTML.query("input#auth_email_input[name='auth[email]'][type='email']")
             |> Enum.any?()

      assert html |> LazyHTML.query("button#request-sign-in-link-button") |> Enum.any?()
    end
  end

  describe "POST /auth" do
    test "shows the same neutral response for known and unknown emails", %{conn: conn} do
      configure_auth_email()
      create_active_member(email: "alice@example.com")

      known_conn = post(conn, ~p"/auth", %{"auth" => %{"email" => " ALICE@EXAMPLE.COM "}})

      assert redirected_to(known_conn) == ~p"/auth"
      assert flash(known_conn, :info) == neutral_notice()

      conn = Phoenix.ConnTest.recycle(conn)
      unknown_conn = post(conn, ~p"/auth", %{"auth" => %{"email" => "unknown@example.com"}})

      assert redirected_to(unknown_conn) == ~p"/auth"
      assert flash(unknown_conn, :info) == neutral_notice()
    end

    test "creates a sign-in token and sends a callback URL email for known member recipients", %{
      conn: conn
    } do
      configure_auth_email()
      create_active_member(email: "alice@example.com")

      conn = post(conn, ~p"/auth", %{"auth" => %{"email" => " ALICE@EXAMPLE.COM "}})

      assert redirected_to(conn) == ~p"/auth"
      assert [%SignInToken{email: "alice@example.com"}] = Repo.all(SignInToken)
      assert_received {:email, %Swoosh.Email{} = email}

      assert email.to == [{"", "alice@example.com"}]
      assert email.text_body =~ "http://localhost:4000/auth/sign-in/"
      assert email.html_body =~ "http://localhost:4000/auth/sign-in/"
    end

    test "creates a sign-in token and sends a callback URL email for new Memba staff", %{
      conn: conn
    } do
      configure_auth_email()

      conn = post(conn, ~p"/auth", %{"auth" => %{"email" => " New.Staff@Memba.IO "}})

      assert redirected_to(conn) == ~p"/auth"
      assert [%SignInToken{email: "new.staff@memba.io"}] = Repo.all(SignInToken)
      assert_received {:email, %Swoosh.Email{} = email}

      assert email.to == [{"", "new.staff@memba.io"}]
      assert email.text_body =~ "http://localhost:4000/auth/sign-in/"
      assert email.html_body =~ "http://localhost:4000/auth/sign-in/"
    end

    test "does not create a token or send email for unknown recipients", %{conn: conn} do
      configure_auth_email()

      conn = post(conn, ~p"/auth", %{"auth" => %{"email" => "unknown@example.com"}})

      assert redirected_to(conn) == ~p"/auth"
      assert Repo.all(SignInToken) == []
      assert_no_email_sent()
    end
  end

  describe "GET /auth/sign-in/:token" do
    test "consumes a valid Memba staff token, signs the browser in, and redirects to the Memba staff area", %{
      conn: conn
    } do
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

      assert redirected_to(conn) == "/admin/clubs?club_id=club-123"
      assert get_session(conn, IdentityAuth.identity_session_key()) == "pat@memba.io"
      assert get_session(conn, IdentityAuth.return_to_session_key()) == nil
    end

    test "rejects unknown tokens without signing in", %{conn: conn} do
      conn = get(conn, ~p"/auth/sign-in/unknown-token")

      assert redirected_to(conn) == ~p"/auth"
      assert flash(conn, :error) == "That sign-in link is invalid or has expired."
      assert get_session(conn, IdentityAuth.identity_session_key()) == nil
    end

    test "rejects expired tokens without signing in", %{conn: conn} do
      requested_at = ~U[2000-01-01 12:00:00.000000Z]
      expired_at = DateTime.add(requested_at, 16 * 60, :second)

      assert {:ok, %{token: token}} =
               Accounts.request_sign_in_link("pat@memba.io", now: requested_at)

      conn = get(conn, ~p"/auth/sign-in/#{token}")

      assert redirected_to(conn) == ~p"/auth"
      assert flash(conn, :error) == "That sign-in link is invalid or has expired."
      assert get_session(conn, IdentityAuth.identity_session_key()) == nil
      assert [%SignInToken{consumed_at: nil}] = Repo.all(SignInToken)
      assert {:error, :expired} = Accounts.consume_sign_in_token(token, now: expired_at)
    end

    test "rejects already-consumed tokens without signing in", %{conn: conn} do
      assert {:ok, %{token: token}} = Accounts.request_sign_in_link("pat@memba.io")
      assert {:ok, %{email: "pat@memba.io"}} = Accounts.consume_sign_in_token(token)

      conn = get(conn, ~p"/auth/sign-in/#{token}")

      assert redirected_to(conn) == ~p"/auth"
      assert flash(conn, :error) == "That sign-in link is invalid or has expired."
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
    "Thanks. You should have an email in your inbox with a sign-in link."
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)

  defp flash(conn, key), do: Phoenix.Flash.get(conn.assigns.flash, key)

  defp create_active_member(attrs) do
    club_id = Ecto.UUID.generate()
    person_id = Ecto.UUID.generate()

    Repo.insert!(%Club{
      club_id: club_id,
      name: Keyword.get(attrs, :club_name, "Kootenay Mountaineering Club")
    })

    Repo.insert!(%Person{
      person_id: person_id,
      name: "Test Member",
      email: Keyword.fetch!(attrs, :email)
    })

    Repo.insert!(%Membership{
      membership_id: Ecto.UUID.generate(),
      club_id: club_id,
      person_id: person_id,
      active: true
    })
  end
end
