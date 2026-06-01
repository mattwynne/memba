{"cmd": "pwd && git status --short && sed -n '1,220p' docs/iterations/011-member-facing-message-behaviour/plan.md && echo '---TODO---' && cat docs/iterations/011-member-facing-message-behaviour/todo.md && echo '---name status---' && git fetch --quiet origin main:refs/remotes/origin/main || true; mb=$(git merge-base HEAD origin/main || git merge-base HEAD main); git diff --name-status $mb..HEAD | sed -n '1,200p'", "timeout": 120000}{
  "context_updates": {
    "plan_conformant": true,
    "plan_rework_available": false
  }
}