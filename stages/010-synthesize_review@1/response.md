{"cmd": "ls -la .fabro || true && find .fabro -maxdepth 4 -type f | sed 's#^#/#' | head -200", "timeout_ms": 10000}{"cmd": "find . -maxdepth 4 -type f | grep -E 'review|fabro|01KTFXCWNP' | head -200", "timeout_ms": 10000}{
  "context_updates": {
    "implementation_accepted": true,
    "review_fixes_available": false
  }
}