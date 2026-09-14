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

const defaultBrowserTagExpression = "not @not-ui and not @todo-ui";

test("default browser Cucumber profile excludes scenarios not ready or not intended for UI", () => {
  assert.equal(cucumberConfig.default.tags, defaultBrowserTagExpression);
});

test("default browser Cucumber profile still loads the shared feature suite", () => {
  assert.deepEqual(cucumberConfig.default.paths, ["features/**/*.feature"]);
});

test("default browser Cucumber profile selects all web-backed shared features", () => {
  const selectedFeatureNames = browserSelectedFeatureNames();

  assert.deepEqual(selectedFeatureNames, [
    "authentication.feature",
    "club_member_invitations.feature",
    "club_membership_administration.feature",
    "club_message_replies.feature",
    "custom_group_conversations.feature",
    "custom_group_creation.feature",
    "custom_group_lifecycle.feature",
    "email_branding.feature",
    "group_conversations.feature",
    "homepage.feature",
    "list_members.feature",
    "memba_staff_email_deliverability.feature",
    "memba_staff_operations.feature",
    "member_club_subdomains.feature",
    "member_message_deliverability.feature",
    "person_email_addresses.feature",
    "request_account.feature",
    "staff_club_slugs.feature"
  ]);
});

test("shared feature suite uses only runner-intent and runner-debt tags", () => {
  const unsupportedTags = browserFeatures().flatMap((feature) =>
    feature.scenarios.flatMap((scenario) =>
      scenario.tags
        .filter((tag) => !supportedFeatureTag(tag))
        .map((tag) => `${feature.name}: ${scenario.name}: ${tag}`)
    )
  );

  assert.deepEqual(unsupportedTags, []);
});

test("scenario inventory inherits feature, rule, and scenario tags within their scopes", () => {
  const scenarios = featureScenarios(
    browserFeaturePathNamed("club_message_replies.feature")
  );

  assert.deepEqual(
    scenarios.get("The sender and repliers automatically follow the conversation").tags,
    ["@iteration-039", "@iteration-040"]
  );
  assert.deepEqual(
    scenarios.get(
      "Email to the club address without reply headers starts a new club-wide message"
    ).tags,
    ["@iteration-039", "@iteration-041", "@iteration-042"]
  );
  assert.deepEqual(
    scenarios.get("A member of another club cannot reply").tags,
    ["@iteration-039"]
  );
});

test("iteration 031 scenarios are no longer blocked from the browser runner", () => {
  const iterationScenarios = browserFeatures().flatMap((feature) =>
    feature.scenarios
      .filter((scenario) => scenario.tags.includes("@iteration-031"))
      .map((scenario) => `${feature.name}: ${scenario.name}: ${scenario.tags.join(" ")}`)
  );

  assert.equal(iterationScenarios.length, 4);
  assert.deepEqual(
    iterationScenarios.filter((scenario) => scenario.includes("@todo-ui")),
    []
  );
});

test("iteration 057 scenarios are no longer blocked from either acceptance runner", () => {
  const iterationScenarios = browserFeatures().flatMap((feature) =>
    feature.scenarios
      .filter((scenario) => scenario.tags.includes("@iteration-057"))
      .map((scenario) => `${feature.name}: ${scenario.name}: ${scenario.tags.join(" ")}`)
  );

  assert.equal(iterationScenarios.length, 4);
  assert.deepEqual(
    iterationScenarios.filter(
      (scenario) => scenario.includes("@todo-domain") || scenario.includes("@todo-ui")
    ),
    []
  );
});

test("group-conversation scenarios retain iteration 058 provenance as later slices evolve them", () => {
  const feature = browserFeatures().find(
    ({ name }) => name === "group_conversations.feature"
  );
  const inheritedIterationScenarios = feature.scenarios.filter((scenario) =>
    scenario.tags.includes("@iteration-058")
  );
  const unchangedIteration058ScenarioNames = inheritedIterationScenarios
    .filter(
      (scenario) =>
        !scenario.tags.some((tag) => /^@iteration-(061|065)$/.test(tag))
    )
    .map((scenario) => scenario.name);

  assert.equal(inheritedIterationScenarios.length, 15);
  assert.deepEqual(unchangedIteration058ScenarioNames, [
    "Bob sees Everyone and Admin",
    "A future named group is presented without a bespoke screen",
    "An Admin member views Admin conversations and members",
    "Bob starts an Admin conversation in the web app",
    "Bob returns to Admin",
    "Alice has no remembered group"
  ]);

  assert.deepEqual(
    inheritedIterationScenarios
      .filter((scenario) => unchangedIteration058ScenarioNames.includes(scenario.name))
      .filter(
        (scenario) =>
          scenario.tags.includes("@todo-domain") || scenario.tags.includes("@todo-ui")
      ),
    []
  );
});

