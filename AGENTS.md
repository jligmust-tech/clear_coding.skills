# Clear Code

Instructions for coding agents working in this repository.

## What this is

Three portable Agent Skills for writing, exploring, and debugging code that stays editable:

| Skill | File | Use when |
|---|---|---|
| explore | `skills/explore-r/SKILL.md` | the data shape is unknown; scratch work; several plots or models |
| debug | `skills/debug-r/SKILL.md` | a value, plot, join, or model output is wrong |
| write | `skills/write-r/SKILL.md` | code will be rerun; promoting a notebook; refactoring |

R is the reference language. The workflow and the rubric are language-agnostic.

## The loop

```
explore  ──promotion gate──▶  write
   ▲                            │
   └──────── debug ◀────────────┘
```

## Before acting

1. Decide which mode the request belongs to.
2. Read the matching `SKILL.md` in full.
3. Follow its checklist. Do not skip the promotion gate.

## Non-negotiables

- **Synthetic data only.** Never add real patient data, personal paths, names, cohorts, or results.
- **Preserve behaviour when refactoring.** Separate the refactor from the feature.
- **One behaviour change, one edit site.** If that is not possible, say so before editing.
- **No speculative helpers.** Do not extract a function for a single use. Do not copy a helper across files.
- **No hidden state.** No mutated inputs, no global flags, no `<<-`, no multi-meaning `NULL`.
- **No absolute paths, credentials, or private repository names.**

## The editability test

> Can I change one behaviour by editing one place, under ten lines, without running the whole script or holding 200 lines in my head?

Score the five tests in `references/editability-rubric.md`. Deliverable code passes 8/10; scratch code is exempt but must still run top to bottom.

## When reviewing

Do not edit. Return one table row per finding:

| Location | Failed test | Why it hurts editing | Minimal fix |
|---|---|---|---|

## Layout

```
skills/       the three SKILL.md files
references/   the rubric and a before/after case study
examples/     synthetic data and a runnable base-R example
scripts/      install.sh for common agents
docs/         per-agent paths and caveats
```
