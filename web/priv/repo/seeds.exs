# Script for populating the development database with representative data.
#
# Run it from the web directory with:
#
#     mix run priv/repo/seeds.exs
#
# The data is idempotent: running this file again refreshes the same records.

alias Memba.Membership.Projections.Club
alias Memba.Membership.Projections.Membership
alias Memba.Membership.Projections.Person
alias Memba.Messaging.Projections.EmailDelivery
alias Memba.Messaging.Projections.MembaStaffEmailDelivery
alias Memba.Messaging.Projections.MemberEmailDelivery
alias Memba.Messaging.Projections.Message
alias Memba.Repo

now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
one_hour_ago = DateTime.add(now, -60 * 60, :second)
two_days_ago = DateTime.add(now, -2 * 24 * 60 * 60, :second)

clubs = [
  %{
    club_id: "11111111-1111-1111-1111-111111111111",
    name: "Kootenay Mountaineering Club",
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    club_id: "22222222-2222-2222-2222-222222222222",
    name: "Nelson Paddling Club",
    inserted_at: two_days_ago,
    updated_at: now
  }
]

people = [
  %{
    person_id: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    name: "Alice Adams",
    email: "alice@example.com",
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    person_id: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
    name: "Bob Brown",
    email: "bob@example.com",
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    person_id: "cccccccc-cccc-cccc-cccc-cccccccccccc",
    name: "Carol Chen",
    email: "carol@example.com",
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    person_id: "dddddddd-dddd-dddd-dddd-dddddddddddd",
    name: "Dana Diaz",
    email: "dana@example.com",
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    person_id: "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee",
    name: "Pat Staff",
    email: "pat@memba.io",
    inserted_at: two_days_ago,
    updated_at: now
  }
]

memberships = [
  %{
    membership_id: "10000000-0000-0000-0000-000000000001",
    club_id: "11111111-1111-1111-1111-111111111111",
    person_id: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    active: true,
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    membership_id: "10000000-0000-0000-0000-000000000002",
    club_id: "11111111-1111-1111-1111-111111111111",
    person_id: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
    active: true,
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    membership_id: "10000000-0000-0000-0000-000000000003",
    club_id: "11111111-1111-1111-1111-111111111111",
    person_id: "cccccccc-cccc-cccc-cccc-cccccccccccc",
    active: true,
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    membership_id: "10000000-0000-0000-0000-000000000004",
    club_id: "11111111-1111-1111-1111-111111111111",
    person_id: "dddddddd-dddd-dddd-dddd-dddddddddddd",
    active: false,
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    membership_id: "10000000-0000-0000-0000-000000000005",
    club_id: "22222222-2222-2222-2222-222222222222",
    person_id: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    active: true,
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    membership_id: "10000000-0000-0000-0000-000000000006",
    club_id: "22222222-2222-2222-2222-222222222222",
    person_id: "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee",
    active: true,
    inserted_at: two_days_ago,
    updated_at: now
  }
]

messages = [
  %{
    message_id: "30000000-0000-0000-0000-000000000001",
    club_id: "11111111-1111-1111-1111-111111111111",
    sender_id: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    subject: "Saturday trail day",
    body: "Meet at the trailhead at 9am. Bring gloves, lunch, and a thermos.",
    inserted_at: one_hour_ago,
    updated_at: one_hour_ago
  },
  %{
    message_id: "30000000-0000-0000-0000-000000000002",
    club_id: "11111111-1111-1111-1111-111111111111",
    sender_id: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
    subject: "Trip planning night",
    body: "We’ll meet at the clubhouse on Thursday at 7pm to plan the next overnight trip.",
    inserted_at: two_days_ago,
    updated_at: two_days_ago
  },
  %{
    message_id: "30000000-0000-0000-0000-000000000003",
    club_id: "22222222-2222-2222-2222-222222222222",
    sender_id: "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee",
    subject: "Lake cleanup this weekend",
    body: "Bring a dry bag and gloves. We’ll meet by the boat ramp at 10am.",
    inserted_at: one_hour_ago,
    updated_at: one_hour_ago
  }
]

