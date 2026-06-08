{"cmd": "sed -n '1,220p' docs/iterations/029-membership-admin-invitations/plan.md && printf '\\n--- TODO ---\\n' && sed -n '1,220p' docs/iterations/029-membership-admin-invitations/todo.md && printf '\\n--- status ---\\n' && git status --short && printf '\\n--- recent commits ---\\n' && git log --oneline --decorate --max-count=20"}{
  "context_updates": {
    "plan_conformant": false,
    "plan_rework_available": true
  }
}