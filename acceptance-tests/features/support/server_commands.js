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

%{
  clubId: club.club_id,
  clubName: club.name,
  clubSlug: club.slug,
  personId: person.person_id,
  personName: person.name,
  email: email,
  membershipId: membership_id
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

Map.fetch!(payload, "members") |> Enum.map(ensure_member)
`,
    { members }
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

  const result = spawnSync(
    "elixir",
    ["--hidden", "--sname", "undefined", "--cookie", cookie, "--rpc-eval", serverNode, wrappedCode],
    { encoding: "utf8", env: process.env }
  );

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
  ensureClub,
  ensureClubSlug,
  ensureMember,
  ensureMembers,
  ensurePeople,
  ensurePerson,
  ensurePersonEmailAddresses,
  ensureSmokeTestClub,
  runCommand
};
