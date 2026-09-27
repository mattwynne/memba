const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { execFileSync } = require("node:child_process");
const test = require("node:test");

const {
  collectChangedFiles,
  isRelevantResponsivePath
} = require("../responsive/change_detector");

function git(repoRoot, args) {
  return execFileSync("git", ["-C", repoRoot, ...args], {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"]
  }).trim();
}

function makeRepo() {
  const repoRoot = fs.mkdtempSync(path.join(os.tmpdir(), "memba-responsive-trigger-"));
  git(repoRoot, ["init", "--initial-branch=main"]);
  git(repoRoot, ["config", "user.email", "test@example.com"]);
  git(repoRoot, ["config", "user.name", "Test User"]);

  writeFile(repoRoot, "README.md", "hello\n");
  writeFile(repoRoot, "styles.css", "body { color: black; }\n");
  writeFile(repoRoot, "web/assets/css/app.css", "@import \"tailwindcss\" source(none);\n");
  writeFile(repoRoot, "web/lib/memba_web/controllers/page_html/public_home.html.heex", "<main>Home</main>\n");
  writeFile(repoRoot, "web/lib/memba_web/live/member_dashboard_live.ex", "defmodule MemberDashboardLive do\nend\n");
  writeFile(repoRoot, "web/lib/memba_web/domain.ex", "defmodule Domain do\nend\n");
  git(repoRoot, ["add", "."]);
  git(repoRoot, ["commit", "-m", "initial"]);
  git(repoRoot, ["commit", "--allow-empty", "-m", "unrelated baseline"]);

  return repoRoot;
}

function writeFile(repoRoot, relativePath, content) {
  const absolutePath = path.join(repoRoot, relativePath);
  fs.mkdirSync(path.dirname(absolutePath), { recursive: true });
  fs.writeFileSync(absolutePath, content);
}

function detectorEnv(overrides = {}) {
  return {
    PATH: process.env.PATH,
    ...overrides
  };
}

test("responsive path matcher is narrow to style and layout/presentation files", () => {
  assert.equal(isRelevantResponsivePath("styles.css"), true);
  assert.equal(isRelevantResponsivePath("web/assets/css/app.css"), true);
  assert.equal(isRelevantResponsivePath("web/assets/vendor/daisyui-theme.js"), true);
  assert.equal(isRelevantResponsivePath("web/assets/vendor/daisyui.js"), true);
  assert.equal(isRelevantResponsivePath("web/assets/vendor/heroicons.js"), true);
  assert.equal(isRelevantResponsivePath("web/assets/js/app.js"), true);
  assert.equal(isRelevantResponsivePath("web/assets/vendor/topbar.js"), true);
  assert.equal(isRelevantResponsivePath("acceptance-tests/responsive/check.js"), true);
  assert.equal(isRelevantResponsivePath("acceptance-tests/responsive/change_detector.js"), true);
  assert.equal(isRelevantResponsivePath("acceptance-tests/gallery/scenes.js"), true);
  assert.equal(isRelevantResponsivePath("acceptance-tests/package.json"), true);
  assert.equal(isRelevantResponsivePath("acceptance-tests/package-lock.json"), true);
  assert.equal(isRelevantResponsivePath("acceptance-tests/features/support/browser_environment.js"), true);
  assert.equal(isRelevantResponsivePath("acceptance-tests/features/support/lifecycle.js"), true);
  assert.equal(isRelevantResponsivePath("bin/dev"), true);
  assert.equal(isRelevantResponsivePath("web/lib/memba_web/controllers/page_html/public_home.html.heex"), true);
  assert.equal(isRelevantResponsivePath("web/lib/memba_web/live/member_dashboard_live.ex"), true);
  assert.equal(isRelevantResponsivePath("web/lib/memba_web/components/layouts.ex"), true);
  assert.equal(isRelevantResponsivePath("web/lib/memba_web/member_dashboard_presentation.ex"), true);

  assert.equal(isRelevantResponsivePath("docs/reference/frontend-design.md"), false);
  assert.equal(isRelevantResponsivePath("web/lib/memba/domain.ex"), false);
  assert.equal(isRelevantResponsivePath("web/lib/memba_web/domain.ex"), false);
  assert.equal(isRelevantResponsivePath("acceptance-tests/features/homepage.feature"), false);
});

