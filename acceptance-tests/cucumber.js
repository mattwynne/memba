module.exports = {
  default: {
    paths: ["features/**/*.feature"],
    require: ["features/support/**/*.js", "features/step_definitions/**/*.js"],
    tags: "not @todo-web",
    format: ["progress"],
    publishQuiet: true
  }
};
