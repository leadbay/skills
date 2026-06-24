## PostHog Setup

Resolve the key from the environment first (so unattended/CI runs can supply it
as a secret), then fall back to the saved config file:

```bash
_PH_KEY="${PH_KEY:-${POSTHOG_API_KEY:-}}"
[ -z "$_PH_KEY" ] && _PH_KEY=$(~/.leadbay-skills/bin/lb-skills-config get posthog_api_key 2>/dev/null || echo "")
echo "PH_KEY_SET: $([ -n "$_PH_KEY" ] && echo yes || echo no)"
```

If `PH_KEY_SET` is `no` AND this is an interactive run: Ask the user for their
PostHog personal API key. Say: "I need a PostHog personal API key to query user
analytics. Generate one at https://eu.posthog.com/settings/user-api-keys (read
access is sufficient)." In a non-interactive / `--auto` run there is no one to
ask — if the key is absent, fail the Phase 0 gate loudly and stop.

Once provided, save it:
```bash
~/.leadbay-skills/bin/lb-skills-config set posthog_api_key "<THE_KEY>"
```

**PostHog config:**
```
POSTHOG_HOST=https://eu.posthog.com
```

All HogQL queries use: `POST $POSTHOG_HOST/api/projects/@current/query/`
with header `Authorization: Bearer $PH_KEY` and body `{"query": {"kind": "HogQLQuery", "query": "..."}}`
