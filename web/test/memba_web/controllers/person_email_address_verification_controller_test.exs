defmodule MembaWeb.PersonEmailAddressVerificationControllerTest do
  use MembaWeb.ConnCase, async: false

  alias Memba.Membership
  alias Memba.Membership.Events.PersonEmailAddressVerified
  alias Memba.Membership.Projectors.Person, as: PersonProjector
  alias Memba.Membership.Projections.PersonEmailAddress
  alias Memba.ReadModelChanges
  alias Memba.Repo

  setup do
    Memba.EventSourcedCase.reset_event_sourced_system!()
    :ok
  end

  describe "GET /my/settings/email-verifications/:token" do
    test "verifies a pending email address, publishes a read-model notification, and renders success",
         %{conn: conn} do
      person_id = create_person!(email: "alice@example.com")
      token = verification_token!(person_id, "Alice+New@Example.COM")

      Phoenix.PubSub.subscribe(Memba.PubSub, ReadModelChanges.topic())

      conn = get(conn, ~p"/my/settings/email-verifications/#{token}")

      response = html_response(conn, 200)
      html = LazyHTML.from_fragment(response)

      assert response =~ "Email verification"
      assert response =~ "Email verified, you can close this browser."

      assert %PersonEmailAddress{
               verified_at: %DateTime{},
               is_primary: false
             } =
               Repo.get_by(PersonEmailAddress,
                 person_id: person_id,
                 normalized_email: "alice+new@example.com"
               )

      assert_receive {:read_model_changed,
                      %{
                        projector: PersonProjector,
                        source_event: %PersonEmailAddressVerified{
                          person_id: ^person_id,
                          normalized_email: "alice+new@example.com"
                        }
                      }}

      assert html
             |> LazyHTML.query("main#person-email-address-verification")
             |> Enum.any?()

      assert html
             |> LazyHTML.query("section#person-email-address-verification-card")
             |> Enum.any?()

      assert html
             |> LazyHTML.query("[data-status='success']")
             |> Enum.any?()
    end

    test "renders a calm invalid/expired state for an unknown token", %{conn: conn} do
      conn = get(conn, ~p"/my/settings/email-verifications/not-a-real-token")

      response = html_response(conn, 422)
      html = LazyHTML.from_fragment(response)

      assert response =~ "Email verification"
      assert response =~ "This verification link is invalid or expired."
      assert response =~ "You can close this browser and ask for another verification email."

      assert html
             |> LazyHTML.query("main#person-email-address-verification[data-status='invalid']")
             |> Enum.any?()
    end

    test "does not verify an address from an expired token", %{conn: conn} do
      person_id = create_person!(email: "alice@example.com")
      issued_at = DateTime.add(DateTime.utc_now(:microsecond), -16 * 60, :second)
      token = verification_token!(person_id, "alice+expired@example.com", now: issued_at)

      conn = get(conn, ~p"/my/settings/email-verifications/#{token}")

      response = html_response(conn, 422)

      assert response =~ "This verification link is invalid or expired."

      assert %PersonEmailAddress{verified_at: nil} =
               Repo.get_by(PersonEmailAddress,
                 person_id: person_id,
                 normalized_email: "alice+expired@example.com"
               )
    end
  end

  defp create_person!(attrs) do
    person_id = Keyword.get_lazy(attrs, :person_id, fn -> Memba.ID.generate(:person) end)
    email = Keyword.fetch!(attrs, :email)

    assert :ok =
             Membership.create_person(
               %{person_id: person_id, name: "Alice Member", email: email},
               consistency: :strong
             )

    person_id
  end

  defp verification_token!(person_id, email, opts \\ []) do
    assert :ok =
             Membership.add_person_email_address(
               %{person_id: person_id, email: email},
               consistency: :strong
             )

    assert {:ok, %{issuer_result: %{token: token}}} =
             Membership.resend_person_email_address_verification(
               %{person_id: person_id, email: email},
               opts
             )

    token
  end
end
