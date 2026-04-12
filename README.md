# Leadbay Skills

Team skills for Claude Code.

## Install

```bash
git clone https://github.com/leadbay/skills.git ~/.leadbay-skills && ~/.leadbay-skills/setup
```

## Update

```bash
~/.leadbay-skills/setup --update
```

Each skill checks for updates on launch and notifies you.

## One-liner (install or update)

```bash
bash <(curl -s https://raw.githubusercontent.com/leadbay/skills/main/install.sh)
```

## Add to a project

From the project root:
```bash
~/.leadbay-skills/setup --add-to-project
```

This appends skill routing rules to your `CLAUDE.md`.

## Available Skills

| Command | Description |
|---------|-------------|
| `/org-retro` | Org-wide engineering retro from GitHub + DBs |
| `/sales-retro` | Sales intelligence from PostHog analytics |

## Architecture

```
~/.leadbay-skills/
  VERSION                  # Update tracking
  setup                    # Install/update/project-inject
  install.sh               # One-liner: install or update
  CLAUDE.md                # Template for project routing
  bin/
    lb-skills-update-check # Cached GitHub version check
    lb-skills-config       # Shared key-value config
  shared/                  # Reusable fragments for skill authors
  org-retro/SKILL.md
  sales-retro/SKILL.md
  config/                  # Local config (gitignored) — API keys
```

## Adding a New Skill

1. Create `my-skill/SKILL.md`
2. Include the preamble (update check) at the top
3. Target output under 1950 chars for Discord
4. Bump `VERSION`, push to main
5. Team runs `~/.leadbay-skills/setup --update`
