defmodule Memba.Cucumber.AuthenticationSteps do
  use Cucumber.StepDefinition

  import Ecto.Query
  import ExUnit.Assertions

  alias Memba.Accounts
  alias Memba.Accounts.MagicToken
  alias Memba.Membership
  alias Memba.Repo

  step "{word} is a member of Kootenay Mountaineering Club", %{args: [person_name]} = context do
    ensure_member(context, person_name, "Kootenay Mountaineering Club")
  end

  step "Alice is a member of Nelson Paddling Club", context do
    ensure_member(context, "Alice", "Nelson Paddling Club")
  end

  step "{word} is not a member of any club", %{args: [person_name]} = context do
    update_context_map(context, :people, person_name, %{email: default_email_for(person_name)})
  end

  step "{word} requests a sign-in link for their email address",
       %{args: [person_name]} = context do
    person = fetch_from_context!(context, :people, person_name)
    request_sign_in_link(context, person_name, person.email)
  end

  step "{word} requests a sign-in link for {string}", %{args: [person_name, email]} = context do
    context
    |> update_context_map(:people, person_name, %{email: email})
    |> request_sign_in_link(person_name, email)
  end

  step "{word} should receive a sign-in link", %{args: [person_name]} = context do
    assert %{token: token} = fetch_from_context!(context, :sign_in_links, person_name)
    assert is_binary(token)
    context
  end

  step "{word} should not receive a sign-in link", %{args: [person_name]} = context do
    assert %{token: nil} = fetch_from_context!(context, :sign_in_links, person_name)
    context
  end

  step "{word} follows the sign-in link", %{args: [person_name]} = context do
    follow_sign_in_link(context, person_name)
  end

  step "{word} follows the same sign-in link again", %{args: [person_name]} = context do
    follow_sign_in_link(context, person_name)
  end

  step "{word} follows a sign-in link that Memba did not issue", context do
    assert {:error, :not_found} = Accounts.consume_magic_token("not-issued-by-memba")
    Map.put(context, :signed_in_identity, nil)
  end

  step "{word} has received a sign-in link for their email address",
       %{args: [person_name]} = context do
    person = fetch_from_context!(context, :people, person_name)

    context
    |> request_sign_in_link(person_name, person.email)
    |> tap(fn context ->
      assert %{token: token} = fetch_from_context!(context, :sign_in_links, person_name)
      assert is_binary(token)
    end)
  end

  step "{word} has already followed the sign-in link", %{args: [person_name]} = context do
    follow_sign_in_link(context, person_name)
  end

  step "the sign-in link has expired", context do
    %{email: email} = fetch_from_context!(context, :sign_in_links, "Alice")
    expired_at = DateTime.add(DateTime.utc_now(:microsecond), -60, :second)

    MagicToken
    |> where([token], token.email == ^Accounts.normalize_email(email))
    |> order_by([token], desc: token.inserted_at)
    |> limit(1)
    |> Repo.one!()
    |> Ecto.Changeset.change(expires_at: expired_at)
    |> Repo.update!()

    context
  end

  step "{word} has tried to open the staff-only area", context do
    Map.put(context, :return_to, :staff_only_homepage)
  end

  step "{word} should be signed in", %{args: [person_name]} = context do
    identity = Map.fetch!(context, :signed_in_identity)
    person = fetch_from_context!(context, :people, person_name)
    assert identity.email == Accounts.normalize_email(person.email)
    context
  end

  step "{word} should be signed in as Memba staff", %{args: [person_name]} = context do
    identity = Map.fetch!(context, :signed_in_identity)
    person = fetch_from_context!(context, :people, person_name)
    assert identity.email == Accounts.normalize_email(person.email)
    assert identity.staff? == true
    context
  end

  step "{word} should not be signed in", context do
    assert Map.get(context, :signed_in_identity) == nil
    context
  end

  step "{word} should be on the staff-only homepage", context do
    identity = Map.fetch!(context, :signed_in_identity)
    assert identity.staff? == true
    context
  end

  step "{word} should see Kootenay Mountaineering Club in their clubs", context do
    assert_signed_in_club(context, "Kootenay Mountaineering Club")
  end

  step "{word} should see Nelson Paddling Club in their clubs", context do
    assert_signed_in_club(context, "Nelson Paddling Club")
  end

  step "{word} should be able to see Kootenay Mountaineering Club in their clubs", context do
    assert_signed_in_club(context, "Kootenay Mountaineering Club")
  end

  defp ensure_member(context, person_name, club_name) do
    context
    |> ensure_club(club_name)
    |> ensure_person(person_name)
    |> add_member(person_name, club_name)
  end

  defp ensure_club(context, club_name) do
    if get_in(context, [:clubs, club_name]) do
      context
    else
      club_id = Ecto.UUID.generate()

      assert :ok =
               Membership.create_club(%{club_id: club_id, name: club_name}, consistency: :strong)

      update_context_map(context, :clubs, club_name, club_id)
    end
  end

  defp ensure_person(context, person_name) do
    if get_in(context, [:people, person_name, :person_id]) do
      context
    else
      person_id = Ecto.UUID.generate()
      email = default_email_for(person_name)

      assert :ok =
               Membership.create_person(
                 %{person_id: person_id, name: person_name, email: email},
                 consistency: :strong
               )

      update_context_map(context, :people, person_name, %{person_id: person_id, email: email})
    end
  end

  defp add_member(context, person_name, club_name) do
    club_id = fetch_from_context!(context, :clubs, club_name)
    %{person_id: person_id} = fetch_from_context!(context, :people, person_name)

    if Membership.active_member_of_club?(club_id, person_id) do
      context
    else
      assert :ok =
               Membership.add_member(
                 %{membership_id: Ecto.UUID.generate(), club_id: club_id, person_id: person_id},
                 consistency: :strong
               )

      update_context_map(context, :memberships, {club_name, person_name}, true)
    end
  end

  defp request_sign_in_link(context, person_name, email) do
    case Accounts.request_magic_link(email) do
      {:ok, %{token: token, email: normalized_email}} ->
        update_context_map(context, :sign_in_links, person_name, %{
          token: token,
          email: normalized_email
        })

      {:ok, nil} ->
        update_context_map(context, :sign_in_links, person_name, %{token: nil, email: email})

      {:error, reason} ->
        flunk("Expected sign-in link request not to error; got #{inspect(reason)}")
    end
  end

  defp follow_sign_in_link(context, person_name) do
    %{token: token} = fetch_from_context!(context, :sign_in_links, person_name)

    case Accounts.consume_magic_token(token) do
      {:ok, %{email: email}} ->
        Map.put(context, :signed_in_identity, %{
          email: email,
          staff?: Accounts.staff_email?(email),
          active_clubs: Accounts.list_active_clubs_for_email(email)
        })

      {:error, _reason} ->
        Map.put(context, :signed_in_identity, nil)
    end
  end

  defp assert_signed_in_club(context, club_name) do
    identity = Map.fetch!(context, :signed_in_identity)
    assert Enum.any?(identity.active_clubs, &(&1.name == club_name))
    context
  end

  defp default_email_for("Pat"), do: "pat@memba.io"
  defp default_email_for(person_name), do: email_for(person_name)

  defp email_for(name) do
    normalized_name =
      name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, ".")
      |> String.trim(".")

    "#{normalized_name}@example.test"
  end

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
      |> Map.put(item_key, value)

    Map.put(context, collection_key, collection)
  end
end
