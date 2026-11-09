---
name: explore-r
description: Notebook-mode R for exploratory analysis — write fast, keep intermediates inspectable, and leave a script that still runs from a clean session. Use when the shape of the data is unknown, when you are trying several plots or models, or when the code is scratch work that may never become a deliverable. Triggers — explore this dataset, quick look, try a few plots, scratch script, notebook mode, 探索, 快速看一下.
metadata:
  audience: data analysts
  workflow: exploratory
  language: R
---

# Explore R — notebook mode

## What this mode is for

You do not know the data yet. You need to look, try, discard, and look again. The cost of writing a function is higher than the cost of pasting a block, because the question may change in five minutes.

This mode protects that speed. It also protects you from the failure mode of notebooks: a script that only runs if you execute lines in a magic order.

**The contract**

- Fast to write.
- Intermediates visible and named.
- Re-runnable top to bottom in a clean session by the end of the day.
- Disposable by default. Nothing here is a deliverable.

## When not to use it

| Situation | Use instead |
|---|---|
| Someone else will rerun the code | `write-r` |
| A known bug is being fixed | `debug-r` |
| The analysis is settled and needs to be handed over | promote with `write-r` |
| The same block has been copied a third time with a stable variation axis | extract it, then continue here |

## Script header

Every exploratory script starts with this. It takes thirty seconds and saves a week.

```r
# ============================================================
# explore: <one-sentence question>
# date:    2026-11-09
# data:    data/example_cohort.csv  (read-only)
# run:     clean session; source top to bottom
# expect:  cohort (n = 6), features (n = 2)
# ============================================================
```

The `expect` line is the seed of every assertion you will later need.

## Section anatomy

Use four section types, in order. Not every script needs all four, but the order is fixed.

```r
# == 1. load ================================================
cohort <- read.csv("data/example_cohort.csv")
str(cohort)
stopifnot(nrow(cohort) == 6)

# == 2. look ================================================
summary(cohort$feature_1)
table(cohort$group, useNA = "ifany")

# == 3. try =================================================
# Q: does feature_1 differ by group?
boxplot(feature_1 ~ group, data = cohort)

# == 4. conclude ============================================
# learned:  ...
# promote:  boxplot by group -> write-r
# delete:   ...
```

Rules for the sections:

1. **One question per `try` section.** If you have two questions, make two sections.
2. **One plot or model per block.** Do not chain eight transformations into one pipe and then plot the result; you cannot tell which step changed the shape.
3. **Name every intermediate.** `raw`, `clean`, `scored`, `plot_df`. Reuse the names consistently.
4. **Never overwrite the input.** If a transformation is needed, assign to a new name.
5. **Long domain names are fine here.** Add a one-line comment saying what the object is. Retrieval beats brevity in a notebook.
6. **No functions until the third stable repetition**, and only when the axis of variation is stable. Three copies that differ by a column are a spec table, not a function.
7. **At most one `00_load.R`.** Do not `source()` a sibling analysis; that is how hidden globals start.
8. **Expensive objects go to `cache/`** as `saveRDS(obj, "cache/<name>_<date>.rds")`.
9. **End with the conclusion block.** If you cannot write it, the section is not finished.

## Markers

Use three markers consistently. They survive grep and they tell the next reader what kind of attention a line needs.

| Marker | Meaning | Action |
|---|---|---|
| `#!` | Human checkpoint | Inspect this value before trusting downstream output |
| `#?` | Open question | Unresolved; do not promote yet |
| `#X` | Dead end | Keep it; it records what was tried and why it failed |

`#X` is not clutter. It is the cheapest form of documentation you will ever write.

## Debugging inside this mode

- Run the **block**, not the script.
- Put `print()` or `str()` immediately before and after the suspect line.
- Keep a `known_good/` copy of the previous output before changing anything.
- When the block works, delete the probe — not the block.
- If the bug only appears in the full run, the problem is order or shared state, not the block.

For a systematic protocol, switch to `debug-r`.

## Promotion gate

A section is ready to leave notebook mode when all five are true:

- [ ] The question is settled; no `#?` markers remain in the section.
- [ ] The variation axes are known (what changes between instances, and what does not).
- [ ] A fixture exists: one row, one patient, one cohort, or one panel.
- [ ] The output is frozen somewhere for a later diff.
- [ ] The section runs top to bottom in a clean session.

If any box is unchecked, keep exploring. Folding too early is how a 40-line helper becomes a 200-line helper with six special cases.

## Minimal example

```r
# == 1. load ================================================
cohort <- read.csv("data/example_cohort.csv")
str(cohort)

# == 2. look ================================================
table(cohort$group, cohort$marker_1, useNA = "ifany")
summary(cohort$feature_1)

# == 3. try =================================================
# Q: is feature_1 higher in cohort_b?
boxplot(feature_1 ~ group, data = cohort)

# Q: does the marker explain the split?
boxplot(feature_1 ~ marker_1, data = cohort)

# == 4. conclude ============================================
# learned: cohort_b is higher; marker_1 is unbalanced across groups.
# promote: the first plot, once the group sizes are confirmed.
# delete:  the second plot; it confounds group and marker.
```

## Anti-patterns, even in scratch

These are the habits that make a notebook unrecoverable. They cost nothing to avoid.

- `setwd()` — use relative paths or `here::here()`.
- Hardcoded absolute paths — use `data/`, `output/`, and a `DATA_ROOT` environment variable.
- `rm(list = ls())` at the top — it hides dependencies instead of resolving them.
- `source()` chains — one loader, no sibling analyses.
- Overwriting the input object — always assign to a new name.
- A script that depends on a specific line execution order — if it cannot run top to bottom, it is not finished.
- Silent type changes — `str()` after every load and every join.

## Exit checklist

- [ ] Header is complete: question, date, data, run order, expected shape.
- [ ] The script runs top to bottom in a fresh session.
- [ ] Intermediates are named and inspectable.
- [ ] `#!`, `#?`, and `#X` markers are used where they belong.
- [ ] The conclusion block lists what was learned, what to promote, and what to delete.
- [ ] Expensive results are cached, not recomputed.
