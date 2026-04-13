## Database Credentials

Resolve credentials using the first source that provides them:

```bash
# 1. Environment variables
_DB_USER="${LEADBAY_DB_RO_USER:-}"
_DB_PASS="${LEADBAY_DB_RO_PASS:-}"

# 2. lb-skills-config
[ -z "$_DB_USER" ] && _DB_USER=$(~/.leadbay-skills/bin/lb-skills-config get db_ro_user 2>/dev/null || echo "")
[ -z "$_DB_PASS" ] && _DB_PASS=$(~/.leadbay-skills/bin/lb-skills-config get db_ro_pass 2>/dev/null || echo "")

echo "DB_CREDS_SET: $([ -n "$_DB_USER" ] && [ -n "$_DB_PASS" ] && echo yes || echo no)"
```

If `DB_CREDS_SET` is `no`:

1. Check if a `.env` file exists in the project root or `~/.leadbay-skills/` — look for
   `LEADBAY_DB_RO_USER` and `LEADBAY_DB_RO_PASS`. If found, export them and retry.
2. Check if `CLAUDE.local.md` (gitignored) exists in the project root — it may contain
   the credentials in a configuration section.
3. If still missing, ask the user:
   "I need the read-only database credentials for Leadbay databases.
   Please provide the username and password."

Once obtained, persist them so they survive across sessions:
```bash
~/.leadbay-skills/bin/lb-skills-config set db_ro_user "<USER>"
~/.leadbay-skills/bin/lb-skills-config set db_ro_pass "<PASS>"
```

Use `$_DB_USER` and `$_DB_PASS` (already resolved above) for all psql connections.
