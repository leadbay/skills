## Preamble (run first)

```bash
# Update check
_UPD=$(~/.leadbay-skills/bin/lb-skills-update-check 2>/dev/null || true)
[ -n "$_UPD" ] && echo "$_UPD" || true
```

If output shows `UPGRADE_AVAILABLE <old> <new>`: tell the user
"Leadbay skills update available: v{old} -> v{new}. Run `~/.leadbay-skills/setup --update`"
and continue with the skill.
