# Leadbay Skills for Claude Code

## Installation

Leadbay skills require a one-time setup. The `--with-knowledge` flag also clones
the shared knowledge mirror, installs hooks (auto-find before every prompt,
auto-capture on every Stop, validate on every Write/Edit), and a 30-min sync
timer.

```bash
gh repo clone leadbay/skills ~/.leadbay-skills && \
  ~/.leadbay-skills/setup --with-knowledge
```

If `~/.leadbay-skills` already exists, update instead:

```bash
~/.leadbay-skills/setup --update --with-knowledge
```

For developers who also use gstack and want one shared learnings store:

```bash
~/.leadbay-skills/setup --with-knowledge --gstack-interop
```

## Available skills

| Command | What it does |
|---------|-------------|
| `/knowledge-find` | Pre-task brief — auto-fired by `UserPromptSubmit` hook |
| `/knowledge-capture` | Post-task journal write — auto-fired by `Stop` hook |
| `/knowledge-explore` | Bootstrap a new product surface (paired or code-only) |
| `/knowledge-question` | Flag an open question into `questions/` |
| `/knowledge-sync` | Push local journal to `leadbay/knowledge` |
| `/knowledge-dream` | Manual local consolidator preview |
| `/diagnose` | Deep diagnostic root cause analysis (no code changes) |
| `/relentless` | Overnight autonomous build-deploy-eval-iterate loop on a live system |
| `/org-retro` | Weekly org-wide engineering retro (Discord-sized) |
| `/sales-retro` | Weekly sales intelligence: signups, activation, churn, Big Fish |

## Skill routing

When the user's request matches an available Leadbay skill, invoke it using the
Skill tool as your FIRST action. Do NOT answer directly.

- "what do we know about X", "search the wiki" → `/knowledge-find`
- "save this", "remember this for next time" → `/knowledge-capture`
- "explore the X tab", "document the X service" → `/knowledge-explore`
- "I'm not sure", "open question", "file a knowledge question" → `/knowledge-question`
- "sync knowledge", "push my journal" → `/knowledge-sync`
- Weekly retro, what did we ship, engineering retrospective → `/org-retro`
- Sales retro, user activity, signups, churn, who to call → `/sales-retro`
- Diagnose this, root cause analysis, deep dive, why is this happening → `/diagnose`
- "Relentless mode", "overnight", "iterate until perfect", "I'll be away — keep going",
  "make it bulletproof", "don't stop until it's great" → `/relentless`

### Standing instructions (always-on, after install)

Once `setup --with-knowledge` has installed hooks, every prompt arrives with a
prepended Knowledge brief from `lb-knowledge-find` and a standing-instructions
block. Follow that block — it tells you when to invoke `/knowledge-question`
and `/knowledge-explore` from inside a normal coding task.

Never write to `~/.leadbay/knowledge/wiki/`, `glossary.md`, `index.md`, or
`log.md` from a normal session. Those are exclusively written by the `dream`
GitHub workflows in `leadbay/knowledge`. The PreToolUse hook will block hot-lane
writes there mechanically; if you find yourself wanting to update the wiki,
drop a `proposed/` entry via `lb-knowledge-write proposed` and let the dream
promote it.

## Storage layout

```
~/.leadbay/                       state dir, owned by this machine
├── projects/<slug>/
│   ├── learnings.jsonl           append-only learnings (lb-learnings-log)
│   └── timeline.jsonl            session events (lb-timeline-log)
├── knowledge/                    git mirror of leadbay/knowledge
│   ├── wiki/ journal/ proposed/ sources/ questions/ ...
│   └── bin/lb-knowledge-validate-all   single source of validation truth
└── slug-cache/                   project slug cache

~/.leadbay-skills/                git clone, immutable
├── bin/lb-*                      vendored memory primitives + knowledge tools
├── shared/*.md                   reusable skill fragments
├── <skill>/SKILL.md{,.tmpl}      one dir per skill
└── setup                         install / update / hook-install
```

## Assembly

Skills are composed from `SKILL.md.tmpl` templates and `shared/*.md` fragments.
Run `bin/lb-skills-assemble` to regenerate `SKILL.md` files from templates.

- Edit `.tmpl` files and `shared/*.md` fragments, never `SKILL.md` directly.
- Both `.tmpl` and generated `SKILL.md` are checked in.
- Always run `bin/lb-skills-assemble` before committing.
