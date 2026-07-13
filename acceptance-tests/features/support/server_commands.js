const os = require("node:os");
const { spawnSync } = require("node:child_process");

const defaultServerNodeName = "memba_acceptance_server";
const defaultCookie = "memba_acceptance_cookie";

function ensureClub({ clubName, clubSlug }) {
  return runCommand(
    `
club_name = Map.fetch!(payload, "clubName")
club_slug = Map.fetch!(payload, "clubSlug")

club =
  case Memba.Membership.get_club_by_slug(club_slug) do
    nil ->
      club_id = Memba.ID.generate(:club)
      :ok = Memba.Membership.create_club(
        %{club_id: club_id, name: club_name, slug: club_slug},
        consistency: :strong
      )
      Memba.Membership.get_club_by_slug(club_slug)

    club ->
      club
  end

%{clubId: club.club_id, clubName: club.name, clubSlug: club.slug}
`,
    { clubName, clubSlug }
  );
}

function ensurePerson({ personName, email }) {
  return runCommand(
    `
person_name = Map.fetch!(payload, "personName")
email = Map.fetch!(payload, "email")

person =
  case Memba.Membership.get_person_by_email(email) do
    nil ->
      person_id = Memba.ID.generate(:person)
      :ok = Memba.Membership.create_person(
        %{person_id: person_id, name: person_name, email: email},
        consistency: :strong
      )
      Memba.Membership.get_person_by_email(email)

    person ->
      person
  end

%{personId: person.person_id, personName: person.name, email: email}
`,
    { personName, email }
  );
}

function ensureMember({ clubName, clubSlug, personName, email }) {
  return runCommand(
    `
club_name = Map.fetch!(payload, "clubName")
club_slug = Map.fetch!(payload, "clubSlug")
person_name = Map.fetch!(payload, "personName")
email = Map.fetch!(payload, "email")

club =
  case Memba.Membership.get_club_by_slug(club_slug) do
    nil ->
      club_id = Memba.ID.generate(:club)
      :ok = Memba.Membership.create_club(
        %{club_id: club_id, name: club_name, slug: club_slug},
        consistency: :strong
      )
      Memba.Membership.get_club_by_slug(club_slug)

    club ->
      club
  end

person =
  case Memba.Membership.get_person_by_email(email) do
    nil ->
      person_id = Memba.ID.generate(:person)
      :ok = Memba.Membership.create_person(
        %{person_id: person_id, name: person_name, email: email},
        consistency: :strong
      )
      Memba.Membership.get_person_by_email(email)

    person ->
      person
  end

membership =
  Memba.Repo.get_by(Memba.Membership.Projections.Membership,
    club_id: club.club_id,
    person_id: person.person_id,
    active: true
  )

membership_id =
  case membership do
    nil ->
      membership_id = Memba.ID.generate(:membership)
      :ok = Memba.Membership.add_member(
        %{membership_id: membership_id, club_id: club.club_id, person_id: person.person_id},
        consistency: :strong
      )
      membership_id

    %{membership_id: membership_id} ->
      membership_id
  end

%{rows: [[membership_projector_checkpoint]]} =
  Memba.Repo.query!(
    "SELECT COALESCE(MAX(last_seen_event_number), 0) FROM projection_versions WHERE projection_name = 'Memba.Membership.Projectors.Membership'",
    []
  )

%{
  clubId: club.club_id,
  clubName: club.name,
  clubSlug: club.slug,
  personId: person.person_id,
  personName: person.name,
  email: email,
  membershipId: membership_id,
  membershipProjectorCheckpoint: membership_projector_checkpoint
}
`,
    { clubName, clubSlug, personName, email }
  );
}

