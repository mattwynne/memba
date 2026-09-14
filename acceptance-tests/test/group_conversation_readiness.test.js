const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const vm = require("node:vm");

const stepsPath = path.resolve(__dirname, "../features/step_definitions/group_conversation_steps.js");

for (const alreadySelected of [false, true]) {
  test(`member-list assertions wait for the current LiveView root (members selected: ${alreadySelected})`, async () => {
    let ready = false;
    let activeTab = alreadySelected ? "members" : "conversations";
    let focused = null;
    const keys = [];
    const steps = [];
    const world = { people: { Carol: { personId: "carol" } } };

    function locator(selector) {
      const tab = selector.endsWith("-members") ? "members" : "conversations";
      return {
        selector,
        async getAttribute(name) {
          assert.ok(ready, "tab state read before LiveView readiness");
          assert.equal(name, "aria-selected");
          return String(activeTab === tab);
        },
        async focus() {
          assert.ok(ready, "keyboard focus before LiveView readiness");
          focused = selector;
        },
        async press(key) {
          assert.ok(ready, "keyboard input before LiveView readiness");
          keys.push(key);
          activeTab = ["ArrowRight", "End"].includes(key) ? "members" : "conversations";
          focused = `#member-section-tab-${activeTab}`;
        },
        locator() {
          return { count: async () => 1 };
        }
      };
    }
    world.page = { locator };

    function expect(target) {
      return {
        async toBeFocused() { assert.equal(focused, target.selector); },
        async toHaveAttribute(name, value) { assert.equal(await target.getAttribute(name), value); },
        async toBeVisible() { assert.equal(activeTab, "members"); },
        async toBeHidden() { assert.equal(activeTab, "members"); }
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
    assert.deepEqual(keys, alreadySelected ? [] : ["ArrowRight", "ArrowLeft", "End", "Home", "ArrowRight"]);
  });
}
