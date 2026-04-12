# Leadbay Skills for Claude Code

## Installation

Leadbay skills require a one-time setup:

```bash
gh repo clone leadbay/skills ~/.leadbay-skills && ~/.leadbay-skills/setup
```

If `~/.leadbay-skills` already exists, update instead:

```bash
~/.leadbay-skills/setup --update
```

## Available skills

| Command | What it does |
|---------|-------------|
| `/org-retro` | Weekly org-wide engineering retro (Discord-sized) |
| `/sales-retro` | Weekly sales intelligence: signups, activation, churn, Big Fish |

## Skill routing

When the user's request matches an available Leadbay skill, invoke it using the Skill
tool as your FIRST action. Do NOT answer directly.

- Weekly retro, what did we ship, engineering retrospective → invoke org-retro
- Sales retro, user activity, signups, churn, who to call → invoke sales-retro
