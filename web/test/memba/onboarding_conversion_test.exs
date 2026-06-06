defmodule Memba.OnboardingConversionTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Accounts.AuthEmail
  alias Memba.Accounts.SignInToken
  alias Memba.Membership
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Onboarding
  alias Memba.Onboarding.Request
  alias Memba.Repo

  setup do
    original_mailer_config = Application.get_env(:memba, Memba.Mailer)
    original_auth_email_config = Application.get_env(:memba, AuthEmail)

    on_exit(fn ->
      restore_env(Memba.Mailer, original_mailer_config)
      restore_env(AuthEmail, original_auth_email_config)
    end)

    :ok
  end

  describe "convert_request_to_club/3" do
    test "creates a club, new person, active membership, converted request, and wraps welcome email delivery" do
      request = request_fixture("West Coast Paddlers", requester_email: "robin@example.com")
      parent = self()

      assert {:ok, conversion} =
               Onboarding.convert_request_to_club(
                 request.request_id,
                 %{"name" => "West Coast Paddlers", "slug" => "west-coast-paddlers"},
                 staff_email: "Pat@Memba.IO",
                 welcome_email_fun: fn conversion ->
                   send(parent, {:welcome_email, conversion})
                   :ok
                 end
               )

      assert conversion.welcome_email == :ok
      assert %Request{status: "converted"} = converted_request = conversion.request
      assert converted_request.request_id == request.request_id
      assert converted_request.triaged_by_staff_email == "pat@memba.io"
      assert %DateTime{} = converted_request.triaged_at
      assert converted_request.converted_club_id == conversion.club.club_id
      assert converted_request.converted_person_id == conversion.person.person_id
      assert converted_request.converted_membership_id == conversion.membership_id
      refute conversion.person_reused?

      assert conversion.club.name == "West Coast Paddlers"
      assert conversion.club.slug == "west-coast-paddlers"
      assert conversion.person.name == "Robin Requester"
      assert conversion.person.email == "robin@example.com"

      assert %MembershipProjection{active: true} =
               Repo.get!(MembershipProjection, conversion.membership_id)

      assert Membership.active_member_of_club_by_email?(
               conversion.club.club_id,
               request.requester_email
             )

      assert_receive {:welcome_email, delivered_conversion}
      assert delivered_conversion.request.request_id == request.request_id
      assert delivered_conversion.club.club_id == conversion.club.club_id
      assert delivered_conversion.person.person_id == conversion.person.person_id

      reloaded_request = Repo.get!(Request, request.request_id)
      assert reloaded_request.status == "converted"
      assert reloaded_request.converted_club_id == conversion.club.club_id
      assert reloaded_request.converted_person_id == conversion.person.person_id
      assert reloaded_request.converted_membership_id == conversion.membership_id
    end

    test "reuses an existing person when the request email already belongs to one" do
      person_id = Memba.ID.generate(:person)

      assert :ok =
               Membership.create_person(
                 %{person_id: person_id, name: "Existing Robin", email: "robin@example.com"},
                 consistency: :strong
               )

      request = request_fixture("Reuse Paddlers", requester_email: "Robin@Example.com")

      assert {:ok, conversion} =
               Onboarding.convert_request_to_club(
                 request.request_id,
                 %{"name" => "Reuse Paddlers", "slug" => "reuse-paddlers"}
               )

      assert conversion.person_reused?
      assert conversion.person.person_id == person_id
      assert conversion.person.name == "Existing Robin"
      assert conversion.request.converted_person_id == person_id

      assert Membership.active_member_of_club_by_email?(
               conversion.club.club_id,
               "robin@example.com"
             )
    end

    test "does not mark the request converted or deliver welcome email when club creation fails" do
      assert :ok =
               Membership.create_club(
                 %{
                   club_id: Memba.ID.generate(:club),
                   name: "Existing Club",
                   slug: "taken-slug"
                 },
                 consistency: :strong
               )

      request = request_fixture("Taken Slug Club")
      parent = self()

      assert {:error, :slug_taken} =
               Onboarding.convert_request_to_club(
                 request.request_id,
                 %{"name" => "Taken Slug Club", "slug" => "taken-slug"},
                 welcome_email_fun: fn conversion ->
                   send(parent, {:unexpected_welcome_email, conversion})
                   :ok
                 end
               )

      refute_receive {:unexpected_welcome_email, _conversion}

      reloaded_request = Repo.get!(Request, request.request_id)
      assert reloaded_request.status == "active"
      assert is_nil(reloaded_request.converted_club_id)
      assert is_nil(reloaded_request.converted_person_id)
      assert is_nil(reloaded_request.converted_membership_id)
    end

    test "returns welcome email errors without rolling back successful conversion" do
      request = request_fixture("Email Error Paddlers")

      assert {:ok, conversion} =
               Onboarding.convert_request_to_club(
                 request.request_id,
                 %{"name" => "Email Error Paddlers", "slug" => "email-error-paddlers"},
                 welcome_email_fun: fn _conversion -> {:error, :smtp_down} end
               )

      assert conversion.welcome_email == {:error, :smtp_down}
      assert Repo.get!(Request, request.request_id).status == "converted"
      assert Membership.get_club(conversion.club.club_id)

      assert Membership.active_member_of_club_by_email?(
               conversion.club.club_id,
               request.requester_email
             )
    end

    test "delivers the default welcome email with a member-home sign-in link" do
      configure_auth_email()
      request = request_fixture("Welcome Email Paddlers", requester_email: "Robin@Example.COM")

      assert {:ok, conversion} =
               Onboarding.convert_request_to_club(
                 request.request_id,
                 %{"name" => "Welcome Email Paddlers", "slug" => "welcome-email-paddlers"}
               )

      assert conversion.welcome_email == :ok
      assert [%SignInToken{email: "robin@example.com", consumed_at: nil}] = Repo.all(SignInToken)
      assert_received {:email, %Swoosh.Email{} = email}

      assert email.to == [{"Robin Requester", "robin@example.com"}]
      assert email.subject == "Welcome to Welcome Email Paddlers on Memba"
      assert email.text_body =~ "Welcome to Welcome Email Paddlers on Memba."
      assert email.text_body =~ "http://welcome-email-paddlers.lvh.me:4002/auth/sign-in/"
      assert email.text_body =~ "return_to=http%3A%2F%2Fwelcome-email-paddlers.lvh.me%3A4002%2F"
    end
  end

  defp request_fixture(club_name, opts \\ []) do
    unique = System.unique_integer([:positive])

    {:ok, request} =
      Onboarding.create_request(%{
        requester_name: Keyword.get(opts, :requester_name, "Robin Requester"),
        requester_email: Keyword.get(opts, :requester_email, "requester-#{unique}@example.com"),
        requested_club_name: club_name,
        note: "Please onboard #{club_name}."
      })

    request
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

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
