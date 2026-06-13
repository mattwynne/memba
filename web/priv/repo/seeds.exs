# Script for populating the development database with representative data.
#
# Run it from the web directory with:
#
#     mix run priv/repo/seeds.exs
#
# The data is idempotent: running this file again refreshes the same records.

alias Memba.Membership.Projections.Club
alias Memba.Membership.Projections.MemberPermission
alias Memba.Membership.Projections.Membership
alias Memba.Membership.Projections.Person
alias Memba.Membership.Projections.PersonEmailAddress
alias Memba.Membership.Projections.Role
alias Memba.Membership.Projections.RoleAssignment
alias Memba.Membership.Projections.RolePermission
alias Memba.Membership.Permissions
alias Memba.Membership.Roles
alias Memba.Messaging.Projections.EmailDelivery
alias Memba.Messaging.Projections.MembaStaffEmailDelivery
alias Memba.Messaging.Projections.MemberEmailDelivery
alias Memba.Messaging.Projections.Message
alias Memba.Repo

import Ecto.Query

now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
one_hour_ago = DateTime.add(now, -60 * 60, :second)
two_days_ago = DateTime.add(now, -2 * 24 * 60 * 60, :second)

clubs = [
  %{
    club_id: "clb_11111111-1111-1111-1111-111111111111",
    name: "Kootenay Mountaineering Club",
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    club_id: "clb_22222222-2222-2222-2222-222222222222",
    name: "Nelson Paddling Club",
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    club_id: "clb_33333333-3333-3333-3333-333333333333",
    name: "Smoke Test Club",
    slug: "test",
    inserted_at: two_days_ago,
    updated_at: now
  }
]

people = [
  %{
    person_id: "per_aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    name: "Alice Adams",
    email: "alice@example.com",
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    person_id: "per_bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
    name: "Bob Brown",
    email: "bob@example.com",
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    person_id: "per_cccccccc-cccc-cccc-cccc-cccccccccccc",
    name: "Carol Chen",
    email: "carol@example.com",
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    person_id: "per_dddddddd-dddd-dddd-dddd-dddddddddddd",
    name: "Dana Diaz",
    email: "dana@example.com",
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    person_id: "per_eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee",
    name: "Pat Staff",
    email: "pat@memba.io",
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    person_id: "per_ffffffff-ffff-ffff-ffff-ffffffffffff",
    name: "Smoke Tester",
    email: "test@memba.io",
    inserted_at: two_days_ago,
    updated_at: now
  }
]

person_email_addresses = [
  %{
    id: "ead_20000000-0000-0000-0000-000000000001",
    person_id: "per_aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    email: "alice@example.com",
    normalized_email: "alice@example.com",
    is_primary: true,
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    id: "ead_20000000-0000-0000-0000-000000000002",
    person_id: "per_aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    email: "alice@work.example",
    normalized_email: "alice@work.example",
    is_primary: false,
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    id: "ead_20000000-0000-0000-0000-000000000003",
    person_id: "per_bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
    email: "bob@example.com",
    normalized_email: "bob@example.com",
    is_primary: true,
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    id: "ead_20000000-0000-0000-0000-000000000004",
    person_id: "per_cccccccc-cccc-cccc-cccc-cccccccccccc",
    email: "carol@example.com",
    normalized_email: "carol@example.com",
    is_primary: true,
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    id: "ead_20000000-0000-0000-0000-000000000005",
    person_id: "per_dddddddd-dddd-dddd-dddd-dddddddddddd",
    email: "dana@example.com",
    normalized_email: "dana@example.com",
    is_primary: true,
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    id: "ead_20000000-0000-0000-0000-000000000006",
    person_id: "per_eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee",
    email: "pat@memba.io",
    normalized_email: "pat@memba.io",
    is_primary: true,
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    id: "ead_20000000-0000-0000-0000-000000000007",
    person_id: "per_ffffffff-ffff-ffff-ffff-ffffffffffff",
    email: "test@memba.io",
    normalized_email: "test@memba.io",
    is_primary: true,
    inserted_at: two_days_ago,
    updated_at: now
  }
]

