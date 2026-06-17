# Script for populating the development database with representative data.
#
# Reset and seed from the web directory with:
#
#     mix ecto.reset
#
# Or seed an already-reset database with:
#
#     mix run priv/repo/seeds.exs
#
# The data uses stable IDs and names for deterministic screenshots. It is
# intended to run after a fresh dev database reset.

defmodule Memba.DevSeeds do
  @moduledoc false

  alias Memba.Accounts
  alias Memba.Accounts.AuthEmail
  alias Memba.ClubInboundEmailAddress
  alias Memba.Membership
  alias Memba.Membership.App, as: MembershipApp
  alias Memba.Membership.ClubMemberInvitationEmail
  alias Memba.Membership.Commands.AssignMemberRole
  alias Memba.Membership.Roles
  alias Memba.Messaging
  alias Memba.Messaging.EmailDeliveryProviders.Local, as: LocalDeliveryProvider
  alias Memba.Messaging.LocalDeliveryFacts
  alias Memba.Onboarding
  alias Memba.Onboarding.NewRequestEmail
  alias Memba.Onboarding.Request
  alias Memba.Onboarding.WelcomeEmail

  import Swoosh.Email

  @read_model_timeout 5_000
  @read_model_poll_interval 50

  @clubs [
    %{
      key: "kac",
      club_id: "clb_11111111-1111-1111-1111-111111111111",
      name: "Kootenay Alpine Club",
      initials: "KAC",
      slug: "kootenay-alpine",
      members: [
        %{
          person_id: "per_aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
          membership_id: "mem_10000000-0000-0000-0000-000000000001",
          name: "Alice Adams",
          email: "alice@example.com",
          alternate_emails: ["alice@work.example"],
          manager?: true
        },
        %{
          person_id: "per_bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
          membership_id: "mem_10000000-0000-0000-0000-000000000002",
          name: "Benji Brooks",
          email: "benji@example.com"
        },
        %{
          person_id: "per_cccccccc-cccc-cccc-cccc-cccccccccccc",
          membership_id: "mem_10000000-0000-0000-0000-000000000003",
          name: "Carmen Cho",
          email: "carmen@example.com"
        },
        %{
          person_id: "per_dddddddd-dddd-dddd-dddd-dddddddddddd",
          membership_id: "mem_10000000-0000-0000-0000-000000000004",
          name: "Drew Diaz",
          email: "drew@example.com"
        }
      ],
      messages: [
        %{
          message_id: "msg_30000000-0000-0000-0000-000000000001",
          sender_id: "per_aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
          subject: "Saturday ridge walk",
          body:
            "Meet at the trailhead at 9am. Bring gloves, lunch, and a thermos. Weather looks clear but cool.",
          statuses: ["delivered", "bounced", "sent", "delayed"]
        },
        %{
          message_id: "msg_30000000-0000-0000-0000-000000000002",
          sender_id: "per_bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
          subject: "Trip planning night",
          body:
            "We will meet at the community room on Thursday at 7pm to plan July overnight trips.",
          statuses: ["sent", "delivered", "bounced", "delivered"]
        }
      ]
    },
    %{
      key: "wcc",
      club_id: "clb_22222222-2222-2222-2222-222222222222",
      name: "Wessex Chamber Choir",
      initials: "WCC",
      slug: "wessex-choir",
      members: [
        %{
          person_id: "per_eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee",
          membership_id: "mem_10000000-0000-0000-0000-000000000005",
          name: "Eleanor Evans",
          email: "eleanor@example.com",
          manager?: true
        },
        %{
          person_id: "per_ffffffff-ffff-ffff-ffff-ffffffffffff",
          membership_id: "mem_10000000-0000-0000-0000-000000000006",
          name: "Felix Foster",
          email: "felix@example.com"
        },
        %{
          person_id: "per_12345678-1234-1234-1234-123456789abc",
          membership_id: "mem_10000000-0000-0000-0000-000000000007",
          name: "Greta Green",
          email: "greta@example.com"
        }
      ],
      messages: [
        %{
          message_id: "msg_30000000-0000-0000-0000-000000000003",
          sender_id: "per_eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee",
          subject: "June rehearsal notes",
          body:
            "Please review the marked sections before Tuesday. Altos will start with bars 42 through 68.",
          statuses: ["delivered", "sent", "bounced"]
        },
        %{
          message_id: "msg_30000000-0000-0000-0000-000000000004",
          sender_id: "per_ffffffff-ffff-ffff-ffff-ffffffffffff",
          subject: "Concert dress reminder",
          body: "Black folders and concert dress for Saturday. Doors open to singers at 6:15pm.",
          statuses: ["bounced", "delivered", "sent"]
        }
      ]
    },
    %{
      key: "rps",
      club_id: "clb_33333333-3333-3333-3333-333333333333",
      name: "Rideau Park Sailing",
      initials: "RPS",
      slug: "rideau-sailing",
      members: [
        %{
          person_id: "per_87654321-4321-4321-4321-cba987654321",
          membership_id: "mem_10000000-0000-0000-0000-000000000008",
          name: "Hana Hall",
          email: "hana@example.com",
          manager?: true
        },
        %{
          person_id: "per_99999999-9999-9999-9999-999999999999",
          membership_id: "mem_10000000-0000-0000-0000-000000000009",
          name: "Ivan Iqbal",
          email: "ivan@example.com"
        },
        %{
          person_id: "per_12121212-1212-1212-1212-121212121212",
          membership_id: "mem_10000000-0000-0000-0000-000000000010",
          name: "Juniper Jones",
          email: "juniper@example.com"
        }
      ],
      messages: [
        %{
          message_id: "msg_30000000-0000-0000-0000-000000000005",
          sender_id: "per_87654321-4321-4321-4321-cba987654321",
          subject: "Dock work party",
          body:
            "The dock crew starts at 8:30am. Please bring labelled tools and wear closed-toe shoes.",
          statuses: ["sent", "delivered", "bounced"]
        },
        %{
          message_id: "msg_30000000-0000-0000-0000-000000000006",
          sender_id: "per_99999999-9999-9999-9999-999999999999",
          subject: "Wednesday race roster",
          body:
            "Crews are posted for the Wednesday race. Check in with the dock captain by 5:45pm.",
          statuses: ["delivered", "delayed", "sent"]
        }
      ]
    }
  ]

  def run do
    with_local_mailbox_delivery(fn ->
      clear_local_mailbox()
      LocalDeliveryFacts.reset()

      clubs = seed_membership()
      seed_pending_invitation(clubs)
      seed_pending_account_request()
      seed_messages(clubs)

      IO.puts("Seeded representative Memba data.")
      IO.puts("Reset and seed path: cd web && mix ecto.reset")
      IO.puts("Seed-only path: cd web && mix run priv/repo/seeds.exs")
      IO.puts("Member sign-in emails: alice@example.com, eleanor@example.com, hana@example.com")
      IO.puts("Alice alternate sign-in email: alice@work.example")
      IO.puts("Pending invitation email: invitee.kac@example.com")
      IO.puts("Pending account request email: priya.requester@example.com")
      IO.puts("Representative emails are available at /dev/mailbox.")
    end)
  end

  def deliver_representative_emails do
    with_local_mailbox_delivery(fn ->
      deliver_transactional_examples(@clubs)
    end)
  end

  defp with_local_mailbox_delivery(fun) when is_function(fun, 0) do
    original_provider = Application.get_env(:memba, :messaging_email_delivery_provider)
    original_mailer = Application.get_env(:memba, Memba.Mailer)
    original_auth_email = Application.get_env(:memba, Memba.Accounts.AuthEmail)

    configure_local_mailbox_delivery()

    try do
      fun.()
    after
      restore_env(:messaging_email_delivery_provider, original_provider)
      restore_env(Memba.Mailer, original_mailer)
      restore_env(Memba.Accounts.AuthEmail, original_auth_email)
    end
  end

  defp configure_local_mailbox_delivery do
    Application.put_env(:memba, :messaging_email_delivery_provider, LocalDeliveryProvider)
    Application.put_env(:memba, Memba.Mailer, adapter: Swoosh.Adapters.Local)

    Application.put_env(:memba, Memba.Accounts.AuthEmail,
      from: "auth@mail.memba.local",
      message_stream: "development-auth"
    )
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)

  defp clear_local_mailbox do
    case :global.whereis_name(Swoosh.Adapters.Local.Storage.Memory) do
      pid when is_pid(pid) -> Swoosh.Adapters.Local.Storage.Memory.delete_all()
      :undefined -> :ok
    end
  end

  defp seed_membership do
    Enum.each(@clubs, fn club ->
      dispatch_unless_projected(Membership.get_club(club.club_id), fn ->
        Membership.create_club(
          %{club_id: club.club_id, name: club.name, slug: club.slug},
          consistency: :strong
        )
      end)
    end)

    await_seeded_clubs!()

    @clubs
    |> all_members()
    |> Enum.each(fn member ->
      dispatch_unless_projected(Membership.get_person(member.person_id), fn ->
        Membership.create_person(
          %{
            person_id: member.person_id,
            name: member.name,
            email_addresses: email_addresses(member)
          },
          consistency: :strong
        )
      end)
    end)

    await_seeded_people!()

    @clubs
    |> Enum.each(fn club ->
      Enum.each(club.members, fn member ->
        unless Membership.active_member_of_club?(club.club_id, member.person_id) do
          assert_ok!(
            Membership.add_member(
              %{
                membership_id: member.membership_id,
                club_id: club.club_id,
                person_id: member.person_id
              },
              consistency: :strong
            ),
            "add member #{member.name} to #{club.name}"
          )
        end
      end)
    end)

    await_seeded_memberships!()

    @clubs
    |> Enum.each(fn club ->
      club.members
      |> Enum.filter(&Map.get(&1, :manager?, false))
      |> Enum.each(&assign_membership_manager!(club, &1))
    end)

    await_seeded_manager_permissions!()
    @clubs
  end

  defp email_addresses(member) do
    primary = [%{email: member.email, is_primary: true}]

    alternates =
      member
      |> Map.get(:alternate_emails, [])
      |> Enum.map(&%{email: &1, is_primary: false})

    primary ++ alternates
  end

  defp assign_membership_manager!(club, member) do
    role_id = Roles.membership_administrator_role_id(club.club_id)

    result =
      MembershipApp.dispatch(
        %AssignMemberRole{
          club_id: club.club_id,
          membership_id: member.membership_id,
          person_id: member.person_id,
          role_id: role_id
        },
        consistency: :strong
      )

    case result do
      :ok -> :ok
      {:error, :role_already_assigned} -> :ok
      {:error, reason} -> raise "Could not assign #{member.name} as manager: #{inspect(reason)}"
    end
  end

  defp seed_pending_invitation(clubs) do
    club = Enum.find(clubs, &(&1.key == "kac"))

    result =
      Membership.invite_club_member(
        %{
          invitation_id: "inv_50000000-0000-0000-0000-000000000001",
          club_id: club.club_id,
          email: "invitee.kac@example.com"
        },
        consistency: :strong
      )

    invitation =
      case result do
        {:ok, %{invitation_id: invitation_id, invitation_token: invitation_token}} ->
          %{invitation_id: invitation_id, invitation_token: invitation_token}

        {:error, :already_invited} ->
          nil

        {:error, reason} ->
          raise "Could not create pending club invitation: #{inspect(reason)}"
      end

    await_pending_invitation!(club)

    if invitation do
      assert_ok!(
        ClubMemberInvitationEmail.deliver(%{
          email: "invitee.kac@example.com",
          club: %{club_id: club.club_id, name: club.name},
          invitation_id: invitation.invitation_id,
          invitation_url:
            "http://#{club.slug}.lvh.me:4000/invitations/club-members/#{invitation.invitation_token}"
        }),
        "deliver club-member invitation email"
      )
    end
  end

  defp seed_pending_account_request do
    attrs = %{
      requester_name: "Priya Patel",
      requested_club_name: "Prairie Lantern Society",
      note:
        "We are moving our member list out of spreadsheets and want to try Memba for our summer programme."
    }

    case Onboarding.create_request(attrs, verified_identity_email: "priya.requester@example.com") do
      {:ok, request} ->
        assert_ok!(NewRequestEmail.deliver(request), "deliver new account request email")

      {:error, changeset} ->
        raise "Could not create pending account request: #{inspect(changeset.errors)}"
    end
  end

  defp seed_messages(clubs) do
    Enum.each(clubs, fn club ->
      Enum.each(club.messages, fn message ->
        if Messaging.get_message(message.message_id) do
          :ok
        else
          assert_ok!(
            Messaging.send_club_message(
              Map.take(message, [:message_id, :club_id, :sender_id, :subject, :body])
              |> Map.put(:club_id, club.club_id),
              consistency: :strong
            ),
            "send #{message.subject}"
          )
        end

        await_seeded_message!(club, message)
        await_message_deliveries!(club, message)
        report_delivery_statuses!(message)
        await_message_delivery_statuses!(message)
      end)
    end)

    await_seeded_messages!(clubs)
  end

  defp report_delivery_statuses!(message) do
    message.message_id
    |> Messaging.list_recipient_deliveries()
    |> Enum.zip(message.statuses)
    |> Enum.each(fn {delivery, status} ->
      report_delivery_status!(message.message_id, delivery.delivery_id, status)
    end)
  end

  defp report_delivery_status!(_message_id, _delivery_id, "sent"), do: :ok

  defp report_delivery_status!(message_id, delivery_id, "delivered") do
    assert_ok!(
      Messaging.report_email_delivery_delivered(
        %{message_id: message_id, delivery_id: delivery_id},
        consistency: :strong
      ),
      "report delivered delivery #{delivery_id}"
    )
  end

  defp report_delivery_status!(message_id, delivery_id, "delayed") do
    assert_ok!(
      Messaging.report_email_delivery_delayed(
        %{
          message_id: message_id,
          delivery_id: delivery_id,
          reason: "Temporary mailbox throttling"
        },
        consistency: :strong
      ),
      "report delayed delivery #{delivery_id}"
    )
  end

  defp report_delivery_status!(message_id, delivery_id, "bounced") do
    assert_ok!(
      Messaging.report_email_delivery_bounced(
        %{
          message_id: message_id,
          delivery_id: delivery_id,
          reason: "Mailbox unavailable"
        },
        consistency: :strong
      ),
      "report bounced delivery #{delivery_id}"
    )
  end

  defp deliver_transactional_examples(clubs) do
    club = Enum.find(clubs, &(&1.key == "wcc"))
    member = Enum.find(club.members, & &1.manager?)

    deliver_sign_in_link!(club, member)
    deliver_welcome!(club)
    deliver_inbound_rejection!(clubs)
    deliver_renewal_reminder!(club, member)
  end

  defp deliver_sign_in_link!(club, member) do
    {:ok, %{token: token, email: email}} = Accounts.create_sign_in_token(member.email)

    assert_ok!(
      AuthEmail.deliver_sign_in_link(
        email,
        "http://#{club.slug}.lvh.me:4000/auth/sign-in/#{token}",
        club: %{name: club.name}
      ),
      "deliver sign-in link email"
    )
  end

  defp deliver_welcome!(club) do
    request = %Request{
      request_id: "req_70000000-0000-0000-0000-000000000001",
      requester_name: "Nadia North",
      requester_email: "nadia.north@example.com",
      requested_club_name: club.name,
      note: "Seeded welcome-email example"
    }

    assert_ok!(
      WelcomeEmail.deliver(%{request: request, club: %{name: club.name, slug: club.slug}}),
      "deliver welcome email"
    )
  end

  defp deliver_inbound_rejection!(clubs) do
    club = Enum.find(clubs, &(&1.key == "rps"))
    provider = "dev-seed"
    provider_message_id = "dev-seed-unknown-sender-rps"

    assert_ok!(
      Messaging.receive_inbound_club_email(
        %{
          provider: provider,
          provider_message_id: provider_message_id,
          from_address: "unknown.sender@example.net",
          recipient_addresses: [ClubInboundEmailAddress.address(club.slug)],
          subject: "Can I post this?",
          text_body: "This should be rejected because the sender is not a member."
        },
        consistency: :strong
      ),
      "receive rejected inbound club email"
    )

    await_inbound_email_source!(provider, provider_message_id)
  end

  defp deliver_renewal_reminder!(club, member) do
    new()
    |> from({"#{club.name} via Memba", "auth@mail.memba.local"})
    |> to({member.name, member.email})
    |> subject("Renewal reminder: #{club.name}")
    |> text_body("""
    Hi #{member.name},

    This is a seeded renewal reminder for #{club.name}. Your annual membership renewal is due on 30 June 2026.

    Thanks,
    #{club.initials} membership team
    """)
    |> html_body("""
    <p>Hi #{member.name},</p>
    <p>This is a seeded renewal reminder for #{club.name}. Your annual membership renewal is due on 30 June 2026.</p>
    <p>Thanks,<br>#{club.initials} membership team</p>
    """)
    |> Memba.Mailer.deliver()
    |> normalize_mailer_delivery("deliver renewal reminder email")
  end

  defp dispatch_unless_projected(nil, fun) when is_function(fun, 0) do
    assert_ok!(fun.(), "dispatch seed command")
  end

  defp dispatch_unless_projected(_projection, _fun), do: :ok

  defp all_members(clubs) do
    clubs
    |> Enum.flat_map(fn club ->
      Enum.map(club.members, &Map.put(&1, :club_id, club.club_id))
    end)
    |> Enum.uniq_by(& &1.person_id)
  end

  defp await_seeded_clubs! do
    club_ids = MapSet.new(Enum.map(@clubs, & &1.club_id))

    await_read_model!("seeded clubs to be queryable via Membership.list_clubs/0", fn ->
      Membership.list_clubs()
      |> Enum.map(& &1.club_id)
      |> MapSet.new()
      |> then(&MapSet.subset?(club_ids, &1))
    end)
  end

  defp await_seeded_people! do
    person_ids = MapSet.new(Enum.map(all_members(@clubs), & &1.person_id))

    await_read_model!("seeded people to be queryable via Membership.list_people/0", fn ->
      @clubs
      |> all_members()
      |> Enum.map(& &1.person_id)
      |> Enum.all?(&Membership.get_person/1) and
        Membership.list_people()
        |> Enum.map(& &1.person_id)
        |> MapSet.new()
        |> then(&MapSet.subset?(person_ids, &1))
    end)
  end

  defp await_seeded_memberships! do
    Enum.each(@clubs, fn club ->
      expected_member_ids = MapSet.new(Enum.map(club.members, & &1.person_id))

      await_read_model!(
        "seeded members for #{club.name} to be queryable via Membership.list_active_members_of_club/1",
        fn ->
          actual_member_ids =
            club.club_id
            |> Membership.list_active_members_of_club()
            |> Enum.map(& &1.id)
            |> MapSet.new()

          MapSet.subset?(expected_member_ids, actual_member_ids)
        end
      )
    end)
  end

  defp await_seeded_manager_permissions! do
    @clubs
    |> Enum.each(fn club ->
      club.members
      |> Enum.filter(&Map.get(&1, :manager?, false))
      |> Enum.each(fn member ->
        await_read_model!(
          "seeded manager permission for #{member.name} in #{club.name} to be queryable via Membership.person_has_club_permission?/3",
          fn ->
            Membership.person_has_club_permission?(
              club.club_id,
              member.person_id,
              "club.manage_members"
            )
          end
        )
      end)
    end)
  end

  defp await_pending_invitation!(club) do
    await_read_model!(
      "pending invitation for #{club.name} to be queryable via Membership.get_pending_club_member_invitation_by_email/2",
      fn ->
        Membership.get_pending_club_member_invitation_by_email(
          club.club_id,
          "invitee.kac@example.com"
        )
      end
    )
  end

  defp await_seeded_message!(club, message) do
    await_read_model!(
      "seeded message #{message.subject} to be queryable via Messaging.list_messages_for_club/1",
      fn ->
        club.club_id
        |> Messaging.list_messages_for_club()
        |> Enum.any?(&(&1.message_id == message.message_id))
      end
    )
  end

  defp await_message_deliveries!(club, message) do
    expected_count = length(club.members)

    await_read_model!(
      "recipient deliveries for #{message.subject} to be queryable via Messaging.list_recipient_deliveries/1",
      fn ->
        message.message_id
        |> Messaging.list_recipient_deliveries()
        |> length() == expected_count
      end
    )
  end

  defp await_message_delivery_statuses!(message) do
    expected_operator_status_counts = Enum.frequencies(message.statuses)

    expected_member_status_counts =
      message.statuses
      |> Enum.map(fn
        "delayed" -> "delivery problem"
        "bounced" -> "delivery problem"
        status -> status
      end)
      |> Enum.frequencies()

    await_read_model!(
      "member-facing delivery statuses for #{message.subject} to be queryable via Messaging.list_member_email_deliverys/1",
      fn ->
        actual_member_status_counts =
          message.message_id
          |> Messaging.list_member_email_deliverys()
          |> Enum.map(& &1.status)
          |> Enum.frequencies()

        actual_member_status_counts == expected_member_status_counts
      end
    )

    await_read_model!(
      "operator delivery statuses for #{message.subject} to be queryable via Messaging.list_operator_email_deliveries/1",
      fn ->
        actual_operator_status_counts =
          message.message_id
          |> Messaging.list_operator_email_deliveries()
          |> Enum.map(& &1.status)
          |> Enum.frequencies()

        actual_operator_status_counts == expected_operator_status_counts
      end
    )
  end

  defp await_seeded_messages!(clubs) do
    Enum.each(clubs, fn club ->
      expected_message_ids = MapSet.new(Enum.map(club.messages, & &1.message_id))

      await_read_model!(
        "seeded messages for #{club.name} to be queryable via Messaging.list_messages_for_club/1",
        fn ->
          actual_message_ids =
            club.club_id
            |> Messaging.list_messages_for_club()
            |> Enum.map(& &1.message_id)
            |> MapSet.new()

          MapSet.subset?(expected_message_ids, actual_message_ids)
        end
      )
    end)
  end

  defp await_inbound_email_source!(provider, provider_message_id) do
    await_read_model!(
      "inbound email source #{provider}/#{provider_message_id} to be queryable via Messaging.get_inbound_email_source/2",
      fn ->
        Messaging.get_inbound_email_source(provider, provider_message_id)
      end
    )
  end

  defp await_read_model!(label, fun) when is_function(fun, 0) do
    deadline = System.monotonic_time(:millisecond) + @read_model_timeout
    do_await_read_model!(label, fun, deadline)
  end

  defp do_await_read_model!(label, fun, deadline) do
    if fun.() do
      :ok
    else
      if System.monotonic_time(:millisecond) >= deadline do
        raise "Timed out waiting for #{label}"
      end

      Process.sleep(@read_model_poll_interval)
      do_await_read_model!(label, fun, deadline)
    end
  end

  defp assert_ok!(:ok, _label), do: :ok
  defp assert_ok!({:ok, _result}, _label), do: :ok

  defp assert_ok!({:error, reason}, label) do
    raise "#{label} failed: #{inspect(reason)}"
  end

  defp assert_ok!(other, label) do
    raise "#{label} returned unexpected result: #{inspect(other)}"
  end

  defp normalize_mailer_delivery({:ok, _delivery}, _label), do: :ok

  defp normalize_mailer_delivery({:error, reason}, label) do
    raise "#{label} failed: #{inspect(reason)}"
  end
end
