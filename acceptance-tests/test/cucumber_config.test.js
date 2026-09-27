const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const {
  AstBuilder,
  GherkinClassicTokenMatcher,
  Parser
} = require("@cucumber/gherkin");

const cucumberConfig = require("../cucumber");
const featuresRoot = path.resolve(__dirname, "../features");
const defaultBrowserTagExpression = "@journey and not @todo";
const legacyTags = new Set(["@not-domain", "@not-ui", "@todo-domain", "@todo-ui"]);

// Both runners use inherited Gherkin tags: an untagged example runs in the
// domain layer, while only a non-todo journey runs in the browser layer.
function selectedByBrowser(tags) {
  return tags.includes("@journey") && !tags.includes("@todo");
}

function selectedByDomain(tags) {
  return !tags.includes("@journey") && !tags.includes("@todo");
}

test("default browser profile selects journeys, excluding future plans", () => {
  assert.equal(cucumberConfig.default.tags, defaultBrowserTagExpression);
  assert.equal(selectedByBrowser([]), false);
  assert.equal(selectedByBrowser(["@journey"]), true);
  assert.equal(selectedByBrowser(["@journey", "@todo"]), false);
  assert.equal(selectedByDomain([]), true);
  assert.equal(selectedByDomain(["@todo"]), false);
  assert.equal(selectedByDomain(["@journey"]), false);
});

test("feature, rule, and scenario tags inherit only within their scopes", () => {
  const feature = parse(`
    @iteration-039
    Feature: Tag scopes
      Scenario: Direct child
        Given a condition
      @iteration-040
      Rule: Email followers
        Scenario: Inherits feature and rule
          Given a condition
        @iteration-042 @todo
        Scenario: Future follower rule
          Given a condition
      Rule: Other rule
        @journey
        Scenario: Browser-only example
          Given a condition
  `);
  const scenarios = scenariosIn(feature);

  assert.deepEqual(scenarios.map(({ tags }) => tags), [
    ["@iteration-039"],
    ["@iteration-039", "@iteration-040"],
    ["@iteration-039", "@iteration-040", "@iteration-042", "@todo"],
    ["@iteration-039", "@journey"]
  ]);
  assert.deepEqual(scenarios.map(({ tags }) => selectedByBrowser(tags)), [false, false, false, true]);
  assert.deepEqual(scenarios.map(({ tags }) => selectedByDomain(tags)), [true, true, false, false]);
});

test("feature tags propagate to every rule and direct scenario", () => {
  const scenarios = scenariosIn(parse(`
    @journey @todo
    Feature: Deferred browser work
      Scenario: Direct child
        Given a condition
      Rule: Future rule
        Scenario: Rule child
          Given a condition
  `));
  assert.equal(scenarios.length, 2);
  assert.ok(scenarios.every(({ tags }) => tags.includes("@journey") && tags.includes("@todo")));
  assert.ok(scenarios.every(({ tags }) => !selectedByBrowser(tags) && !selectedByDomain(tags)));
});

test("feature files use provenance, journey, and todo tags, never legacy runner tags", () => {
  const invalid = featureFiles().flatMap((filePath) => {
    const feature = parseFile(filePath);
    const tags = [
      ...tagNames(feature.tags),
      ...feature.children.flatMap((child) => child.rule ? tagNames(child.rule.tags) : []),
      ...scenariosIn(feature).flatMap((scenario) => scenario.tags)
    ];
    return [...new Set(tags)]
      .filter((tag) => legacyTags.has(tag) || !supportedTag(tag))
      .map((tag) => `${path.relative(featuresRoot, filePath)}: ${tag}`);
  });

  assert.deepEqual(invalid, []);
});

test("only dedicated journey files select browser scenarios", () => {
  const misplaced = featureFiles().flatMap((filePath) =>
    scenariosIn(parseFile(filePath))
      .filter(({ tags }) => selectedByBrowser(tags))
      .filter(() => !path.relative(featuresRoot, filePath).startsWith(`journeys${path.sep}`))
      .map(({ name }) => `${path.relative(featuresRoot, filePath)}: ${name}`)
  );
  assert.deepEqual(misplaced, []);
});

test("journey files contain one coherent browser scenario each", () => {
  const journeyRoot = path.join(featuresRoot, "journeys");
  const files = featureFiles(journeyRoot);
  assert.ok(files.length > 0, "Expected at least one dedicated browser journey");

  for (const filePath of files) {
    const feature = parseFile(filePath);
    const scenarios = scenariosIn(feature);
    assert.equal(scenarios.length, 1, `${filePath} must describe one journey`);
    assert.ok(scenarios[0].tags.includes("@journey"), `${filePath} must be a browser journey`);
    assert.equal(selectedByBrowser(scenarios[0].tags), !scenarios[0].tags.includes("@todo"));
    assert.equal(selectedByDomain(scenarios[0].tags), false);
  }
});

test("club reply examples keep feature, rule, and scenario provenance in the domain", () => {
  const scenarios = scenariosNamed("club_message_replies.feature");
  assert.deepEqual(scenarios.get("The sender and repliers automatically follow the conversation").tags,
    ["@iteration-039", "@iteration-040"]);
  assert.deepEqual(scenarios.get("Email to the club address without reply headers starts a new club-wide message").tags,
    ["@iteration-039", "@iteration-041", "@iteration-042"]);
  assert.deepEqual(scenarios.get("A member of another club cannot reply").tags, ["@iteration-039"]);
  assert.ok([...scenarios.values()].every(({ tags }) => selectedByDomain(tags)));
});