memberships = [
  %{
    membership_id: "mem_10000000-0000-0000-0000-000000000001",
    club_id: "clb_11111111-1111-1111-1111-111111111111",
    person_id: "per_aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    active: true,
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    membership_id: "mem_10000000-0000-0000-0000-000000000002",
    club_id: "clb_11111111-1111-1111-1111-111111111111",
    person_id: "per_bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
    active: true,
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    membership_id: "mem_10000000-0000-0000-0000-000000000003",
    club_id: "clb_11111111-1111-1111-1111-111111111111",
    person_id: "per_cccccccc-cccc-cccc-cccc-cccccccccccc",
    active: true,
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    membership_id: "mem_10000000-0000-0000-0000-000000000004",
    club_id: "clb_11111111-1111-1111-1111-111111111111",
    person_id: "per_dddddddd-dddd-dddd-dddd-dddddddddddd",
    active: false,
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    membership_id: "mem_10000000-0000-0000-0000-000000000005",
    club_id: "clb_22222222-2222-2222-2222-222222222222",
    person_id: "per_aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    active: true,
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    membership_id: "mem_10000000-0000-0000-0000-000000000006",
    club_id: "clb_22222222-2222-2222-2222-222222222222",
    person_id: "per_eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee",
    active: true,
    inserted_at: two_days_ago,
    updated_at: now
  },
  %{
    membership_id: "mem_10000000-0000-0000-0000-000000000007",
    club_id: "clb_33333333-3333-3333-3333-333333333333",
    person_id: "per_ffffffff-ffff-ffff-ffff-ffffffffffff",
    active: true,
    inserted_at: two_days_ago,
    updated_at: now
  }
]

membership_administrator_roles =
  Enum.map(clubs, fn club ->
    %{
      role_id: Roles.membership_administrator_role_id(club.club_id),
      club_id: club.club_id,
      role_key: Roles.membership_administrator_key(),
      name: Roles.membership_administrator_name(),
      inserted_at: club.inserted_at,
      updated_at: now
    }
  end)

membership_administrator_role_by_club_id =
  Map.new(membership_administrator_roles, fn role -> {role.club_id, role} end)

membership_administrator_role_permissions =
  Enum.map(membership_administrator_roles, fn role ->
    %{
      club_id: role.club_id,
      role_id: role.role_id,
      permission: Permissions.club_manage_members(),
      inserted_at: two_days_ago,
      updated_at: now
    }
  end)

membership_administrator_memberships =
  memberships
  |> Enum.filter(& &1.active)
  |> Enum.reduce(%{}, fn membership, memberships_by_club_id ->
    Map.put_new(memberships_by_club_id, membership.club_id, membership)
  end)
  |> Map.values()

membership_administrator_role_assignments =
  Enum.map(membership_administrator_memberships, fn membership ->
    role = Map.fetch!(membership_administrator_role_by_club_id, membership.club_id)

    %{
      club_id: membership.club_id,
      membership_id: membership.membership_id,
      person_id: membership.person_id,
      role_id: role.role_id,
      active: true,
      inserted_at: membership.inserted_at,
      updated_at: now
    }
  end)

membership_administrator_member_permissions =
  Enum.map(membership_administrator_role_assignments, fn assignment ->
    %{
      club_id: assignment.club_id,
      membership_id: assignment.membership_id,
      person_id: assignment.person_id,
      permission: Permissions.club_manage_members(),
      grant_count: 1,
      inserted_at: assignment.inserted_at,
      updated_at: now
    }
  end)

messages = [
  %{
    message_id: "msg_30000000-0000-0000-0000-000000000001",
    club_id: "clb_11111111-1111-1111-1111-111111111111",
    sender_id: "per_aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    subject: "Saturday trail day",
    body: "Meet at the trailhead at 9am. Bring gloves, lunch, and a thermos.",
    inserted_at: one_hour_ago,
    updated_at: one_hour_ago
  },
  %{
    message_id: "msg_30000000-0000-0000-0000-000000000002",
    club_id: "clb_11111111-1111-1111-1111-111111111111",
    sender_id: "per_bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
    subject: "Trip planning night",
    body: "We’ll meet at the clubhouse on Thursday at 7pm to plan the next overnight trip.",
    inserted_at: two_days_ago,
    updated_at: two_days_ago
  },
  %{
    message_id: "msg_30000000-0000-0000-0000-000000000003",
    club_id: "clb_22222222-2222-2222-2222-222222222222",
    sender_id: "per_eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee",
    subject: "Lake cleanup this weekend",
    body: "Bring a dry bag and gloves. We’ll meet by the boat ramp at 10am.",
    inserted_at: one_hour_ago,
    updated_at: one_hour_ago
  }
]

