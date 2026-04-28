## Leadbay Integration Setup (run after preamble)

```bash
_LB_BIN="$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)/bin" 2>/dev/null || _LB_BIN="$HOME/.leadbay-skills/bin"
[ ! -d "$_LB_BIN" ] && _LB_BIN="$HOME/.leadbay-skills/bin"
eval "$("$_LB_BIN/lb-slug" 2>/dev/null)" 2>/dev/null || true
SLUG="${SLUG:-unknown}"
echo "SLUG: $SLUG"
echo "BRANCH: ${BRANCH:-unknown}"
source <("$_LB_BIN/lb-repo-mode" 2>/dev/null) || true
REPO_MODE=${REPO_MODE:-unknown}
echo "REPO_MODE: $REPO_MODE"
# Learnings count
LEADBAY_HOME="${LEADBAY_HOME:-$HOME/.leadbay}"
_LEARN_FILE="$LEADBAY_HOME/projects/$SLUG/learnings.jsonl"
if [ -f "$_LEARN_FILE" ]; then
  _LEARN_COUNT=$(wc -l < "$_LEARN_FILE" 2>/dev/null | tr -d ' ')
  echo "LEARNINGS: $_LEARN_COUNT entries loaded"
  if [ "$_LEARN_COUNT" -gt 5 ] 2>/dev/null; then
    "$_LB_BIN/lb-learnings-search" --limit 3 2>/dev/null || true
  fi
else
  echo "LEARNINGS: 0"
fi
# Check bun availability (needed for learnings commands)
_HAS_BUN=$(command -v bun >/dev/null 2>&1 && echo "yes" || echo "no")
echo "BUN: $_HAS_BUN"
```

If `BUN` is `no`: learnings commands will not work. The diagnostic methodology
still functions fully, but cached knowledge from prior sessions is unavailable.
