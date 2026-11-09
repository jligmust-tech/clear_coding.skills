---
name: write-r
description: Write or refactor R that stays editable — staged functions, explicit contracts, spec tables for repeated families, stage caches, and a definition of done. Use when code will be rerun by someone else, when turning a notebook into a deliverable, or when reviewing agent-written R for editability. Triggers — write the final script, make this a pipeline, turn the notebook into a deliverable, refactor this, this will be rerun, review this code.
metadata:
  audience: data analysts
  workflow: deliverable
  language: R
---

# Write R — deliverable mode

## What this mode is for

The analysis is settled. Someone else will rerun it, or future you will rerun it after the details are gone. The code now has to do two jobs: produce the result, and make the next change cheap.

Most "clean code" advice optimizes the first job. This skill optimizes the second.

**The standard:** can you change one behaviour by editing one place, under ten lines, without running the whole script or holding 200 lines in your head?

## When not to use it

| Situation | Use instead |
|---|---|
| The question is still moving | `explore-r` |
| A known bug is being fixed | `debug-r` first, then come back |
| The code is a one-off you will delete tomorrow | `explore-r` |
| You only need to review, not edit | review mode at the bottom of this skill |

## Promotion prerequisites

Do not fold until all five are true. Folding early is how a 40-line helper becomes a 200-line helper with six special cases.

- [ ] The question is settled; no open `#?` markers.
- [ ] The variation axes are known: what changes between instances, and what does not.
- [ ] A fixture exists: one row, one patient, one cohort, or one panel.
- [ ] The current output is frozen for a later diff.
- [ ] The unrolled version runs top to bottom in a clean session.

## Architecture: stages, not steps

```
load → validate → compute → plot → save
```

Each stage:

- is one function;
- takes explicit inputs and returns one object;
- writes a cache file;
- can run alone.

```
run_analysis.R
R/
  load.R
  validate.R
  compute.R
  plot.R
cache/
  01_data.rds
  02_scored.rds
output/
  03_figure.pdf
```

The cache is the deliverable equivalent of "jump to the block." Without it, every edit costs a full rerun. With it, a bug in the plotting stage takes three seconds to reproduce.

## Ten rules

### 1. One job per function, ≤40 lines, nesting ≤2

If the body needs a comment every five lines to explain the phases, it is several functions wearing one name.

### 2. Pure core, side effects at the bottom

Compute and plot functions return objects. Only the bottom of the script writes files.

```r
# good
scored <- score_stage(data)
plot_obj <- plot_panel(panels[1, ], scored)

# at the bottom
saveRDS(scored, "cache/02_scored.rds")
ggsave("output/figure.pdf", plot_obj)
```

A function that reads a global, writes a file, and returns `NULL` cannot be tested or reused.

### 3. Explicit contract: named arguments, one return shape

```r
# bad: what does NULL mean here?
summarise_group <- function(d, min_n = NULL) { ... }

# good: one meaning per argument
summarise_group <- function(d, min_n = 5) { ... }
```

Rules:

- One return shape. Always a data frame, or always a list, or always `NULL` with a documented reason.
- Never use `NULL` for three different meanings ("use default", "drop", "unknown").
- Pass config values as arguments, not by mutating a shared list.
- Use `stopifnot()` at the top for preconditions.

### 4. No hidden state

- Do not mutate an outer object from inside a function.
- Do not use `<<-` for core logic.
- Do not use `assign()` or `get()` to route data.
- Do not rely on a global flag set in another file.
- Return a new object instead of attaching fields to an input.

```r
# bad: the caller's spec changes under it
for (i in seq_len(nrow(spec))) {
  spec$states[[i]] <- compute_states(spec[i, ])
}

# good: build a new spec
spec$states <- lapply(seq_len(nrow(spec)), function(i) compute_states(spec[i, ]))
```

### 5. Names: `verb_noun` for functions, meaning for locals

- Functions: `load_cohort`, `score_marker`, `plot_panel`.
- Booleans: `is_valid`, `has_missing`.
- Locals: meaningful once a scope exceeds about fifteen lines. `d`, `x`, `v` are fine in a three-line lambda and hostile in a 200-line function.
- One name for one concept across the whole script. Do not alternate `df`, `dat`, `data`, `tbl`.

### 6. One style object

```r
STYLE <- list(
  base_size   = 9,
  line_width  = 0.4,
  point_size  = 1.2,
  ok_colour   = "#4C78A8",
  warn_colour = "#E45756"
)
```

No repeated font sizes, units, alpha values, or log ranges scattered through the file. If a number appears twice, it belongs in `STYLE`, a spec table, or a named constant.

### 7. Repeated families → spec table + one interpreter

Do not write six near-identical `norm_*` helpers. Write one function and a table of the differences.

```r
markers <- data.frame(
  id      = c("marker_1", "marker_2"),
  unknown = c("unknown", NA_character_),
  label   = c("Marker 1", "Marker 2"),
  stringsAsFactors = FALSE
)

normalise_marker <- function(x, unknown) {
  out <- ifelse(x %in% c("mut", "wt"), x, unknown)
  stopifnot(length(out) == length(x))
  out
}

cohort$marker_1_norm <- normalise_marker(cohort$marker_1, markers$unknown[1])
```

The table is the documentation. A new instance is a new row, not a new function.

### 8. Header block for every helper