function ensureMembers(members) {
  return runCommand(
    `
ensure_club = fn club_name, club_slug ->
  case Memba.Membership.get_club_by_slug(club_slug) do
    nil ->
      club_id = Memba.ID.generate(:club)
      :ok = Memba.Membership.create_club(
        %{club_id: club_id, name: club_name, slug: club_slug},
        consistency: :strong
      )
      Memba.Membership.get_club_by_slug(club_slug)

    club ->
      if club.name == club_name do
        club
      else
        :ok = Memba.Membership.update_club(
          %{club_id: club.club_id, name: club_name, slug: club_slug},
          consistency: :strong
        )
        Memba.Membership.get_club_by_slug(club_slug)
      end
  end
end

ensure_person = fn person_name, email ->
  case Memba.Membership.get_person_by_email(email) do
    nil ->
      person_id = Memba.ID.generate(:person)
      :ok = Memba.Membership.create_person(
        %{person_id: person_id, name: person_name, email: email},
        consistency: :strong
      )
      Memba.Membership.get_person_by_email(email)

    person ->
      person
  end
end

ensure_member = fn member ->
  club_name = Map.fetch!(member, "clubName")
  club_slug = Map.fetch!(member, "clubSlug")
  person_name = Map.fetch!(member, "personName")
  email = Map.fetch!(member, "email")

  club = ensure_club.(club_name, club_slug)
  person = ensure_person.(person_name, email)

  membership =
    Memba.Repo.get_by(Memba.Membership.Projections.Membership,
      club_id: club.club_id,
      person_id: person.person_id,
      active: true
    )

  membership_id =
    case membership do
      nil ->
        membership_id = Memba.ID.generate(:membership)
        :ok = Memba.Membership.add_member(
          %{membership_id: membership_id, club_id: club.club_id, person_id: person.person_id},
          consistency: :strong
        )
        membership_id

      %{membership_id: membership_id} ->
        membership_id
    end

  %{
    clubId: club.club_id,
    clubName: club.name,
    clubSlug: club.slug,
    personId: person.person_id,
    personName: person.name,
    email: email,
    membershipId: membership_id
  }
end

results = Map.fetch!(payload, "members") |> Enum.map(ensure_member)

%{rows: [[membership_projector_checkpoint]]} =
  Memba.Repo.query!(
    "SELECT COALESCE(MAX(last_seen_event_number), 0) FROM projection_versions WHERE projection_name = 'Memba.Membership.Projectors.Membership'",
    []
  )

Enum.map(results, &Map.put(&1, "membershipProjectorCheckpoint", membership_projector_checkpoint))
`,
    { members }
  );
}

function ensureMemberRoles({ clubId, membershipId, personId, roleNames }) {
  return runCommand(
    `
club_id = Map.fetch!(payload, "clubId")
membership_id = Map.fetch!(payload, "membershipId")
person_id = Map.fetch!(payload, "personId")
role_names = Map.fetch!(payload, "roleNames")

role_key = fn role_name ->
  role_name
  |> String.downcase()
  |> String.replace(~r/[^a-z0-9]+/u, "-")
  |> String.trim("-")
end

ensure_role = fn role_name ->
  key = role_key.(role_name)

  case Memba.Repo.get_by(Memba.Membership.Projections.Role, club_id: club_id, role_key: key) do
    nil ->
      role_id = Memba.ID.deterministic(:role, ["acceptance-list-members", club_id, key])

      :ok =
        Memba.Membership.App.dispatch(
          %Memba.Membership.Commands.DefineClubRole{
            club_id: club_id,
            role_id: role_id,
            role_key: key,
            name: role_name
          },
          consistency: :strong
        )

      Memba.Repo.get!(Memba.Membership.Projections.Role, role_id)

    role ->
      role
  end
end

ensure_assignment = fn role ->
  active_assignment =
    Memba.Repo.get_by(Memba.Membership.Projections.RoleAssignment,
      club_id: club_id,
      membership_id: membership_id,
      person_id: person_id,
      role_id: role.role_id,
      active: true
    )

  if is_nil(active_assignment) do
    :ok =
      Memba.Membership.App.dispatch(
        %Memba.Membership.Commands.AssignMemberRole{
          club_id: club_id,
          membership_id: membership_id,
          person_id: person_id,
          role_id: role.role_id
        },
        consistency: :strong
      )
  end

  %{roleId: role.role_id, roleName: role.name}
end

role_names
|> Enum.map(ensure_role)
|> Enum.map(ensure_assignment)
`,
    { clubId, membershipId, personId, roleNames }
  );
}

function ensurePeople(people) {
  return runCommand(
    `
ensure_person = fn person ->
  person_name = Map.fetch!(person, "personName")
  email = Map.fetch!(person, "email")

  person =
    case Memba.Membership.get_person_by_email(email) do
      nil ->
        person_id = Memba.ID.generate(:person)
        :ok = Memba.Membership.create_person(
          %{person_id: person_id, name: person_name, email: email},
          consistency: :strong
        )
        Memba.Membership.get_person_by_email(email)

      person ->
        person
    end

  %{personId: person.person_id, personName: person.name, email: email}
end

Map.fetch!(payload, "people") |> Enum.map(ensure_person)
`,
    { people }
  );
}