test("iteration 061 scenarios run in each intended acceptance layer", () => {
  const feature = browserFeatures().find(
    ({ name }) => name === "group_conversations.feature"
  );
  const iterationScenarios = feature.scenarios.filter((scenario) =>
    scenario.tags.includes("@iteration-061")
  );
  const domainScenarioNames = iterationScenarios
    .filter((scenario) => !scenario.tags.includes("@not-domain"))
    .map((scenario) => scenario.name);
  const browserScenarioNames = iterationScenarios
    .filter((scenario) => matchesDefaultBrowserTags(scenario.tags))
    .map((scenario) => scenario.name);

  assert.deepEqual(domainScenarioNames, [
    "Alice sees Admin without belonging to it",
    "Alice follows an Admin group link",
    "Alice can find Board but cannot read its discussions",
    "Bob inspects Board's members without joining",
    "Neither ordinary membership nor club administration grants Board access",
    "Another club's member cannot discover KMC groups"
  ]);
  assert.deepEqual(browserScenarioNames, iterationScenarios.map((scenario) => scenario.name));
  assert.deepEqual(
    iterationScenarios.filter(
      (scenario) =>
        scenario.tags.includes("@todo-domain") || scenario.tags.includes("@todo-ui")
    ),
    []
  );
});

test("iteration 062 custom-group creation scenarios run in each intended acceptance layer", () => {
  const feature = browserFeatures().find(
    ({ name }) => name === "custom_group_creation.feature"
  );
  const iterationScenarios = feature.scenarios.filter((scenario) =>
    scenario.tags.includes("@iteration-062")
  );
  const domainScenarioNames = iterationScenarios
    .filter((scenario) => !scenario.tags.includes("@not-domain"))
    .map((scenario) => scenario.name);
  const browserScenarioNames = iterationScenarios
    .filter((scenario) => matchesDefaultBrowserTags(scenario.tags))
    .map((scenario) => scenario.name);

  assert.equal(iterationScenarios.length, 14);
  assert.equal(domainScenarioNames.length, 10);
  assert.deepEqual(browserScenarioNames, iterationScenarios.map((scenario) => scenario.name));
  assert.deepEqual(
    iterationScenarios.filter((scenario) => scenario.tags.includes("@todo-ui")),
    []
  );
});

test("iteration 062 custom-group conversation scenarios run in both acceptance layers", () => {
  const feature = browserFeatures().find(
    ({ name }) => name === "custom_group_conversations.feature"
  );
  const iterationScenarios = feature.scenarios.filter((scenario) =>
    scenario.tags.includes("@iteration-062")
  );
  const domainScenarioNames = iterationScenarios
    .filter((scenario) => !scenario.tags.includes("@not-domain"))
    .map((scenario) => scenario.name);
  const browserScenarioNames = iterationScenarios
    .filter((scenario) => matchesDefaultBrowserTags(scenario.tags))
    .map((scenario) => scenario.name);

  assert.equal(iterationScenarios.length, 8);
  assert.deepEqual(domainScenarioNames, iterationScenarios.map((scenario) => scenario.name));
  assert.deepEqual(browserScenarioNames, iterationScenarios.map((scenario) => scenario.name));
  assert.deepEqual(
    iterationScenarios.filter(
      (scenario) =>
        scenario.tags.includes("@todo-domain") || scenario.tags.includes("@todo-ui")
    ),
    []
  );
});

test("iteration 062 custom-group lifecycle scenarios run in both acceptance layers", () => {
  const feature = browserFeatures().find(
    ({ name }) => name === "custom_group_lifecycle.feature"
  );
  const iterationScenarios = feature.scenarios.filter((scenario) =>
    scenario.tags.includes("@iteration-062")
  );
  const domainScenarioNames = iterationScenarios
    .filter((scenario) => !scenario.tags.includes("@not-domain"))
    .map((scenario) => scenario.name);
  const browserScenarioNames = iterationScenarios
    .filter((scenario) => matchesDefaultBrowserTags(scenario.tags))
    .map((scenario) => scenario.name);

  assert.equal(iterationScenarios.length, 2);
  assert.deepEqual(domainScenarioNames, iterationScenarios.map((scenario) => scenario.name));
  assert.deepEqual(browserScenarioNames, iterationScenarios.map((scenario) => scenario.name));
  assert.deepEqual(
    iterationScenarios.filter(
      (scenario) =>
        scenario.tags.includes("@todo-domain") || scenario.tags.includes("@todo-ui")
    ),
    []
  );
});

