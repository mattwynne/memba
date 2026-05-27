v >/dev/null; then
   echo "warning: devenv not found; skipping 'dev up'. Ensure required services are already running." >&2
   return 0
 fi
 ...
}
down similar no-op
ci uses trap only if up succeeded maybe yes.

Also web/check commands call mix directly; if mix absent they fail with clear message maybe currently command not found.
Could add helper require_cmd mix for friendly. not necessary.

Need ensure script still works with argc when present: eval at end.
if argc absent and devenv absent we need manual dispatch and exit.

Let's patch file. Use apply_patch.

Before patch maybe check if any docs around bin scripts? no.

Let's patch minimal.

Also maybe dev check script in pipeline uses /repos/.../bin/dev with PATH includes bin. Shebang bash. Good.

Let's apply patch careful context.

♀♀♀♀assistant to=functions.apply_patch մեկնաբանություն code:
*** Begin Patch
*** Update File: /repos/mattwynne/memba/bin/dev
@@
 set -euo pipefail
 
-if ! command -v argc >/dev/null 2>&1; then
+has_devenv() {
+  command -v devenv >/dev/null 2>&1
+}
+
+if ! command -v argc >/dev/null 2>&1 && has_devenv; then
   exec devenv shell -- "$0" "$@"
 fi
@@
 up() {
-  DEVENV_TUI=false devenv up -d postgres
-  devenv processes wait --timeout 120
+  if ! has_devenv; then
+    echo "warning: devenv not found; skipping service startup. Ensure required services are already running." >&2
+    return 0
+  fi
+
+  DEVENV_TUI=false devenv up -d postgres
+  devenv processes wait --timeout 120
 }
@@
 down() {
+  if ! has_devenv; then
+    return 0
+  fi
+
   devenv processes down
 }
@@
-eval "$(argc --argc-eval "$0" "$@")"
+if command -v argc >/dev/null 2>&1; then
+  eval "$(argc --argc-eval "$0" "$@")"
+  exit 0
+fi
+
+if [ "$#" -eq 0 ]; then
+  echo "usage: dev <up|down|ci|web|check|acceptance>" >&2
+  exit 1
+fi
+
+cmd="$1"
+shift
+
+case "$cmd" in
+  up|down|ci|web|check|acceptance)
+    "$cmd" "$@"
+    ;;
+  *)
+    echo "unknown command: $cmd" >&2
+    echo "usage: dev <up|down|ci|web|check|acceptance>" >&2
+    exit 1
+    ;;
+esac
*** End Patch
