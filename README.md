# Leadbay Skills

Team skills for Claude Code.

## Install

```bash
gh repo clone leadbay/skills ~/.leadbay-skills
~/.leadbay-skills/setup
```

## Update

```bash
~/.leadbay-skills/setup --update
```

Each skill checks for updates on launch and tells you when a new version is available.

## Add to a project

To make Claude auto-discover these skills in a project, add to the project's `CLAUDE.md`:

```markdown
## Leadbay Skills

If `~/.leadbay-skills` exists, the following skills are available:

| Command | What it does |
|---------|-------------|
| `/org-retro` | Weekly org-wide engineering retro (Discord-sized) |
| `/sales-retro` | Weekly sales intelligence: signups, activation, churn, Big Fish |

When the user's request matches a skill, invoke it with the Skill tool first.
```

Or run `~/.leadbay-skills/setup --add-to-project` from the project root.

## Available Skills

| Skill | Command | Description |
|-------|---------|-------------|
| org-retro | `/org-retro` | Org-wide engineering retro from GitHub + DBs |
| sales-retro | `/sales-retro` | Sales intelligence from PostHog analytics |

## Architecture

```
~/.leadbay-skills/
  VERSION                  # Version tracking for update checks
  setup                    # Install/update script
  CLAUDE.md                # Template for project-level routing
  bin/
    lb-skills-update-check # Cached version check against GitHub
    lb-skills-config       # Shared key-value config (PostHog keys, etc.)
  shared/                  # Reusable fragments for skill authors
    preamble.md            # Update check + config loading pattern
    posthog.md             # PostHog HogQL query setup
    voice.md               # Tone guidelines
    discord-output.md      # Discord formatting rules
  org-retro/SKILL.md       # Engineering retro skill
  sales-retro/SKILL.md     # Sales retro skill
  config/                  # Local config (gitignored) — API keys etc.
```

**Shared fragments** in `shared/` are reference patterns for skill authors.
Each SKILL.md is self-contained but follows the same preamble/config/output patterns.

**Config** is stored in `~/.leadbay-skills/config/` (gitignored). Keys like `posthog_api_key`
are prompted once and cached. Config survives git pulls and works across all workspaces/worktrees.

## Adding a New Skill

1. Create `my-skill/SKILL.md` following the pattern in existing skills
2. Include the shared preamble (update check) at the top
3. If it needs PostHog, include the PostHog setup block
4. Target output under 1950 chars for Discord compatibility
5. Bump `VERSION`
6. Push to main
7. Team runs `~/.leadbay-skills/setup --update`
