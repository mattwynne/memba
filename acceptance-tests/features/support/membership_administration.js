const assert = require("node:assert/strict");
const { clubSlugFor, emailFor, ensureState } = require("./member_message");
const serverCommands = require("./server_commands");

function ensureMembershipAdministrator(world, personName, clubName) {
  const member = ensureMember(world, personName, clubName);

  const status = serverCommands.runCommand(
    `
import Ecto.Query

club_id = Map.fetch!(payload, "clubId")
membership_id = Map.fetch!(payload, "membershipId")
person_id = Map.fetch!(payload, "personId")
role_id = Memba.Membership.Roles.membership_administrator_role_id(club_id)

already_assigned? =
  Memba.Membership.Projections.RoleAssignment
  |> where([assignment],
    assignment.club_id == ^club_id and
      assignment.membership_id == ^membership_id and
      assignment.person_id == ^person_id and
      assignment.role_id == ^role_id and
      assignment.active == true
  )
  |> Memba.Repo.exists?()

unless already_assigned? do
  :ok =
    Memba.Membership.App.dispatch(
      %Memba.Membership.Commands.AssignMemberRole{
        club_id: club_id,
        membership_id: membership_id,
        person_id: person_id,
        role_id: role_id
      },
      consistency: :strong
    )
end

%{status: "ok"}
`,
    member
  );

  assert.equal(status.status, "ok");
  assertMembershipAdministrator(world, personName, clubName);
}

function ensureOnlyMembershipAdministrator(world, personName, clubName) {
  ensureMembershipAdministrator(world, personName, clubName);

  const count = membershipAdministratorCount(world, clubName);
  assert.equal(count, 1, `Expected ${personName} to be the only Admin of ${clubName}`);
}

function ensureOrdinaryMember(world, personName, clubName) {
  ensureMember(world, personName, clubName);
  assertNotMembershipAdministrator(world, personName, clubName);
}

function makeMembershipAdministrator(world, actorName, targetName, clubName) {
  const actor = memberStatus(world, actorName, clubName);
  const target = ensureMember(world, targetName, clubName);

  assert.ok(actor.personId, `Expected ${actorName} to be known in ${clubName}`);

  const result = membershipAdministratorCommand("assign", {
    actorPersonId: actor.personId,
    clubId: target.clubId,
    membershipId: target.membershipId,
    personId: target.personId
  });

  assert.deepEqual(result, { status: "ok" });
  world.lastMembershipAdministrationResult = result;
}

function tryMakeMembershipAdministrator(world, actorName, targetName, clubName) {
  const actor = memberStatus(world, actorName, clubName);
  const target = ensureMember(world, targetName, clubName);

  assert.ok(actor.personId, `Expected ${actorName} to be known in ${clubName}`);

  const result = membershipAdministratorCommand("assign", {
    actorPersonId: actor.personId,
    clubId: target.clubId,
    membershipId: target.membershipId,
    personId: target.personId
  });

  assert.deepEqual(result, { status: "error", reason: "unauthorized" });
  world.lastMembershipAdministrationResult = result;
}

function tryRemoveMembershipAdministrator(world, actorName, targetName, clubName) {
  const actor = memberStatus(world, actorName, clubName);
  const target = memberStatus(world, targetName, clubName);

  assert.ok(actor.personId, `Expected ${actorName} to be known in ${clubName}`);
  assert.ok(target.membershipId, `Expected ${targetName} to be an active member of ${clubName}`);

  const result = membershipAdministratorCommand("remove", {
    actorPersonId: actor.personId,
    clubId: target.clubId,
    membershipId: target.membershipId,
    personId: target.personId
  });

  assert.deepEqual(result, { status: "error", reason: "last_membership_administrator" });
  world.lastMembershipAdministrationResult = result;
}

function assertMembershipAdministrator(world, personName, clubName) {
  const status = memberStatus(world, personName, clubName);

  assert.equal(status.activeMember, true, `Expected ${personName} to be an active member of ${clubName}`);
  assert.equal(
    status.membershipAdministrator,
    true,
    `Expected ${personName} to be an Admin of ${clubName}`
  );

  rememberMember(world, {
    clubId: status.clubId,
    clubName,
    clubSlug: status.clubSlug,
    email: status.email,
    membershipId: status.membershipId,
    personId: status.personId,
    personName
  });
}

function assertNotMembershipAdministrator(world, personName, clubName) {
  const status = memberStatus(world, personName, clubName);

  assert.equal(
    status.membershipAdministrator,
    false,
    `Expected ${personName} not to be an Admin of ${clubName}`
  );
}

function ensureMember(world, personName, clubName) {
  ensureState(world);

  const member = serverCommands.ensureMember({
    clubName,
    clubSlug: clubSlugFor(clubName),
    personName,
    email: emailFor(personName)
  });

  rememberMember(world, member);
  return member;
}

