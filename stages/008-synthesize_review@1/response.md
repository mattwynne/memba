{"cmd": "ls -R .fabro/tmp 2>/dev/null | sed -n '1,200p' && echo '---' && find .fabro/tmp -maxdepth 3 -type f -print"}{
  "context_updates": {
    "implementation_accepted": true,
    "review_fixes_available": false
  }
}