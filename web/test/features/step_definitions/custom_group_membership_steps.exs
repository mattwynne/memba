defmodule Memba.Cucumber.CustomGroupMembershipSteps do
  use Cucumber.StepDefinition

  import ExUnit.Assertions

  alias Memba.Membership
  alias Memba.Membership.CustomGroupAdmission
  alias Memba.Membership.GroupWelcomeEmail
  alias Memba.Membership.Permissions
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging

  @club_name "Kootenay Mountaineering Club"
  @board_name "Board"
  @agenda_subject "September agenda"

  step ~r/^(\w+) adds (\w+) to Board$/,
       %{args: [actor_name, target_text]} = context do
    admit!(context, actor_name, reflexive_target(actor_name, target_text), @board_name)
  end

  step "Bob has added Carol to Board", context do
    admit!(context, "Bob", "Carol", @board_name)
  end

  step ~r/^(\w+) also adds (\w+) to Board$/,
       %{args: [actor_name, target_name]} = context do
    admit!(context, actor_name, target_name, @board_name)
  end

  step ~r/^(\w+) directly tries to add (herself|himself|\w+) to Board$/,
       %{args: [actor_name, target_text]} = context do
    target_name = reflexive_target(actor_name, target_text)
    attempt_admission(context, actor_name, target_name, @board_name)
  end

  step ~r/^(\w+) tries to add (\w+) to Board$/,
       %{args: [actor_name, target_name]} = context do
    attempt_admission(context, actor_name, target_name, @board_name)
  end

  step ~r/^(\w+) tries to add (\w+) to Admin as though it were a custom group$/,
       %{args: [actor_name, target_name]} = context do
    attempt_admission(context, actor_name, target_name, "Admin")
  end

  step ~r/^(\w+) removes (\w+) from Board$/,
       %{args: [actor_name, target_name]} = context do
    remove!(context, actor_name, target_name, @board_name)
  end

  step ~r/^(\w+) attempts to remove (\w+) from Board$/,
       %{args: [actor_name, target_name]} = context do
    attempt_removal(context, actor_name, target_name, @board_name)
  end

  step ~r/^(\w+) tries to leave (Everyone|Admin) as though it were a custom group$/,
       %{args: [actor_name, group_name]} = context do
    attempt_removal(context, actor_name, actor_name, group_name)
  end

  step "Alice is the only remaining club admin", context do
    assert :ok =
             Membership.remove_membership_administrator_as_club_member(
               %{
                 club_id: club_id!(context, @club_name),
                 membership_id: membership_id!(context, @club_name, "Dan"),
                 person_id: person_id!(context, "Dan"),
                 actor_person_id: person_id!(context, "Alice")
               },
               consistency: :strong
             )

    context
  end

  step "Robin has been invited to KMC but has not joined", context do
    context = ensure_person(context, "Robin")
    email = person!(context, "Robin").email

    assert {:ok, %{invitation_id: invitation_id}} =
             Membership.invite_club_member(
               %{club_id: club_id!(context, @club_name), email: email},
               consistency: :strong
             )

    context
    |> put_context(:attempt_memberships, {@club_name, "Robin"}, Memba.ID.generate(:membership))
    |> Map.put(:robin_invitation_id, invitation_id)
  end

  step "Carol is no longer an active member of KMC", context do
    assert :ok =
             Membership.remove_member(
               %{membership_id: membership_id!(context, @club_name, "Carol")},
               consistency: :strong
             )

    context
  end

  step "Carol has rejoined KMC after losing her Board membership", context do
    context = admit!(context, "Bob", "Carol", @board_name, deliver_welcome?: false)
    message = message!(context, @agenda_subject)

    assert :ok =
             Messaging.follow_conversation_as_current_member(
               %{
                 club_id: club_id!(context, @club_name),
                 conversation_id: message.message_id,
                 member_id: person_id!(context, "Carol")
               },
               consistency: :strong
             )

    assert :ok =
             Membership.remove_member(
               %{membership_id: membership_id!(context, @club_name, "Carol")},
               consistency: :strong
             )

    replacement_membership_id = Memba.ID.generate(:membership)

    assert :ok =
             Membership.add_member(
               %{
                 club_id: club_id!(context, @club_name),
                 membership_id: replacement_membership_id,
                 person_id: person_id!(context, "Carol")
               },
               consistency: :strong
             )

    put_context(
      context,
      :memberships,
      {@club_name, "Carol"},
      replacement_membership_id
    )
  end

  step ~r/^(\w+) should belong to Board$/,
       %{args: [person_name]} = context do
    assert group_member?(context, @board_name, person_name)
    context
  end

  step "Bob should remain an ordinary club member", context do
    bob_id = person_id!(context, "Bob")
    club_id = club_id!(context, @club_name)

    assert Membership.active_member_of_club?(club_id, bob_id)

    refute Membership.person_has_club_permission?(
             club_id,
             bob_id,
             Permissions.club_manage_members()
           )

    refute Membership.active_member_of_group?(
             SystemGroups.admin_group_id(club_id),
             bob_id
           )

    context
  end

  step "Dan should still have no access to Board conversations", context do
    refute group_member?(context, @board_name, "Dan")

    Enum.each(
      Messaging.list_conversations_for_group(group_id!(context, @board_name)),
      fn message ->
        refute Messaging.member_has_conversation_access?(
                 message.message_id,
                 club_id!(context, @club_name),
                 person_id!(context, "Dan"),
                 :read
               )
      end
    )

    context
  end

  step ~r/^he should be able to read "([^"]+)"$/,
       %{args: [subject]} = context do
    assert_can_read(context, Map.fetch!(context, :last_admission_actor), subject)
  end

  step "Carol should have one active Board membership", context do
    assert active_group_member_count(context, @board_name, "Carol") == 1
    context
  end

  step "Carol should have received one Board welcome email", context do
    assert length(welcome_emails_for(context, "Carol", @board_name)) == 1
    context
  end

  step "Alice and Bob should remain Board's only members", context do
    assert active_group_member_names(context, @board_name) == ["Alice", "Bob"]
    context
  end

  step ~r/^(\w+) should not become an active KMC member through that attempt$/,
       %{args: [person_name]} = context do
    refute Membership.active_member_of_club?(
             club_id!(context, @club_name),
             person_id!(context, person_name)
           )

    context
  end

  step ~r/^(\w+) should not belong to Admin$/,
       %{args: [person_name]} = context do
    refute Membership.active_member_of_group?(
             SystemGroups.admin_group_id(club_id!(context, @club_name)),
             person_id!(context, person_name)
           )

    context
  end

  step ~r/^(\w+) should no longer belong to Board$/,
       %{args: [person_name]} = context do
    refute group_member?(context, @board_name, person_name)
    context
  end

  step "Alice should still be a club admin", context do
    assert club_admin?(context, "Alice")
    context
  end

  step "Alice should still be able to manage Board's membership", context do
    assert club_admin?(context, "Alice")
    context
  end

  step "Alice should no longer be able to read Board conversations", context do
    refute_group_conversation_access(context, "Alice")
  end

  step "Bob should remain an active KMC member", context do
    assert Membership.active_member_of_club?(
             club_id!(context, @club_name),
             person_id!(context, "Bob")
           )

    context
  end

  step "Bob should remain in Everyone", context do
    assert group_member?(context, "Everyone", "Bob")
    context
  end

  step "Bob should remain an active club member", context do
    assert Membership.active_member_of_club?(
             club_id!(context, @club_name),
             person_id!(context, "Bob")
           )

    context
  end

  step "Alice should remain a club admin and a member of Admin", context do
    assert club_admin?(context, "Alice")
    assert group_member?(context, "Admin", "Alice")
    context
  end

  step "Eve should remain an ordinary club member", context do
    eve_id = person_id!(context, "Eve")
    club_id = club_id!(context, @club_name)

    assert Membership.active_member_of_club?(club_id, eve_id)

    refute Membership.person_has_club_permission?(
             club_id,
             eve_id,
             Permissions.club_manage_members()
           )

    context
  end

  step ~r/^Carol should be able to read "([^"]+)" and "([^"]+)"$/,
       %{args: [subject, reply_body]} = context do
    assert_can_read(context, "Carol", subject)

    assert Enum.any?(
             Messaging.list_conversation_messages(message!(context, subject).message_id),
             &(&1.body == reply_body)
           )

    context
  end

  step "Carol should be able to read Board's whole conversation history", context do
    assert_can_read(context, "Carol", @agenda_subject)

    assert length(
             Messaging.list_conversation_messages(message!(context, @agenda_subject).message_id)
           ) >= 2

    context
  end

  step "Carol should receive a welcome email with a link to Board", context do
    assert [email] = welcome_emails_for(context, "Carol", @board_name)
    assert email.subject =~ "You've been added to Board"
    assert email.text_body =~ group_url(context, @board_name)
    context
  end

  step "Carol should not be sent old conversation emails from Board", context do
    carol_id = person_id!(context, "Carol")

    context
    |> conversation_message_ids(@agenda_subject)
    |> Enum.each(fn message_id ->
      refute Enum.any?(
               Messaging.list_recipient_deliveries(message_id),
               &(&1.recipient_id == carol_id)
             )
    end)

    context
  end

  step "Carol's former conversation follows should not be restored", context do
    refute Messaging.following_conversation?(
             message!(context, @agenda_subject).message_id,
             person_id!(context, "Carol")
           )

    context
  end

  defp remove!(context, actor_name, target_name, group_name) do
    context = attempt_removal(context, actor_name, target_name, group_name)
    assert {:ok, %Memba.Membership.CustomGroupRemoval{}} = context.last_removal_result
    context
  end

  defp attempt_removal(context, actor_name, target_name, group_name) do
    result =
      Membership.remove_custom_group_member(
        %{
          club_id: club_id!(context, @club_name),
          group_id: group_id!(context, group_name),
          membership_id: membership_id!(context, @club_name, target_name),
          person_id: person_id!(context, target_name),
          actor_person_id: person_id!(context, actor_name),
          removal_operation_id: Ecto.UUID.generate()
        },
        consistency: :strong
      )

    Map.put(context, :last_removal_result, result)
  end

  defp admit!(context, actor_name, target_name, group_name, opts \\ []) do
    context = attempt_admission(context, actor_name, target_name, group_name, opts)

    assert {:ok, %CustomGroupAdmission{}} = Map.fetch!(context, :last_admission_result)
    context
  end

  defp attempt_admission(context, actor_name, target_name, group_name, opts \\ []) do
    result =
      Membership.add_custom_group_member(
        %{
          club_id: club_id!(context, @club_name),
          group_id: group_id!(context, group_name),
          membership_id: admission_membership_id!(context, target_name),
          person_id: person_id!(context, target_name),
          actor_person_id: person_id!(context, actor_name)
        },
        consistency: :strong
      )

    context =
      context
      |> Map.put(:last_admission_result, result)
      |> Map.put(:last_admission_actor, actor_name)

    case result do
      {:ok, %CustomGroupAdmission{transition: :member_added} = admission} ->
        if Keyword.get(opts, :deliver_welcome?, true) do
          assert :ok = deliver_welcome(context, admission, actor_name, target_name, group_name)
          remember_delivered_email(context)
        else
          context
        end

      _other ->
        context
    end
  end

  defp deliver_welcome(context, admission, actor_name, target_name, group_name) do
    target = person!(context, target_name)
    actor = person!(context, actor_name)

    GroupWelcomeEmail.deliver(%{
      club: Membership.get_club(admission.club_id),
      group: Membership.get_group(admission.group_id),
      recipient: %{person_id: admission.person_id, name: target.name, email: target.email},
      added_by: %{person_id: admission.actor_person_id, name: actor.name},
      group_url: group_url(context, group_name)
    })
  end

  defp remember_delivered_email(context) do
    receive do
      {:email, email} ->
        Map.update(context, :group_welcome_emails, [email], &(&1 ++ [email]))
    after
      0 ->
        flunk("Expected custom-group welcome email delivery")
    end
  end

  defp welcome_emails_for(context, person_name, group_name) do
    expected_subject = "You've been added to #{group_name}"
    person = person!(context, person_name)

    context
    |> Map.get(:group_welcome_emails, [])
    |> Enum.filter(fn email ->
      String.contains?(email.subject, expected_subject) and
        Enum.any?(email.to, &email_address?(&1, person.email))
    end)
  end

  defp email_address?({_name, address}, expected), do: same_email?(address, expected)

  defp email_address?(address, expected) when is_binary(address),
    do: same_email?(address, expected)

  defp same_email?(left, right), do: String.downcase(left) == String.downcase(right)

  defp assert_can_read(context, person_name, subject) do
    message = message!(context, subject)

    assert Messaging.member_has_conversation_access?(
             message.message_id,
             message.club_id,
             person_id!(context, person_name),
             :read
           )

    context
  end

  defp conversation_message_ids(context, subject) do
    context
    |> message!(subject)
    |> Map.fetch!(:message_id)
    |> Messaging.list_conversation_messages()
    |> Enum.map(& &1.message_id)
  end

  defp active_group_member_names(context, group_name) do
    context
    |> group_id!(group_name)
    |> Membership.list_active_members_of_group()
    |> Enum.map(& &1.name)
    |> Enum.sort()
  end

  defp active_group_member_count(context, group_name, person_name) do
    person_id = person_id!(context, person_name)

    context
    |> group_id!(group_name)
    |> Membership.list_active_members_of_group()
    |> Enum.count(&(&1.id == person_id))
  end

  defp group_member?(context, group_name, person_name) do
    Membership.active_member_of_group?(
      group_id!(context, group_name),
      person_id!(context, person_name)
    )
  end

  defp ensure_person(context, person_name) do
    case get_in(context, [:people, person_name]) do
      %{person_id: person_id} when is_binary(person_id) ->
        context

      nil ->
        person_id = Memba.ID.generate(:person)
        email = "#{String.downcase(person_name)}-#{scenario_suffix(context)}@example.test"

        assert :ok =
                 Membership.create_person(
                   %{
                     person_id: person_id,
                     name: person_name,
                     email_addresses: [%{email: email, is_primary: true}]
                   },
                   consistency: :strong
                 )

        put_context(context, :people, person_name, %{
          person_id: person_id,
          email: email,
          name: person_name
        })
    end
  end

  defp admission_membership_id!(context, person_name) do
    get_in(context, [:memberships, {@club_name, person_name}]) ||
      get_in(context, [:attempt_memberships, {@club_name, person_name}]) ||
      other_club_membership_id!(context, person_name)
  end

  defp other_club_membership_id!(context, person_name) do
    context
    |> Map.fetch!(:memberships)
    |> Enum.find_value(fn
      {{_club_name, ^person_name}, membership_id} -> membership_id
      _entry -> nil
    end)
    |> case do
      nil -> flunk("Expected a membership identity for #{person_name}")
      membership_id -> membership_id
    end
  end

  defp membership_id!(context, club_name, person_name) do
    context
    |> Map.fetch!(:memberships)
    |> Map.fetch!({club_name, person_name})
  end

  defp club_id!(context, club_name) do
    context
    |> Map.fetch!(:clubs)
    |> Map.fetch!(club_name)
  end

  defp group_id!(context, "Admin") do
    SystemGroups.admin_group_id(club_id!(context, @club_name))
  end

  defp group_id!(context, "Everyone") do
    SystemGroups.everyone_group_id(club_id!(context, @club_name))
  end

  defp group_id!(context, group_name) do
    context
    |> Map.fetch!(:groups)
    |> Map.fetch!({@club_name, group_name})
  end

  defp club_admin?(context, person_name) do
    Membership.person_has_club_permission?(
      club_id!(context, @club_name),
      person_id!(context, person_name),
      Permissions.club_manage_members()
    )
  end

  defp refute_group_conversation_access(context, person_name) do
    Enum.each(
      Messaging.list_conversations_for_group(group_id!(context, @board_name)),
      fn message ->
        refute Messaging.member_has_conversation_access?(
                 message.message_id,
                 club_id!(context, @club_name),
                 person_id!(context, person_name),
                 :read
               )
      end
    )

    context
  end

  defp person_id!(context, person_name), do: person!(context, person_name).person_id

  defp person!(context, person_name) do
    context
    |> Map.fetch!(:people)
    |> Map.fetch!(person_name)
  end

  defp message!(context, subject) do
    context
    |> Map.fetch!(:messages)
    |> Map.fetch!(subject)
  end

  defp put_context(context, collection_key, item_key, value) do
    Map.update(context, collection_key, %{item_key => value}, &Map.put(&1, item_key, value))
  end

  defp group_url(context, group_name) do
    "https://kmc.example.test/groups/#{group_id!(context, group_name)}"
  end

  defp reflexive_target(actor_name, target_text)
       when target_text in ["herself", "himself"],
       do: actor_name

  defp reflexive_target(_actor_name, target_name), do: target_name

  defp scenario_suffix(context) do
    context
    |> Map.get(:scenario_name, "scenario")
    |> :erlang.phash2(1_000_000)
    |> Integer.to_string(36)
  end
end
