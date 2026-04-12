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

Or just wait — each skill checks for updates on launch and tells you when a new version is available.

## Available Skills

| Skill | Command | Description |
|-------|---------|-------------|
| org-retro | `/org-retro` | Weekly org-wide engineering retro (Discord-sized) |

## Adding a New Skill

1. Create a directory: `my-skill/SKILL.md`
2. Add the standard preamble (copy from an existing skill)
3. Bump `VERSION`
4. Push to main
