const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const vm = require("node:vm");

const stepsPath = path.resolve(__dirname, "../features/step_definitions/group_conversation_steps.js");

for (const alreadySelected of [false, true]) {
  test(`member-list assertions wait for the current LiveView root (members selected: ${alreadySelected})`, async () => {
    let ready = false;
    let activeSection = alreadySelected ? "members" : "conversations";
    let clickedMembers = false;
    const steps = [];
    const world = { people: { Carol: { personId: "carol" } } };

    function locator(selector) {
      return {
        selector,
        async getAttribute(name) {
          assert.ok(ready, "navigation state read before LiveView readiness");

          if (name === "aria-current") {
            return selector.endsWith("-members") && activeSection === "members"
              ? "page"
              : selector.endsWith("-conversations") && activeSection === "conversations"
                ? "page"
                : null;
          }

          if (name === "role" || name === "tabindex") return null;

          throw new Error(`Unexpected attribute ${name}`);
        },
        async click() {
          assert.ok(ready, "section link clicked before LiveView readiness");
          assert.equal(selector, "#member-section-tab-members");
          clickedMembers = true;
          activeSection = "members";
        },
        locator() {
          return { count: async () => 1 };
        }
      };
    }
    world.page = { locator };

    function expect(target) {
      return {
        not: {
          async toHaveAttribute(name, value) {
            assert.notEqual(await target.getAttribute(name), value);
          }
        },
        async toHaveAttribute(name, value) {
          assert.equal(await target.getAttribute(name), value);
        },
        async toBeVisible() {
          if (target.selector === "#member-section-panel-members") {
            assert.equal(activeSection, "members");
          }
        },
        async toBeHidden() {
          assert.equal(target.selector, "#member-section-panel-conversations");
          assert.equal(activeSection, "members");
        }
      };
    }

    const dependencies = {
      "node:assert/strict": assert,
      "@cucumber/cucumber": {
        Given() {},
        When() {},
        Then(pattern, action) { steps.push({ pattern, action }); }
      },
      "@playwright/test": { expect },
      "../support/member_message": {
        ensureState() {},
        async waitForLiveViewConnected(member) {
          assert.equal(member, world);
          ready = true;
        }
      },
      "../support/member_harness": {
        async withMemberHarness(currentWorld, viewer, action) {
          assert.equal(currentWorld, world);
          assert.equal(viewer, "Bob");
          await action(world);
        }
      },
      "../support/membership_administration": {},
      "../support/server_commands": {}
    };
    vm.runInNewContext(fs.readFileSync(stepsPath, "utf8"), {
      require(name) {
        assert.ok(Object.hasOwn(dependencies, name), `Unexpected dependency ${name}`);
        return dependencies[name];
      }
    }, { filename: stepsPath });

    const step = steps.find(({ pattern }) => pattern.test("Bob should see Carol in the member list"));
    assert.ok(step);
    await step.action.call(world, "Bob", "Carol");
    assert.equal(ready, true);
    assert.equal(clickedMembers, !alreadySelected);
  });
}

for (const clickNavigates of [false, true]) {
  test(`group selection ${clickNavigates ? "uses the rail click" : "fails when the rail click does not navigate"}`, async () => {
    const steps = [];
    const selected = {
      groupName: "Everyone",
      groupId: "everyone-id",
      url: "http://kmc.clubs.memba.io/conversations"
    };
    let forcedNavigations = 0;
    const world = {
      groups: { "Kootenay Mountaineering Club:Board": "board-id" },
      page: {
        url: () => selected.url,
        async goto(url) {
          forcedNavigations += 1;
          selected.url = url;
          selected.groupName = "Board";
          selected.groupId = "board-id";
        },
        locator(selector) {
          return {
            selector,
            async getAttribute(name) {
              if (name === "data-group-id") return "board-id";
              if (name === "href") return "/groups/board-id";
              throw new Error(`Unexpected attribute ${name}`);
            },
            async click() {
              assert.match(selector, /member-group-rail/);
              if (clickNavigates) {
                selected.url = "http://kmc.clubs.memba.io/groups/board-id";
                selected.groupName = "Board";
                selected.groupId = "board-id";
              }
            }
          };
        }
      }
    };

    const dependencies = {
      "node:assert/strict": assert,
      "@cucumber/cucumber": {
        When(pattern, action) { steps.push({ pattern, action }); },
        Then() {}
      },
      "@playwright/test": {
        expect(target) {
          return {
            async toBeVisible() {},
            async toHaveURL(value) {
              assert.equal(target, world.page);
              assert.equal(selected.url, value);
            },
            async toHaveText(value) {
              assert.equal(target.selector, "#member-group-name");
              assert.equal(selected.groupName, value);
            },
            async toHaveAttribute(name, value) {
              assert.equal(target.selector, "#member-club-home");
              assert.equal(name, "data-selected-group-id");
              assert.equal(selected.groupId, value);
            }
          };
        }
      },
      "../support/member_message": {
        kootenayClubName: "Kootenay Mountaineering Club",
        async openMemberClubHome() {}
      },
      "../support/member_harness": {
        async withMemberHarness(currentWorld, viewer, action) {
          assert.equal(currentWorld, world);
          assert.equal(viewer, "Eve");
          await action(world);
        }
      },
      "../support/server_commands": {}
    };

    vm.runInNewContext(fs.readFileSync(stepsPath, "utf8"), {
      URL,
      require(name) {
        assert.ok(Object.hasOwn(dependencies, name), `Unexpected dependency ${name}`);
        return dependencies[name];
      }
    }, { filename: stepsPath });

    const step = steps.find(({ pattern }) => pattern.test("Eve selects the Board group"));
    assert.ok(step);
    if (clickNavigates) {
      await step.action.call(world, "Eve", "Board");
    } else {
      await assert.rejects(step.action.call(world, "Eve", "Board"), { name: "AssertionError" });
    }
    assert.equal(forcedNavigations, 0, "the step must not navigate directly after clicking");
  });
}
