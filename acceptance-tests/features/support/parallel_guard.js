function assertAcceptanceParallelDisabled(env = process.env) {
  if (env.CUCUMBER_PARALLEL === "true") {
    throw new Error(
      [
        "Acceptance tests cannot run with Cucumber parallel workers yet.",
        "The browser acceptance harness shares one Phoenix app, test database, reset endpoint, mailbox, and provider configuration across scenarios.",
        "Running with --parallel would make scenarios race over that shared global state.",
        "Remove --parallel, or implement scenario-scoped isolation before enabling parallel acceptance tests."
      ].join(" ")
    );
  }
}

module.exports = {
  assertAcceptanceParallelDisabled
};