function ensureClubSlug({ clubId, clubName, clubSlug }) {
  return runCommand(
    `
club_name = Map.fetch!(payload, "clubName")
club_slug = Map.fetch!(payload, "clubSlug")
club_id = Map.get(payload, "clubId")
existing_club = if club_id, do: Memba.Membership.get_club(club_id), else: Memba.Membership.get_club_by_slug(club_slug)

club =
  cond do
    existing_club && existing_club.name == club_name && existing_club.slug == club_slug ->
      existing_club

    existing_club ->
      :ok = Memba.Membership.update_club(
        %{club_id: existing_club.club_id, name: club_name, slug: club_slug},
        consistency: :strong
      )
      Memba.Membership.get_club(existing_club.club_id)

    true ->
      club_id = Memba.ID.generate(:club)
      :ok = Memba.Membership.create_club(
        %{club_id: club_id, name: club_name, slug: club_slug},
        consistency: :strong
      )
      Memba.Membership.get_club(club_id)
  end

%{clubId: club.club_id, clubName: club.name, clubSlug: club.slug}
`,
    { clubId, clubName, clubSlug }
  );
}

function ensurePersonEmailAddresses({ personId, personName, emailAddresses }) {
  return runCommand(
    `
person_name = Map.fetch!(payload, "personName")
person_id = Map.get(payload, "personId")
email_addresses =
  Map.fetch!(payload, "emailAddresses")
  |> Enum.map(fn email_address ->
    %{
      "email" => Map.fetch!(email_address, "email"),
      "is_primary" => Map.get(email_address, "isPrimary", Map.get(email_address, "is_primary", false))
    }
  end)

primary_email_address = Enum.find(email_addresses, &Map.fetch!(&1, "is_primary"))
primary_email = Map.fetch!(primary_email_address, "email")
existing_person = if person_id, do: Memba.Membership.get_person(person_id), else: Memba.Membership.get_person_by_email(primary_email)

same_email? = fn left, right ->
  String.downcase(String.trim(left)) == String.downcase(String.trim(right))
end

ensure_desired_addresses_are_verified = fn person_id ->
  current_email_addresses = Memba.Membership.list_person_email_addresses(person_id)

  Enum.each(email_addresses, fn %{"email" => email} ->
    unless Enum.any?(current_email_addresses, &same_email?.(&1.email, email)) do
      :ok = Memba.Membership.add_person_email_address(
        %{person_id: person_id, email: email},
        consistency: :strong
      )

      :ok = Memba.Membership.verify_person_email_address(
        %{person_id: person_id, email: email},
        consistency: :strong
      )
    end
  end)
end

person =
  case existing_person do
    nil ->
      person_id = Memba.ID.generate(:person)
      :ok = Memba.Membership.create_person(
        %{person_id: person_id, name: person_name, email_addresses: email_addresses},
        consistency: :strong
      )
      Memba.Membership.get_person(person_id)

    person ->
      ensure_desired_addresses_are_verified.(person.person_id)

      :ok = Memba.Membership.replace_person_email_addresses(
        %{person_id: person.person_id, email_addresses: email_addresses},
        consistency: :strong
      )
      Memba.Membership.get_person(person.person_id)
  end

%{
  personId: person.person_id,
  personName: person.name,
  email: primary_email,
  emailAddresses: Memba.Membership.list_person_email_addresses(person.person_id)
}
`,
    { personId, personName, emailAddresses }
  );
}

function ensureSmokeTestClub({ clubName, clubSlug, personName, email }) {
  const [member] = ensureMembers([{ clubName, clubSlug, personName, email }]);
  return member;
}

function sendClubMessage({ clubId, senderId, senderName, subject, body, timeoutMs = 1000 }) {
  return runCommand(
    `
club_id = Map.fetch!(payload, "clubId")
sender_id = Map.fetch!(payload, "senderId")
sender_name = Map.fetch!(payload, "senderName")
subject = Map.fetch!(payload, "subject")
body = Map.fetch!(payload, "body")
timeout = Map.get(payload, "timeoutMs", 1000)
message_id = Memba.ID.generate(:message)

:ok = Memba.Messaging.send_club_message(
  %{message_id: message_id, club_id: club_id, sender_id: sender_id, subject: subject, body: body},
  consistency: :strong
)

Memba.ProjectionBarrier.await!(
  [
    Memba.Messaging.Projectors.EmailDelivery,
    Memba.Messaging.Projectors.MemberEmailDelivery,
    Memba.Messaging.Projectors.MembaStaffEmailDelivery
  ],
  timeout: timeout
)

%{
  messageId: message_id,
  clubId: club_id,
  senderId: sender_id,
  senderName: sender_name,
  subject: subject,
  body: body
}
`,
    { clubId, senderId, senderName, subject, body, timeoutMs }
  );
}

function listLocalDeliveryFacts() {
  return runCommand(
    `
Memba.Messaging.LocalDeliveryFacts.list()
`,
    {}
  );
}