function memberStatus(world, personName, clubName) {
  ensureState(world);

  const status = serverCommands.runCommand(
    `
import Ecto.Query

club_name = Map.fetch!(payload, "clubName")
email = Map.fetch!(payload, "email")

club =
  Memba.Membership.Projections.Club
  |> where([club], club.name == ^club_name)
  |> order_by([club], desc: club.inserted_at)
  |> limit(1)
  |> Memba.Repo.one()

person = Memba.Membership.get_person_by_email(email)

membership =
  if club && person do
    Memba.Membership.Projections.Membership
    |> where([membership],
      membership.club_id == ^club.club_id and
        membership.person_id == ^person.person_id and
        membership.active == true
    )
    |> limit(1)
    |> Memba.Repo.one()
  end

role_id =
  if club do
    Memba.Membership.Roles.membership_administrator_role_id(club.club_id)
  end

role_assignment? =
  if club && person && membership && role_id do
    Memba.Membership.Projections.RoleAssignment
    |> where([assignment],
      assignment.club_id == ^club.club_id and
        assignment.membership_id == ^membership.membership_id and
        assignment.person_id == ^person.person_id and
        assignment.role_id == ^role_id and
        assignment.active == true
    )
    |> Memba.Repo.exists?()
  else
    false
  end

permission? =
  if club && person do
    Memba.Membership.person_has_club_permission?(
      club.club_id,
      person.person_id,
      Memba.Membership.Permissions.club_manage_members()
    )
  else
    false
  end

%{
  activeMember: not is_nil(membership),
  clubId: if(club, do: club.club_id),
  clubSlug: if(club, do: club.slug),
  email: email,
  membershipAdministrator: role_assignment? && permission?,
  membershipId: if(membership, do: membership.membership_id),
  personId: if(person, do: person.person_id),
  personName: if(person, do: person.name)
}
`,
    { clubName, email: emailFor(personName) }
  );

  if (status.activeMember) {
    rememberMember(world, {
      clubId: status.clubId,
      clubName,
      clubSlug: status.clubSlug,
      email: status.email,
      membershipId: status.membershipId,
      personId: status.personId,
      personName: status.personName || personName
    });
  }

  return status;
}

function membershipAdministratorCount(world, clubName) {
  return serverCommands.runCommand(
    `
import Ecto.Query

club_name = Map.fetch!(payload, "clubName")

club =
  Memba.Membership.Projections.Club
  |> where([club], club.name == ^club_name)
  |> order_by([club], desc: club.inserted_at)
  |> limit(1)
  |> Memba.Repo.one()

count =
  if club do
    role_id = Memba.Membership.Roles.membership_administrator_role_id(club.club_id)

    Memba.Membership.Projections.RoleAssignment
    |> where([assignment], assignment.club_id == ^club.club_id)
    |> where([assignment], assignment.role_id == ^role_id)
    |> where([assignment], assignment.active == true)
    |> Memba.Repo.aggregate(:count, :membership_id)
  else
    0
  end

%{count: count}
`,
    { clubName }
  ).count;
}

function membershipAdministratorCommand(action, attrs) {
  const functionName =
    action === "assign"
      ? "assign_membership_administrator_as_club_member"
      : "remove_membership_administrator_as_club_member";

  return serverCommands.runCommand(
    `
function_name = Map.fetch!(payload, "functionName")

attrs = %{
  club_id: Map.fetch!(payload, "clubId"),
  membership_id: Map.fetch!(payload, "membershipId"),
  person_id: Map.fetch!(payload, "personId"),
  actor_person_id: Map.fetch!(payload, "actorPersonId")
}

result = apply(Memba.Membership, String.to_existing_atom(function_name), [attrs, [consistency: :strong]])

case result do
  :ok -> %{status: "ok"}
  {:error, reason} -> %{status: "error", reason: to_string(reason)}
end
`,
    { ...attrs, functionName }
  );
}

function rememberMember(world, member) {
  ensureState(world);

  world.clubs[member.clubName] = {
    clubId: member.clubId,
    name: member.clubName,
    slug: member.clubSlug
  };

  world.people[member.personName] = {
    alternateEmails: [],
    email: member.email,
    emailAddresses: [{ email: member.email, isPrimary: true }],
    name: member.personName,
    personId: member.personId,
    primaryEmail: member.email
  };

  world.memberships[`${member.clubName}:${member.personName}`] = {
    clubId: member.clubId,
    membershipId: member.membershipId,
    personId: member.personId
  };
}

module.exports = {
  assertMembershipAdministrator,
  assertNotMembershipAdministrator,
  ensureMembershipAdministrator,
  ensureOnlyMembershipAdministrator,
  ensureOrdinaryMember,
  makeMembershipAdministrator,
  tryMakeMembershipAdministrator,
  tryRemoveMembershipAdministrator
};
