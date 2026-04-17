## SETUP (run this check BEFORE any browse command)

```bash
_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
B=""
[ -n "$_ROOT" ] && [ -x "$_ROOT/.claude/skills/gstack/browse/dist/browse" ] && B="$_ROOT/.claude/skills/gstack/browse/dist/browse"
[ -z "$B" ] && [ -x "$HOME/.claude/skills/gstack/browse/dist/browse" ] && B="$HOME/.claude/skills/gstack/browse/dist/browse"
if [ -n "$B" ] && [ -x "$B" ]; then
  echo "BROWSE: READY ($B)"
else
  echo "BROWSE: UNAVAILABLE"
fi
```

If `BROWSE` is `UNAVAILABLE`: browser-based evidence gathering (Phases 1g, 3b, 5c) is
skipped. The diagnostic methodology still works — you just lose visual evidence and
UI-based hypothesis testing. Focus on code, database, and error tracker evidence instead.

If `BROWSE` is `READY`: use `$B` for all browse commands throughout the diagnosis.
