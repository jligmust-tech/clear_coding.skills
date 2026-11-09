# Clear Code

Three agent skills for code that stays editable after the agent writes it.

R is the reference language. The loop and the rubric are language-agnostic; every code sample is R, and the same structure ports directly to Python or Julia.

Most "clean code" advice optimizes for a reader who never edits the code. This collection optimizes for the person who has to **change one behaviour tomorrow** — which, when an agent writes the code, is you.

## The loop

```
explore  ──promotion gate──▶  write
   ▲                            │
   └──────── debug ◀────────────┘
```

| Skill | Mode | Promise |
|---|---|---|
| `explore-r` | notebook | Fast to write, safe to leave, re-runnable |
| `debug-r` | both | Reduce to a fixture, locate the stage, fix once |
| `write-r` | deliverable | One place to change, one way to verify |

The gate between explore and write is the **editability rubric**: five tests, scored 0–2 each. Scratch code is exempt. Anything handed to someone else must score 8/10.

## Why this exists

Agent-written R often reads well at the call site and badly at the definition:

- a 200-line function that mixes six stages;
- a config list mutated in a loop and read by a later step;
- the same helper copy-pasted into five scripts with drifting signatures;
- `NULL` meaning three different things;
- nested `ifelse()` four levels deep.

The fix is not "more functions." It is **editability by construction**: one job per function, explicit contracts, one place to change, a fixture to verify, and a cache so you can rerun a single stage.

## Install

The skills use the open **Agent Skills** layout: one directory per skill containing `SKILL.md`. The same file works in Claude Code, Codex CLI, Cursor, Gemini CLI, OpenCode, and other compatible agents.

```bash
# global, all known agents
./scripts/install.sh

# one agent, global or project scope
./scripts/install.sh claude global
./scripts/install.sh codex project
```

The script symlinks `skills/*` into the right directories, so a `git pull` updates every installed copy.

Manual equivalent, for example with OpenCode:

```bash
mkdir -p .opencode/skills
ln -s "$PWD/skills/explore-r" .opencode/skills/explore-r
ln -s "$PWD/skills/debug-r"   .opencode/skills/debug-r
ln -s "$PWD/skills/write-r"   .opencode/skills/write-r
```

### Agent paths

| Agent | Project path | Global path |
|---|---|---|
| Claude Code | `.claude/skills/` | `~/.claude/skills/` |
| Codex CLI | `.agents/skills/` | `~/.agents/skills/` |
| Cursor | `.cursor/skills/` | `~/.cursor/skills/` |
| Gemini CLI | `.gemini/skills/` | `~/.gemini/skills/` |
| OpenCode | `.opencode/skills/` | `~/.config/opencode/skills/` |
| GitHub Copilot | client-dependent | `~/.copilot/skills/` |

See `docs/compatibility.md` for caveats and legacy paths.

### Agents that do not read `SKILL.md`

Point them at `AGENTS.md`. It contains the loop, the mode selection, the non-negotiables, and links to the three skills. The repository also ships thin entry points for agents that expect a specific filename:

- `CLAUDE.md` for Claude Code (imports `AGENTS.md`)
- `GEMINI.md` for Gemini CLI
- `.github/copilot-instructions.md` for GitHub Copilot
- `.aider.conf.yml` for Aider

## Contents

```
clear-code.skills/
├── README.md
├── AGENTS.md
├── CLAUDE.md
├── GEMINI.md
├── PUBLISHING.md
├── .github/copilot-instructions.md
├── .aider.conf.yml
├── skills/
│   ├── explore-r/SKILL.md
│   ├── debug-r/SKILL.md
│   └── write-r/SKILL.md
├── references/
│   ├── editability-rubric.md
│   └── case-study.md
├── examples/
│   ├── synthetic_cohort.csv
│   └── run_all.R
├── scripts/
│   └── install.sh
└── docs/
    └── compatibility.md
```

- `references/editability-rubric.md` — the five tests and how to score them.
- `references/case-study.md` — a full before/after fold with scores.
- `examples/run_all.R` — the "after" code, runnable with base R only.

## How to use it

1. **Exploring?** Ask for `explore-r`. The skill will make you write a header, named intermediates, a conclusion block, and a promotion list.
2. **Something is wrong?** Ask for `debug-r`. The skill will force a fixture, a stage, and a frozen output before any edit.
3. **Promoting or refactoring?** Ask for `write-r`. The skill will refuse to fold until the prerequisites are met, then enforce contracts, spec tables, and stage caches.
4. **Reviewing agent code?** Ask for `write-r` in review mode. It returns a findings table and makes no edits.

## What the skills assume

- **Agent Skills format.** `SKILL.md` with YAML frontmatter using only portable fields: `name`, `description`, `metadata`.
- **R is the reference language.** Examples use base R; the workflow and rubric are language-agnostic.
- **Synthetic data only.** No example contains real patients, cohorts, paths, or results.

## Design stance

- The gate matters more than the rule of three. Duplication is allowed while exploring; it must be resolved before delivery.
- Preserve behaviour when refactoring. Separate the refactor from the feature.
- A function is not automatically simpler. It is simpler only if it gives you one edit site and one way to verify.
- The test is not "does it look clean?" It is: *can I change one behaviour by editing one place, under ten lines, without running the whole script or holding 200 lines in my head?*

## Publishing

See `PUBLISHING.md` before the first public push.

## License

Apache-2.0. See `LICENSE`.

## Acknowledgements

The simplification stance draws on [`addyosmani/agent-skills`](https://github.com/addyosmani/agent-skills), especially its `code-simplification` skill. Check that project's license before reusing text verbatim.
