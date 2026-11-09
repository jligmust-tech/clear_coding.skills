---
name: debug-r
description: Debug R by reducing to a fixture, locating the failing stage, fixing once, and adding a regression check. Works for unrolled notebook code and for staged pipelines. Use when a number, plot, join, or model output is wrong, when something that worked before changed, or when an error only appears in the full run. Triggers — debug this, why is this NA, the numbers changed, this plot is wrong, error in, it worked before.
metadata:
  audience: data analysts
  workflow: debugging
  language: R
---

# Debug R — locate, reduce, fix once

## The one rule

**Never debug the full run when a three-second fixture exists.**

The full run hides the failure in noise: too many rows, too many groups, too many stages. A fixture makes the failure small enough to see.

## Step 0 — Freeze the failing output

Before touching anything, save what is wrong. You need a diff target, and you need to know whether your fix changed anything else.

```r
dir.create("debug", showWarnings = FALSE)
file.copy("output/result.csv", "debug/known_bad_result.csv", overwrite = TRUE)
file.copy("output/figure.pdf", "debug/known_bad_figure.pdf", overwrite = TRUE)
```

If the output is a plot, also save the data that produced it. A wrong plot is usually a wrong data frame, not a wrong `ggplot` call.

## Step 1 — Reduce to a fixture

Try, in this order:

1. One row / one patient.
2. One column / one feature.
3. One group / one cohort.
4. One panel / one instance.
5. One stage.

```r
fixture <- read.csv("data/example_cohort.csv")[1, ]
```

If the bug disappears on the fixture, you have learned something important: the per-row logic is fine and the bug is in an aggregation, a join, or a loop that only some rows reach. That is progress, not failure.

Write the fixture down. It becomes the regression test in Step 7.

## Step 2 — Locate the stage

### Notebook lane

You have an unrolled script. Bisect by section.

```r
# == 1. load ==
# == 2. look ==
# == 3. try ==   <- suspect
# == 4. conclude ==
```

- Comment out sections from the bottom until the bad value disappears.
- Or run top to bottom and inspect after each section.
- Print the object immediately **before** and **after** the suspect block.
- If the value is already wrong before the block, the bug is upstream.

### Pipeline lane

You have staged functions and cached intermediates. Run only the failing stage.

```r
source("R/stages.R")

data   <- readRDS("cache/01_data.rds")
scored <- score_stage(data)
saveRDS(scored, "cache/02_scored_debug.rds")
```

If there is no cache, add one before debugging. That is the change that makes the next bug cheap.

## Step 3 — Inspect the intermediate

Do not guess. Look at the object.

```r
str(x)
summary(x)
head(x)
table(x$group, useNA = "ifany")
nrow(x); ncol(x)
names(x)
sapply(x, class)
```

For joins and merges, check three things:

```r
nrow(before); nrow(after)                  # did rows disappear?
setdiff(unique(before$id), unique(after$id))  # who is missing?
table(duplicated(after$id))                # did rows multiply?
```

For grouped results, compare the number of groups before and after:

```r
length(unique(input$group))
length(unique(output$group))
```

A mismatch is almost always a silent `NULL` drop or an inner join.

## Step 4 — One hypothesis, one change

Write the hypothesis as a comment before you edit.

```r
# hypothesis: cut_stats() returns NULL for groups with n < 5,
#             and rbind() silently drops those groups.
```

Then change one thing, rerun the fixture, and look.

If it is not fixed, **revert before the next hypothesis.** Stacking guesses is how a one-line bug becomes a three-hour refactor.

## Step 5 — Classify the fix

| Type | Example | Action |
|---|---|---|
| **Positional** | Wrong column or index for one panel | Fix locally and record why this instance differs |
| **Conceptual** | Wrong rule for every instance | Fix the function or spec, then rerun the whole family |

Never encode a conceptual fix as a one-off `if` inside a loop. That is how a family of instances drifts: one special case at a time.

If the fix is conceptual, ask: *which other call sites share this assumption?* Fix them in the same change.

## Step 6 — Verify at three scales

1. **Fixture** — the smallest case now produces the expected value.
2. **Family** — every instance of that analysis, not just the one that failed.
3. **Full run** — the complete pipeline from a clean session.

Then diff against the frozen output:

```r
old <- read.csv("debug/known_bad_result.csv")
new <- read.csv("output/result.csv")
# explain every changed row, not just the one you intended to change
```

Unexplained changes are new bugs. Do not ship them because the target number looks right.

## Step 7 — Add a regression check

The bug is not fixed until it cannot come back silently.

```r
# check_result.R
stopifnot(nrow(result) == length(unique(cohort$group)))
stopifnot(!anyNA(result$estimate))
```

Or a fixture test:

```r
stopifnot(identical(map_marker(NA_character_), "unknown"))
```

Keep the fixture in `tests/fixtures/` or `debug/`. It is cheaper than rediscovering the bug.

## Tool table

| Need | Use |
|---|---|
| Step into a function once | `debugonce(f)` |
| Stop at a line | `browser()` |
| Trace a call | `trace(f, print = TRUE)` |
| Drop into the browser on error | `options(error = recover)` |
| Catch and inspect an error | `tryCatch(expr, error = function(e) e)` |
| See the call stack | `rlang::last_trace()` |
| Print inside a pipeline | `message()` temporarily; remove it after |
| Snapshot an object | `saveRDS(obj, "debug/<name>.rds")` |
| Compare two data frames | `waldo::compare(old, new)` |

## Worked example

**Symptom.** A grouped summary has three groups in the input and two in the output. No error is raised.

```r
cut_stats <- function(d) {
  if (nrow(d) < 5) return(NULL)
  data.frame(n = nrow(d), mean = mean(d$value))
}

res <- do.call(rbind, lapply(split(cohort, cohort$group), cut_stats))
```

**Reduce.** Use the smallest group as the fixture.

```r
small <- subset(cohort, group == "cohort_c")
nrow(small)          # 3
cut_stats(small)     # NULL
```

**Locate.** The bug is not in `rbind()`; it is in the contract of `cut_stats()`. A function that sometimes returns `NULL` silently deletes a group.

**Fix.** Decide what "too small" means and make it explicit.

```r
cut_stats <- function(d, min_n = 5) {
  data.frame(
    n    = nrow(d),
    mean = if (nrow(d) < min_n) NA_real_ else mean(d$value)
  )
}

res <- do.call(rbind, lapply(split(cohort, cohort$group), cut_stats))
```

**Classify.** Conceptual. Every caller of `cut_stats()` inherits the old NULL-dropping behaviour, so all callers must be checked.

**Regress.**

```r
stopifnot(nrow(res) == length(unique(cohort$group)))
stopifnot(identical(rownames(res), sort(unique(cohort$group))))
```

## Anti-patterns

- Debugging the thirty-minute run when a three-second fixture exists.
- Adding a permanent `print()` and forgetting it.
- Fixing the output instead of the input.
- Rerunning from scratch when a cache exists.
- One-off `if` special cases inside a family.
- Changing several things at once, then not knowing which one worked.
- No frozen output, so "it looks right" is the only verification.
- Fixing the symptom in the final figure while the data frame stays wrong.

## Checklist

- [ ] Failing output frozen.
- [ ] Fixture is one row / one group / one stage.
- [ ] Failing stage identified.
- [ ] Intermediate inspected, not guessed.
- [ ] One hypothesis per change.
- [ ] Fix classified as positional or conceptual.
- [ ] Fixture, family, and full run verified.
- [ ] Output diff explained.
- [ ] Regression check added.
