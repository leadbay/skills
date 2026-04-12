---
name: org-retro
description: Weekly org-wide engineering retro in Discord-compatible format
version: 0.1.0
---

## User-invocable
When the user types `/org-retro`, run this skill.

## Arguments
- `/org-retro` — default: last 7 days
- `/org-retro 14d` — last 14 days
- `/org-retro 30d` — last 30 days

## Preamble

```bash
_UPD=$(~/.leadbay-skills/bin/lb-skills-update-check 2>/dev/null || true)
[ -n "$_UPD" ] && echo "$_UPD" || true
```

If output shows `UPGRADE_AVAILABLE <old> <new>`: tell the user
"Leadbay skills update available: v{old} -> v{new}. Run `~/.leadbay-skills/setup --update`"
and continue with the skill.

## Instructions

Parse the argument to determine the time window. Default to 7 days if no argument given.

Compute midnight-aligned start date in local timezone. For example, if today is
2026-04-18 and window is 7d, use `--since="2026-04-11T00:00:00"`.

### Configuration

These values are hardcoded. Edit them when the org changes.

```
GITHUB_ORG=leadbay
EXCLUDED_REPOS=visceral-media
DB_RO_USER=milan_ro
DB_RO_PASS=REDACTED_ROTATE_THIS_PASSWORD
FR_PROD_HOST=10.0.1.8
FR_PROD_DB=prod
US_PROD_HOST=10.2.0.4
US_PROD_DB=us_staging
WORLDVIEW_HOST=10.0.1.7
WORLDVIEW_DB=worldview
```

### Step 1: Gather GitHub data

List all non-archived repos in the org, excluding repos in EXCLUDED_REPOS:

```bash
gh repo list $GITHUB_ORG --limit 100 --json name,pushedAt,isArchived \
  --jq '.[] | select(.isArchived==false) | select(.name != "visceral-media") | .name + "|" + .pushedAt' \
  | sort -t'|' -k2 -r
```

For each repo pushed within the time window, fetch commits:

```bash
gh api "repos/$GITHUB_ORG/$REPO/commits?since=${START_DATE}T00:00:00Z&per_page=100" \
  --jq '.[] | .commit.author.name + "|" + .commit.author.date + "|" + (.commit.message | split("\n")[0])'
```

Also fetch releases within the window:

```bash
gh api "repos/$GITHUB_ORG/$REPO/releases?per_page=10" \
  --jq '.[] | select(.published_at > "'$START_DATE'") | .tag_name + " (" + .published_at[0:10] + ")"'
```

### Step 2: Gather database data

Run these queries in parallel:

**Backend lead imports (FR prod):**
```sql
-- Connect: psql -h $FR_PROD_HOST -U $DB_RO_USER -d $FR_PROD_DB
SELECT
  COUNT(*) FILTER (WHERE last_worldview_import >= '$START_DATE') as imported_this_period,
  COUNT(*) as total_leads
FROM leads;
```

**Backend lead imports (US prod):**
```sql
-- Connect: psql -h $US_PROD_HOST -U $DB_RO_USER -d $US_PROD_DB
SELECT
  COUNT(*) FILTER (WHERE last_worldview_import >= '$START_DATE') as imported_this_period,
  COUNT(*) as total_leads
FROM leads;
```

**Worldview claims (website + FR leads):**
```sql
-- Connect: psql -h $WORLDVIEW_HOST -U $DB_RO_USER -d $WORLDVIEW_DB
SELECT s.name as source, COUNT(*) as claims
FROM claims.website w JOIN sources s ON s.id = w.source_id
WHERE w.date >= '$START_DATE'
GROUP BY s.name ORDER BY claims DESC;

SELECT s.name as source, COUNT(*) as claims
FROM claims.lead l JOIN sources s ON s.id = l.source_id
WHERE l.date >= '$START_DATE'
GROUP BY s.name ORDER BY claims DESC;

SELECT COUNT(DISTINCT selector_value) as unique_websites
FROM claims.website WHERE date >= '$START_DATE';
```

**Worldview claims (US leads):**
```sql
-- This table is large. Use a 60s timeout.
SET statement_timeout = '60s';
SELECT s.name as source, COUNT(*) as claims
FROM claims.lead_us l JOIN sources s ON s.id = l.source_id
WHERE l.date >= '$START_DATE'
GROUP BY s.name ORDER BY claims DESC;
```

If the US leads query times out, note it and report what you have.

**Co-authored-by analysis (for AI-assisted %):**
Only run this on repos where you have local git access or can fetch via API.
For the current repo, use:
```bash
git log origin/main --since="$START_DATE" --format="%b" | grep -i "Co-Authored-By" | sort | uniq -c | sort -rn
```

### Step 3: Compute and format

Aggregate all data into the following Discord-compatible format.
Keep it under 2000 characters. Use a code block so it renders as monospace.

**IMPORTANT formatting rules:**
- Claims are field-level writes, NOT unique entities. When reporting worldview claims,
  say "X field updates" not "X leads". The actual lead count comes from backend ingestion.
- Round large numbers: use "4.2M" not "4,212,206"
- Align columns in the leaderboard
- Group small repos into a single "other" line
- Only include SIGNALS that are genuinely noteworthy (don't pad with generic observations)

**Template:**

```
📊 Leadbay Org Retro — {date range}
{total_commits} commits · {contributors} contributors · {active_repos} repos · {releases} releases

DATA PIPELINE
  {summarize worldview claims and backend imports}
  {2-3 lines max}

RELEASES
  {repo}  {version_range}  ({count} releases)
  {only repos with releases}

{PER_REPO_SECTION for each repo with 5+ commits, sorted by commit count desc}
  {contributors with counts}
  • {key items, 2-5 bullets}

{one-liner for repos with <5 commits}

LEADERBOARD
  {name}    {commits} commits  {repos} repos  {notable extra if any}
  {sorted by commits desc}

TOP WINS
🥇 {highest impact ship} ({who}) — {why it matters}
🥈 {second} ({who}) — {why}
🥉 {third} ({who}) — {why}

SIGNALS
{only genuinely noteworthy items, 2-5 lines with emoji prefixes}
```

### Step 4: Output

Output the formatted retro directly to the conversation inside a single code block.
Do NOT write any files. The user will copy-paste it into Discord.

## Voice

Direct, concrete, no filler. Sound like a builder reporting to builders.
Name specific PRs, specific people, specific numbers.
Skip generic praise. If something is noteworthy, say exactly what and why.

## Important Rules

- ALL output goes to the conversation. No files written.
- Keep total output under 2000 characters (Discord limit for a single message).
- If it's too long, cut the smallest repos first, then trim bullets.
- Use monospace code block so it renders cleanly in Discord.
- Do NOT include internal job processing stats (refresh_monitor, ai_rescore, etc.) — only import/ingestion numbers.
- Do NOT include org signup counts — only lead/data pipeline numbers.
- Claims are field-level writes. Always clarify "field updates" not "leads" for worldview claims.
- If a DB query fails or times out, skip it gracefully and note "(query timed out)" in the output.
