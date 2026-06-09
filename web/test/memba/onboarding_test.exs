defmodule Memba.OnboardingTest do
  use Memba.DataCase, async: true

  alias Memba.Onboarding
  alias Memba.Onboarding.Request
  alias Memba.Membership
  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.MemberPermission
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Projections.Person
  alias Memba.Membership.Projections.PersonEmailAddress
  alias Memba.Membership.Projections.RoleAssignment

  describe "create_request/2" do
    test "creates an active request with trimmed details and the verified identity email" do
      assert {:ok, %Request{} = request} =
               Onboarding.create_request(
                 %{
                   "requester_name" => " Robin Rider ",
                   "requester_email" => " forged@example.net ",
                   "requested_club_name" => " West Coast Paddlers ",
                   "note" => " We want to try Memba. "
                 },
                 verified_identity_email: " Robin@Example.COM "
               )

      assert "req_" <> _uuid = request.request_id
      assert request.status == "active"
      assert request.requester_name == "Robin Rider"
      assert request.requester_email == "robin@example.com"
      assert request.normalized_requester_email == "robin@example.com"
      assert request.requested_club_name == "West Coast Paddlers"
      assert request.note == "We want to try Memba."
      assert is_nil(request.requester_person_id)
      assert is_nil(request.triaged_at)
    end

    test "requires a verified identity email instead of trusting a typed requester email" do
      assert {:error, changeset} =
               Onboarding.create_request(%{
                 requester_name: "Robin Rider",
                 requester_email: "spoofed@example.net",
                 requested_club_name: "West Coast Paddlers",
                 note: "Please onboard my club."
               })

      assert %{requester_email: ["must be verified"]} = errors_on(changeset)
      assert Repo.aggregate(Request, :count) == 0
    end

    test "stores a signed-in requester person ID when provided by the caller" do
      person_id = Memba.ID.generate(:person)

      assert {:ok, %Request{requester_person_id: ^person_id}} =
               Onboarding.create_request(
                 %{
                   requester_name: "Alice Admin",
                   requester_email: "alice@example.com",
                   requested_club_name: "Alice Paddling Club",
                   note: "Please onboard my club."
                 },
                 verified_identity_email: "alice@example.com",
                 requester_person_id: person_id
               )
    end

    test "rejects missing details, invalid emails, and invalid signed-in person IDs" do
      assert {:error, changeset} =
               Onboarding.create_request(
                 %{
                   requester_name: " ",
                   requester_email: "not an email",
                   requested_club_name: "",
                   note: nil
                 },
                 verified_identity_email: "not an email",
                 requester_person_id: "not-a-person-id"
               )

      assert %{
               requester_name: ["can't be blank"],
               requester_email: ["is invalid"],
               requester_person_id: ["is invalid"],
               requested_club_name: ["can't be blank"],
               note: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "does not create membership-domain records for a verified request submission" do
      membership_projection_counts = membership_projection_counts()

      assert {:ok, %Request{} = request} =
               Onboarding.create_request(
                 %{
                   requester_name: "Robin Rider",
                   requester_email: "forged@example.net",
                   requested_club_name: "West Coast Paddlers",
                   note: "Please onboard my club."
                 },
                 verified_identity_email: "robin@example.com"
               )

      assert request.requester_email == "robin@example.com"

      assert membership_projection_counts() == membership_projection_counts
      assert Membership.list_active_clubs_for_member_email("robin@example.com") == []
    end
  end

  describe "list_active_requests/0 and get_request/1" do
    test "lists only active requests ordered by submission time and request ID" do
      newest = request_fixture("Newest Paddlers")
      oldest = request_fixture("Oldest Paddlers")
      first_tie = request_fixture("Tie A")
      second_tie = request_fixture("Tie B")
      rejected = request_fixture("Rejected Paddlers")

      update_inserted_at(newest, ~U[2026-06-01 12:00:00Z])
      update_inserted_at(oldest, ~U[2026-06-01 10:00:00Z])
      update_inserted_at(first_tie, ~U[2026-06-01 11:00:00Z])
      update_inserted_at(second_tie, ~U[2026-06-01 11:00:00Z])

      assert {:ok, %Request{status: "rejected"}} =
               Onboarding.reject_request(rejected.request_id, %{internal_rejection_notes: "Spam"})

      tie_ids = Enum.sort([first_tie.request_id, second_tie.request_id])

      assert [
               %Request{request_id: oldest_id},
               %Request{request_id: first_tie_id},
               %Request{request_id: second_tie_id},
               %Request{request_id: newest_id}
             ] = Onboarding.list_active_requests()

      assert oldest_id == oldest.request_id
      assert [first_tie_id, second_tie_id] == tie_ids
      assert newest_id == newest.request_id
    end

    test "gets requests by typed ID and returns nil for invalid or missing IDs" do
      request = request_fixture("Findable Paddlers")

      assert %Request{request_id: request_id} = Onboarding.get_request(request.request_id)
      assert request_id == request.request_id
      assert is_nil(Onboarding.get_request("not-a-request-id"))
      assert is_nil(Onboarding.get_request(Memba.ID.generate(:onboarding_request)))
    end
  end

  describe "reject_request/3" do
    test "rejects an active request with required internal notes and staff audit details" do
      request = request_fixture("Rejected Club")
      triaged_at = ~U[2026-06-02 09:30:00.000000Z]

      assert {:ok, %Request{} = rejected} =
               Onboarding.reject_request(
                 request.request_id,
                 %{internal_rejection_notes: " Not a real club. "},
                 staff_email: " Pat@Memba.IO ",
                 triaged_at: triaged_at
               )

      assert rejected.status == "rejected"
      assert rejected.internal_rejection_notes == "Not a real club."
      assert rejected.triaged_by_staff_email == "pat@memba.io"
      assert rejected.triaged_at == triaged_at
      assert is_nil(rejected.converted_club_id)
    end

    test "requires internal rejection notes and only transitions active requests" do
      request = request_fixture("Needs Notes Club")

      assert {:error, changeset} =
               Onboarding.reject_request(request.request_id, %{internal_rejection_notes: " "})

      assert %{internal_rejection_notes: ["can't be blank"]} = errors_on(changeset)

      assert {:ok, %Request{status: "rejected"}} =
               Onboarding.reject_request(request.request_id, %{internal_rejection_notes: "Spam"})

      assert {:error, :not_active} =
               Onboarding.reject_request(request.request_id, %{internal_rejection_notes: "Again"})

      assert {:error, :not_found} =
               Onboarding.reject_request("not-a-request-id", %{internal_rejection_notes: "Nope"})
    end
  end

  describe "convert_request/3" do
    test "marks an active request converted with converted IDs and staff audit details" do
      request = request_fixture("Converted Club")
      club_id = Memba.ID.generate(:club)
      person_id = Memba.ID.generate(:person)
      membership_id = Memba.ID.generate(:membership)
      triaged_at = ~U[2026-06-02 10:30:00.000000Z]

      assert {:ok, %Request{} = converted} =
               Onboarding.convert_request(
                 request.request_id,
                 %{
                   converted_club_id: club_id,
                   converted_person_id: person_id,
                   converted_membership_id: membership_id
                 },
                 staff_email: " Pat@Memba.IO ",
                 triaged_at: triaged_at
               )

      assert converted.status == "converted"
      assert converted.converted_club_id == club_id
      assert converted.converted_person_id == person_id
      assert converted.converted_membership_id == membership_id
      assert converted.triaged_by_staff_email == "pat@memba.io"
      assert converted.triaged_at == triaged_at
      assert is_nil(converted.internal_rejection_notes)
    end

    test "validates converted IDs and only transitions active requests" do
      request = request_fixture("Invalid Conversion Club")

      assert {:error, changeset} =
               Onboarding.convert_request(request.request_id, %{
                 converted_club_id: "not-a-club-id",
                 converted_person_id: nil,
                 converted_membership_id: "not-a-membership-id"
               })

      assert %{
               converted_club_id: ["is invalid"],
               converted_person_id: ["can't be blank"],
               converted_membership_id: ["is invalid"]
             } = errors_on(changeset)

      assert {:ok, %Request{status: "rejected"}} =
               Onboarding.reject_request(request.request_id, %{internal_rejection_notes: "Spam"})

      assert {:error, :not_active} =
               Onboarding.convert_request(request.request_id, %{
                 converted_club_id: Memba.ID.generate(:club),
                 converted_person_id: Memba.ID.generate(:person),
                 converted_membership_id: Memba.ID.generate(:membership)
               })

      assert {:error, :not_found} =
               Onboarding.convert_request("not-a-request-id", %{
                 converted_club_id: Memba.ID.generate(:club),
                 converted_person_id: Memba.ID.generate(:person),
                 converted_membership_id: Memba.ID.generate(:membership)
               })
    end
  end

  defp request_fixture(club_name) do
    unique = System.unique_integer([:positive])

    requester_email = "requester-#{unique}@example.com"

    {:ok, request} =
      Onboarding.create_request(
        %{
          requester_name: "Requester #{unique}",
          requester_email: requester_email,
          requested_club_name: club_name,
          note: "Please onboard #{club_name}."
        },
        verified_identity_email: requester_email
      )

    request
  end

  defp membership_projection_counts do
    %{
      clubs: Repo.aggregate(Club, :count),
      member_permissions: Repo.aggregate(MemberPermission, :count),
      memberships: Repo.aggregate(MembershipProjection, :count),
      people: Repo.aggregate(Person, :count),
      person_email_addresses: Repo.aggregate(PersonEmailAddress, :count),
      role_assignments: Repo.aggregate(RoleAssignment, :count)
    }
  end

  defp update_inserted_at(%Request{} = request, inserted_at) do
    Repo.update_all(
      from(onboarding_request in Request,
        where: onboarding_request.request_id == ^request.request_id
      ),
      set: [inserted_at: inserted_at]
    )
  end
end
