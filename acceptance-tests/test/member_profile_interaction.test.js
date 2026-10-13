const assert = require("node:assert/strict");
const { test, before, after } = require("node:test");
const { chromium } = require("playwright");
const { expect } = require("@playwright/test");
const { createBrowserAcceptanceLifecycle } = require("../features/support/lifecycle");
const { configureBrowserEnvironment } = require("../features/support/browser_environment");
const { ensureMember, signInDirectly, openClubPage, kootenayClubName } = require("../features/support/authentication");
const { runCommand } = require("../features/support/server_commands");
const lifecycle = createBrowserAcceptanceLifecycle();
let browser;

before(async () => {
  configureBrowserEnvironment();
  await lifecycle.start();
  browser = await chromium.launch({ headless: true });
});
after(async () => {
  if (browser) await browser.close();
  await lifecycle.stop();
});

async function edit(page) {
  await page.locator("#my-settings-edit-name").click();
  await expect(page.getByLabel("Your name", { exact: true })).toBeVisible();
}
async function save(page, name) {
  await page.getByLabel("Your name", { exact: true }).fill(name);
  await page.locator("#my-settings-save-name").click();
  await expect(page.locator("#my-settings-name-form")).toHaveCount(0);
}

for (const width of [390, 1320]) {
  test(`connected conflict, consent, focus and errors at ${width}px`, { timeout: 120000 }, async () => {
    const context = await browser.newContext({ viewport: { width, height: 1000 } });
    try {
      const page = await context.newPage();
      const world = { browser, context, page, baseUrl: lifecycle.baseUrl };
      const reset = await context.request.post(new URL("/dev/test-support/reset", world.baseUrl).toString());
      assert.equal(reset.status(), 204);
      await ensureMember(world, "Alice Smith", kootenayClubName);
      await signInDirectly(world, "Alice Smith");
      await openClubPage(world, kootenayClubName);
      await expect(page.locator(".phx-connected #club-site-identity-menu-button")).toBeVisible();
      await page.locator("#club-site-identity-menu-button").click();
      await page.locator("#club-site-account-settings-link").click();
      await expect(page.locator(".phx-connected #my-settings")).toBeVisible();
      const other = await context.newPage();
      await other.goto(page.url());
      await expect(other.locator(".phx-connected #my-settings")).toBeVisible();
      await edit(page);
      await edit(other);
      const input = page.getByLabel("Your name", { exact: true });
      // LiveView normally preserves a focused input, even if it is untouched.
      await input.focus();
      await save(other, "Robin Jones");
      await expect(input).toHaveValue("Robin Jones");
      await expect(input).toBeFocused();
      await input.press("Enter");
      await expect(page.locator("#my-settings-name-form")).toHaveCount(0);
      await expect(page.locator("#my-settings-profile-name")).toHaveText("Robin Jones");
      await edit(page);
      await input.fill("Not saved");
      await edit(other);
      await save(other, "Alice Smith");
      await expect(input).toHaveValue("Not saved");
      await input.fill(" Robin   Jones ");
      await expect(input).toHaveValue("Alice Smith");
      // Hold only this input's change event until blur. Both remote patches
      // therefore reach the real LiveView before this local draft does.
      await input.evaluate(el => el.setAttribute("phx-debounce", "blur"));
      await input.fill("Alice Brown");
      await edit(other);
      await save(other, "Alice Brown");
      await edit(other);
      await save(other, "Alice Jones");
      await expect(page.locator("#my-settings-profile-name")).toHaveText("Alice Jones");
      await expect(input).toHaveValue("Alice Brown");
      await expect(input).toBeFocused();
      await input.press("Enter");
      const warning = page.locator("#my-settings-name-conflict");
      await expect(warning).toContainText("Changed elsewhere to “Alice Jones”.");
      await expect(input).toHaveValue("Alice Brown");
      await expect(warning).toHaveAttribute("role", "alert");
      await expect(warning).toBeFocused();
      await input.evaluate(el => el.removeAttribute("phx-debounce"));
      await page.keyboard.press("Enter");
      await expect(warning).toBeVisible();
      await expect(page.locator("#my-settings-profile-name")).toHaveText("Alice Jones");
      await page.locator("#my-settings-save-name").click();
      await expect(warning).toContainText("Alice Jones");
      await expect(warning).toBeFocused();
      await edit(other);
      await save(other, "Alice Green");
      await expect(page.locator("#my-settings-profile-name")).toHaveText("Alice Green");
      await expect(warning).toContainText("Alice Jones");
      await page.locator("#my-settings-name-save-anyway").click();
      await expect(warning).toContainText("Alice Green");
      await expect(warning).toBeFocused();
      await expect(input).toHaveValue("Alice Brown");
      await input.fill("Alice Blue");
      await expect(warning).toHaveCount(0);
      await input.press("Enter");
      await expect(warning).toContainText("Alice Green");
      assert.equal(await page.evaluate(() => document.documentElement.scrollWidth > innerWidth), false);
      await page.locator("#my-settings-name-cancel-changes").click();
      await expect(page.locator("#my-settings-edit-name")).toBeFocused();
      await expect(page.locator("#my-settings-profile-name")).toHaveText("Alice Green");
      await edit(page);
      await input.fill("Alice Brown");
      await edit(other);
      await save(other, "Alice Jones");
      await input.press("Enter");
      await expect(warning).toContainText("Alice Jones");
      await page.locator("#my-settings-name-save-anyway").click();
      await expect(page.locator("#my-settings-profile-name")).toHaveText("Alice Brown");
      await expect(page.locator("#my-settings-name-form")).toHaveCount(0);
      await edit(page);
      await input.fill("   ");
      await input.press("Enter");
      await expect(input).toHaveValue("   ");
      await expect(input).toHaveAttribute("aria-invalid", "true");
      await expect(input).toHaveAttribute("aria-describedby", /my-settings-name-error/);
      await expect(page.locator("#my-settings-name-error")).toHaveText("Enter the name your clubs should see.");
      await input.fill("界".repeat(101));
      await input.press("Enter");
      await expect(page.locator("#my-settings-name-error")).toHaveText("That name is too long.");
      assert.equal(await input.getAttribute("maxlength"), null);
      assert.equal(await page.evaluate(() => document.documentElement.scrollWidth > innerWidth), false);
      await page.locator("#my-settings-cancel-name").click();
      await expect(page.locator("#my-settings-edit-name")).toBeFocused();
      await expect(page.locator("#my-settings-profile-name")).toHaveText("Alice Brown");
      await edit(page);
      await save(page, "界".repeat(100));
      await expect(page.locator("#my-settings-profile-name")).toHaveText("界".repeat(100));
      assert.equal(await page.evaluate(() => document.documentElement.scrollWidth > innerWidth), false);
    } finally {
      await context.close();
    }
  });

  test(`saved unbroken 100-character name keeps Edit inside the visible card at ${width}px`, { timeout: 120000 }, async () => {
    const context = await browser.newContext({ viewport: { width, height: 1000 } });
    try {
      const page = await context.newPage();
      const world = { browser, context, page, baseUrl: lifecycle.baseUrl };
      assert.equal((await context.request.post(new URL("/dev/test-support/reset", world.baseUrl).toString())).status(), 204);
      await ensureMember(world, "Alice Smith", kootenayClubName);
      await signInDirectly(world, "Alice Smith");
      await openClubPage(world, kootenayClubName);
      await expect(page.locator(".phx-connected #club-site-identity-menu-button")).toBeVisible();
      await page.locator("#club-site-identity-menu-button").click();
      await page.locator("#club-site-account-settings-link").click();
      await expect(page.locator(".phx-connected #my-settings")).toBeVisible();
      const name = "W".repeat(100);
      await edit(page);
      await save(page, name);
      await expect(page.locator("#my-settings-profile-name")).toHaveText(name);
      const card = page.locator("#my-settings-profile-card");
      await card.scrollIntoViewIfNeeded();
      const bounds = await page.locator("#my-settings-edit-name").evaluate(button => {
        const card = button.closest("#my-settings-profile-card").getBoundingClientRect();
        const edit = button.getBoundingClientRect();
        return {
          card: { left: card.left, right: card.right, top: card.top, bottom: card.bottom },
          edit: { left: edit.left, right: edit.right, top: edit.top, bottom: edit.bottom },
          viewport: { width: innerWidth, height: innerHeight },
          styles: {
            rowDisplay: getComputedStyle(button.parentElement).display,
            cardOverflow: getComputedStyle(button.closest("#my-settings-profile-card")).overflow,
            nameMinWidth: getComputedStyle(document.querySelector("#my-settings-profile-name")).minWidth,
            nameOverflowWrap: getComputedStyle(document.querySelector("#my-settings-profile-name")).overflowWrap
          }
        };
      });
      console.info(`Saved maximum ASCII name at ${width}px: ${JSON.stringify(bounds)}`);
      assert.ok(bounds.edit.right > bounds.edit.left && bounds.edit.bottom > bounds.edit.top);
      assert.ok(bounds.edit.left >= Math.max(bounds.card.left, 0)
        && bounds.edit.right <= Math.min(bounds.card.right, bounds.viewport.width)
        && bounds.edit.top >= Math.max(bounds.card.top, 0)
        && bounds.edit.bottom <= Math.min(bounds.card.bottom, bounds.viewport.height),
      `Edit must be entirely inside the visible card: ${JSON.stringify(bounds)}`);
      assert.equal(await page.evaluate(() => document.documentElement.scrollWidth > innerWidth), false);
      // A bounded rectangle alone is not proof that the saved name is editable.
      await edit(page);
      await expect(page.getByLabel("Your name", { exact: true })).toHaveValue(name);
    } finally {
      await context.close();
    }
  });

  test(`untouched stale Save never confirms an undisplayed draft at ${width}px`, { timeout: 120000 }, async () => {
    const context = await browser.newContext({ viewport: { width, height: 1000 } });
    const projector = `
{_child, pid, :worker, _modules} =
  Enum.find(Supervisor.which_children(Memba.Supervisor), fn
    {{Memba.Membership.Projectors.Person, _opts}, pid, :worker, _modules} -> is_pid(pid)
    _ -> false
  end)
`;
    try {
      const page = await context.newPage();
      const world = { browser, context, page, baseUrl: lifecycle.baseUrl };
      assert.equal((await context.request.post(new URL("/dev/test-support/reset", world.baseUrl).toString())).status(), 204);
      await ensureMember(world, "Alice Smith", kootenayClubName);
      await signInDirectly(world, "Alice Smith");
      await openClubPage(world, kootenayClubName);
      await expect(page.locator(".phx-connected #club-site-identity-menu-button")).toBeVisible();
      await page.locator("#club-site-identity-menu-button").click();
      await page.locator("#club-site-account-settings-link").click();
      await expect(page.locator(".phx-connected #my-settings")).toBeVisible();
      await edit(page);
      const input = page.getByLabel("Your name", { exact: true });
      try {
        runCommand(`${projector}
:ok = :sys.suspend(pid)
{:ok, command} = Memba.Membership.PersonCommands.prepare_rename(
  %{person_id: payload["personId"]},
  %{person_id: payload["personId"], name: "Alice Jones", expected_name: "Alice Smith"})
:ok = Memba.Membership.CommandDispatch.dispatch(command, consistency: :eventual)
%{suspended: true}
`, { personId: world.people["Alice Smith"].personId });
        await input.press("Enter");
        await expect(page.locator("#my-settings-name-conflict")).toContainText("Alice Jones");
        await expect(input).toHaveValue("Alice Smith");
      } finally {
        runCommand(`${projector}
:ok = :sys.resume(pid)
Memba.ProjectionBarrier.await!([Memba.Membership.Projectors.Person])
%{resumed: true}
`, {});
      }
      await expect(page.locator("#my-settings-profile-name")).toHaveText("Alice Jones");
      await expect(input).toHaveValue("Alice Smith");
      await page.locator("#my-settings-name-save-anyway").click();
      await expect(page.locator("#my-settings-profile-name")).toHaveText("Alice Smith");
      await expect(page.locator("#my-settings-name-form")).toHaveCount(0);
    } finally {
      await context.close();
    }
  });
}
