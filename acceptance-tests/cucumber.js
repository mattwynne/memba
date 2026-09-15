module.exports = {
  default: {
    // Let Cucumber discover features by default. Configured paths are merged
    // with CLI paths, which would turn a focused run back into a suite run.
    require: ["features/support/**/*.js", "features/step_definitions/**/*.js"],
    tags: "not @not-ui and not @todo-ui",
    format: ["pretty"],
    publishQuiet: true
  }
};
