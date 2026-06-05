function enabled(world) {
  return process.env.ACCEPTANCE_SCENARIO_SCOPING === "1" && world && world.scenarioId;
}

function scopedLabel(world, label) {
  if (isSharedFixtureLabel(label)) {
    return label;
  }

  return enabled(world) ? `${label} ${world.scenarioId}` : label;
}

function displayClubName(world, clubName) {
  return (world.clubs && world.clubs[clubName] && world.clubs[clubName].name) || scopedLabel(world, clubName);
}

function displayPersonName(world, personName) {
  return (world.people && world.people[personName] && world.people[personName].name) || scopedLabel(world, personName);
}

function scopedEmailAddress(world, email) {
  if (!enabled(world)) {
    return email;
  }

  const value = String(email || "").trim();

  if (isSharedFixtureEmail(value)) {
    return value;
  }

  const atIndex = value.lastIndexOf("@");

  if (atIndex <= 0) {
    return scopedLabel(world, value);
  }

  const localPart = value.slice(0, atIndex);
  const domain = value.slice(atIndex + 1);
  const safeScenarioId = String(world.scenarioId).replace(/[^a-z0-9]+/gi, ".");

  if (localPart.endsWith(`+${safeScenarioId}`)) {
    return value;
  }

  return `${localPart}+${safeScenarioId}@${domain}`;
}

function scopedSlug(world, slug) {
  if (!enabled(world)) {
    return slug;
  }

  if (String(slug || "").trim().toLowerCase() === "test") {
    return slug;
  }

  const suffix = `-${world.scenarioId}`;
  const maxLength = 32;
  const base = String(slug || "")
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "") || "club";
  const trimmedBase = base
    .slice(0, maxLength - suffix.length)
    .replace(/^-+|-+$/g, "") || "club";

  return `${trimmedBase}${suffix}`;
}

function displayStaffEmail(world, fallback = process.env.ACCEPTANCE_STAFF_EMAIL || "acceptance-staff@memba.io") {
  return scopedEmailAddress(world, fallback);
}

function isSharedFixtureLabel(label) {
  return ["Smoke Test Club", "Smoke Tester"].includes(String(label || ""));
}

function isSharedFixtureEmail(email) {
  return String(email || "").toLowerCase() === "test@memba.io";
}

module.exports = {
  displayClubName,
  displayPersonName,
  displayStaffEmail,
  enabled,
  scopedEmailAddress,
  scopedLabel,
  scopedSlug
};
