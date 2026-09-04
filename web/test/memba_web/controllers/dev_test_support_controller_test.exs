defmodule MembaWeb.DevTestSupportControllerTest do
  use ExUnit.Case, async: false

  @endpoint MembaWeb.Endpoint

  use MembaWeb, :verified_routes

  import Plug.Conn
  import Phoenix.ConnTest

  alias Memba.Membership
  alias Memba.Membership.Projections.Club, as: ClubProjection
  alias Memba.Membership.Projections.Group, as: GroupProjection
  alias Memba.Membership.Projections.Person, as: PersonProjection
  alias Memba.Membership.SystemGroups
  alias Memba.Repo
  alias Memba.Messaging.EmailDeliveryProviders.Local
  alias Memba.Messaging.EmailDeliveryProviders.Unavailable

  setup_all do
    Ecto.Adapters.SQL.Sandbox.mode(Memba.Repo, :auto)

    on_exit(fn ->
      Ecto.Adapters.SQL.Sandbox.mode(Memba.Repo, :manual)
    end)

    :ok
  end

  setup do
    original_provider = Application.get_env(:memba, :messaging_email_delivery_provider)

    on_exit(fn ->
      restore_env(:messaging_email_delivery_provider, original_provider)
    end)

    {:ok, conn: build_conn() |> PhoenixTest.put_endpoint(MembaWeb.Endpoint)}
  end

  test "POST /dev/test-support/messaging-delivery-provider switches provider for acceptance support",
       %{conn: conn} do
    conn =
      post(conn, ~p"/dev/test-support/messaging-delivery-provider", %{
        "provider" => "unavailable"
      })

    assert response(conn, 204) == ""
    assert Application.get_env(:memba, :messaging_email_delivery_provider) == Unavailable

    conn =
      build_conn()
      |> PhoenixTest.put_endpoint(MembaWeb.Endpoint)
      |> post(~p"/dev/test-support/messaging-delivery-provider", %{"provider" => "local"})

    assert response(conn, 204) == ""
    assert Application.get_env(:memba, :messaging_email_delivery_provider) == Local
  end

  test "POST /dev/test-support/reset restores the local messaging provider", %{conn: conn} do
    Application.put_env(:memba, :messaging_email_delivery_provider, Unavailable)

    conn = post(conn, ~p"/dev/test-support/reset")

    assert response(conn, 204) == ""
    assert Application.get_env(:memba, :messaging_email_delivery_provider) == Local
  end

  test "POST /dev/test-support/reset clears event-sourced server state for fixed identities" do
    ids = %{
      club_id: Memba.ID.deterministic(:club, ["dev-test-support-reset-regression-club"]),
      person_id: Memba.ID.deterministic(:person, ["dev-test-support-reset-regression-person"]),
      membership_id:
        Memba.ID.deterministic(:membership, ["dev-test-support-reset-regression-membership"])
    }

    dispatch_opts = [consistency: :strong, timeout: 5_000]

    on_exit(fn ->
      reset_acceptance_state!()
    end)

    reset_acceptance_state!()
    create_member_with_fixed_ids!(ids, dispatch_opts)

    reset_acceptance_state!()
    create_member_with_fixed_ids!(ids, dispatch_opts)
  end

  test "POST /dev/test-support/sign-in stores the signed-in identity in the browser session",
       %{conn: conn} do
    conn = post(conn, ~p"/dev/test-support/sign-in", %{"email" => "Alice@Example.Test"})

    assert response(conn, 204) == ""
    assert get_session(conn, MembaWeb.IdentityAuth.identity_session_key()) == "alice@example.test"
  end

  test "POST /dev/test-support/messaging-delivery-provider rejects unknown provider names",
       %{conn: conn} do
    original_provider = Application.get_env(:memba, :messaging_email_delivery_provider)

    conn =
      post(conn, ~p"/dev/test-support/messaging-delivery-provider", %{
        "provider" => "postmark"
      })

    assert json_response(conn, 404) == %{"error" => "unknown messaging email delivery provider"}
    assert Application.get_env(:memba, :messaging_email_delivery_provider) == original_provider
  end

  describe "GET /dev/test-support/stop-follow-url" do
    test "returns a path with a token scoped to the seeded Drew follow", %{conn: conn} do
      conn = get(conn, "/dev/test-support/stop-follow-url")

      assert %{"path" => path} = json_response(conn, 200)
      assert "/messages/conversations/stop-following/" <> token = path

      assert {:ok, scope} = Memba.Messaging.ConversationStopFollowToken.verify(token)
      assert scope.club_id == "clb_11111111-1111-1111-1111-111111111111"
      assert scope.conversation_id == "msg_30000000-0000-0000-0000-000000000001"
      assert scope.member_id == "per_dddddddd-dddd-dddd-dddd-dddddddddddd"
    end
  end

  defp reset_acceptance_state! do
    conn =
      build_conn()
      |> PhoenixTest.put_endpoint(MembaWeb.Endpoint)
      |> post(~p"/dev/test-support/reset")

    assert response(conn, 204) == ""
  end

  defp create_member_with_fixed_ids!(ids, dispatch_opts) do
    %{
      club_id: club_id,
      person_id: person_id,
      membership_id: membership_id
    } = ids

    everyone_group_id = SystemGroups.everyone_group_id(club_id)
    admin_group_id = SystemGroups.admin_group_id(club_id)

    assert :ok =
             Membership.create_club(
               %{club_id: club_id, name: "Reset Regression Club"},
               dispatch_opts
             )

    assert %ClubProjection{club_id: ^club_id, name: "Reset Regression Club"} =
             Membership.get_club(club_id)

    assert %GroupProjection{
             group_id: ^everyone_group_id,
             group_key: "everyone",
             name: "Everyone"
           } = Repo.get_by(GroupProjection, group_id: everyone_group_id)

    assert %GroupProjection{group_id: ^admin_group_id, group_key: "admin", name: "Admin"} =
             Repo.get_by(GroupProjection, group_id: admin_group_id)

    assert :ok =
             Membership.create_person(
               %{person_id: person_id, name: "Reset Riley", email: "reset-riley@example.com"},
               dispatch_opts
             )

    assert %PersonProjection{person_id: ^person_id, name: "Reset Riley"} =
             Membership.get_person(person_id)

    assert :ok =
             Membership.add_member(
               %{membership_id: membership_id, club_id: club_id, person_id: person_id},
               dispatch_opts
             )

    assert [
             %{
               id: ^person_id,
               membership_id: ^membership_id,
               name: "Reset Riley",
               email: "reset-riley@example.com"
             }
           ] = Membership.list_active_members_of_group(everyone_group_id)
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