function dispatchPendingEmailDeliveries() {
  return runCommand(
    `
Memba.Messaging.EmailDeliveryDispatcher.dispatch_pending_email_deliveries()
|> Enum.map(fn delivery ->
  %{
    deliveryId: delivery.delivery_id,
    status: delivery.status
  }
end)
`,
    {}
  );
}

function waitForProjectionBarrier({ projectors, timeoutMs = 1000, checkpoint = null }) {
  return runCommand(
    `
projectors = Map.fetch!(payload, "projectors")
timeout = Map.get(payload, "timeoutMs", 1000)
checkpoint = Map.get(payload, "checkpoint")
opts = if is_nil(checkpoint), do: [timeout: timeout], else: [timeout: timeout, checkpoint: checkpoint]

case Memba.ProjectionBarrier.await(projectors, opts) do
  {:ok, result} ->
    Map.put(result, :status, "satisfied")

  {:error, :timeout, result} ->
    raise "Projection barrier timed out waiting for #{inspect(projectors)} to reach checkpoint #{result.checkpoint}; positions: #{inspect(result.projectors)}"
end
`,
    { projectors, timeoutMs, checkpoint }
  );
}

function recordAuthEmailProviderAccepted({ requestId }) {
  return runCommand(
    `
request_id = Map.fetch!(payload, "requestId")

case Memba.Accounts.record_auth_email_provider_accepted(request_id, %{
       provider: "postmark",
       provider_event_id: "acceptance-#{request_id}",
       provider_event_type: "Delivered",
       provider_message_id: "acceptance-message-#{request_id}",
       provider_message_stream: "outbound-authentication"
     }) do
  {:ok, request} ->
    %{
      requestId: request.request_id,
      status: request.status,
      providerEventId: request.provider_event_id,
      providerEventType: request.provider_event_type
    }

  {:error, reason} ->
    raise "Could not record auth-email provider acceptance for #{request_id}: #{inspect(reason)}"
end
`,
    { requestId }
  );
}

function runCommand(code, payload = {}) {
  const serverNode = acceptanceServerNode();
  const cookie = process.env.ACCEPTANCE_SERVER_COOKIE || defaultCookie;
  const encodedPayload = Buffer.from(JSON.stringify(payload), "utf8").toString("base64");
  const wrappedCode = `
payload = ${JSON.stringify(encodedPayload)} |> Base.decode64!() |> Jason.decode!()
result = (fn payload ->
${code}
end).(payload)
result |> Jason.encode!() |> IO.write()
`;

  const deadline = Date.now() + Number(process.env.ACCEPTANCE_SERVER_COMMAND_CONNECT_TIMEOUT_MS || 5000);
  let result = null;

  do {
    result = spawnSync(
      "elixir",
      ["--hidden", "--sname", "undefined", "--cookie", cookie, "--rpc-eval", serverNode, wrappedCode],
      { encoding: "utf8", env: process.env }
    );

    if (result.status === 0 || !serverCommandConnectionFailed(result) || Date.now() >= deadline) {
      break;
    }

    sleepSync(100);
  } while (true);

  if (result.status !== 0) {
    throw new Error(
      `Acceptance server command failed with exit code ${result.status}.\n` +
        `Server node: ${serverNode}\n` +
        `STDOUT:\n${result.stdout || ""}\nSTDERR:\n${result.stderr || ""}`
    );
  }

  try {
    return JSON.parse(result.stdout);
  } catch (error) {
    throw new Error(`Acceptance server command returned invalid JSON: ${result.stdout}`, { cause: error });
  }
}

function serverCommandConnectionFailed(result) {
  return String(result && result.stderr).includes("RPC failed with reason :noconnection");
}

function sleepSync(ms) {
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);
}

function acceptanceServerNode() {
  const configured = process.env.ACCEPTANCE_SERVER_NODE || defaultServerNodeName;

  if (configured.includes("@")) {
    return configured;
  }

  return `${configured}@${shortHostname()}`;
}

function shortHostname() {
  return os.hostname().split(".")[0];
}

module.exports = {
  acceptanceServerNode,
  dispatchPendingEmailDeliveries,
  ensureClub,
  ensureClubSlug,
  ensureMember,
  ensureMembers,
  ensureMemberRoles,
  ensurePeople,
  ensurePerson,
  ensurePersonEmailAddresses,
  ensureSmokeTestClub,
  listLocalDeliveryFacts,
  recordAuthEmailProviderAccepted,
  runCommand,
  sendClubMessage,
  waitForProjectionBarrier
};