test("iteration 057 email routing stays a domain example", () => {
  const tags = scenariosNamed("member_message_deliverability.feature")
    .get("Alice emails the KMC Admin address without belonging to Admin").tags;
  assert.ok(tags.includes("@iteration-057"));
  assert.ok(selectedByDomain(tags));
  assert.equal(selectedByBrowser(tags), false);
});

test("iteration 058 remains the provenance of unchanged group rules", () => {
  const scenarios = scenariosNamed("group_conversations.feature");
  for (const name of [
    "Bob sees Everyone and Admin",
    "A future named group is presented without a bespoke screen",
    "An Admin member views Admin conversations and members",
    "Bob starts an Admin conversation in the web app"
  ]) {
    assert.ok(scenarios.get(name).tags.includes("@iteration-058"), name);
  }
  assert.ok(scenarios.get("Alice follows an Admin group link").tags.includes("@iteration-061"));
  assert.ok(selectedByDomain(scenarios.get("Alice follows an Admin group link").tags));
});

test("custom-group rules and their distinct Board journey retain iteration 062 provenance", () => {
  const rules = scenariosNamed("custom_group_conversations.feature");
  assert.ok(selectedByDomain(rules.get("Bob starts a Board discussion without addressing Everyone").tags));
  assert.ok(rules.get("Bob starts a Board discussion without addressing Everyone").tags.includes("@iteration-062"));
  const journey = scenariosNamed("board_conversation.feature").values().next().value;
  assert.ok(journey.tags.includes("@iteration-062"));
  assert.ok(selectedByBrowser(journey.tags));
  assert.equal(rules.has(journey.name), false);
});

test("unfinished lifecycle rules and future access requests remain deferred", () => {
  const lifecycle = scenariosNamed("custom_group_lifecycle.feature");
  assert.ok(lifecycle.get("Carol loses access even with an old Board conversation open").tags.includes("@todo"));
  assert.ok(!selectedByDomain(lifecycle.get("Carol loses access even with an old Board conversation open").tags));
  assert.ok(selectedByDomain(lifecycle.get("Removing Carol does not cancel her queued email").tags));
  const requests = scenariosNamed("custom_group_access_requests.feature");
  assert.ok(requests.size > 0);
  assert.ok([...requests.values()].every(({ tags }) => tags.includes("@todo") && !selectedByDomain(tags) && !selectedByBrowser(tags)));
});

test("concurrent first-admin invitation remains a domain-only regression", () => {
  const scenarios = scenariosNamed("club_membership_administration.feature");
  const tags = scenarios.get("Robin and Alice accept invitations at the same time").tags;
  assert.ok(tags.includes("@iteration-059"));
  assert.ok(selectedByDomain(tags));
  assert.equal(selectedByBrowser(tags), false);
});

test("later-invitee ordinary-member regression remains a domain example", () => {
  const tags = scenariosNamed("club_member_invitations.feature")
    .get("Robin invites Dana to join West Coast Paddlers").tags;
  assert.ok(tags.includes("@iteration-029"));
  assert.ok(selectedByDomain(tags));
  assert.equal(selectedByBrowser(tags), false);
});

function scenariosNamed(fileName) {
  const filePath = featureFiles().find((candidate) => path.basename(candidate) === fileName);
  assert.ok(filePath, `Expected feature file ${fileName}`);
  return new Map(scenariosIn(parseFile(filePath)).map((scenario) => [scenario.name, scenario]));
}

function featureFiles(directory = featuresRoot) {
  return fs.readdirSync(directory, { withFileTypes: true })
    .flatMap((entry) => {
      const entryPath = path.join(directory, entry.name);
      return entry.isDirectory() ? featureFiles(entryPath) :
        entry.isFile() && entry.name.endsWith(".feature") ? [entryPath] : [];
    }).sort();
}

function parseFile(filePath) {
  return parse(fs.readFileSync(filePath, "utf8"));
}

function parse(source) {
  let nextId = 0;
  const parser = new Parser(new AstBuilder(() => String(nextId++)), new GherkinClassicTokenMatcher());
  return parser.parse(source).feature;
}

function scenariosIn(feature) {
  const inherited = tagNames(feature.tags);
  return feature.children.flatMap((child) => {
    if (child.scenario) {
      return [scenarioWithTags(child.scenario, inherited)];
    }
    if (child.rule) {
      const ruleTags = [...inherited, ...tagNames(child.rule.tags)];
      return child.rule.children
        .filter((ruleChild) => ruleChild.scenario)
        .map((ruleChild) => scenarioWithTags(ruleChild.scenario, ruleTags));
    }
    return [];
  });
}

function scenarioWithTags(scenario, inherited) {
  return { name: scenario.name, tags: [...inherited, ...tagNames(scenario.tags)] };
}

function tagNames(tags) {
  return tags.map(({ name }) => name);
}

function supportedTag(tag) {
  return tag === "@journey" || tag === "@todo" || /^@iteration-\d+$/.test(tag);
}
