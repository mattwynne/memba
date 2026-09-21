const assert = require("node:assert/strict");
const test = require("node:test");

const { signOut } = require("../features/support/authentication");

test("club sign-out waits for the identity menu to reveal its sign-out button", async () => {
  let menuOpen = false;
  let signOutClicked = false;
  const calls = [];

  const identityMenuButton = {
    async isVisible() {
      return true;
    },
    async click() {
      menuOpen = true;
      calls.push("open identity menu");
    }
  };

  const clubSignOutButton = {
    async waitFor(options) {
      calls.push(`wait for sign-out button: ${options.state}`);
      assert.equal(menuOpen, true);
    },
    async click() {
      signOutClicked = true;
      calls.push("club sign out");
    }
  };

  const page = {
    locator(selector) {
      if (selector === "#club-site-identity-menu-button") {
        return identityMenuButton;
      }

      if (selector === "#club-site-sign-out-button") {
        return clubSignOutButton;
      }

      throw new Error(`Unexpected locator: ${selector}`);
    },
    getByRole() {
      throw new Error("The generic sign-out button should not be used on a club page");
    }
  };

  await signOut({ page });

  assert.equal(signOutClicked, true);
  assert.deepEqual(calls, [
    "open identity menu",
    "wait for sign-out button: visible",
    "club sign out"
  ]);
});
