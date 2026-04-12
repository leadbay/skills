---
name: sales-retro
description: Weekly sales intelligence retro — new signups, activation, churn risk, Big Fish
version: 0.1.0
---

## User-invocable
When the user types `/sales-retro`, run this skill.

## Arguments
- `/sales-retro` — default: last 7 days
- `/sales-retro 14d` — last 14 days
- `/sales-retro 30d` — last 30 days

## Preamble

```bash
_UPD=$(~/.leadbay-skills/bin/lb-skills-update-check 2>/dev/null || true)
[ -n "$_UPD" ] && echo "$_UPD" || true

# Check for PostHog API key
_PH_KEY=$(~/.leadbay-skills/bin/lb-skills-config get posthog_api_key 2>/dev/null || echo "")
echo "PH_KEY_SET: $([ -n "$_PH_KEY" ] && echo yes || echo no)"
```

If `PH_KEY_SET` is `no`: Ask the user for their PostHog personal API key.
Tell them: "I need a PostHog personal API key to query user analytics.
Generate one at https://eu.posthog.com/settings/user-api-keys (read access is sufficient)."

Once they provide it, save it:
```bash
~/.leadbay-skills/bin/lb-skills-config set posthog_api_key "<THE_KEY>"
```

Then continue. On subsequent runs the key is loaded automatically.

## Configuration

```
POSTHOG_HOST=https://eu.posthog.com
GITHUB_ORG=leadbay
```

The PostHog API key is read from: `~/.leadbay-skills/bin/lb-skills-config get posthog_api_key`

All queries use the HogQL endpoint: `POST $POSTHOG_HOST/api/projects/@current/query/`
with header `Authorization: Bearer $PH_KEY` and body `{"query": {"kind": "HogQLQuery", "query": "..."}}`

## Instructions

Parse the argument for time window. Default 7 days. Compute midnight-aligned start date.
Also compute the PRIOR window of the same length (e.g., if this week is Apr 4-11,
prior week is Mar 28 - Apr 4) for comparison.

### Step 1: New signups this period

HogQL query:
```sql
SELECT
  distinct_id as email,
  timestamp,
  properties.is_freemium as freemium,
  properties.source as source,
  person.properties.leadbayOrganization as org,
  person.properties.verified as verified,
  person.properties.billing_status as billing
FROM events
WHERE event = 'user_created'
  AND timestamp >= '{start_date}'
  AND distinct_id NOT LIKE '%@leadbay.ai'
  AND distinct_id NOT LIKE '%@example.com'
ORDER BY timestamp DESC
```

