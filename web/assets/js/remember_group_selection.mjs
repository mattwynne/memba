export function groupSelectionStorageKey(clubId) {
  return `memba:lastGroup:${clubId}`
}

export function createRememberGroupSelectionHook(
  getStorage = () => window.localStorage
) {
  return {
    mounted() {
      this.groupSelectionStorage = availableStorage(getStorage)
      this.groupSelectionStorageKey = storageKeyFor(this.el)

      const selectedGroupId = this.el.dataset.selectedGroupId

      if (!this.groupSelectionStorageKey || !selectedGroupId) return

      if (this.el.dataset.explicitGroupRoute === "true") {
        rememberSelection(this, selectedGroupId)
        return
      }

      const rememberedGroupId = readSelection(this)

      if (!rememberedGroupId || rememberedGroupId === selectedGroupId) {
        rememberSelection(this, selectedGroupId)
        return
      }

      this.pushEvent(
        "restore_remembered_group",
        {group_id: rememberedGroupId},
        reply => rememberSelection(this, reply && reply.selected_group_id)
      )
    },

    updated() {
      const currentStorageKey = storageKeyFor(this.el)

      if (currentStorageKey !== this.groupSelectionStorageKey) {
        this.groupSelectionStorageKey = currentStorageKey
      }

      rememberSelection(this, this.el.dataset.selectedGroupId)
    }
  }
}

function storageKeyFor(element) {
  const clubId = element.dataset.clubId
  return clubId ? groupSelectionStorageKey(clubId) : null
}

function availableStorage(getStorage) {
  try {
    return getStorage()
  } catch (_error) {
    return null
  }
}

function readSelection(hook) {
  if (!hook.groupSelectionStorage) return null

  try {
    return hook.groupSelectionStorage.getItem(hook.groupSelectionStorageKey)
  } catch (_error) {
    return null
  }
}

function rememberSelection(hook, groupId) {
  if (!hook.groupSelectionStorage || !hook.groupSelectionStorageKey || !groupId) return

  try {
    hook.groupSelectionStorage.setItem(hook.groupSelectionStorageKey, groupId)
  } catch (_error) {
    // Browser-local persistence is a convenience; blocked storage must not break navigation.
  }
}

export default createRememberGroupSelectionHook()
