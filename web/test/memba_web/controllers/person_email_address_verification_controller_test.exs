defmodule MembaWeb.PersonEmailAddressVerificationControllerTest do
  use MembaWeb.ConnCase, async: true

  describe "GET /my/settings/email-verifications/:token" do
    test "renders the standalone email-address verification callback page", %{conn: conn} do
      conn = get(conn, ~p"/my/settings/email-verifications/test-token")

      response = html_response(conn, 200)
      html = LazyHTML.from_fragment(response)

      assert response =~ "Email verification"
      assert response =~ "Checking your verification link"

      assert html
             |> LazyHTML.query("main#person-email-address-verification")
             |> Enum.any?()

      assert html
             |> LazyHTML.query("section#person-email-address-verification-card")
             |> Enum.any?()

      assert html
             |> LazyHTML.query("[data-status='checking']")
             |> Enum.any?()
    end
  end
end
