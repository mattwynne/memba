defmodule Memba.Cucumber.RequestAccountSteps do
  use Cucumber.StepDefinition

  import Ecto.Query
  import ExUnit.Assertions

  alias Memba.Accounts
  alias Memba.Membership
  alias Memba.Onboarding
  alias Memba.Onboarding.Request
  alias Memba.Repo

  step "{word} is signed in", %{args: [person_name]} = context do
    person = ensure_person(context, person_name)

    context
    |> put_person(person_name, person)
    |> Map.put(:signed_in_identity, %{
      email: Accounts.normalize_email(person.email),
      staff?: Accounts.staff_email?(person.email),
      active_clubs: Accounts.list_active_clubs_for_email(person.email)
    })
  end

  step "{word} is a person in Memba", %{args: [person_name]} = context do
    person = ensure_person(context, person_name)
    put_person(context, person_name, person)
  end

  step "{word} is signed in as verified email {string}",
       %{args: [person_name, email]} = context do
    sign_in_as_verified_email(context, person_name, email)
  end

  step "{word} has submitted a verified request for {word} {word} {word} with email {string}",
       %{args: [person_name, club_word_1, club_word_2, club_word_3, email]} = context do
    club_name = Enum.join([club_word_1, club_word_2, club_word_3], " ")

    context
    |> sign_in_as_verified_email(person_name, email)
    |> request_access(person_name, club_name, requester_name: "#{person_name} Example")
  end

  step "{word} has requested Memba access for {word} {word} {word}",
       %{args: [person_name, club_word_1, club_word_2, club_word_3]} = context do
    create_request_directly(
      context,
      person_name,
      Enum.join([club_word_1, club_word_2, club_word_3], " ")
    )
  end

  step "{word} has requested Memba access for {word} {word}",
       %{args: [person_name, club_word_1, club_word_2]} = context do
    create_request_directly(context, person_name, Enum.join([club_word_1, club_word_2], " "))
  end

  step "{word} requests Memba access for {word} {word} {word} with a short note",
       %{args: [person_name, club_word_1, club_word_2, club_word_3]} = context do
    request_access(context, person_name, Enum.join([club_word_1, club_word_2, club_word_3], " "))
  end

  step "{word} starts requesting Memba access with email {string}",
       %{args: [person_name, email]} = context do
    email = Accounts.normalize_email(email)

    assert {:ok, %{email: ^email, token: token}} = Accounts.create_sign_in_token(email)

    context
    |> put_verified_requester_email(person_name, email)
    |> update_context_map(:sign_in_links, person_name, %{email: email, token: token})
    |> Map.put(:return_to, :get_started)
  end

  step "{word} requests Memba access for {word} {word} {word} with name {string} and a short note",
       %{args: [person_name, club_word_1, club_word_2, club_word_3, requester_name]} = context do
    request_access(
      context,
      person_name,
      Enum.join([club_word_1, club_word_2, club_word_3], " "),
      requester_name: requester_name
    )
  end

  step "{word} requests Memba access for {word} {word} {word} {word} with a short note",
       %{args: [person_name, club_word_1, club_word_2, club_word_3, club_word_4]} = context do
    request_access(
      context,
      person_name,
      Enum.join([club_word_1, club_word_2, club_word_3, club_word_4], " ")
    )
  end

  step "{word} opens the get-started page", context do
    Map.put(context, :current_page, :get_started)
  end

  step "{word} opens the active requests inbox", context do
    Map.put(context, :current_page, :active_requests_inbox)
  end

  step "{word} changes the club slug to {string} and converts the request",
       %{args: [_staff_name, slug]} = context do
    request = fetch_last_request!(context, "West Coast Paddlers")
    convert_request(context, request, %{name: request.requested_club_name, slug: slug})
  end

  step "{word} converts {word}'s {word} {word} {word} request",
       %{args: [_staff_name, person_name, club_word_1, club_word_2, club_word_3]} = context do
    club_name = Enum.join([club_word_1, club_word_2, club_word_3], " ")
    request = fetch_request!(context, person_name, club_name)
    convert_request(context, request, %{name: club_name, slug: slug_for(club_name)})
  end

  step ~r/^(\w+) converts (\w+)'s (\w+) (\w+) (\w+) request with slug "([^"]+)"$/,
       %{args: [_staff_name, person_name, club_word_1, club_word_2, club_word_3, slug]} =
         context do
    club_name = Enum.join([club_word_1, club_word_2, club_word_3], " ")
    request = fetch_request!(context, person_name, club_name)
    convert_request(context, request, %{name: club_name, slug: slug})
  end

  step "{word} rejects {word}'s {word} {word} {word} request with the internal note {string}",
       %{args: [staff_name, person_name, club_word_1, club_word_2, club_word_3, internal_note]} =
         context do
    club_name = Enum.join([club_word_1, club_word_2, club_word_3], " ")
    request = fetch_request!(context, person_name, club_name)
    staff_email = staff_email_for(staff_name)

    assert {:ok, %Request{status: "rejected"} = rejected_request} =
             Onboarding.reject_request(
               request.request_id,
               %{internal_rejection_notes: internal_note},
               staff_email: staff_email
             )

    context
    |> put_request(person_name, club_name, rejected_request)
    |> Map.put(:last_onboarding_request_club_name, club_name)
  end

  step "{word} follows the staff notification link for {word}'s request",
       %{args: [_staff_name, person_name]} = context do
    request = fetch_last_request_for_person!(context, person_name)

    context
    |> Map.put(:current_page, :convert_request)
    |> Map.put(:converting_request_id, request.request_id)
  end

  step "{word} follows the welcome sign-in link", %{args: [person_name]} = context do
    email =
      Map.get(context, :welcome_emails, %{}) |> Map.get(person_name) ||
        welcome_email_for!(context, person_name)

    token = sign_in_token_from_email!(email)

    assert {:ok, %{email: email_address}} = Accounts.consume_sign_in_token(token)

    identity = %{
      email: email_address,
      staff?: Accounts.staff_email?(email_address),
      active_clubs: Accounts.list_active_clubs_for_email(email_address)
    }

    context
    |> Map.put(:signed_in_identity, identity)
    |> Map.put(:current_page, :club_home)
  end

  step "{word} should see that Memba will review the request", context do
    assert Map.get(context, :last_request_result) == :created
    context
  end

  step "Memba staff should be notified about {word}'s request",
       %{args: [person_name]} = context do
    assert_staff_notified(context, person_name)
  end

  step "Memba staff should be notified about Robin's request", context do
    assert_staff_notified(context, "Robin")
  end

  step "Memba staff should not be notified about {word}'s request yet",
       %{args: [_person_name]} = context do
    refute_received {:email, %Swoosh.Email{subject: <<"New Memba request: ", _rest::binary>>}}

    context
  end

  step "Memba staff should not be notified about Robin's request yet", context do
    refute_received {:email, %Swoosh.Email{subject: <<"New Memba request: ", _rest::binary>>}}

    context
  end

  step "{word} should be completing a verified request as {string}",
       %{args: [_person_name, expected_email]} = context do
    expected_email = Accounts.normalize_email(expected_email)

    assert Map.get(context, :current_page) == :get_started
    assert get_in(context, [:signed_in_identity, :email]) == expected_email
    refute Membership.get_person_by_email(expected_email)

    context
  end

  step "{word} {word} {word} should not exist as a club yet",
       %{args: [word_1, word_2, word_3]} = context do
    assert_club_absent(context, Enum.join([word_1, word_2, word_3], " "))
  end

  step "{word} {word} {word} should not exist as a club",
       %{args: [word_1, word_2, word_3]} = context do
    assert_club_absent(context, Enum.join([word_1, word_2, word_3], " "))
  end

  step "{word} should not be able to sign in to {word} {word} {word} yet",
       %{args: [person_name, club_word_1, club_word_2, club_word_3]} = context do
    assert_cannot_sign_in_to_club(
      context,
      person_name,
      Enum.join([club_word_1, club_word_2, club_word_3], " ")
    )
  end

  step "Robin should not be able to sign in to Suspicious Sender Club", context do
    assert_cannot_sign_in_to_club(context, "Robin", "Suspicious Sender Club")
  end

  step "{word} should see their known name and email address as read-only request details",
       %{args: [person_name]} = context do
    assert Map.get(context, :current_page) == :get_started
    assert %{name: ^person_name, email: email} = fetch_person_from_context!(context, person_name)
    assert is_binary(email)
    context
  end

  step "Memba should record {word}'s request with {word}'s known name and email address",
       %{args: [requester_name, details_person_name]} = context do
    request = fetch_last_request_for_person!(context, requester_name)
    person = fetch_person_from_context!(context, details_person_name)

    assert request.requester_name == person.name
    assert request.requester_email == person.email
    assert request.requester_person_id == person.person_id

    context
  end

  step "Memba should record {word}'s request with verified email {string}",
       %{args: [person_name, expected_email]} = context do
    expected_email = Accounts.normalize_email(expected_email)
    request = fetch_last_request_for_person!(context, person_name)

    assert request.requester_email == expected_email
    assert request.normalized_requester_email == expected_email
    refute request.requester_person_id

    context
  end

  step "Memba should record Robin's request with verified email {string}",
       %{args: [expected_email]} = context do
    expected_email = Accounts.normalize_email(expected_email)
    request = fetch_last_request_for_person!(context, "Robin")

    assert request.requester_email == expected_email
    assert request.normalized_requester_email == expected_email
    refute request.requester_person_id

    context
  end

  step "{word}'s request should not appear in the active requests inbox",
       %{args: [person_name]} = context do
    person_request_ids =
      context
      |> Map.get(:onboarding_requests, %{})
      |> Enum.flat_map(fn
        {{^person_name, _club_name}, request} -> [request.request_id]
        _entry -> []
      end)

    active_request_ids = Enum.map(Onboarding.list_active_requests(), & &1.request_id)

    assert Enum.empty?(person_request_ids)
    assert Enum.all?(person_request_ids, &(&1 not in active_request_ids))

    context
  end

  step "Robin's request should not appear in the active requests inbox", context do
    person_request_ids =
      context
      |> Map.get(:onboarding_requests, %{})
      |> Enum.flat_map(fn
        {{"Robin", _club_name}, request} -> [request.request_id]
        _entry -> []
      end)

    active_request_ids = Enum.map(Onboarding.list_active_requests(), & &1.request_id)

    assert Enum.empty?(person_request_ids)
    assert Enum.all?(person_request_ids, &(&1 not in active_request_ids))

    context
  end

  step "{word} should not be a person in Memba", %{args: [person_name]} = context do
    email = email_for_person_context(context, person_name)

    refute Membership.get_person_by_email(email)

    context
  end

  step "{word} should see {word}'s {word} {word} {word} request",
       %{args: [_staff_name, requester_name, club_word_1, club_word_2, club_word_3]} = context do
    assert Map.get(context, :current_page) == :active_requests_inbox

    request =
      fetch_request!(
        context,
        requester_name,
        Enum.join([club_word_1, club_word_2, club_word_3], " ")
      )

    assert request.status == "active"
    context
  end

  step "{word} should see the suggested club slug {string}",
       %{args: [_staff_name, expected_slug]} = context do
    request = fetch_last_request!(context, "West Coast Paddlers")
    assert slug_for(request.requested_club_name) == expected_slug
    context
  end

  step "{word} should be preparing to convert {word}'s {word} {word} {word} request",
       %{args: [_staff_name, person_name, club_word_1, club_word_2, club_word_3]} = context do
    request =
      fetch_request!(
        context,
        person_name,
        Enum.join([club_word_1, club_word_2, club_word_3], " ")
      )

    assert Map.get(context, :current_page) == :convert_request
    assert Map.get(context, :converting_request_id) == request.request_id
    context
  end

  step "{word} {word} {word} should exist with the slug {string}",
       %{args: [club_word_1, club_word_2, club_word_3, expected_slug]} = context do
    assert_club_present(
      context,
      Enum.join([club_word_1, club_word_2, club_word_3], " "),
      expected_slug
    )
  end

  step "{word} {word} {word} should exist as a club",
       %{args: [club_word_1, club_word_2, club_word_3]} = context do
    assert_club_present(context, Enum.join([club_word_1, club_word_2, club_word_3], " "))
  end

  step "{word} should be an active member of {word} {word} {word}",
       %{args: [person_name, club_word_1, club_word_2, club_word_3]} = context do
    club_name = Enum.join([club_word_1, club_word_2, club_word_3], " ")
    club = fetch_club_by_name!(club_name)
    person = fetch_person_from_context!(context, person_name)

    assert Membership.active_member_of_club?(club.club_id, person.person_id)
    context
  end

  step "{word} should be a person in Memba", %{args: [person_name]} = context do
    email = email_for_person_context(context, person_name)
    person = Membership.get_person_by_email(email)

    assert person

    put_person(context, person_name, person)
  end

  step "{word}'s request should leave the active requests inbox",
       %{args: [person_name]} = context do
    club_name = Map.fetch!(context, :last_onboarding_request_club_name)
    request = fetch_request!(context, person_name, club_name)
    assert request.status in ["converted", "rejected"]
    refute request.request_id in Enum.map(Onboarding.list_active_requests(), & &1.request_id)
    context
  end

  step "Memba should not create a duplicate person for {word}",
       %{args: [person_name]} = context do
    person = fetch_person_from_context!(context, person_name)

    count =
      Membership.Projections.Person
      |> where([person_projection], person_projection.person_id == ^person.person_id)
      |> Repo.aggregate(:count)

    assert count == 1
    context
  end

  step "{word} should not receive an email about the rejected request",
       %{args: [person_name]} = context do
    _person_name = person_name

    refute_received {:email, %Swoosh.Email{}}

    context
  end

  step "{word} should receive a welcome email for {word} {word} {word}",
       %{args: [person_name, club_word_1, club_word_2, club_word_3]} = context do
    club_name = Enum.join([club_word_1, club_word_2, club_word_3], " ")
    email = welcome_email_for!(context, person_name)

    assert email.subject == "Welcome to #{club_name} on Memba"
    assert email.text_body =~ "Welcome to #{club_name} on Memba"

    update_context_map(context, :welcome_emails, person_name, email)
  end

  step "{word} should be signed in to {word} {word} {word}",
       %{args: [_person_name, club_word_1, club_word_2, club_word_3]} = context do
    club_name = Enum.join([club_word_1, club_word_2, club_word_3], " ")
    identity = Map.fetch!(context, :signed_in_identity)

    assert Enum.any?(identity.active_clubs, &(&1.name == club_name))
    context
  end

  step "Memba should record Alice's request with Alice's known name and email address", context do
    request = fetch_last_request_for_person!(context, "Alice")
    person = fetch_person_from_context!(context, "Alice")

    assert request.requester_name == person.name
    assert request.requester_email == person.email
    assert request.requester_person_id == person.person_id

    context
  end

  step "Pat should see Robin's West Coast Paddlers request", context do
    assert Map.get(context, :current_page) == :active_requests_inbox
    request = fetch_request!(context, "Robin", "West Coast Paddlers")
    assert request.status == "active"
    context
  end

  step "Pat converts Alice's Nelson Trail Society request", context do
    request = fetch_request!(context, "Alice", "Nelson Trail Society")

    convert_request(context, request, %{
      name: "Nelson Trail Society",
      slug: slug_for("Nelson Trail Society")
    })
  end

  step "Pat converts Robin's West Coast Paddlers request", context do
    request = fetch_request!(context, "Robin", "West Coast Paddlers")

    convert_request(context, request, %{
      name: "West Coast Paddlers",
      slug: slug_for("West Coast Paddlers")
    })
  end

  step "Pat rejects Robin's Suspicious Sender Club request with the internal note {string}",
       %{args: [internal_note]} = context do
    request = fetch_request!(context, "Robin", "Suspicious Sender Club")

    assert {:ok, %Request{status: "rejected"} = rejected_request} =
             Onboarding.reject_request(
               request.request_id,
               %{internal_rejection_notes: internal_note},
               staff_email: staff_email_for("Pat")
             )

    context
    |> put_request("Robin", "Suspicious Sender Club", rejected_request)
    |> Map.put(:last_onboarding_request_club_name, "Suspicious Sender Club")
  end

  step "Robin's request should leave the active requests inbox", context do
    club_name = Map.fetch!(context, :last_onboarding_request_club_name)
    request = fetch_request!(context, "Robin", club_name)
    assert request.status in ["converted", "rejected"]
    refute request.request_id in Enum.map(Onboarding.list_active_requests(), & &1.request_id)
    context
  end

  step "Pat follows the staff notification link for Robin's request", context do
    request = fetch_last_request_for_person!(context, "Robin")

    context
    |> Map.put(:current_page, :convert_request)
    |> Map.put(:converting_request_id, request.request_id)
  end

  step "Pat should be preparing to convert Robin's West Coast Paddlers request", context do
    request = fetch_request!(context, "Robin", "West Coast Paddlers")
    assert Map.get(context, :current_page) == :convert_request
    assert Map.get(context, :converting_request_id) == request.request_id
    context
  end

  defp ensure_auth_email_config do
    unless Application.get_env(:memba, Memba.Accounts.AuthEmail) do
      Application.put_env(:memba, Memba.Accounts.AuthEmail,
        from: "auth@mail.memba.test",
        message_stream: "test-auth"
      )
    end
  end

  defp assert_staff_notified(context, person_name) do
    request = fetch_last_request_for_person!(context, person_name)

    assert_received {:email, %Swoosh.Email{} = email}
    assert email.subject == "New Memba request: #{request.requested_club_name}"
    assert email.text_body =~ "Request ID: #{request.request_id}"
    assert email.text_body =~ request.requester_name

    context
  end

  defp request_access(context, person_name, club_name, opts \\ []) do
    {attrs, request_opts} = request_attrs_and_opts(context, person_name, club_name, opts)

    assert {:ok, %Request{} = request} = Onboarding.create_request(attrs, request_opts)
    assert :ok = Memba.Onboarding.NewRequestEmail.deliver(request)

    context
    |> put_request(person_name, club_name, request)
    |> Map.put(:last_request_result, :created)
    |> Map.put(:last_onboarding_request_club_name, club_name)
  end

  defp create_request_directly(context, person_name, club_name) do
    {attrs, opts} = request_attrs_and_opts(context, person_name, club_name)

    assert {:ok, %Request{} = request} = Onboarding.create_request(attrs, opts)

    context
    |> put_request(person_name, club_name, request)
    |> Map.put(:last_onboarding_request_club_name, club_name)
  end

  defp request_attrs_and_opts(context, person_name, club_name, opts \\ []) do
    case get_in(context, [:people, person_name]) do
      %{person_id: person_id, name: name, email: email} ->
        {%{
           requester_name: name,
           requester_email: email,
           requested_club_name: club_name,
           note: short_note()
         }, [verified_identity_email: email, requester_person_id: person_id]}

      _missing ->
        requester_email = default_email_for(context, person_name)
        requester_name = Keyword.get(opts, :requester_name, "#{person_name} Requester")

        verified_email =
          get_in(context, [:verified_requester_emails, person_name]) || requester_email

        {%{
           requester_name: requester_name,
           requester_email: requester_email,
           requested_club_name: club_name,
           note: short_note()
         }, [verified_identity_email: verified_email]}
    end
  end

  defp convert_request(context, %Request{} = request, club_attrs) do
    staff_email = get_in(context, [:signed_in_identity, :email]) || staff_email_for("Pat")

    ensure_auth_email_config()

    assert {:ok, conversion} =
             Onboarding.convert_request_to_club(request.request_id, club_attrs,
               staff_email: staff_email
             )

    assert conversion.welcome_email == :ok

    converted_request = conversion.request

    context
    |> put_request_person_from_conversion(request, conversion)
    |> put_request(
      requester_key_from_request(request),
      request.requested_club_name,
      converted_request
    )
    |> put_club(request.requested_club_name, conversion.club)
    |> Map.put(:last_conversion, conversion)
    |> Map.put(:last_onboarding_request_club_name, request.requested_club_name)
  end

  defp put_request_person_from_conversion(context, %Request{} = request, conversion) do
    put_person(context, requester_key_from_request(request), %{
      person_id: conversion.person.person_id,
      name: conversion.person.name,
      email: conversion.person.email
    })
  end

  defp ensure_person(context, person_name) do
    case get_in(context, [:people, person_name]) do
      %{person_id: _person_id} = person ->
        person

      _missing ->
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

        %{person_id: person_id, name: person_name, email: email}
    end
  end

  defp assert_club_absent(context, club_name) do
    refute get_in(context, [:clubs, club_name])
    refute fetch_club_by_name(club_name)
    context
  end

  defp assert_club_present(context, club_name, expected_slug \\ nil) do
    club = fetch_club_by_name!(club_name)

    if expected_slug do
      assert club.slug == expected_slug
    end

    context
  end

  defp assert_cannot_sign_in_to_club(context, person_name, club_name) do
    email =
      context
      |> get_in([:people, person_name, :email])
      |> case do
        nil -> default_email_for(context, person_name)
        email -> email
      end

    active_clubs = Accounts.list_active_clubs_for_email(email)

    refute Enum.any?(active_clubs, &(&1.name == club_name))
    context
  end

  defp fetch_last_request!(context, club_name) do
    requests = Map.get(context, :onboarding_requests, %{})

    requests
    |> Enum.find_value(fn
      {{_person_name, ^club_name}, request} -> request
      _entry -> nil
    end)
    |> case do
      nil -> flunk("Expected a request for #{club_name}")
      request -> Repo.get!(Request, request.request_id)
    end
  end

  defp fetch_request!(context, person_name, club_name) do
    context
    |> get_in([:onboarding_requests, {person_name, club_name}])
    |> case do
      nil -> flunk("Expected #{person_name}'s request for #{club_name}")
      request -> Repo.get!(Request, request.request_id)
    end
  end

  defp fetch_last_request_for_person!(context, person_name) do
    requests = Map.get(context, :onboarding_requests, %{})

    requests
    |> Enum.find_value(fn
      {{^person_name, _club_name}, request} -> request
      _entry -> nil
    end)
    |> case do
      nil -> flunk("Expected a request from #{person_name}")
      request -> Repo.get!(Request, request.request_id)
    end
  end

  defp fetch_person_from_context!(context, person_name) do
    context
    |> get_in([:people, person_name])
    |> case do
      nil -> flunk("Expected #{person_name} to be known")
      person -> person
    end
  end

  defp fetch_club_by_name(club_name) do
    Membership.Projections.Club
    |> where([club], club.name == ^club_name)
    |> limit(1)
    |> Repo.one()
  end

  defp fetch_club_by_name!(club_name) do
    fetch_club_by_name(club_name) || flunk("Expected #{club_name} to exist as a club")
  end

  defp welcome_email_for!(context, person_name) do
    person = fetch_person_from_context!(context, person_name)

    assert_received {:email, %Swoosh.Email{} = email}

    if email.to == [{person.name, person.email}] and email.subject =~ "Welcome to" do
      email
    else
      flunk("Expected welcome email to #{person.name} <#{person.email}>, got #{inspect(email)}")
    end
  end

  defp sign_in_token_from_email!(%Swoosh.Email{text_body: body}) do
    case Regex.run(~r{/auth/sign-in/([^?\s]+)}, body) do
      [_match, token] -> token
      nil -> flunk("Expected welcome email to include a sign-in token link")
    end
  end

  defp put_request(context, person_name, club_name, %Request{} = request) do
    update_context_map(context, :onboarding_requests, {person_name, club_name}, request)
  end

  defp put_person(context, person_name, person) do
    update_context_map(context, :people, person_name, %{
      person_id: person.person_id,
      name: person.name,
      email: person.email
    })
  end

  defp put_club(context, club_name, club) do
    update_context_map(context, :clubs, club_name, club.club_id)
  end

  defp put_verified_requester_email(context, person_name, email) do
    update_context_map(context, :verified_requester_emails, person_name, email)
  end

  defp update_context_map(context, collection_key, item_key, value) do
    collection =
      context
      |> Map.get(collection_key, %{})
      |> Map.put(item_key, value)

    Map.put(context, collection_key, collection)
  end

  defp sign_in_as_verified_email(context, person_name, email) do
    email = Accounts.normalize_email(email)

    context
    |> put_verified_requester_email(person_name, email)
    |> Map.put(:signed_in_identity, %{
      email: email,
      staff?: Accounts.staff_email?(email),
      active_clubs: Accounts.list_active_clubs_for_email(email)
    })
  end

  defp email_for_person_context(context, person_name) do
    context
    |> get_in([:people, person_name, :email])
    |> case do
      nil ->
        get_in(context, [:verified_requester_emails, person_name]) ||
          default_email_for(context, person_name)

      email ->
        email
    end
  end

  defp requester_key_from_request(%Request{} = request) do
    request.requester_name
    |> String.split(" ", parts: 2)
    |> hd()
  end

  defp slug_for(club_name), do: Memba.Membership.Slug.default_from_name(club_name)
  defp staff_email_for(person_name), do: "#{String.downcase(person_name)}@memba.io"
  defp short_note, do: "We want a safer way to message members."

  defp default_email_for(context, person_name) do
    normalized_name =
      person_name
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
end
