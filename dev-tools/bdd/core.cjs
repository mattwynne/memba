const fs = require("node:fs");
const path = require("node:path");
const {execFileSync} = require("node:child_process");
const {createRequire} = require("node:module");

const projectRoot = path.resolve(__dirname, "../..");
const cucumberRequire = createRequire(path.join(projectRoot, "acceptance-tests/package.json"));
const {AstBuilder, GherkinClassicTokenMatcher, Parser} = cucumberRequire("@cucumber/gherkin");

// Keep this vocabulary aligned with .fabro/workflows/scripts/iteration_status.py.
const activeStatuses = new Set([
  "implementing",
  "ready-for-review",
  "in-review",
  "reviewing",
  "finalizing"
]);

function runGit(cwd, args, options = {}) {
  try {
    return execFileSync("git", args, {
      cwd,
      encoding: "utf8",
      maxBuffer: 32 * 1024 * 1024,
      stdio: ["ignore", "pipe", "pipe"],
      ...options
    });
  } catch (error) {
    const detail = error.stderr && String(error.stderr).trim();
    throw new Error(detail || error.message);
  }
}

function repositoryRoot(cwd = process.cwd()) {
  return runGit(cwd, ["rev-parse", "--show-toplevel"]).trim();
}

function resolveCommit(root, commit = "HEAD") {
  return runGit(root, ["rev-parse", "--verify", "--end-of-options", `${commit}^{commit}`]).trim();
}

function iterationRows(source) {
  const rows = [];
  for (const line of source.split("\n")) {
    if (!line.startsWith("|") || !line.includes("[plan](")) continue;
    const cells = line.trim().slice(1, -1).split("|").map(cell => cell.trim());
    const link = cells[4]?.match(/\[plan\]\(([^)]+)\)/);
    if (!/^\d+$/.test(cells[0]) || !cells[2] || !link) {
      throw new Error(`Invalid iteration row: ${line}`);
    }
    const number = Number(cells[0]);
    if (rows.some(row => row.number === number)) throw new Error(`Duplicate iteration ${cells[0]}`);
    rows.push({
      number,
      status: cells[2].toLowerCase(),
      plan: path.posix.join("docs/iterations", link[1])
    });
  }
  if (!rows.length) throw new Error("No iterations found in docs/iterations/README.md");
  return rows;
}

function tagNames(tags) {
  return (tags || []).map(tag => tag.name);
}

function unique(values) {
  return [...new Set(values)];
}

function iterationNumbers(tags) {
  return unique(tags
    .filter(tag => /^@iteration-\d+$/.test(tag))
    .map(tag => Number(tag.slice("@iteration-".length))));
}

function parseFeature(source, file) {
  let id = 0;
  const parser = new Parser(new AstBuilder(() => String(id++)), new GherkinClassicTokenMatcher());
  let document;
  try {
    document = parser.parse(source);
  } catch (error) {
    throw new Error(`${file}: ${error.message}`);
  }
  if (!document.feature) throw new Error(`${file}: no Feature found`);

  const declarations = [];
  const executions = [];
  const feature = document.feature;

  function visit(container, inheritedTags) {
    const parentTags = [...inheritedTags, ...tagNames(container.tags)];
    for (const child of container.children) {
      if (child.rule) {
        visit(child.rule, parentTags);
        continue;
      }
      if (!child.scenario) continue;

      const scenario = child.scenario;
      const scenarioLocal = tagNames(scenario.tags);
      const scenarioInherited = [...parentTags];
      const scenarioTags = unique([...scenarioInherited, ...scenarioLocal]);
      const outline = scenario.keyword === "Scenario Outline" || scenario.keyword === "Scenario Template";
      const scenarioDeclaration = {
        feature: file,
        scenario: scenario.name,
        declaration: outline ? "Scenario Outline" : "Scenario",
        line: scenario.location.line,
        localTags: scenarioLocal,
        inheritedTags: scenarioInherited,
        tags: scenarioTags,
        tagNodes: scenario.tags,
        examples: []
      };
      declarations.push(scenarioDeclaration);

      for (const examples of scenario.examples) {
        const localTags = tagNames(examples.tags);
        const inherited = [...scenarioTags];
        const declaration = {
          feature: file,
          scenario: scenario.name,
          examples: examples.name,
          declaration: "Examples",
          line: examples.location.line,
          localTags,
          inheritedTags: inherited,
          tags: unique([...inherited, ...localTags]),
          tagNodes: examples.tags,
          parent: scenarioDeclaration
        };
        scenarioDeclaration.examples.push(declaration);
        declarations.push(declaration);
        executions.push(declaration);
      }

      if (!scenario.examples.length) executions.push(scenarioDeclaration);
    }
  }

  visit(feature, []);
  return {declarations, executions};
}

