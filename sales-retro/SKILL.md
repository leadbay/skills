---
name: sales-retro
description: Weekly sales intelligence — signups, activation, churn risk, Big Fish detection
version: 0.2.0
---

<!-- Shared: preamble -->
## Preamble (run first)

```bash
_UPD=$(~/.leadbay-skills/bin/lb-skills-update-check 2>/dev/null || true)
[ -n "$_UPD" ] && echo "$_UPD" || true
_PH_KEY=$(~/.leadbay-skills/bin/lb-skills-config get posthog_api_key 2>/dev/null || echo "")
echo "PH_KEY_SET: $([ -n "$_PH_KEY" ] && echo yes || echo no)"
```

If output shows `UPGRADE_AVAILABLE <old> <new>`: tell the user
"Leadbay skills update available: v{old} -> v{new}. Run `~/.leadbay-skills/setup --update`"

If `PH_KEY_SET` is `no`: Ask the user for their PostHog personal API key.
Say: "I need a PostHog personal API key. Generate one at
https://eu.posthog.com/settings/user-api-keys (read access is sufficient)."
Once provided: `~/.leadbay-skills/bin/lb-skills-config set posthog_api_key "<KEY>"`

## User-invocable
When the user types `/sales-retro`, run this skill.

## Arguments
- `/sales-retro` — last 7 days (default)
- `/sales-retro 14d` — last 14 days
- `/sales-retro 30d` — last 30 days

## Configuration

```
POSTHOG_HOST=https://eu.posthog.com
```

PostHog API key: `~/.leadbay-skills/bin/lb-skills-config get posthog_api_key`

All queries use HogQL: `POST $POSTHOG_HOST/api/projects/@current/query/`
with `Authorization: Bearer $PH_KEY` and `{"query": {"kind": "HogQLQuery", "query": "..."}}`

## Instructions

Parse argument for time window. Default 7 days. Compute midnight-aligned start date.
Also compute PRIOR window of same length for activity comparison.

### Step 1: New verified signups

```sql
SELECT distinct_id as email, timestamp, properties.is_freemium,
  person.properties.leadbayOrganization as org,
  person.properties.verified as verified
FROM events
WHERE event = 'user_created' AND timestamp >= '{start}'
  AND distinct_id NOT LIKE '%@leadbay.ai'
  AND distinct_id NOT LIKE '%@example.com'
ORDER BY timestamp DESC
```

**Filter out:** internal emails, test emails, orgs starting with "Wow Effect" (placeholder),
duplicate user_created for same email (keep latest). **Only report verified users.**
Count unverified separately (just the number, no list).

Detect **team rollouts**: multiple users from same email domain = group them as one line.

### Step 2: Activation of new verified signups

```sql
SELECT distinct_id as email, count() as active_days
FROM events WHERE event = 'first_lead_click_of_day'
  AND timestamp >= '{start}'
  AND distinct_id IN ({verified_emails})
GROUP BY distinct_id
```

### Step 3: Quota hits

```sql
SELECT distinct_id as email, count() as hits,
  properties.resource_type, properties.window_type
FROM events WHERE event = 'quota_exceeded' AND timestamp >= '{start}'
  AND distinct_id NOT LIKE '%@leadbay.ai'
GROUP BY distinct_id, properties.resource_type, properties.window_type
ORDER BY hits DESC
```

### Step 4: Cancellations

```sql
SELECT distinct_id as email, properties.old_billing_status as old,
  properties.new_billing_status as new, properties.stripe_status
FROM events WHERE event = 'billing_status_changed' AND timestamp >= '{start}'
  AND distinct_id NOT LIKE '%@leadbay.ai'
  AND properties.new_billing_status != properties.old_billing_status
ORDER BY timestamp DESC
```

Only show transitions TO canceled/NOT_SET_UP (actual cancellations), or ACTION_NEEDED (payment issues).
Skip transitions that are just status corrections or new signups.

### Step 5: Most active existing users

