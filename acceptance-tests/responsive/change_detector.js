const { execFileSync } = require("node:child_process");

const baseEnvKeys = [
  "MEMBA_RESPONSIVE_BASE_SHA",
  "MEMBA_RESPONSIVE_BASE_REF",
  "CI_MERGE_REQUEST_TARGET_BRANCH_SHA",
  "CI_MERGE_REQUEST_TARGET_BRANCH_NAME",
  "GITHUB_BASE_REF",
  "BUILDKITE_PULL_REQUEST_BASE_BRANCH"
];

function normalizePath(filePath) {
  return String(filePath || "").replace(/\\/g, "/").replace(/^\.\//, "");
}

function isRelevantResponsivePath(filePath) {
  const path = normalizePath(filePath);

  if (path === "styles.css") {
    return true;
  }

  if (path.startsWith("web/assets/css/") && !path.endsWith("/")) {
    return true;
  }

  if (path.startsWith("web/assets/vendor/") && path.endsWith(".js")) {
    return true;
  }

  if (path.startsWith("web/assets/js/") && /\.m?js$/.test(path)) {
    return true;
  }

  if (
    path.startsWith("acceptance-tests/responsive/") ||
    path.startsWith("acceptance-tests/gallery/") ||
    [
      "acceptance-tests/package.json",
      "acceptance-tests/package-lock.json",
      "acceptance-tests/features/support/browser_environment.js",
      "acceptance-tests/features/support/lifecycle.js",
      "bin/dev"
    ].includes(path)
  ) {
    return true;
  }

  if (!path.startsWith("web/lib/memba_web/")) {
    return false;
  }

  if (path.endsWith(".heex")) {
    return true;
  }

  if (!path.endsWith(".ex")) {
    return false;
  }

  return (
    path.includes("/components/") ||
    path.includes("/live/") ||
    /_html\.ex$/.test(path) ||
    /_components\.ex$/.test(path) ||
    /_presentation\.ex$/.test(path)
  );
}

function uniqueSorted(values) {
  return [...new Set(values.filter(Boolean).map(normalizePath))].sort();
}

function parseNullSeparated(output) {
  if (!output) {
    return [];
  }

  return output
    .split("\0")
    .map((entry) => entry.trim())
    .filter(Boolean);
}

function git(repoRoot, args, options = {}) {
  return execFileSync("git", ["-C", repoRoot, ...args], {
    encoding: "utf8",
    stdio: ["ignore", "pipe", options.ignoreErrors ? "ignore" : "pipe"]
  });
}

function gitMaybe(repoRoot, args) {
  try {
    return git(repoRoot, args, { ignoreErrors: true });
  } catch (_error) {
    return null;
  }
}

function gitFiles(repoRoot, args) {
  return parseNullSeparated(git(repoRoot, args));
}

function gitFilesMaybe(repoRoot, args) {
  const output = gitMaybe(repoRoot, args);
  return output === null ? [] : parseNullSeparated(output);
}

function resolveBaseCandidate(env = process.env) {
  for (const key of baseEnvKeys) {
    const value = env[key];
    if (value && value !== "0000000000000000000000000000000000000000") {
      return { key, value };
    }
  }

  return null;
}

function ciEnabled(env = process.env) {
  return [env.CI, env.GITHUB_ACTIONS, env.GITLAB_CI, env.BUILDKITE].some((value) => {
    const normalized = String(value || "").toLowerCase();
    return normalized === "1" || normalized === "true" || normalized === "yes";
  });
}

function committedDiffFiles(repoRoot, env = process.env) {
  const candidate = resolveBaseCandidate(env);

  if (!candidate) {
    if (ciEnabled(env)) {
      return {
        files: [],
        failOpen: true,
        mode: "ci-no-base-fail-open",
        explanation:
          "CI did not provide a responsive-check base ref; running the responsive check rather than silently skipping a relevant committed change."
      };
    }

    const previousCommit = gitMaybe(repoRoot, ["rev-parse", "HEAD^"]);

    if (!previousCommit || !previousCommit.trim()) {
      return {
        files: [],
        failOpen: true,
        mode: "local-no-base-fail-open",
        explanation: "No base or previous commit is available; running rather than skipping an unknown committed change."
      };
    }

    return {
      files: gitFiles(repoRoot, [
        "diff", "--name-only", "-z", "--diff-filter=ACDMRTUXB", previousCommit.trim(), "HEAD"
      ]),
      failOpen: false,
      mode: "previous-commit",
      base: previousCommit.trim(),
      explanation: "Checked local committed changes from the previous commit to HEAD."
    };
  }

  const mergeBase = gitMaybe(repoRoot, ["merge-base", candidate.value, "HEAD"]);

  if (!mergeBase || !mergeBase.trim()) {
    if (ciEnabled(env)) {
      return {
        files: [],
        failOpen: true,
        mode: "ci-unresolved-base-fail-open",
        explanation:
          `CI base ${candidate.key}=${candidate.value} could not be resolved; running the responsive check rather than silently skipping a relevant committed change.`
      };
    }

    return {
      files: [],
      failOpen: true,
      mode: "unresolved-base-fail-open",
      explanation: `Base ${candidate.key}=${candidate.value} could not be resolved; running rather than silently skipping a relevant committed change.`
    };
  }

  const base = mergeBase.trim();

  return {
    files: gitFiles(repoRoot, [
      "diff",
      "--name-only",
      "-z",
      "--diff-filter=ACDMRTUXB",
      base,
      "HEAD"
    ]),
    failOpen: false,
    mode: "base",
    base,
    source: candidate,
    explanation: `Checked committed diff from ${candidate.key}=${candidate.value} (merge-base ${base}) to HEAD.`
  };
}

function collectChangedFiles(repoRoot, env = process.env) {
  const staged = gitFiles(repoRoot, [
    "diff",
    "--cached",
    "--name-only",
    "-z",
    "--diff-filter=ACDMRTUXB"
  ]);
  const unstaged = gitFiles(repoRoot, [
    "diff",
    "--name-only",
    "-z",
    "--diff-filter=ACDMRTUXB"
  ]);
  const untracked = gitFiles(repoRoot, ["ls-files", "--others", "--exclude-standard", "-z"]);
  const committed = committedDiffFiles(repoRoot, env);
  const all = uniqueSorted([...staged, ...unstaged, ...untracked, ...committed.files]);
  const relevant = all.filter(isRelevantResponsivePath);
  const failOpen = committed.failOpen === true;

  return {
    all,
    relevant,
    shouldRun: failOpen || relevant.length > 0,
    failOpen,
    sources: {
      staged: uniqueSorted(staged),
      unstaged: uniqueSorted(unstaged),
      untracked: uniqueSorted(untracked),
      committed: {
        ...committed,
        files: uniqueSorted(committed.files)
      }
    }
  };
}

module.exports = {
  baseEnvKeys,
  ciEnabled,
  collectChangedFiles,
  committedDiffFiles,
  isRelevantResponsivePath,
  normalizePath,
  parseNullSeparated,
  resolveBaseCandidate,
  uniqueSorted
};