function label(item) {
  return `${item.feature}:${item.line}: ${item.scenario}`;
}

function choiceDescription(item) {
  return {
    feature: item.feature,
    scenario: item.scenario,
    ...(item.declaration === "Examples" && item.examples ? {examples: item.examples} : {}),
    declaration: item.declaration,
    line: item.line,
    reference: `${item.feature}:${item.line}`
  };
}

function validateOwnership(item, rows) {
  const numbers = iterationNumbers(item.tags);
  if (numbers.length !== 1) {
    throw new Error(`${label(item)}: expected one iteration tag, got ${item.tags.join(" ")}`);
  }
  const row = rows.find(candidate => candidate.number === numbers[0]);
  if (!row) throw new Error(`${label(item)}: iteration ${numbers[0]} is absent from the index`);
  item.iteration = numbers[0];
  if (row.status === "merged" && item.tags.includes("@todo")) {
    throw new Error(`${label(item)}: dangling @todo for merged iteration ${numbers[0]}`);
  }
}

function inspectSnapshot(indexSource, features) {
  const rows = iterationRows(indexSource);
  const parsed = features.map(({file, source}) => ({file, source, ...parseFeature(source, file)}));
  const executions = parsed.flatMap(feature => feature.executions);
  const unfinished = executions.filter(item => item.tags.includes("@todo") || item.tags.includes("@wip"));

  for (const item of unfinished) validateOwnership(item, rows);

  const active = rows.filter(row => activeStatuses.has(row.status));
  if (active.length !== 1) throw new Error(`Expected one active iteration, found ${active.length}`);

  const wip = unfinished.filter(item => item.tags.includes("@wip"));
  if (wip.length) {
    throw new Error(`WIP prevents completion: ${wip.map(label).join("; ")}`);
  }

  const activeNumber = active[0].number;
  const currentExecutions = unfinished.filter(item => item.iteration === activeNumber && item.tags.includes("@todo"));
  const choices = [];

  for (const parsedFeature of parsed) {
    for (const declaration of parsedFeature.declarations) {
      if (!declaration.localTags.includes("@todo")) continue;
      if (!iterationNumbers(declaration.tags).includes(activeNumber)) continue;

      if (declaration.inheritedTags.includes("@todo")) {
        throw new Error(`${label(declaration)}: local @todo conflicts with inherited @todo`);
      }
      if (declaration.declaration === "Scenario Outline" &&
          declaration.examples.some(examples => examples.localTags.includes("@todo"))) {
        throw new Error(`${label(declaration)}: nested local @todo conflicts with outline @todo`);
      }
      choices.push(declaration);
    }
  }

  for (const execution of currentExecutions) {
    const represented = choices.some(choice => choice === execution ||
      (choice.declaration === "Scenario Outline" && choice.examples.includes(execution)));
    if (!represented) {
      throw new Error(`${label(execution)}: unfinished work has no eligible local @todo declaration`);
    }
  }

  const pending = choices.filter(choice => !choice.tags.includes("@journey"));
  const journeys = choices.filter(choice => choice.tags.includes("@journey"));
  return {
    plan: active[0].plan,
    activeIteration: activeNumber,
    pending: pending.map(choiceDescription),
    pending_journeys: journeys.map(choiceDescription),
    domain_complete: pending.length === 0,
    preferred_next_label: pending.length ? "choose" : "done",
    parsed,
    choices
  };
}

function committedFeatureFiles(root, sha) {
  return runGit(root, ["ls-tree", "-rz", "--name-only", sha, "--", "acceptance-tests/features"], {encoding: "buffer"})
    .toString("utf8").split("\0").filter(file => file.endsWith(".feature"));
}

function readCommitted(root, sha, file) {
  return runGit(root, ["show", `${sha}:${file}`]);
}

function fromCommit(commit = "HEAD", cwd = process.cwd()) {
  const root = repositoryRoot(cwd);
  const sha = resolveCommit(root, commit);
  const files = committedFeatureFiles(root, sha);
  if (!files.length) throw new Error("No acceptance feature files found");
  const inspected = inspectSnapshot(
    readCommitted(root, sha, "docs/iterations/README.md"),
    files.map(file => ({file, source: readCommitted(root, sha, file)}))
  );
  readCommitted(root, sha, inspected.plan);
  const {parsed, choices, activeIteration, ...report} = inspected;
  return {commit: sha, active_iteration: activeIteration, ...report};
}

function assertClean(root) {
  const status = runGit(root, ["status", "--porcelain=v1", "-z", "--untracked-files=all"]);
  if (status.length) throw new Error("worktree must be completely clean before picking BDD work");
}