```sql
SELECT distinct_id as email, count() as active_days,
  person.properties.billing_status as billing
FROM events WHERE event = 'first_lead_click_of_day' AND timestamp >= '{start}'
  AND distinct_id NOT LIKE '%@leadbay.ai'
  AND distinct_id NOT LIKE '%@example.com'
GROUP BY distinct_id, person.properties.billing_status
ORDER BY active_days DESC LIMIT 10
```

### Step 6: Activity drops

```sql
SELECT prev.email, prev.days as prev_days, curr.days as curr_days,
  person.properties.billing_status as billing
FROM (
  SELECT distinct_id as email, count() as days FROM events
  WHERE event = 'first_lead_click_of_day'
    AND timestamp >= '{prior_start}' AND timestamp < '{start}'
  GROUP BY distinct_id
) as prev
LEFT JOIN (
  SELECT distinct_id as email, count() as days FROM events
  WHERE event = 'first_lead_click_of_day' AND timestamp >= '{start}'
  GROUP BY distinct_id
) as curr ON prev.email = curr.email
WHERE (curr.days IS NULL OR curr.days < prev.days)
  AND prev.email NOT LIKE '%@leadbay.ai'
  AND prev.email NOT LIKE '%@example.com'
ORDER BY prev.days DESC LIMIT 10
```

### Step 7: Big Fish detection

From ALL data gathered, identify potential enterprise accounts by:
- Email domain of a known large company (Fortune 500, major brands, unicorns)
- Multiple users from same domain (team adoption)
- High activity + quota hits from a recognizable company

For each Big Fish: company name, the specific email(s), and what signal triggered it.

### Step 8: Ad form leads

```sql
SELECT count() FROM events
WHERE event = 'ad_lead_captured' AND timestamp >= '{start}'
```

## Output Format

**CRITICAL: Output MUST be under 1950 characters total (inside the code block).**
Count characters. If over limit, cut: unverified count line, then trim "verified but
not returning" to just a count, then reduce most-active to top 5.

Output a single code block:

```
📈 Sales Retro — {date range}
{verified} verified signups · {form_leads} form leads · {paid_conversions} paid conversions

ACTIVATED (verified + came back)
  {email:35}  {Nd} · quota {Nx} 🔥  ← only if quota hit
  {email:35}  {Nd}
  ...
  Sort by: quota hits desc, then active days desc.
  Team rollouts on one line: "{domain}: {N} users, {details}"

  Not returning: {email}, {email}, ... (one line, comma-separated)

CANCELLATIONS
  {domain} · {domain}(xN) · ... (one compact line)

🔥 QUOTA HITS
  {email} {Nx} · {email} {Nx} · ... (compact, one-two lines)

👑 MOST ACTIVE
  {email:35}  {Nd}  {PAID if paying}
  ... top 8-10

⚠️ DROPPING
  {email:35}  {prev}→{curr}  {PAID/CANCELED if relevant}
  ... top 7-9

🐋 BIG FISH
  {Company} — {signal}
    {email}
  ... 3-6 entries max

📞 DO THIS WEEK
  1. {verb} {email} — {why, one line}
  ... 3-5 actions max
```

**Formatting rules:**
- Emails only, no org names (save space). Exception: Big Fish section names the company.
- Quota hits section: compact inline format, not one-per-line.
- Cancellations: compact inline format.
- "Not returning" verified users: comma-separated on one line.
- SALES ACTIONS: each action names a specific email and a specific reason.
- Sort activated users by quota hits first (most hits = most urgent), then by active days.

## Sales Actions Priority

Rank actions by revenue potential:
1. Quota hitters (want more, ready to pay)
2. Dropping paid users (churn risk, save revenue)
3. Activated Big Fish (enterprise pipeline)
4. High-activity freemium (nurture to convert)

Each action: specific person, specific verb (CALL/WIN-BACK/SAVE/NURTURE), specific why.

## Voice

Sales-focused. Every line answers "who should I call today and why?"
No engineering jargon. Frame as revenue, churn risk, or expansion.

## Important Rules

- Output MUST fit one Discord message (under 1950 chars in the code block).
- If a HogQL query fails, skip it gracefully.
- Emails only — no org names except in Big Fish.
- Filter all @leadbay.ai and @example.com.
- Filter "Wow Effect" orgs.
