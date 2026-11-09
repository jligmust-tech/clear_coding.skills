# Agent compatibility

The skills use the open **Agent Skills** layout: one directory per skill containing `SKILL.md` with YAML frontmatter. That format is read by Claude Code, Codex CLI, Cursor, Gemini CLI, OpenCode, and other compatible agents.

The repository also ships the broad `AGENTS.md` entry point, plus thin pointers for agents that look for a specific filename.

## Paths

| Agent | Project path | Global path | Entry file |
|---|---|---|---|
| Claude Code | `.claude/skills/` | `~/.claude/skills/` | `CLAUDE.md` |
| Codex CLI | `.agents/skills/` | `~/.agents/skills/` | `AGENTS.md` |
| Cursor | `.cursor/skills/` | `~/.cursor/skills/` | `AGENTS.md` |
| Gemini CLI | `.gemini/skills/` | `~/.gemini/skills/` | `GEMINI.md` |
| OpenCode | `.opencode/skills/` | `~/.config/opencode/skills/` | `AGENTS.md` |
| GitHub Copilot | client-dependent | `~/.copilot/skills/` | `.github/copilot-instructions.md` |
| Aider | — | — | `AGENTS.md` (see `.aider.conf.yml`) |
| Windsurf, Zed, Jules, Factory | — | — | `AGENTS.md` |

## Install

```bash
./scripts/install.sh              # all agents, global
./scripts/install.sh claude       # one agent, global
./scripts/install.sh cursor project
```

The script creates symlinks, so a `git pull` updates every installed copy. Run it from the project where you want project-scoped links.

## Frontmatter

The skills use only portable fields:

```yaml
---
name: explore-r
description: ...
metadata:
  audience: data analysts
  workflow: exploratory
  language: R
---
```

No agent-specific frontmatter is required. Some agents accept extra fields such as `license` or `allowed-tools`; they are optional and ignored elsewhere.

## Caveats

- **Cursor** support is project-scoped in most versions; use `.cursor/skills/`.
- **Codex CLI** historically used `~/.codex/skills/`. Newer versions use `.agents/skills/`. If your build still looks in the old path, run:
  ```bash
  mkdir -p ~/.codex/skills
  ln -sfn "$PWD/skills/explore-r" ~/.codex/skills/explore-r
  ```
- **Copilot** project-level skill discovery varies by client; the global path is the safe default.
- Skill names must not contain `claude` or `anthropic`; these three do not.
- All examples are synthetic. No agent needs access to real data to run them.

## Verifying an install

```bash
ls -l ~/.claude/skills/
# explore-r -> /path/to/clear-code.skills/skills/explore-r
```

Then ask the agent to "use the explore-r skill" and check that it reads `skills/explore-r/SKILL.md` before acting.
