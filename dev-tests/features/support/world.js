const {After, setWorldConstructor} = require("@cucumber/cucumber");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");

class DevBddWorld {
  constructor() {
    this.root = fs.mkdtempSync(path.join(os.tmpdir(), "memba-dev-bdd-"));
    this.toolsRoot = fs.mkdtempSync(path.join(os.tmpdir(), "memba-dev-bdd-tools-"));
    this.featurePath = path.join(this.root, "acceptance-tests/features/example.feature");
    this.commits = new Map();
    this.commandEnv = {};
  }
}

setWorldConstructor(DevBddWorld);
After(function () {
  fs.rmSync(this.root, {recursive: true, force: true});
  fs.rmSync(this.toolsRoot, {recursive: true, force: true});
});