email_deliveries = [
  %{
    delivery_id: "40000000-0000-0000-0000-000000000001",
    message_id: "30000000-0000-0000-0000-000000000001",
    recipient_id: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    recipient_name: "Alice Adams",
    recipient_address: "alice@example.com",
    channel: "email",
    status: "opened",
    inserted_at: one_hour_ago,
    updated_at: now
  },
  %{
    delivery_id: "40000000-0000-0000-0000-000000000002",
    message_id: "30000000-0000-0000-0000-000000000001",
    recipient_id: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
    recipient_name: "Bob Brown",
    recipient_address: "bob@example.com",
    channel: "email",
    status: "delivered",
    inserted_at: one_hour_ago,
    updated_at: now
  },
  %{
    delivery_id: "40000000-0000-0000-0000-000000000003",
    message_id: "30000000-0000-0000-0000-000000000001",
    recipient_id: "cccccccc-cccc-cccc-cccc-cccccccccccc",
    recipient_name: "Carol Chen",
    recipient_address: "carol@example.com",
    channel: "email",
    status: "bounced",
    inserted_at: one_hour_ago,
    updated_at: now
  },
  %{
    delivery_id: "40000000-0000-0000-0000-000000000004",
    message_id: "30000000-0000-0000-0000-000000000003",
    recipient_id: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    recipient_name: "Alice Adams",
    recipient_address: "alice@example.com",
    channel: "email",
    status: "delivered",
    inserted_at: one_hour_ago,
    updated_at: now
  },
  %{
    delivery_id: "40000000-0000-0000-0000-000000000005",
    message_id: "30000000-0000-0000-0000-000000000003",
    recipient_id: "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee",
    recipient_name: "Pat Staff",
    recipient_address: "pat@memba.io",
    channel: "email",
    status: "sent",
    inserted_at: one_hour_ago,
    updated_at: now
  }
]

member_email_deliveries =
  Enum.map(email_deliveries, fn delivery ->
    status =
      case delivery.status do
        "opened" -> "opened"
        "delivered" -> "delivered"
        "bounced" -> "delivery problem"
        _other -> "sent"
      end

    delivery
    |> Map.take([
      :delivery_id,
      :message_id,
      :recipient_id,
      :recipient_name,
      :inserted_at,
      :updated_at
    ])
    |> Map.put(:status, status)
  end)

memba_staff_email_deliveries =
  Enum.map(email_deliveries, fn delivery ->
    reason =
      if delivery.status == "bounced" do
        "Mailbox unavailable"
      end

    Map.put(delivery, :reason, reason)
  end)

Repo.insert_all(Club, clubs,
  on_conflict: {:replace_all_except, [:club_id]},
  conflict_target: :club_id
)

Repo.insert_all(Person, people,
  on_conflict: {:replace_all_except, [:person_id]},
  conflict_target: :person_id
)

Repo.insert_all(Membership, memberships,
  on_conflict: {:replace_all_except, [:membership_id]},
  conflict_target: :membership_id
)

Repo.insert_all(Message, messages,
  on_conflict: {:replace_all_except, [:message_id]},
  conflict_target: :message_id
)

Repo.insert_all(EmailDelivery, email_deliveries,
  on_conflict: {:replace_all_except, [:delivery_id]},
  conflict_target: :delivery_id
)

Repo.insert_all(MemberEmailDelivery, member_email_deliveries,
  on_conflict: {:replace_all_except, [:delivery_id]},
  conflict_target: :delivery_id
)

Repo.insert_all(MembaStaffEmailDelivery, memba_staff_email_deliveries,
  on_conflict: {:replace_all_except, [:delivery_id]},
  conflict_target: :delivery_id
)

IO.puts("Seeded representative Memba data.")
IO.puts("Member sign-in emails: alice@example.com, bob@example.com, carol@example.com")
IO.puts("Memba staff sign-in email: pat@memba.io")
