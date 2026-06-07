module.exports = {
  default: {
    paths: ["features/**/*.feature"],
    require: ["features/support/**/*.js", "features/step_definitions/**/*.js"],
    tags: "not @not-ui and not @todo-ui",
    format: ["pretty"],
    publishQuiet: true
  }
};
