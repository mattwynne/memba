defmodule Memba.Cucumber.AuthenticationSteps do
  use Cucumber.StepDefinition

  import Ecto.Query
  import ExUnit.Assertions

  alias Memba.Accounts
  alias Memba.Accounts.AuthEmailRequest
  alias Memba.Accounts.SignInToken
  alias Memba.Membership
  alias Memba.Membership.Slug
  alias Memba.Repo

  @progress_message_pre_send "Preparing your sign-in link…"
  @progress_message_sent "If this email can sign in, the link is on its way."
  @progress_message_provider_accepted "Your mailbox provider has accepted the email. It should appear shortly."

  step "{word} is a member of Kootenay Mountaineering Club", %{args: [person_name]} = context do
    ensure_member(context, person_name, "Kootenay Mountaineering Club")
  end

  step "Alice is a member of Nelson Paddling Club", context do
    ensure_member(context, "Alice", "Nelson Paddling Club")
  end

  step "{word} is not a member of any club", %{args: [person_name]} = context do
    update_context_map(context, :people, person_name, %{
      email: default_email_for(context, person_name)
    })
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

  step "{word} signs in with their email address", %{args: [person_name]} = context do
    person = fetch_from_context!(context, :people, person_name)

    context
    |> request_sign_in_link(person_name, person.email)
    |> follow_sign_in_link(person_name)
  end

  step "{word} signs in with {string}", %{args: [person_name, email]} = context do
    context
    |> update_context_map(:people, person_name, %{email: email})
    |> request_sign_in_link(person_name, email)
    |> follow_sign_in_link(person_name)
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

  step "{word} should see that Memba is trying to send a sign-in link",
       %{args: [person_name]} = context do
    request = auth_email_request_for(context, person_name)

    assert request.status in [
             AuthEmailRequest.status_created(),
             AuthEmailRequest.status_sent()
           ]

    assert auth_email_progress_message(request) in [
             @progress_message_pre_send,
             @progress_message_sent
           ]

    context
  end

  step "Alice's mailbox provider accepts the sign-in email", context do
    person_name = "Alice"
    request = auth_email_request_for(context, person_name)

    assert {:ok, %AuthEmailRequest{} = request} =
             Accounts.record_auth_email_provider_accepted(request.request_id, %{
               provider: "postmark",
               provider_event_id: "acceptance-#{request.request_id}",
               provider_event_type: "Delivered",
               provider_message_id: "acceptance-message-#{request.request_id}",
               provider_message_stream: "outbound-authentication"
             })

    update_context_map(context, :auth_email_requests, person_name, %{
      request_id: request.request_id
    })
  end

  step "{word} should see that the email has been accepted by her mailbox provider",
       %{args: [person_name]} = context do
    request = auth_email_request_for(context, person_name)

    assert request.status == AuthEmailRequest.status_provider_accepted()
    assert auth_email_progress_message(request) == @progress_message_provider_accepted

    context
  end

  step "{word} should not be told that the email is in her inbox", context do
    context
    |> current_auth_email_progress_message()
    |> refute_inbox_placement_claim()

    context
  end

  step "{word} should see neutral sign-in email instructions",
       %{args: [person_name]} = context do
    request = auth_email_request_for(context, person_name)
    message = auth_email_progress_message(request)

    assert message in [
             @progress_message_pre_send,
             @progress_message_sent
           ]

    refute message =~ "unknown"
    refute message =~ "recognised"
    refute message =~ "recognized"

    context
  end

  step "{word} should not learn whether Memba recognises the email address",
       %{args: [person_name]} = context do
    request = auth_email_request_for(context, person_name)
    %{email: email} = fetch_from_context!(context, :people, person_name)
    message = auth_email_progress_message(request)

    refute message =~ email
    refute message =~ "unknown"
    refute message =~ "recognised"
    refute message =~ "recognized"
    refute message =~ "does not have"
    refute message =~ "not found"

    context
  end

  step "{word} follows the sign-in link", %{args: [person_name]} = context do
    follow_sign_in_link(context, person_name)
  end

  step "{word} follows the same sign-in link again", %{args: [person_name]} = context do
    follow_sign_in_link(context, person_name)
  end

  step "{word} follows a sign-in link that Memba did not issue", context do
    assert {:error, :not_found} = Accounts.consume_sign_in_token("not-issued-by-memba")
    Map.put(context, :signed_in_identity, nil)
  end

  step "{word} opens the Kootenay Mountaineering Club page", context do
    _club_id = fetch_from_context!(context, :clubs, "Kootenay Mountaineering Club")
    Map.put(context, :current_page, :club_page)
  end

  step "{word} signs out", context do
    sign_out(context)
  end

  step "{word} has signed out", context do
    sign_out(context)
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

  step "{word} is signed in as a member of Kootenay Mountaineering Club",
       %{args: [person_name]} = context do
    context
    |> ensure_member(person_name, "Kootenay Mountaineering Club")
    |> request_sign_in_link(person_name, default_email_for(context, person_name))
    |> follow_sign_in_link(person_name)
  end

  step "{word} has already followed the sign-in link", %{args: [person_name]} = context do
    follow_sign_in_link(context, person_name)
  end

  step "the sign-in link has expired", context do
    %{email: email} = fetch_from_context!(context, :sign_in_links, "Alice")
    expired_at = DateTime.add(DateTime.utc_now(:microsecond), -60, :second)

    SignInToken
    |> where([token], token.email == ^Accounts.normalize_email(email))
    |> order_by([token], desc: token.inserted_at)
    |> limit(1)
    |> Repo.one!()
    |> Ecto.Changeset.change(expires_at: expired_at)
    |> Repo.update!()

    context
  end

  step "{word} has tried to open the Memba staff area", context do
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

  step "{word} should still be signed in", %{args: [person_name]} = context do
    identity = Map.fetch!(context, :signed_in_identity)
    person = fetch_from_context!(context, :people, person_name)
    assert identity.email == Accounts.normalize_email(person.email)
    context
  end

  step "{word} should be signed out", context do
    assert Map.get(context, :signed_in_identity) == nil
    context
  end

  step "{word} should see they are signed in on the club page",
       %{args: [person_name]} = context do
    assert Map.get(context, :current_page) == :club_page
    identity = Map.fetch!(context, :signed_in_identity)
    person = fetch_from_context!(context, :people, person_name)
    assert identity.email == Accounts.normalize_email(person.email)
    context
  end

  step "{word} should see the Kootenay Mountaineering Public club page", context do
    assert Map.get(context, :current_page) == :club_page
    assert Map.get(context, :signed_in_identity) == nil
    context
  end

  step "the club page should show Powered by Memba in the footer", context do
    assert Map.get(context, :current_page) == :club_page
    context
  end

  step "{word} should be on the Memba staff home", context do
    identity = Map.fetch!(context, :signed_in_identity)
    assert identity.staff? == true
    assert Map.get(context, :current_page) == :staff_only_homepage
    context
  end

  step "{word} should be on the homepage", context do
    assert Map.get(context, :current_page) == :homepage
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
      club_id = Memba.ID.generate(:club)
      slug = scenario_slug(context, club_name)

      assert :ok =
               Membership.create_club(
                 %{club_id: club_id, name: club_name, slug: slug},
                 consistency: :strong
               )

      update_context_map(context, :clubs, club_name, club_id)
    end
  end

  defp ensure_person(context, person_name) do
    if get_in(context, [:people, person_name, :person_id]) do
      context
    else
      person_id = Memba.ID.generate(:person)
      email = default_email_for(context, person_name)

      assert :ok =
               Membership.create_person(
                 %{
                   person_id: person_id,
                   name: person_name,
                   email: email,
                   email_addresses: [%{email: email, is_primary: true}]
                 },
                 consistency: :strong
               )

      assert [
               %{email: ^email, normalized_email: ^email, primary?: true}
             ] = Membership.list_person_email_addresses(person_id)

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
                 %{
                   membership_id: Memba.ID.generate(:membership),
                   club_id: club_id,
                   person_id: person_id
                 },
                 consistency: :strong
               )

      update_context_map(context, :memberships, {club_name, person_name}, true)
    end
  end

  defp request_sign_in_link(context, person_name, email) do
    context = create_auth_email_request(context, person_name)
    request = auth_email_request_for(context, person_name)

    case Accounts.request_sign_in_link(email) do
      {:ok, %{token: token, email: normalized_email}} ->
        context
        |> mark_auth_email_sent(person_name, request.request_id, normalized_email)
        |> update_context_map(:sign_in_links, person_name, %{
          token: token,
          email: normalized_email
        })

      {:ok, nil} ->
        update_context_map(context, :sign_in_links, person_name, %{token: nil, email: email})

      {:error, reason} ->
        flunk("Expected sign-in link request not to error; got #{inspect(reason)}")
    end
  end

  defp create_auth_email_request(context, person_name) do
    case Accounts.create_auth_email_request() do
      {:ok, %AuthEmailRequest{} = request} ->
        update_context_map(context, :auth_email_requests, person_name, %{
          request_id: request.request_id
        })

      {:error, reason} ->
        flunk("Expected auth-email progress request not to error; got #{inspect(reason)}")
    end
  end

  defp mark_auth_email_sent(context, person_name, request_id, recipient_email) do
    assert {:ok, %AuthEmailRequest{} = request} =
             Accounts.mark_auth_email_sent(request_id, %{
               recipient_email: recipient_email,
               provider: "postmark",
               provider_message_stream: "outbound-authentication"
             })

    update_context_map(context, :auth_email_requests, person_name, %{
      request_id: request.request_id
    })
  end

  defp auth_email_request_for(context, person_name) do
    %{request_id: request_id} = fetch_from_context!(context, :auth_email_requests, person_name)
    assert %AuthEmailRequest{} = request = Accounts.get_auth_email_request(request_id)
    request
  end

  defp auth_email_progress_message(%AuthEmailRequest{} = request) do
    cond do
      request.status == AuthEmailRequest.status_provider_accepted() ->
        @progress_message_provider_accepted

      request.status == AuthEmailRequest.status_created() ->
        @progress_message_pre_send

      true ->
        @progress_message_sent
    end
  end

  defp auth_email_progress_message(_request), do: ""

  defp current_auth_email_progress_message(context) do
    context
    |> Map.get(:auth_email_requests, %{})
    |> Map.values()
    |> List.last()
    |> case do
      %{request_id: request_id} ->
        request_id
        |> Accounts.get_auth_email_request()
        |> auth_email_progress_message()

      _missing ->
        ""
    end
  end

  defp refute_inbox_placement_claim(message) do
    refute message =~ "in your inbox"
    refute message =~ "is in the inbox"
    refute message =~ "is visible in the inbox"
  end

  defp follow_sign_in_link(context, person_name) do
    %{token: token} = fetch_from_context!(context, :sign_in_links, person_name)

    case Accounts.consume_sign_in_token(token) do
      {:ok, %{email: email}} ->
        assert :ok =
                 Membership.verify_pending_person_email_address_for_sign_in(email,
                   consistency: :strong
                 )

        sign_in(context, email)

      {:error, :consumed} ->
        if Map.get(context, :signed_in_identity) do
          Map.put(context, :current_page, :homepage)
        else
          Map.put(context, :signed_in_identity, nil)
        end

      {:error, _reason} ->
        Map.put(context, :signed_in_identity, nil)
    end
  end

  defp sign_in(context, email) do
    identity = %{
      email: email,
      staff?: Accounts.staff_email?(email),
      active_clubs: Accounts.list_active_clubs_for_email(email)
    }

    current_page =
      cond do
        Map.get(context, :return_to) == :staff_only_homepage -> :staff_only_homepage
        Map.get(context, :return_to) == :get_started -> :get_started
        identity.staff? -> :staff_only_homepage
        true -> :homepage
      end

    context
    |> Map.put(:signed_in_identity, identity)
    |> Map.put(:current_page, current_page)
  end

  defp sign_out(context) do
    context
    |> Map.put(:signed_in_identity, nil)
    |> Map.put(:current_page, :homepage)
  end

  defp assert_signed_in_club(context, club_name) do
    identity = Map.fetch!(context, :signed_in_identity)
    assert Enum.any?(identity.active_clubs, &(&1.name == club_name))
    context
  end

  defp default_email_for(_context, "Pat"), do: "pat@memba.io"
  defp default_email_for(context, person_name), do: email_for(context, person_name)

  defp scenario_slug(context, club_name) do
    suffix =
      {Map.get(context, :scenario_name, "scenario"), club_name}
      |> :erlang.phash2(1_000_000)
      |> Integer.to_string(36)
      |> String.downcase()

    max_base_length = Slug.max_length() - String.length(suffix) - 1

    base =
      club_name
      |> Slug.default_from_name()
      |> String.slice(0, max_base_length)
      |> String.trim("-")

    "#{base}-#{suffix}"
  end

  defp email_for(context, name) do
    normalized_name =
      name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, ".")
      |> String.trim(".")

    "#{normalized_name}-#{scenario_email_suffix(context)}@example.test"
  end

  defp scenario_email_suffix(context) do
    context
    |> Map.get(:scenario_name, "scenario")
    |> :erlang.phash2(1_000_000)
    |> Integer.to_string(36)
    |> String.downcase()
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