function parseReference(reference) {
  const match = /^(.*):([1-9]\d*)$/.exec(reference);
  if (!match) throw new Error(`invalid feature reference: ${reference}`);
  const feature = match[1];
  if (path.posix.isAbsolute(feature) || feature.includes("\0") ||
      !feature.startsWith("acceptance-tests/features/") || !feature.endsWith(".feature") ||
      feature.split("/").includes("..")) {
    throw new Error(`feature must be a repository path below acceptance-tests/features: ${feature}`);
  }
  return {feature, line: Number(match[2])};
}

function replaceLocalTodo(root, declaration) {
  const todo = declaration.tagNodes.find(tag => tag.name === "@todo");
  if (!todo) throw new Error(`${label(declaration)}: does not have its own local @todo`);
  const target = path.join(root, declaration.feature);
  const source = fs.readFileSync(target, "utf8");
  const lines = source.split(/(?<=\n)/);
  const prior = lines.slice(0, todo.location.line - 1).join("");
  const line = lines[todo.location.line - 1] || "";
  const columnIndex = [...line].slice(0, todo.location.column - 1).join("").length;
  const offset = prior.length + columnIndex;
  if (source.slice(offset, offset + 5) !== "@todo") {
    throw new Error(`${declaration.feature}:${todo.location.line}: local @todo location is stale`);
  }
  const updated = source.slice(0, offset) + "@wip" + source.slice(offset + 5);
  const mode = fs.statSync(target).mode;
  const temporary = path.join(path.dirname(target), `.${path.basename(target)}.bdd-pick-${process.pid}`);
  try {
    fs.writeFileSync(temporary, updated, {flag: "wx", mode});
    fs.renameSync(temporary, target);
  } finally {
    try { fs.unlinkSync(temporary); } catch (error) {
      if (error.code !== "ENOENT") throw error;
    }
  }
}

function pick(reference, from, cwd = process.cwd()) {
  const root = repositoryRoot(cwd);
  assertClean(root);
  const head = resolveCommit(root, "HEAD");
  if (from !== undefined) {
    const requested = resolveCommit(root, from);
    if (requested !== head) throw new Error(`--from must resolve to HEAD (${head}), got ${requested}`);
  }

  const locator = parseReference(reference);
  const files = committedFeatureFiles(root, head);
  if (!files.includes(locator.feature)) throw new Error(`${locator.feature}: is not a committed acceptance feature`);
  const indexSource = readCommitted(root, head, "docs/iterations/README.md");
  const features = files.map(file => ({file, source: readCommitted(root, head, file)}));
  const selectedSource = features.find(feature => feature.file === locator.feature).source;
  const preliminary = parseFeature(selectedSource, locator.feature);
  const matches = preliminary.declarations.filter(declaration => declaration.line === locator.line);
  if (matches.length !== 1) {
    throw new Error(`${locator.feature}:${locator.line}: no Scenario, Scenario Outline, or Examples declaration at this line`);
  }
  const preliminarySelection = matches[0];
  if (!preliminarySelection.localTags.includes("@todo")) {
    throw new Error(`${label(preliminarySelection)}: does not have its own local @todo`);
  }
  if (preliminarySelection.inheritedTags.includes("@todo")) {
    throw new Error(`${label(preliminarySelection)}: local @todo conflicts with inherited @todo`);
  }
  if (preliminarySelection.declaration === "Scenario Outline" &&
      preliminarySelection.examples.some(examples => examples.localTags.includes("@todo"))) {
    throw new Error(`${label(preliminarySelection)}: nested local @todo conflicts with outline @todo`);
  }

  const inspected = inspectSnapshot(indexSource, features);
  readCommitted(root, head, inspected.plan);
  const selected = inspected.parsed.find(feature => feature.file === locator.feature)
    .declarations.find(declaration => declaration.line === locator.line);
  if (selected.tags.includes("@journey")) throw new Error(`${label(selected)}: journey work is not eligible for pick`);
  const selectedIterations = iterationNumbers(selected.tags);
  if (selectedIterations.length !== 1 || selectedIterations[0] !== inspected.activeIteration) {
    throw new Error(`${label(selected)}: selection does not belong to the active iteration`);
  }
  if (!inspected.choices.includes(selected)) throw new Error(`${label(selected)}: selection is not eligible for pick`);

  replaceLocalTodo(root, selected);
  return choiceDescription(selected);
}

module.exports = {
  activeStatuses,
  fromCommit,
  inspectSnapshot,
  iterationRows,
  parseFeature,
  pick,
  resolveCommit
};
