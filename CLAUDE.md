# Leadbay Skills for Claude Code

## Installation

```bash
gh repo clone leadbay/skills ~/.leadbay-skills && \
  ~/.leadbay-skills/setup --with-knowledge
```

`--with-knowledge` clones the [`leadbay/knowledge`](https://github.com/leadbay/knowledge)
mirror into `~/.leadbay/knowledge` and installs Claude Code hooks
(`UserPromptSubmit`, `PreToolUse`).

For developers who also use [gstack](https://github.com/garrytan/gstack):

```bash
~/.leadbay-skills/setup --with-knowledge --gstack-interop
```

## Available skills

| Command | What it does |
|---------|-------------|
| `/knowledge-find` | Pre-task brief from the wiki — auto-fired by `UserPromptSubmit` hook |
| `/knowledge-explore` | Map a NEW workflow into the wiki via live tour (browser-based, NOT source-only) |
| `/knowledge-question` | Flag an open question into `questions/` |
| `/learnings-from-pr` | Pre-PR knowledge capture — invoke AFTER implementation, BEFORE `git push` |
| `/diagnose` | Deep diagnostic root cause analysis (no code changes) |
| `/org-retro` | Weekly org-wide engineering retro (Discord-sized) |
| `/sales-retro` | Weekly sales intelligence retro |

## Skill routing

When the user's request matches a skill, invoke it with the Skill tool as your FIRST action.

- "what does X do", "show wiki for Y", "find prior knowledge" → `/knowledge-find`
- "explore the X workflow", "document how Y works", "we keep getting confused about Z" → `/knowledge-explore`
- "I'm not sure", "open question", "file a question" → `/knowledge-question`
- about to push / open a PR → `/learnings-from-pr` (FIRST, before `git push`)
- "weekly retro", "what did we ship" → `/org-retro`
- "sales retro", "user activity" → `/sales-retro`
- "diagnose this", "root cause" → `/diagnose`

### Standing instructions (always-on, after install)

After `setup --with-knowledge`, every prompt arrives with a Knowledge brief
prepended by `lb-knowledge-find` and a standing-instructions block. Follow
that block — it tells you when to invoke `/knowledge-question` and
`/knowledge-explore` from inside a normal coding task.

Never write to `~/.leadbay/knowledge/wiki/`, `glossary.md`, `index.md`,
`log.md` from a normal session. Those are exclusively written by
`/knowledge-explore` (or by manual cold-lane consolidation). The PreToolUse
hook will block hot-lane writes there mechanically.

## Storage layout

```
~/.leadbay/                       state dir, owned by this machine
├── projects/<slug>/              local learnings (gstack format, vendored)
├── knowledge/                    git mirror of leadbay/knowledge
│   ├── wiki/                     canonical knowledge — only /knowledge-explore writes here
│   ├── journal/                  per-run learnings (mostly unused under v2)
│   ├── proposed/                 candidate concepts (deprecated path under v2)
│   ├── sources/app-tours/        live network-capture artifacts
│   └── questions/                open questions to resolve
└── slug-cache/                   project slug cache

~/.leadbay-skills/                git clone, immutable
├── bin/                          lb-knowledge-find, validate, write
│                                 + vendored gstack primitives
├── shared/                       reusable skill fragments
├── <skill>/SKILL.md{,.tmpl}      one dir per skill
└── setup                         install / update / hook-install
```

## Assembly

Skills are composed from `SKILL.md.tmpl` templates and `shared/*.md` fragments.

- Edit `.tmpl` files and `shared/*.md` fragments, never `SKILL.md` directly.
- Both `.tmpl` and generated `SKILL.md` are checked in.
- Always run `bin/lb-skills-assemble` before committing.
