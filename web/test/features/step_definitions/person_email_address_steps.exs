defmodule Memba.Cucumber.PersonEmailAddressSteps do
  use Cucumber.StepDefinition

  import ExUnit.Assertions

  alias Memba.Accounts
  alias Memba.Membership
  alias Memba.Messaging.EmailDeliveryDispatcher
  alias Memba.Messaging.EmailDeliveryProviders.Fake

  step "Alice's primary email address is {string}", %{args: [primary_email]} = context do
    set_primary_email_address(context, "Alice", primary_email)
  end

  step "{word}'s primary email address is {string}",
       %{args: [person_name, primary_email]} = context do
    set_primary_email_address(context, person_name, primary_email)
  end

  defp set_primary_email_address(context, person_name, primary_email) do
    current = person_email_addresses_for(context, person_name)

    alternates =
      current
      |> Enum.reject(& &1.is_primary)
      |> Enum.reject(&same_email?(&1.email, primary_email))

    ensure_person_email_addresses(context, person_name, [
      %{email: primary_email, is_primary: true} | alternates
    ])
  end

  step "Alice's alternate email address is {string}", %{args: [alternate_email]} = context do
    add_alternate_email_address(context, "Alice", alternate_email)
  end

  step "{word}'s alternate email address is {string}",
       %{args: [person_name, alternate_email]} = context do
    add_alternate_email_address(context, person_name, alternate_email)
  end

  defp add_alternate_email_address(context, person_name, alternate_email) do
    current = person_email_addresses_for(context, person_name)

    primary =
      Enum.find(current, & &1.is_primary) ||
        %{
          email: default_email_for(person_name),
          is_primary: true
        }

    alternates =
      current
      |> Enum.reject(& &1.is_primary)
      |> Enum.reject(&same_email?(&1.email, alternate_email))

    ensure_person_email_addresses(context, person_name, [
      primary | alternates ++ [%{email: alternate_email, is_primary: false}]
    ])
  end

  step "{word} should receive a sign-in link at {string}",
       %{args: [person_name, expected_email]} = context do
    assert %{token: token, email: email} =
             fetch_from_context!(context, :sign_in_links, person_name)

    assert is_binary(token)
    assert email == Accounts.normalize_email(expected_email)
    context
  end

  step "{word} should receive the email at {string}",
       %{args: [_person_name, expected_email]} = context do
    dispatch_pending_email_deliveries()

    assert Enum.any?(Fake.deliveries(), &same_email?(&1.recipient_address, expected_email))
    context
  end

  step "{word} should not receive the email at {string}",
       %{args: [_person_name, unexpected_email]} = context do
    dispatch_pending_email_deliveries()

    refute Enum.any?(Fake.deliveries(), &same_email?(&1.recipient_address, unexpected_email))
    context
  end

  step "{word} is signed in as Memba staff", %{args: [person_name]} = context do
    email = staff_email_for(person_name)

    context
    |> update_context_map(:people, person_name, %{email: email})
    |> Map.put(:signed_in_identity, %{email: email, staff?: true, active_clubs: []})
    |> Map.put(:current_page, :staff_only_homepage)
  end

  step "{word} creates a person named {word} with primary email {string} and alternate email {string}",
       %{args: [_staff_name, person_name, primary_email, alternate_email]} = context do
    ensure_person_email_addresses(context, person_name, [
      %{email: primary_email, is_primary: true},
      %{email: alternate_email, is_primary: false}
    ])
  end

  step "{word} has primary email {string} and alternate email {string}",
       %{args: [person_name, primary_email, alternate_email]} = context do
    ensure_person_email_addresses(context, person_name, [
      %{email: primary_email, is_primary: true},
      %{email: alternate_email, is_primary: false}
    ])
  end

  step "Pat makes {string} Alice's primary email address",
       %{args: [new_primary_email]} = context do
    make_primary_email_address(context, "Alice", new_primary_email)
  end

  step "{word} makes {string} {word}'s primary email address",
       %{args: [_staff_name, new_primary_email, person_name]} = context do
    make_primary_email_address(context, person_name, new_primary_email)
  end

  defp make_primary_email_address(context, person_name, new_primary_email) do
    current = person_email_addresses_for(context, person_name)

    assert Enum.any?(current, &same_email?(&1.email, new_primary_email)),
           "Expected #{person_name} to have known email address #{new_primary_email}"

    next_email_addresses =
      Enum.map(current, fn email_address ->
        %{
          email: email_address.email,
          is_primary: same_email?(email_address.email, new_primary_email)
        }
      end)

    ensure_person_email_addresses(context, person_name, next_email_addresses)
  end

  step "Alice's primary email address should be {string}", %{args: [expected_email]} = context do
    assert_primary_email_address(context, "Alice", expected_email)
  end

  step "{word}'s primary email address should be {string}",
       %{args: [person_name, expected_email]} = context do
    assert_primary_email_address(context, person_name, expected_email)
  end

  step "Alice's alternate email addresses should include {string}",
       %{args: [expected_email]} = context do
    assert_alternate_email_address(context, "Alice", expected_email)
  end

  step "{word}'s alternate email addresses should include {string}",
       %{args: [person_name, expected_email]} = context do
    assert_alternate_email_address(context, person_name, expected_email)
  end

  defp assert_primary_email_address(context, person_name, expected_email) do
    email_addresses = persisted_person_email_addresses(context, person_name)

    assert Enum.any?(email_addresses, &(&1.primary? and &1.email == expected_email))
    context
  end

  defp assert_alternate_email_address(context, person_name, expected_email) do
    email_addresses = persisted_person_email_addresses(context, person_name)

    assert Enum.any?(email_addresses, &(!&1.primary? and &1.email == expected_email))
    context
  end

  defp ensure_person_email_addresses(context, person_name, email_addresses) do
    case context_person_id(context, person_name) do
      nil ->
        person_id = Memba.ID.generate(:person)
        primary_email = primary_email!(email_addresses)

        assert :ok =
                 Membership.create_person(
                   %{
                     person_id: person_id,
                     name: person_name,
                     email: primary_email,
                     email_addresses: email_addresses
                   },
                   consistency: :strong
                 )

        update_context_map(context, :people, person_name, %{
          person_id: person_id,
          email: primary_email
        })

      person_id ->
        ensure_desired_addresses_are_verified(person_id, email_addresses)

        assert :ok =
                 Membership.replace_person_email_addresses(
                   %{person_id: person_id, email_addresses: email_addresses},
                   consistency: :strong
                 )

        update_context_map(context, :people, person_name, %{
          person_id: person_id,
          email: primary_email!(email_addresses)
        })
    end
  end

  defp person_email_addresses_for(context, person_name) do
    case context_person_id(context, person_name) do
      nil ->
        []

      person_id ->
        person_id
        |> Membership.list_person_email_addresses()
        |> Enum.map(fn email_address ->
          %{email: email_address.email, is_primary: email_address.primary?}
        end)
    end
  end

  defp persisted_person_email_addresses(context, person_name) do
    case context_person_id(context, person_name) do
      nil -> flunk("Expected #{person_name} to be known in the scenario")
      person_id -> Membership.list_person_email_addresses(person_id)
    end
  end

  defp context_person_id(context, person_name) do
    case Map.get(context, :people, %{}) |> Map.get(person_name) do
      %{person_id: person_id} -> person_id
      person_id when is_binary(person_id) -> person_id
      _missing -> nil
    end
  end

  defp primary_email!(email_addresses) do
    case Enum.find(email_addresses, & &1.is_primary) do
      %{email: email} -> email
      nil -> flunk("Expected exactly one primary email address")
    end
  end

  defp ensure_desired_addresses_are_verified(person_id, email_addresses) do
    current_email_addresses = Membership.list_person_email_addresses(person_id)

    Enum.each(email_addresses, fn %{email: email} ->
      unless Enum.any?(current_email_addresses, &same_email?(&1.email, email)) do
        assert :ok =
                 Membership.add_person_email_address(
                   %{person_id: person_id, email: email},
                   consistency: :strong
                 )

        assert :ok =
                 Membership.verify_person_email_address(
                   %{person_id: person_id, email: email},
                   consistency: :strong
                 )
      end
    end)
  end

  defp same_email?(left, right),
    do: Accounts.normalize_email(left) == Accounts.normalize_email(right)

  defp default_email_for(person_name), do: "#{String.downcase(person_name)}@example.test"
  defp staff_email_for(person_name), do: "#{String.downcase(person_name)}@memba.io"

  defp fetch_from_context!(context, collection_key, item_key) do
    context
    |> Map.get(collection_key, %{})
    |> Map.fetch(item_key)
    |> case do
      {:ok, value} -> value
      :error -> flunk("Expected #{inspect(item_key)} to be present in #{inspect(collection_key)}")
    end
  end

  defp update_context_map(context, collection_key, item_key, value) do
    collection =
      context
      |> Map.get(collection_key, %{})
      |> Map.update(item_key, value, fn
        existing when is_map(existing) -> Map.merge(existing, value)
        _existing -> value
      end)

    Map.put(context, collection_key, collection)
  end

  defp dispatch_pending_email_deliveries do
    _deliveries = EmailDeliveryDispatcher.dispatch_pending_email_deliveries()
    :ok
  end
end