test("trigger includes staged relevant changes", () => {
  const repoRoot = makeRepo();
  writeFile(repoRoot, "styles.css", "body { color: green; }\n");
  git(repoRoot, ["add", "styles.css"]);

  const changes = collectChangedFiles(repoRoot, detectorEnv());

  assert.equal(changes.shouldRun, true);
  assert.deepEqual(changes.relevant, ["styles.css"]);
  assert.ok(changes.sources.staged.includes("styles.css"));
});

test("trigger includes unstaged relevant changes", () => {
  const repoRoot = makeRepo();
  writeFile(repoRoot, "web/assets/css/app.css", "body { color: blue; }\n");

  const changes = collectChangedFiles(repoRoot, detectorEnv());

  assert.equal(changes.shouldRun, true);
  assert.deepEqual(changes.relevant, ["web/assets/css/app.css"]);
  assert.ok(changes.sources.unstaged.includes("web/assets/css/app.css"));
});

test("trigger includes untracked relevant changes", () => {
  const repoRoot = makeRepo();
  writeFile(repoRoot, "web/lib/memba_web/components/new_card.ex", "defmodule NewCard do\nend\n");

  const changes = collectChangedFiles(repoRoot, detectorEnv());

  assert.equal(changes.shouldRun, true);
  assert.deepEqual(changes.relevant, ["web/lib/memba_web/components/new_card.ex"]);
  assert.ok(changes.sources.untracked.includes("web/lib/memba_web/components/new_card.ex"));
});

test("trigger ignores unrelated docs and domain changes", () => {
  const repoRoot = makeRepo();
  writeFile(repoRoot, "docs/reference/frontend-design.md", "prose\n");
  writeFile(repoRoot, "web/lib/memba_web/domain.ex", "defmodule Domain do\n  def changed, do: :ok\nend\n");

  const changes = collectChangedFiles(repoRoot, detectorEnv());

  assert.equal(changes.shouldRun, false);
  assert.deepEqual(changes.relevant, []);
});

test("trigger includes committed diff relative to CI base", () => {
  const repoRoot = makeRepo();
  const base = git(repoRoot, ["rev-parse", "HEAD"]);
  writeFile(repoRoot, "web/lib/memba_web/controllers/page_html/public_home.html.heex", "<main>Changed</main>\n");
  git(repoRoot, ["add", "web/lib/memba_web/controllers/page_html/public_home.html.heex"]);
  git(repoRoot, ["commit", "-m", "layout change"]);

  const changes = collectChangedFiles(repoRoot, detectorEnv({ CI: "true", MEMBA_RESPONSIVE_BASE_SHA: base }));

  assert.equal(changes.shouldRun, true);
  assert.deepEqual(changes.relevant, ["web/lib/memba_web/controllers/page_html/public_home.html.heex"]);
  assert.equal(changes.sources.committed.mode, "base");
  assert.ok(changes.sources.committed.files.includes("web/lib/memba_web/controllers/page_html/public_home.html.heex"));
});

test("deleted staged presentation file still runs responsive checks", () => {
  const repoRoot = makeRepo();
  git(repoRoot, ["rm", "styles.css"]);

  const changes = collectChangedFiles(repoRoot, detectorEnv());

  assert.equal(changes.shouldRun, true);
  assert.deepEqual(changes.relevant, ["styles.css"]);
  assert.ok(changes.sources.staged.includes("styles.css"));
});

test("deleted unstaged presentation file still runs responsive checks", () => {
  const repoRoot = makeRepo();
  fs.unlinkSync(path.join(repoRoot, "web/assets/css/app.css"));

  const changes = collectChangedFiles(repoRoot, detectorEnv());

  assert.equal(changes.shouldRun, true);
  assert.deepEqual(changes.relevant, ["web/assets/css/app.css"]);
  assert.ok(changes.sources.unstaged.includes("web/assets/css/app.css"));
});

