const fs = require("node:fs");
const path = require("node:path");

function findNixFontconfigFile(storePath = "/nix/store", fsModule = fs, pathModule = path) {
  if (!fsModule.existsSync(storePath)) {
    return null;
  }

  return fsModule
    .readdirSync(storePath)
    .filter((entry) => /fontconfig-\d/.test(entry))
    .map((entry) => pathModule.join(storePath, entry, "etc", "fonts", "fonts.conf"))
    .find((candidate) => fsModule.existsSync(candidate)) || null;
}

function configureBrowserEnvironment(env = process.env) {
  if (process.platform !== "linux" || env.FONTCONFIG_FILE) {
    return env;
  }

  const fontconfigFile = findNixFontconfigFile();

  if (fontconfigFile) {
    env.FONTCONFIG_FILE = fontconfigFile;
    env.FONTCONFIG_PATH = path.dirname(fontconfigFile);
  }

  return env;
}

module.exports = {
  configureBrowserEnvironment,
  findNixFontconfigFile
};
