module.exports = {
  default: {
    paths: ["features/**/*.feature"],
    require: ["features/support/**/*.js", "features/step_definitions/**/*.js"],
    tags: "not @todo-web and not @wip",
    format: ["progress"],
    publishQuiet: true
  }
};
