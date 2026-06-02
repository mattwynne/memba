defmodule MembaWeb.MemberMessageDetailLoaderTest do
  use MembaWeb.ConnCase, async: true

  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Membership
  alias Memba.Membership.Projections.Person
  alias Memba.Messaging.Projections.MemberReceipt
  alias Memba.Messaging.Projections.Message
  alias Memba.Repo
  alias MembaWeb.MemberMessageDetail

  test "loads detail assigns for an active selected club message" do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    bob =
      create_active_member(
        email: "bob@example.com",
        name: "Bob Builder",
        club_name: "Alpine Club",
        club_id: alice.club_id
      )

    message =
      create_message(
        club_id: alice.club_id,
        sender_id: alice.person_id,
        subject: "Trip planning night",
        body: "Bring your maps."
      )

    create_member_receipt(
      message_id: message.message_id,
      recipient_id: bob.person_id,
      recipient_name: "Bob Builder",
      receipt_status: "delivered"
    )

    assert {:ok, assigns} =
             MemberMessageDetail.load(
               %{"club_id" => alice.club_id, "message_id" => message.message_id},
               [alice]
             )

    assert assigns.page_title == "Trip planning night"
    assert assigns.selected_club.club_id == alice.club_id
    assert assigns.message.message_id == message.message_id
    assert assigns.sender_name == "Alice Adams"
    assert assigns.member_receipt_count == 1

    assert Enum.map(assigns.member_receipt_summary, &{&1.status, &1.count, &1.percentage}) == [
             {"opened", 0, 0},
             {"delivered", 1, 100},
             {"sent", 0, 0},
             {"delivery problem", 0, 0}
           ]

    assert [%{status: "delivered", status_label: "Delivered", count: 1}] =
             assigns.member_receipt_groups
  end

  test "forbids missing, invalid, or unauthorized selected clubs" do
    club = create_active_member(email: "alice@example.com", club_name: "Alpine Club")
    other_club = create_active_member(email: "pat@example.com", club_name: "Paddling Club")

    message =
      create_message(
        club_id: club.club_id,
        sender_id: club.person_id,
        subject: "Members only"
      )

    assert {:error, :forbidden} =
             MemberMessageDetail.load(%{"message_id" => message.message_id}, [club])

    assert {:error, :forbidden} =
             MemberMessageDetail.load(
               %{"club_id" => "not-a-uuid", "message_id" => message.message_id},
               [club]
             )

    assert {:error, :forbidden} =
             MemberMessageDetail.load(
               %{"club_id" => club.club_id, "message_id" => message.message_id},
               [other_club]
             )
  end

  test "returns not found for missing messages and message club mismatches" do
    club = create_active_member(email: "alice@example.com", club_name: "Alpine Club")
    other_club = create_club(name: "Paddling Club")

    mismatched_message =
      create_message(
        club_id: other_club.club_id,
        sender_id: club.person_id,
        subject: "Wrong club"
      )

    assert {:error, :not_found} =
             MemberMessageDetail.load(
               %{"club_id" => club.club_id, "message_id" => Ecto.UUID.generate()},
               [club]
             )

    assert {:error, :not_found} =
             MemberMessageDetail.load(
               %{"club_id" => club.club_id, "message_id" => mismatched_message.message_id},
               [club]
             )
  end

  defp create_club(attrs) do
    insert_membership_club!(attrs)
  end

  defp create_active_member(attrs) do
    club_id = Keyword.get_lazy(attrs, :club_id, &Ecto.UUID.generate/0)
    person_id = Ecto.UUID.generate()
    club_name = Keyword.fetch!(attrs, :club_name)

    club =
      Repo.get(Club, club_id) ||
        insert_membership_club!(
          club_id: club_id,
          name: club_name
        )

    Repo.insert!(%Person{
      person_id: person_id,
      name: Keyword.get(attrs, :name, "Test Member"),
      email: Keyword.fetch!(attrs, :email)
    })

    Repo.insert!(%Membership{
      membership_id: Ecto.UUID.generate(),
      club_id: club_id,
      person_id: person_id,
      active: true
    })

    club
    |> Map.from_struct()
    |> Map.put(:person_id, person_id)
  end

  defp create_message(attrs) do
    Repo.insert!(%Message{
      message_id: Ecto.UUID.generate(),
      club_id: Keyword.fetch!(attrs, :club_id),
      sender_id: Keyword.fetch!(attrs, :sender_id),
      subject: Keyword.fetch!(attrs, :subject),
      body: Keyword.get(attrs, :body, "Message body")
    })
  end

  defp create_member_receipt(attrs) do
    Repo.insert!(%MemberReceipt{
      delivery_id: Ecto.UUID.generate(),
      message_id: Keyword.fetch!(attrs, :message_id),
      recipient_id: Keyword.fetch!(attrs, :recipient_id),
      recipient_name: Keyword.fetch!(attrs, :recipient_name),
      receipt_status: Keyword.fetch!(attrs, :receipt_status)
    })
  end
end
