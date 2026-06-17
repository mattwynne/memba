#!/usr/bin/env node

const fs = require("node:fs");
const path = require("node:path");

const repoRoot = path.resolve(__dirname, "../..");
const galleryDir = path.join(repoRoot, "tmp", "gallery");
const manifestPath = path.join(galleryDir, "manifest.json");
const outputPath = path.join(galleryDir, "gallery.html");

function readManifest() {
  if (!fs.existsSync(manifestPath)) {
    throw new Error(`Gallery manifest not found: ${path.relative(repoRoot, manifestPath)}`);
  }

  const parsed = JSON.parse(fs.readFileSync(manifestPath, "utf8"));

  if (!Array.isArray(parsed)) {
    throw new Error("Gallery manifest must be a JSON array.");
  }

  for (const [index, entry] of parsed.entries()) {
    for (const field of ["area", "id", "label", "viewport", "file"]) {
      if (typeof entry[field] !== "string" || entry[field].trim() === "") {
        throw new Error(`Gallery manifest entry ${index} is missing string field '${field}'.`);
      }
    }
  }

  return parsed;
}

function htmlEscape(value) {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function scriptJson(value) {
  return JSON.stringify(value).replace(/</g, "\\u003c");
}

function renderHtml(manifest) {
  const generatedAt = new Date().toISOString();
  const appCount = manifest.filter((entry) => entry.area === "app").length;
  const emailCount = manifest.filter((entry) => entry.area === "emails").length;

  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Memba gallery walk</title>
  <style>
    :root {
      color-scheme: light;
      --ink: #17211d;
      --muted: #60706a;
      --line: #d9e0dc;
      --panel: #ffffff;
      --paper: #f5f7f4;
      --accent: #1f7a5b;
      --accent-ink: #ffffff;
      --shadow: 0 12px 32px rgba(28, 43, 37, 0.10);
    }

    * {
      box-sizing: border-box;
    }

    body {
      margin: 0;
      background: var(--paper);
      color: var(--ink);
      font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      line-height: 1.45;
    }

    header {
      position: sticky;
      top: 0;
      z-index: 10;
      border-bottom: 1px solid var(--line);
      background: rgba(245, 247, 244, 0.94);
      backdrop-filter: blur(12px);
    }

    .bar,
    main {
      width: min(1440px, calc(100vw - 32px));
      margin: 0 auto;
    }

    .bar {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
      min-height: 72px;
    }

    h1,
    h2,
    h3,
    p {
      margin: 0;
    }

    h1 {
      font-size: 22px;
      font-weight: 720;
    }

    .meta {
      color: var(--muted);
      font-size: 13px;
    }

    .toolbar {
      display: flex;
      align-items: center;
      gap: 10px;
      flex-wrap: wrap;
      justify-content: flex-end;
    }

    .toggle {
      display: inline-grid;
      grid-template-columns: 1fr 1fr;
      min-width: 190px;
      padding: 3px;
      border: 1px solid var(--line);
      border-radius: 8px;
      background: #eef2ee;
    }

    .toggle button {
      border: 0;
      border-radius: 6px;
      padding: 8px 12px;
      background: transparent;
      color: var(--muted);
      font: inherit;
      font-size: 14px;
      cursor: pointer;
    }

    .toggle button[aria-pressed="true"] {
      background: var(--accent);
      color: var(--accent-ink);
      box-shadow: 0 1px 2px rgba(0, 0, 0, 0.10);
    }

    main {
      padding: 26px 0 56px;
    }

    section + section {
      margin-top: 40px;
    }

    .section-heading {
      display: flex;
      align-items: end;
      justify-content: space-between;
      gap: 16px;
      margin-bottom: 14px;
    }

    h2 {
      font-size: 18px;
      font-weight: 720;
    }

    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(min(100%, 420px), 1fr));
      gap: 18px;
      align-items: start;
    }

    .card {
      overflow: hidden;
      border: 1px solid var(--line);
      border-radius: 8px;
      background: var(--panel);
      box-shadow: var(--shadow);
    }

    .card-head {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      min-height: 58px;
      padding: 13px 14px;
      border-bottom: 1px solid var(--line);
    }

    h3 {
      min-width: 0;
      overflow-wrap: anywhere;
      font-size: 15px;
      font-weight: 680;
    }

    .badge {
      flex: none;
      border: 1px solid var(--line);
      border-radius: 999px;
      padding: 4px 9px;
      color: var(--muted);
      font-size: 12px;
      text-transform: capitalize;
    }

    .shot-wrap {
      overflow: auto;
      background: #e9eeeb;
    }

    .shot {
      display: block;
      width: 100%;
      height: auto;
      background: #ffffff;
    }

    .missing {
      padding: 28px;
      color: var(--muted);
      font-size: 14px;
    }

    @media (max-width: 720px) {
      .bar,
      main {
        width: min(100vw - 20px, 1440px);
      }

      .bar,
      .section-heading {
        align-items: stretch;
        flex-direction: column;
      }

      .bar {
        justify-content: center;
        padding: 12px 0;
      }

      .toolbar {
        justify-content: stretch;
      }

      .toggle {
        width: 100%;
      }
    }
  </style>