email_deliveries = [
  %{
    delivery_id: "del_40000000-0000-0000-0000-000000000001",
    message_id: "msg_30000000-0000-0000-0000-000000000001",
    recipient_id: "per_aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    recipient_name: "Alice Adams",
    recipient_address: "alice@example.com",
    channel: "email",
    status: "opened",
    inserted_at: one_hour_ago,
    updated_at: now
  },
  %{
    delivery_id: "del_40000000-0000-0000-0000-000000000002",
    message_id: "msg_30000000-0000-0000-0000-000000000001",
    recipient_id: "per_bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
    recipient_name: "Bob Brown",
    recipient_address: "bob@example.com",
    channel: "email",
    status: "delivered",
    inserted_at: one_hour_ago,
    updated_at: now
  },
  %{
    delivery_id: "del_40000000-0000-0000-0000-000000000003",
    message_id: "msg_30000000-0000-0000-0000-000000000001",
    recipient_id: "per_cccccccc-cccc-cccc-cccc-cccccccccccc",
    recipient_name: "Carol Chen",
    recipient_address: "carol@example.com",
    channel: "email",
    status: "bounced",
    inserted_at: one_hour_ago,
    updated_at: now
  },
  %{
    delivery_id: "del_40000000-0000-0000-0000-000000000004",
    message_id: "msg_30000000-0000-0000-0000-000000000003",
    recipient_id: "per_aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    recipient_name: "Alice Adams",
    recipient_address: "alice@example.com",
    channel: "email",
    status: "delivered",
    inserted_at: one_hour_ago,
    updated_at: now
  },
  %{
    delivery_id: "del_40000000-0000-0000-0000-000000000005",
    message_id: "msg_30000000-0000-0000-0000-000000000003",
    recipient_id: "per_eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee",
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

seed_person_ids = Enum.map(people, & &1.person_id)

Repo.delete_all(
  from(email_address in PersonEmailAddress, where: email_address.person_id in ^seed_person_ids)
)

Repo.insert_all(PersonEmailAddress, person_email_addresses,
  on_conflict: {:replace_all_except, [:id]},
  conflict_target: :id
)

Repo.insert_all(Membership, memberships,
  on_conflict: {:replace_all_except, [:membership_id]},
  conflict_target: :membership_id
)

seed_membership_ids = Enum.map(memberships, & &1.membership_id)
seed_club_ids = Enum.map(clubs, & &1.club_id)
seed_role_ids = Enum.map(membership_administrator_roles, & &1.role_id)

existing_seed_admin_role_ids =
  Repo.all(
    from(role in Role,
      where: role.club_id in ^seed_club_ids,
      where: role.role_key == ^Roles.membership_administrator_key(),
      select: role.role_id
    )
  )

seed_admin_role_ids = Enum.uniq(seed_role_ids ++ existing_seed_admin_role_ids)

Repo.delete_all(
  from(member_permission in MemberPermission,
    where:
      member_permission.membership_id in ^seed_membership_ids and
        member_permission.permission == ^Permissions.club_manage_members()
  )
)

Repo.delete_all(
  from(role_assignment in RoleAssignment, where: role_assignment.role_id in ^seed_admin_role_ids)
)

Repo.delete_all(
  from(role_permission in RolePermission, where: role_permission.role_id in ^seed_admin_role_ids)
)

Repo.delete_all(from(role in Role, where: role.role_id in ^seed_admin_role_ids))

Repo.insert_all(Role, membership_administrator_roles,
  on_conflict: {:replace_all_except, [:role_id]},
  conflict_target: :role_id
)

Repo.insert_all(RolePermission, membership_administrator_role_permissions,
  on_conflict: :nothing,
  conflict_target: [:role_id, :permission]
)

Repo.insert_all(RoleAssignment, membership_administrator_role_assignments,
  on_conflict: :nothing,
  conflict_target: [:membership_id, :role_id]
)

Repo.insert_all(MemberPermission, membership_administrator_member_permissions,
  on_conflict: :nothing,
  conflict_target: [:club_id, :person_id, :membership_id, :permission]
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
IO.puts("Alice alternate sign-in email: alice@work.example")
IO.puts("Memba staff sign-in email: pat@memba.io")
IO.puts("Smoke-test member sign-in email: test@memba.io")
IO.puts("Smoke-test inbound email address: test@clubs.memba.io")
