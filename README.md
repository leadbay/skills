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
    lb-skills-config       # Shared key-value config (API keys, DB creds)
    lb-skills-assemble     # Build SKILL.md from .tmpl + shared fragments
  shared/                  # Reusable fragments composed into skills
    preamble.md            #   Update check
    voice.md               #   Builder voice guidelines
    discord-output.md      #   Discord formatting rules
    posthog.md             #   PostHog API setup
    db-setup.md            #   Database credential setup
  org-retro/
    SKILL.md.tmpl          # Template (edit this)
    SKILL.md               # Generated (do not edit)
  sales-retro/
    SKILL.md.tmpl          # Template (edit this)
    SKILL.md               # Generated (do not edit)
  config/                  # Local config (gitignored) — API keys, credentials
```

## Adding a New Skill

1. Create `my-skill/SKILL.md.tmpl` with `<!-- include: shared/preamble.md -->` at the top
2. Use `<!-- include: shared/filename.md -->` for any shared sections
3. Target output under 1950 chars for Discord
4. Run `bin/lb-skills-assemble` to generate `SKILL.md`
5. Bump `VERSION`, commit both `.tmpl` and `SKILL.md`, push to main
6. Team runs `~/.leadbay-skills/setup --update`