```r
# purpose: summarise one feature by group
# input:   d         data frame with group and value
#          min_n     integer, groups below this get NA
# output:  data frame, one row per group
# effects: none
# example: summarise_feature(cohort, "feature_1")
```

If you cannot fill in `output` and `effects`, the contract is not clear enough to write.

### 9. Stage caches and a single-entry CLI

```r
# run_analysis.R
args <- commandArgs(trailingOnly = TRUE)
stage <- if (length(args) >= 1) as.integer(args[1]) else 3

if (stage <= 1) {
  data <- load_cohort("data/example_cohort.csv")
  saveRDS(data, "cache/01_data.rds")
}

if (stage <= 2) {
  data <- readRDS("cache/01_data.rds")
  scored <- score_stage(data)
  saveRDS(scored, "cache/02_scored.rds")
}

if (stage <= 3) {
  scored <- readRDS("cache/02_scored.rds")
  plot_obj <- plot_panel(scored)
  ggsave("output/figure.pdf", plot_obj)
}
```

`Rscript run_analysis.R 2` reruns from the scoring stage. That is the edit loop you want.

### 10. Assertions at boundaries, diff at the end

```r
stopifnot(nrow(data) > 0)
stopifnot(!anyDuplicated(data$id))
stopifnot(all(c("id", "group") %in% names(data)))
```

Then:

```r
old <- read.csv("output/known_good/result.csv")
new <- read.csv("output/result.csv")
# explain every changed row
```

Assertions catch structural breakage; the diff catches behavioural breakage. You need both.

## Editability by construction

These are the habits that make the one-place edit possible.

- **Knobs at the top.** Thresholds, columns, colours, and paths go in one block, not on line 187.
- **Lookup tables over nested `ifelse()`.** Four levels deep is unreadable and untestable.
- **Explicit loops when step-through matters.** `lapply()` is fine for a pure one-liner; a named accumulator loop is easier to debug.
- **A `DEBUG` switch instead of temporary prints.**
  ```r
  if (isTRUE(getOption("debug.stage"))) return(list(intermediate = x, result = y))
  ```
- **No clever one-liners for core logic.** Save the tricks for throwaway code.
- **A one-row call must work.** If `f(fixture)` fails, the function is not ready.
- **Stage names are nouns.** `raw`, `clean`, `scored`, `plot_df`. The name tells you where you are.

## Definition of done

- [ ] Editability rubric score ≥ 8/10.
- [ ] `f(fixture)` works for every core function.
- [ ] `Rscript run_analysis.R` runs from a clean session.
- [ ] Every stage can run alone from its cache.
- [ ] Output diff against the frozen version is explained.
- [ ] No absolute paths; data root comes from an argument or env var.
- [ ] No secrets, tokens, or credentials.
- [ ] `sessionInfo()` printed at the end of the run.
- [ ] The refactor is committed separately from any behaviour change.

## Refactor protocol

1. **Freeze** the current output.
2. **Change one concept** per commit: rename, or extract, or move saving — never all three.
3. **Run** after each change.
4. **Diff** the output.
5. **Commit** the refactor separately from the feature.
6. **Stop** if the diff is unexplained. Behaviour preservation is the constraint, not the goal.

## Anti-pattern gallery

These are structural patterns, not style opinions.

| Pattern | Why it hurts | Minimal fix |
|---|---|---|
| **The 200-line overview** | Mixes clustering, colour mapping, matrix assembly, legend assembly, drawing, and saving. You cannot run a piece. | Split at the natural stage boundaries; each becomes a function with a cache. |
| **The mutated spec** | A loop attaches fields to a config list; a later step reads them. The function's output depends on history. | Return a new object; never mutate the input. |
| **The multi-meaning `NULL`** | `NULL` means "default", "drop", or "unknown" depending on the caller. | Separate arguments, or an explicit sentinel. |
| **The drifting copy** | The same helper appears in five scripts with different signatures. Editing one does not fix the family. | One function, one spec table, one call site per instance. |
| **The bypassed helper** | A helper exists, but four call sites hand-build the same thing. Editing the helper changes nothing. | Delete the copies; route every call through the helper. |
| **The nested `ifelse()`** | Four levels deep, no way to see which rule fired. | Lookup table plus one `match()`/`merge()`. |
| **The placeholder overwritten later** | A config value is set to a dummy, then replaced thirty lines down. Readers trust the first value. | Compute once and pass it explicitly. |
| **The short name in a long scope** | `d`, `x`, `v` live for 200 lines and mean different things in different blocks. | Rename at the boundary; scope the variable tightly. |

## Review mode

When asked to review rather than edit, do **not** change the code. Produce this table:

| Location | Failed rubric test | Why it hurts editing | Minimal fix |
|---|---|---|---|
| `plot_overview()` | Change | Six concerns in one body | Split at blank-line boundaries |
| `cfg$platform` | Inspect | Overwritten later | Compute once, pass explicitly |
| `norm_*` family | Change | Six copies of one skeleton | Spec table + one interpreter |

One row per finding. The minimal fix moves the score up one point; it is not a rewrite.

## Checklist

- [ ] Promotion prerequisites met.
- [ ] Stages named and cacheable.
- [ ] Every function has one job and an explicit contract.
- [ ] No hidden state or mutated inputs.
- [ ] Repeated families are spec tables.
- [ ] Style constants live in one object.
- [ ] Assertions at boundaries.
- [ ] Fixture, full run, and output diff pass.
- [ ] Rubric ≥ 8/10.