**Filter out:**
- Internal emails (@leadbay.ai)
- Test emails (@example.com)
- Orgs starting with "Wow Effect" (auto-generated placeholder orgs that haven't completed onboarding)
- Duplicate user_created events for the same email (take the latest)

**Classify each signup:**
- **Verified**: `verified = true` (they confirmed their email)
- **Unverified**: `verified = false` or null (signed up but didn't confirm)
- **Freemium**: `freemium = true`
- **Invited** (wow source, not freemium): came through an invite/onboarding flow

**Region detection:**
- FR if email domain ends in `.fr` or org name looks French (common French company suffixes)
- US otherwise (rough heuristic — good enough for sales)

### Step 2: Activation — who came back?

For each new verified signup from Step 1, check how many days they were active:

```sql
SELECT
  distinct_id as email,
  count() as active_days
FROM events
WHERE event = 'first_lead_click_of_day'
  AND timestamp >= '{start_date}'
  AND distinct_id IN ({list_of_new_verified_emails})
GROUP BY distinct_id
```

Classify:
- **Activated** (2+ active days): came back after signup
- **One-shot** (0-1 active days): signed up, maybe poked around, never returned
- **Power user** (4+ active days): daily user already

### Step 3: Quota hits

```sql
SELECT
  distinct_id as email,
  count() as hits,
  properties.resource_type as resource,
  properties.window_type as window
FROM events
WHERE event = 'quota_exceeded'
  AND timestamp >= '{start_date}'
  AND distinct_id NOT LIKE '%@leadbay.ai'
GROUP BY distinct_id, properties.resource_type, properties.window_type
ORDER BY hits DESC
```

Users hitting quotas are the hottest conversion signals. They want more than freemium allows.

### Step 4: Conversions

```sql
SELECT
  distinct_id as email,
  properties.new_plan as new_plan,
  properties.old_plan as old_plan,
  timestamp
FROM events
WHERE event = 'quota_plan_changed'
  AND timestamp >= '{start_date}'
  AND distinct_id NOT LIKE '%@leadbay.ai'
ORDER BY timestamp DESC
```

Also check:
```sql
SELECT
  distinct_id as email,
  properties.stripe_status as status,
  properties.billing_status as billing,
  timestamp
FROM events
WHERE event = 'stripe_subscription_created'
  AND timestamp >= '{start_date}'
  AND distinct_id NOT LIKE '%@leadbay.ai'
ORDER BY timestamp DESC
```

And cancellations:
```sql
SELECT
  distinct_id as email,
  properties.new_billing_status as new_status,
  properties.old_billing_status as old_status,
  properties.stripe_status as stripe,
  person.properties.leadbayOrganization as org,
  timestamp
FROM events
WHERE event = 'billing_status_changed'
  AND timestamp >= '{start_date}'
  AND distinct_id NOT LIKE '%@leadbay.ai'
ORDER BY timestamp DESC
```

### Step 5: Existing user activity — most active

```sql
SELECT
  distinct_id as email,
  count() as active_days,
  min(timestamp) as first_active,
  max(timestamp) as last_active,
  person.properties.leadbayOrganization as org,
  person.properties.billing_status as billing
FROM events
WHERE event = 'first_lead_click_of_day'
  AND timestamp >= '{start_date}'
  AND distinct_id NOT LIKE '%@leadbay.ai'
  AND distinct_id NOT LIKE '%@example.com'
GROUP BY distinct_id, person.properties.leadbayOrganization, person.properties.billing_status
ORDER BY active_days DESC
LIMIT 20
```

### Step 6: Activity drops — needs attention

Compare activity this period vs prior period:

```sql
SELECT
  prev.email,
  prev.days as prev_days,
  curr.days as curr_days,
  person.properties.leadbayOrganization as org,
  person.properties.billing_status as billing
FROM (
  SELECT distinct_id as email, count() as days
  FROM events
  WHERE event = 'first_lead_click_of_day'
    AND timestamp >= '{prior_start}' AND timestamp < '{start_date}'
  GROUP BY distinct_id
) as prev
LEFT JOIN (
  SELECT distinct_id as email, count() as days
  FROM events
  WHERE event = 'first_lead_click_of_day'
    AND timestamp >= '{start_date}'
  GROUP BY distinct_id
) as curr ON prev.email = curr.email
LEFT JOIN persons as person ON prev.email = person.properties.email
WHERE (curr.days IS NULL OR curr.days < prev.days)
  AND prev.email NOT LIKE '%@leadbay.ai'
  AND prev.email NOT LIKE '%@example.com'
ORDER BY prev.days DESC
LIMIT 20
```

### Step 7: Big Fish detection

From ALL new signups (Step 1), identify potential enterprise accounts:

**Big Fish signals:**
- Email domain matches a known large company (Fortune 500, major brands)
- Org name matches known enterprise names
- Domain is a well-known company (e.g., clay.com, sodexo.com, axa.fr, chronoflex.com, hexa.com)
- Multiple users from the same domain signing up (team adoption signal)

**Also check existing users for Big Fish that are active or hitting quotas.**
Cross-reference the most active users list and quota-exceeded list with company domains.

For each Big Fish candidate, report:
- Company name and domain
- Number of users from that domain
- Their activity level
- Whether they hit quotas (buying signal)
- Billing status (freemium vs paid)

### Step 8: Ad leads captured (form submissions)

```sql
SELECT count() as total
FROM events
WHERE event = 'ad_lead_captured'
  AND timestamp >= '{start_date}'
```

These are marketing form submissions (Meta ads, website forms) that haven't converted to
accounts yet. Report the count as top-of-funnel context.

### Output Format

Output directly to conversation. Keep it actionable for sales team.
Use a code block for Discord compatibility.

```
📈 Leadbay Sales Retro — {date range}

NEW SIGNUPS: {total} ({verified} verified, {unverified} unverified)
  FR: {count}  US: {count}

  Verified & activated (came back 2+ days):
    {email:40}  {org:25}  {active_days}d active  {quota_hit_flag}
    ...

  Verified but inactive (signed up, didn't return):
    {email:40}  {org:25}
    ...

  Unverified (didn't confirm email):
    {count} users (list only if < 10, otherwise just count)

CONVERSIONS
  {email}  {old_plan} → {new_plan}  ({date})
  ...
  (or "None this period")

CANCELLATIONS
  {email}  {org}  {old} → {new}  ({date})
  ...

🔥 QUOTA HITS (buying signals)
  {email:40}  {hits} hits  {resource} ({window})  {org}
  ...

👑 MOST ACTIVE USERS
  {email:40}  {active_days}d  {org:25}  {billing}
  ...top 10

⚠️ DROPPING ACTIVITY (needs outreach)
  {email:40}  {prev}d → {curr}d  {org:25}  {billing}
  ...
  Focus: {1-2 sentence recommendation on who to call first and why}

🐋 BIG FISH
  {company_name} ({domain})
    {N} users · {activity summary} · {billing status}
    {specific action recommendation}
  ...

FUNNEL
  Ad leads captured: {count} form submissions
  New signups: {count} ({verified} verified)
  Activated (2+ days): {count}
  Hitting quota: {count}
  Converted to paid: {count}

SALES ACTIONS THIS WEEK
  1. {most urgent action — e.g., "Call rifat@dgftech.us — hit daily quota 7x, wants more"}
  2. {second action}
  3. {third action}
```

**SALES ACTIONS rules:**
- Max 5 actions, sorted by revenue potential
- Each action names a specific person and why
- Prioritize: quota hitters > dropping paid users > activated Big Fish > high-activity freemium
- Be specific: "Call X" not "Reach out to active users"

## Important Rules

- ALL output goes to conversation. No files written.
- Filter out ALL @leadbay.ai and @example.com emails — these are internal/test.
- Filter out orgs starting with "Wow Effect" — these are placeholder names from incomplete onboarding.
- Keep Discord-friendly: under 2000 chars if possible. If it must be longer, split into
  two code blocks (Discord allows multiple messages).
- If a HogQL query fails, note it and continue with what you have.
- Refer to users by email always — that's how sales identifies them.
- For Big Fish: err on the side of inclusion. Better to flag a medium company than miss an enterprise.
- Billing status "OK" = paying customer. "NOT_SET_UP" = freemium or not yet set up.
  "ACTION_NEEDED" = payment failed.

## Voice

Sales-focused. Direct. Every line should answer "so what?" for someone deciding
who to call today. No engineering jargon. Frame everything in terms of:
- Revenue potential (who's likely to convert?)
- Churn risk (who's about to leave?)
- Expansion opportunity (who needs a bigger plan?)
