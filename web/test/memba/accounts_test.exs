defmodule Memba.AccountsTest do
  use Memba.DataCase, async: true

  alias Memba.Accounts
  alias Memba.Accounts.MagicToken
  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Projections.Person

  describe "normalize_email/1" do
    test "trims and lowercases email addresses" do
      assert Accounts.normalize_email("  Member@Example.COM  ") == {:ok, "member@example.com"}
    end

    test "rejects invalid email addresses" do
      assert Accounts.normalize_email("not-an-email") == {:error, :invalid_email}
      assert Accounts.normalize_email("@example.com") == {:error, :invalid_email}
      assert Accounts.normalize_email(nil) == {:error, :invalid_email}
    end
  end

  describe "staff_email?/1" do
    test "returns true only for normalized memba.io addresses" do
      assert Accounts.staff_email?(" Staff@Memba.IO ")

      refute Accounts.staff_email?("member@example.com")
      refute Accounts.staff_email?("staff@sub.memba.io")
      refute Accounts.staff_email?("not-an-email")
    end
  end

  describe "request_magic_link/1" do
    test "creates a hashed expiring token for a staff email" do
      before_request = DateTime.utc_now(:microsecond)

      assert {:ok, request} = Accounts.request_magic_link(" Staff@Memba.IO ")

      assert request.email == "staff@memba.io"
      assert is_binary(request.token)
      assert byte_size(request.token) > 20
      assert DateTime.diff(request.expires_at, before_request, :minute) in 14..15

      assert [magic_token] = Repo.all(MagicToken)
      assert magic_token.email == "staff@memba.io"
      assert magic_token.token_hash == Accounts.hash_magic_token(request.token)
      refute magic_token.token_hash == request.token
      assert DateTime.compare(magic_token.expires_at, request.expires_at) == :eq
      assert is_nil(magic_token.consumed_at)
    end

    test "creates a token for an active member email" do
      club = insert_projected_club(name: "Kootenay Mountaineering Club")
      person = insert_projected_person(email: "member@example.com")
      insert_projected_membership(club_id: club.club_id, person_id: person.person_id)

      assert {:ok, %{email: "member@example.com", token: token}} =
               Accounts.request_magic_link(" MEMBER@example.com ")

      assert [%MagicToken{token_hash: token_hash}] = Repo.all(MagicToken)
      assert token_hash == Accounts.hash_magic_token(token)
    end

    test "does not create a token for a valid but unknown email" do
      assert {:ok, :not_requested} = Accounts.request_magic_link("unknown@example.com")

      assert Repo.all(MagicToken) == []
    end
  end

  describe "consume_magic_token/1" do
    test "returns the email and marks a valid token consumed exactly once" do
      assert {:ok, %{token: token}} = Accounts.create_magic_token("member@example.com")

      assert {:ok, "member@example.com"} = Accounts.consume_magic_token(token)
      assert {:error, :invalid_or_expired_token} = Accounts.consume_magic_token(token)

      assert %MagicToken{consumed_at: %DateTime{}} = Repo.one!(MagicToken)
    end

    test "rejects expired tokens without consuming them" do
      token = "expired-token"

      Repo.insert!(%MagicToken{
        email: "member@example.com",
        token_hash: Accounts.hash_magic_token(token),
        expires_at: DateTime.add(DateTime.utc_now(:microsecond), -1, :minute)
      })

      assert {:error, :invalid_or_expired_token} = Accounts.consume_magic_token(token)

      assert %MagicToken{consumed_at: nil} = Repo.one!(MagicToken)
    end

    test "rejects unknown or malformed token values" do
      assert {:error, :invalid_or_expired_token} = Accounts.consume_magic_token("missing-token")
      assert {:error, :invalid_or_expired_token} = Accounts.consume_magic_token(nil)
    end
  end

  describe "club membership queries by email" do
    test "lists clubs where the normalized email belongs to an active member" do
      alpine = insert_projected_club(name: "Alpine Club")
      kootenay = insert_projected_club(name: "Kootenay Mountaineering Club")
      other = insert_projected_club(name: "Other Club")
      inactive = insert_projected_club(name: "Inactive Club")

      alice = insert_projected_person(name: "Alice", email: "member@example.com")
      bob = insert_projected_person(name: "Bob", email: "other@example.com")

      inactive_alice =
        insert_projected_person(name: "Inactive Alice", email: "member@example.com")

      insert_projected_membership(club_id: kootenay.club_id, person_id: alice.person_id)
      insert_projected_membership(club_id: alpine.club_id, person_id: alice.person_id)
      insert_projected_membership(club_id: other.club_id, person_id: bob.person_id)

      insert_projected_membership(
        club_id: inactive.club_id,
        person_id: inactive_alice.person_id,
        active: false
      )

      assert Accounts.list_clubs_for_email(" MEMBER@example.com ") == [alpine, kootenay]
      assert Accounts.list_clubs_for_email("unknown@example.com") == []
      assert Accounts.list_clubs_for_email("not-an-email") == []
    end

    test "checks whether an email is an active member of a club" do
      club = insert_projected_club()
      other_club = insert_projected_club()
      person = insert_projected_person(email: "member@example.com")

      insert_projected_membership(club_id: club.club_id, person_id: person.person_id)

      assert Accounts.active_member_of_club?(" MEMBER@example.com ", club.club_id)

      refute Accounts.active_member_of_club?("member@example.com", other_club.club_id)
      refute Accounts.active_member_of_club?("other@example.com", club.club_id)
      refute Accounts.active_member_of_club?("not-an-email", club.club_id)
      refute Accounts.active_member_of_club?("member@example.com", "not-a-uuid")
    end
  end

  defp insert_projected_club(attrs \\ []) do
    Repo.insert!(%Club{
      club_id: Keyword.get_lazy(attrs, :club_id, &Ecto.UUID.generate/0),
      name: Keyword.get(attrs, :name, "Club #{System.unique_integer([:positive])}")
    })
  end

  defp insert_projected_person(attrs) do
    Repo.insert!(%Person{
      person_id: Keyword.get_lazy(attrs, :person_id, &Ecto.UUID.generate/0),
      name: Keyword.get(attrs, :name, "Member #{System.unique_integer([:positive])}"),
      email: Keyword.get(attrs, :email, "member#{System.unique_integer([:positive])}@example.com")
    })
  end

  defp insert_projected_membership(attrs) do
    Repo.insert!(%MembershipProjection{
      membership_id: Keyword.get_lazy(attrs, :membership_id, &Ecto.UUID.generate/0),
      club_id: Keyword.fetch!(attrs, :club_id),
      person_id: Keyword.fetch!(attrs, :person_id),
      active: Keyword.get(attrs, :active, true)
    })
  end
end
