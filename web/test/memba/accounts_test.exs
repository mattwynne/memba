defmodule Memba.AccountsTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Accounts
  alias Memba.Accounts.SignInToken
  alias Memba.Membership
  alias Memba.Repo

  describe "email identity helpers" do
    test "normalizes email addresses for authentication lookups" do
      assert Accounts.normalize_email(" Alice@Example.COM ") == "alice@example.com"
      assert Accounts.normalize_email("\nPAT@MEMBA.IO\t") == "pat@memba.io"
      assert Accounts.normalize_email("   ") == nil
      assert Accounts.normalize_email(nil) == nil
    end

    test "identifies staff by exact memba.io email domain" do
      assert Accounts.staff_email?(" Pat@Memba.IO ")

      refute Accounts.staff_email?("pat@example.com")
      refute Accounts.staff_email?("pat@staff.memba.io")
      refute Accounts.staff_email?("@memba.io")
      refute Accounts.staff_email?(nil)
    end
  end

  describe "request_sign_in_link/2" do
    test "creates a single-use expiring hashed token for staff email addresses" do
      now = ~U[2026-05-31 12:00:00.000000Z]

      assert {:ok, %{email: "pat@memba.io", token: token, expires_at: expires_at}} =
               Accounts.request_sign_in_link(" Pat@Memba.IO ", now: now)

      assert is_binary(token)
      assert byte_size(token) >= 32
      assert expires_at == DateTime.add(now, 15 * 60, :second)

      assert %SignInToken{
               email: "pat@memba.io",
               token_hash: token_hash,
               expires_at: ^expires_at,
               consumed_at: nil
             } = Repo.one(SignInToken)

      assert token_hash == Accounts.hash_sign_in_token(token)
      refute token_hash == token
    end

    test "creates tokens for active member emails and no token for unknown emails" do
      now = ~U[2026-05-31 12:00:00.000000Z]
      create_active_member(club_name: "Kootenay Mountaineering Club", email: "alice@example.com")

      assert {:ok, %{email: "alice@example.com"}} =
               Accounts.request_sign_in_link(" ALICE@EXAMPLE.COM ", now: now)

      assert {:ok, nil} = Accounts.request_sign_in_link("unknown@example.com", now: now)

      assert ["alice@example.com"] =
               SignInToken
               |> select([sign_in_token], sign_in_token.email)
               |> Repo.all()
    end

    test "creates tokens for alternate email addresses attached to active members" do
      now = ~U[2026-05-31 12:00:00.000000Z]

      create_active_member(
        club_name: "Kootenay Mountaineering Club",
        email_addresses: [
          %{email: "alice@example.com", is_primary: true},
          %{email: "Alice.Work@Example.COM", is_primary: false}
        ]
      )

      assert {:ok, %{token: token}} =
               Accounts.request_sign_in_link(" alice.work@example.com ", now: now)

      assert is_binary(token)
      assert Repo.aggregate(SignInToken, :count) == 1
    end
  end

  describe "consume_sign_in_token/2" do
    test "consumes a valid token once and stores the consumption timestamp" do
      requested_at = ~U[2026-05-31 12:00:00.000000Z]
      consumed_at = ~U[2026-05-31 12:05:00.000000Z]

      assert {:ok, %{token: token}} =
               Accounts.request_sign_in_link("pat@memba.io", now: requested_at)

      assert {:ok, %{email: "pat@memba.io"}} =
               Accounts.consume_sign_in_token(token, now: consumed_at)

      assert %SignInToken{consumed_at: ^consumed_at} = Repo.one(SignInToken)
      assert {:error, :consumed} = Accounts.consume_sign_in_token(token, now: consumed_at)
    end

    test "rejects unknown and expired tokens without consuming rows" do
      requested_at = ~U[2026-05-31 12:00:00.000000Z]
      expired_at = ~U[2026-05-31 12:16:00.000000Z]

      assert {:error, :not_found} = Accounts.consume_sign_in_token("unknown", now: requested_at)

      assert {:ok, %{token: token}} =
               Accounts.request_sign_in_link("pat@memba.io", now: requested_at)

      assert {:error, :expired} = Accounts.consume_sign_in_token(token, now: expired_at)
      assert %SignInToken{consumed_at: nil} = Repo.one(SignInToken)
    end
  end

  describe "membership-backed identity helpers" do
    test "lists active clubs for a normalized email address" do
      kootenay =
        create_active_member(
          club_name: "Kootenay Mountaineering Club",
          email: "alice@example.com"
        )

      nelson =
        create_active_member(
          club_name: "Nelson Cycling Club",
          person_id: kootenay.person_id,
          email: "alice@example.com"
        )

      _other = create_active_member(club_name: "Other Club", email: "other@example.com")

      assert [
               %{club_id: kootenay_id, name: "Kootenay Mountaineering Club"},
               %{club_id: nelson_id, name: "Nelson Cycling Club"}
             ] = Accounts.list_active_clubs_for_email(" ALICE@EXAMPLE.COM ")

      assert kootenay_id == kootenay.club_id
      assert nelson_id == nelson.club_id
      assert Accounts.list_active_clubs_for_email("unknown@example.com") == []
      assert Accounts.list_active_clubs_for_email(nil) == []
    end

    test "checks active club membership by club id and email address" do
      club =
        create_active_member(
          club_name: "Kootenay Mountaineering Club",
          email: "alice@example.com"
        )

      assert Accounts.active_member_of_club?(club.club_id, " ALICE@EXAMPLE.COM ")

      refute Accounts.active_member_of_club?(club.club_id, "other@example.com")
      refute Accounts.active_member_of_club?(Ecto.UUID.generate(), "alice@example.com")
      refute Accounts.active_member_of_club?("not-a-uuid", "alice@example.com")
      refute Accounts.active_member_of_club?(club.club_id, nil)
    end
  end

  defp create_active_member(attrs) do
    club_id = Ecto.UUID.generate()
    person_id = Keyword.get_lazy(attrs, :person_id, &Ecto.UUID.generate/0)

    assert :ok =
             Membership.create_club(
               membership_club_attrs(club_id: club_id, name: Keyword.fetch!(attrs, :club_name)),
               consistency: :strong
             )

    unless Membership.get_person(person_id) do
      assert :ok =
               Membership.create_person(
                 create_person_attrs(attrs, person_id),
                 consistency: :strong
               )
    end

    assert :ok =
             Membership.add_member(
               %{membership_id: Ecto.UUID.generate(), club_id: club_id, person_id: person_id},
               consistency: :strong
             )

    %{club_id: club_id, person_id: person_id}
  end

  defp create_person_attrs(attrs, person_id) do
    base_attrs = %{
      person_id: person_id,
      name: "Test Member"
    }

    case Keyword.fetch(attrs, :email_addresses) do
      {:ok, email_addresses} ->
        Map.put(base_attrs, :email_addresses, email_addresses)

      :error ->
        Map.put(base_attrs, :email, Keyword.fetch!(attrs, :email))
    end
  end
end