test("iteration 059 UI scenarios run while its concurrency scenario remains domain-only", () => {
  const feature = browserFeatures().find(
    ({ name }) => name === "club_membership_administration.feature"
  );
  const iterationScenarios = feature.scenarios.filter((scenario) =>
    scenario.tags.includes("@iteration-059")
  );
  const browserScenarioNames = iterationScenarios
    .filter((scenario) => matchesDefaultBrowserTags(scenario.tags))
    .map((scenario) => scenario.name);

  assert.equal(iterationScenarios.length, 5);
  assert.deepEqual(browserScenarioNames, [
    "Robin accepts the first invitation to an empty club",
    "Pat cannot remove Robin while Robin is the only Admin",
    "Pat removes Robin after Alice becomes an Admin",
    "Pat cannot remove the club's only member"
  ]);
});

test("the later-invitee ordinary-member regression remains selected by the browser runner", () => {
  const scenario = browserFeaturePathNamed("club_member_invitations.feature");
  const invitationScenarios = featureScenarios(scenario);

  assert.equal(
    matchesDefaultBrowserTags(
      invitationScenarios.get("Robin invites Dana to join West Coast Paddlers").tags
    ),
    true
  );
});

function browserSelectedFeatureNames() {
  return browserFeatures()
    .filter((feature) => feature.scenarios.some((scenario) => matchesDefaultBrowserTags(scenario.tags)))
    .map((feature) => feature.name)
    .sort();
}

function browserSkippedFeatures() {
  return browserFeatures()
    .filter((feature) => feature.scenarios.every((scenario) => !matchesDefaultBrowserTags(scenario.tags)))
    .sort((left, right) => left.name.localeCompare(right.name));
}

function browserFeatures() {
  assert.deepEqual(cucumberConfig.default.paths, ["features/**/*.feature"]);

  const featuresRoot = path.resolve(__dirname, "../features");

  return listFeatureFiles(featuresRoot).map((filePath) => ({
    name: path.basename(filePath),
    tags: featureTags(filePath),
    scenarios: [...featureScenarios(filePath).values()]
  }));
}

function browserFeaturePathNamed(featureName) {
  const featuresRoot = path.resolve(__dirname, "../features");
  const featurePath = listFeatureFiles(featuresRoot).find(
    (filePath) => path.basename(filePath) === featureName
  );

  assert.ok(featurePath, `Expected browser feature file ${featureName}`);

  return featurePath;
}

function listFeatureFiles(directory) {
  return fs
    .readdirSync(directory, { withFileTypes: true })
    .flatMap((entry) => {
      const entryPath = path.join(directory, entry.name);

      if (entry.isDirectory()) {
        return listFeatureFiles(entryPath);
      }

      return entry.isFile() && entry.name.endsWith(".feature") ? [entryPath] : [];
    })
    .sort();
}

function featureTags(filePath) {
  return tagNames(parseFeature(filePath).tags);
}

function featureScenarios(filePath) {
  const feature = parseFeature(filePath);
  const scenarios = new Map();
  const featureLevelTags = tagNames(feature.tags);

  for (const child of feature.children) {
    if (child.scenario) {
      addScenario(scenarios, child.scenario, featureLevelTags);
      continue;
    }

    if (child.rule) {
      const ruleLevelTags = [
        ...featureLevelTags,
        ...tagNames(child.rule.tags)
      ];

      for (const ruleChild of child.rule.children) {
        if (ruleChild.scenario) {
          addScenario(scenarios, ruleChild.scenario, ruleLevelTags);
        }
      }
    }
  }

  return scenarios;
}

function parseFeature(filePath) {
  let nextId = 0;
  const newId = () => String(nextId++);
  const parser = new Parser(
    new AstBuilder(newId),
    new GherkinClassicTokenMatcher()
  );

  return parser.parse(fs.readFileSync(filePath, "utf8")).feature;
}

function addScenario(scenarios, scenario, inheritedTags) {
  scenarios.set(scenario.name, {
    name: scenario.name,
    tags: [...inheritedTags, ...tagNames(scenario.tags)]
  });
}

function tagNames(tags) {
  return tags.map(({ name }) => name);
}

function supportedFeatureTag(tag) {
  return ["@not-domain", "@not-ui", "@todo-domain", "@todo-ui"].includes(tag) || /^@iteration-\d+$/.test(tag);
}

function matchesDefaultBrowserTags(tags) {
  assert.equal(cucumberConfig.default.tags, defaultBrowserTagExpression);

  return (
    !tags.includes("@not-ui") &&
    !tags.includes("@todo-ui")
  );
}
