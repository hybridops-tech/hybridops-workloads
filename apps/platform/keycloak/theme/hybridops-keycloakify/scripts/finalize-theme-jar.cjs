#!/usr/bin/env node
const fs = require("fs");
const os = require("os");
const path = require("path");
const { execSync } = require("child_process");

const distDir = path.resolve(__dirname, "..", "dist_keycloak");
const outputJar = path.join(distDir, "hybridops-theme.jar");

if (!fs.existsSync(distDir)) {
  console.error(`dist_keycloak not found: ${distDir}`);
  process.exit(1);
}

const jars = fs
  .readdirSync(distDir)
  .filter((name) => name.endsWith(".jar"))
  .filter((name) => name !== "hybridops-theme.jar");

if (jars.length === 0) {
  console.error(`No built jar found in ${distDir}`);
  process.exit(1);
}

const sourceJar = path.join(distDir, jars[0]);
const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "hyops-theme-"));

try {
  execSync(`unzip -q "${sourceJar}" -d "${tempDir}"`, { stdio: "inherit" });

  const messagesDir = path.join(tempDir, "theme", "hybridops", "login", "messages");
  if (fs.existsSync(messagesDir)) {
    for (const name of fs.readdirSync(messagesDir)) {
      const isLocaleBundle = /^messages_[^.]+\.properties$/.test(name);
      if (isLocaleBundle && name !== "messages_en.properties") {
        fs.rmSync(path.join(messagesDir, name), { force: true });
      }
    }
  }

  const assetsDir = path.join(
    tempDir,
    "theme",
    "hybridops",
    "login",
    "resources",
    "dist",
    "assets"
  );
  if (fs.existsSync(assetsDir)) {
    for (const name of fs.readdirSync(assetsDir)) {
      const isLocaleChunk = /^[a-z]{2}(?:-[A-Z]{2})?-.*\.js$/.test(name);
      if (isLocaleChunk) {
        fs.rmSync(path.join(assetsDir, name), { force: true });
      }
    }
  }

  const defaultResourcesCommonDir = path.join(
    tempDir,
    "theme",
    "hybridops",
    "login",
    "resources",
    "resources-common"
  );
  if (fs.existsSync(defaultResourcesCommonDir)) {
    fs.rmSync(defaultResourcesCommonDir, { recursive: true, force: true });
  }

  if (fs.existsSync(outputJar)) {
    fs.rmSync(outputJar, { force: true });
  }

  execSync(`cd "${tempDir}" && zip -qr "${outputJar}" .`, { stdio: "inherit" });

  console.log(`Theme jar ready: ${outputJar}`);
} finally {
  fs.rmSync(tempDir, { recursive: true, force: true });
}
