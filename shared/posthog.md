## PostHog Setup

```bash
_PH_KEY=$(~/.leadbay-skills/bin/lb-skills-config get posthog_api_key 2>/dev/null || echo "")
echo "PH_KEY_SET: $([ -n "$_PH_KEY" ] && echo yes || echo no)"
```

If `PH_KEY_SET` is `no`: Ask the user for their PostHog personal API key.
Say: "I need a PostHog personal API key to query user analytics.
Generate one at https://eu.posthog.com/settings/user-api-keys (read access is sufficient)."

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