test("deleted committed presentation file runs relative to CI base", () => {
  const repoRoot = makeRepo();
  const base = git(repoRoot, ["rev-parse", "HEAD"]);
  git(repoRoot, ["rm", "web/assets/css/app.css"]);
  git(repoRoot, ["commit", "-m", "delete stylesheet"]);

  const changes = collectChangedFiles(repoRoot, detectorEnv({ CI: "true", MEMBA_RESPONSIVE_BASE_SHA: base }));

  assert.equal(changes.shouldRun, true);
  assert.deepEqual(changes.relevant, ["web/assets/css/app.css"]);
  assert.ok(changes.sources.committed.files.includes("web/assets/css/app.css"));
});

test("deleted committed presentation file runs against previous local commit", () => {
  const repoRoot = makeRepo();
  git(repoRoot, ["rm", "styles.css"]);
  git(repoRoot, ["commit", "-m", "delete stylesheet"]);

  const changes = collectChangedFiles(repoRoot, detectorEnv());

  assert.equal(changes.shouldRun, true);
  assert.deepEqual(changes.relevant, ["styles.css"]);
  assert.ok(changes.sources.committed.files.includes("styles.css"));
});

test("CI with unknown base fails open instead of silently skipping", () => {
  const repoRoot = makeRepo();

  const changes = collectChangedFiles(
    repoRoot,
    detectorEnv({ CI: "true", MEMBA_RESPONSIVE_BASE_SHA: "missing-base" })
  );

  assert.equal(changes.shouldRun, true);
  assert.equal(changes.failOpen, true);
  assert.equal(changes.sources.committed.mode, "ci-unresolved-base-fail-open");
  assert.match(changes.sources.committed.explanation, /running the responsive check/);
});

test("an explicitly configured but unresolved local base fails open", () => {
  const repoRoot = makeRepo();
  const changes = collectChangedFiles(repoRoot, detectorEnv({ MEMBA_RESPONSIVE_BASE_SHA: "missing-base" }));

  assert.equal(changes.shouldRun, true);
  assert.equal(changes.failOpen, true);
  assert.equal(changes.sources.committed.mode, "unresolved-base-fail-open");
});

test("CI without a base fails open instead of silently skipping", () => {
  const repoRoot = makeRepo();

  const changes = collectChangedFiles(repoRoot, detectorEnv({ CI: "true" }));

  assert.equal(changes.shouldRun, true);
  assert.equal(changes.failOpen, true);
  assert.equal(changes.sources.committed.mode, "ci-no-base-fail-open");
  assert.match(changes.sources.committed.explanation, /running the responsive check/);
});

test("local clean committed layout changes run against the previous commit", () => {
  const repoRoot = makeRepo();
  writeFile(repoRoot, "styles.css", "body { color: green; }\n");
  git(repoRoot, ["add", "styles.css"]);
  git(repoRoot, ["commit", "-m", "style change"]);

  const changes = collectChangedFiles(repoRoot, detectorEnv());

  assert.equal(changes.shouldRun, true);
  assert.deepEqual(changes.relevant, ["styles.css"]);
});

test("responsive-check --force forwards force to the Playwright runner", () => {
  const script = fs.readFileSync(path.join(__dirname, "../../bin/dev"), "utf8");
  const commands = script.slice(script.indexOf("responsive_check() {"), script.indexOf("dev_test() {"));
  assert.ok(commands.includes("responsive_check() {") && commands.includes("_responsive_check() {"));

  const shell = `
    set -e
    repo_root=${JSON.stringify(path.resolve(__dirname, "../.."))}
    ${commands}
    with_quality_gate_lock() { local command="$1"; shift; "$command" "$@"; }
    start_postgres() { :; }
    _setup() { :; }
    local_test_email_env() { printf '%s\\n' "$@"; }
    argc_force=1
    responsive_check
  `;
  const output = execFileSync("bash", ["-c", shell], { encoding: "utf8" });
  assert.match(output, /npm\nrun\ntest:responsive\n--\n--force\n/);
});

test("a failing responsive check stops dev check before acceptance", () => {
  const script = fs.readFileSync(path.join(__dirname, "../../bin/dev"), "utf8");
  assert.ok(script.includes("responsive_check || return $?"));
  assert.ok(script.includes("node --test test/responsive_change_detector.test.js || return $?"));
});