</head>
<body>
  <header>
    <div class="bar">
      <div>
        <h1>Memba gallery walk</h1>
        <p class="meta">${htmlEscape(appCount)} app screenshots, ${htmlEscape(emailCount)} email screenshots. Generated ${htmlEscape(generatedAt)}.</p>
      </div>
      <div class="toolbar">
        <div class="toggle" role="group" aria-label="App screenshot viewport">
          <button type="button" data-viewport-button="desktop" aria-pressed="true">Desktop</button>
          <button type="button" data-viewport-button="mobile" aria-pressed="false">Mobile</button>
        </div>
      </div>
    </div>
  </header>
  <main>
    <section aria-labelledby="app-heading">
      <div class="section-heading">
        <div>
          <h2 id="app-heading">App</h2>
          <p class="meta">Each scene groups its desktop and mobile capture.</p>
        </div>
      </div>
      <div id="app-grid" class="grid"></div>
    </section>

    <section aria-labelledby="emails-heading">
      <div class="section-heading">
        <div>
          <h2 id="emails-heading">Emails</h2>
          <p class="meta">Mailbox previews captured after the gallery seed.</p>
        </div>
      </div>
      <div id="email-grid" class="grid"></div>
    </section>
  </main>

  <script>
    const manifest = ${scriptJson(manifest)};

    function groupedById(entries) {
      const groups = new Map();
      for (const entry of entries) {
        if (!groups.has(entry.id)) {
          groups.set(entry.id, { id: entry.id, label: entry.label, shots: new Map() });
        }
        groups.get(entry.id).shots.set(entry.viewport, entry);
      }
      return Array.from(groups.values());
    }

    function element(tag, attributes = {}, children = []) {
      const node = document.createElement(tag);
      for (const [name, value] of Object.entries(attributes)) {
        if (value === false || value === null || value === undefined) {
          continue;
        }
        if (name === "className") {
          node.className = value;
        } else {
          node.setAttribute(name, value);
        }
      }
      for (const child of children) {
        node.append(child);
      }
      return node;
    }

    function renderApp(viewport) {
      const grid = document.querySelector("#app-grid");
      grid.replaceChildren();

      for (const scene of groupedById(manifest.filter((entry) => entry.area === "app"))) {
        const shot = scene.shots.get(viewport) || scene.shots.get("desktop") || scene.shots.values().next().value;
        const card = element("article", { className: "card" }, [
          element("div", { className: "card-head" }, [
            element("h3", {}, [scene.label]),
            element("span", { className: "badge" }, [shot ? shot.viewport : "missing"])
          ])
        ]);

        if (shot) {
          card.append(element("div", { className: "shot-wrap" }, [
            element("img", {
              className: "shot",
              src: shot.file,
              alt: scene.label + " " + shot.viewport + " screenshot",
              loading: "lazy"
            })
          ]));
        } else {
          card.append(element("p", { className: "missing" }, ["No screenshot found for this scene."]));
        }

        grid.append(card);
      }
    }

    function renderEmails() {
      const grid = document.querySelector("#email-grid");
      const emails = manifest.filter((entry) => entry.area === "emails");
      grid.replaceChildren(...emails.map((entry) => element("article", { className: "card" }, [
        element("div", { className: "card-head" }, [
          element("h3", {}, [entry.label]),
          element("span", { className: "badge" }, [entry.viewport])
        ]),
        element("div", { className: "shot-wrap" }, [
          element("img", {
            className: "shot",
            src: entry.file,
            alt: entry.label + " email screenshot",
            loading: "lazy"
          })
        ])
      ])));
    }

    function setViewport(viewport) {
      for (const button of document.querySelectorAll("[data-viewport-button]")) {
        button.setAttribute("aria-pressed", String(button.dataset.viewportButton === viewport));
      }
      renderApp(viewport);
    }

    for (const button of document.querySelectorAll("[data-viewport-button]")) {
      button.addEventListener("click", () => setViewport(button.dataset.viewportButton));
    }

    renderEmails();
    setViewport("desktop");
  </script>
</body>
</html>
`;
}

function main() {
  const manifest = readManifest();
  fs.mkdirSync(galleryDir, { recursive: true });
  fs.writeFileSync(outputPath, renderHtml(manifest));
  process.stdout.write(`Wrote ${path.relative(repoRoot, outputPath)}\n`);
}

try {
  main();
} catch (error) {
  process.stderr.write(`${error.stack || error.message}\n`);
  process.exitCode = 1;
}
