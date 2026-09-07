const assert = require("node:assert/strict");
const path = require("node:path");
const { pathToFileURL } = require("node:url");
const test = require("node:test");

const hookModule = import(
  pathToFileURL(path.resolve(__dirname, "../../web/assets/js/remember_group_selection.mjs")).href
);

test("selection storage keys are scoped by club", async () => {
  const { groupSelectionStorageKey } = await hookModule;

  assert.equal(
    groupSelectionStorageKey("club-123"),
    "memba:lastGroup:club-123"
  );
});

test("the hook asks the server to restore a remembered group and stores its authoritative reply", async () => {
  const { createRememberGroupSelectionHook } = await hookModule;
  const storage = fakeStorage([["memba:lastGroup:club-123", "group-remembered"]]);
  const pushedEvents = [];
  const hook = hookContext(createRememberGroupSelectionHook(() => storage), {
    clubId: "club-123",
    selectedGroupId: "group-everyone",
    explicitGroupRoute: "false"
  });

  hook.pushEvent = (event, payload, callback) => {
    pushedEvents.push([event, payload]);
    callback({ selected_group_id: "group-remembered" });
  };

  hook.mounted();

  assert.deepEqual(pushedEvents, [
    ["restore_remembered_group", { group_id: "group-remembered" }]
  ]);
  assert.equal(storage.getItem("memba:lastGroup:club-123"), "group-remembered");
});

test("the hook replaces a stale remembered group with the server fallback", async () => {
  const { createRememberGroupSelectionHook } = await hookModule;
  const storage = fakeStorage([["memba:lastGroup:club-123", "group-stale"]]);
  const hook = hookContext(createRememberGroupSelectionHook(() => storage), {
    clubId: "club-123",
    selectedGroupId: "group-everyone",
    explicitGroupRoute: "false"
  });

  hook.pushEvent = (_event, _payload, callback) => {
    callback({ selected_group_id: "group-everyone" });
  };

  hook.mounted();

  assert.equal(storage.getItem("memba:lastGroup:club-123"), "group-everyone");
});

test("an explicit group route is remembered without consulting a previous selection", async () => {
  const { createRememberGroupSelectionHook } = await hookModule;
  const storage = fakeStorage([["memba:lastGroup:club-123", "group-previous"]]);
  const hook = hookContext(createRememberGroupSelectionHook(() => storage), {
    clubId: "club-123",
    selectedGroupId: "group-explicit",
    explicitGroupRoute: "true"
  });

  hook.pushEvent = () => {
    assert.fail("an explicit group route must not request restoration");
  };

  hook.mounted();

  assert.equal(storage.getItem("memba:lastGroup:club-123"), "group-explicit");
});

test("a successful LiveView rail update remembers the newly selected group", async () => {
  const { createRememberGroupSelectionHook } = await hookModule;
  const storage = fakeStorage();
  const hook = hookContext(createRememberGroupSelectionHook(() => storage), {
    clubId: "club-123",
    selectedGroupId: "group-everyone",
    explicitGroupRoute: "false"
  });

  hook.mounted();
  hook.el.dataset.selectedGroupId = "group-trips";
  hook.updated();

  assert.equal(storage.getItem("memba:lastGroup:club-123"), "group-trips");
});

function hookContext(hook, dataset) {
  return {
    ...hook,
    el: { dataset }
  };
}

function fakeStorage(entries = []) {
  const values = new Map(entries);

  return {
    getItem(key) {
      return values.has(key) ? values.get(key) : null;
    },
    setItem(key, value) {
      values.set(key, value);
    }
  };
}
