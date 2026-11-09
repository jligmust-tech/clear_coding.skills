# Case study: unroll, then fold

A synthetic example. The data is six rows; the pattern is the point.

## The notebook version

The analysis starts as two copied blocks because the second feature is "just like the first one."

```r
cohort <- read.csv("data/example_cohort.csv")

# ---- feature 1 ----
summary_1 <- aggregate(
  feature_1 ~ group,
  data = cohort,
  FUN = function(x) mean(x, na.rm = TRUE)
)
summary_1$feature <- "feature_1"

pdf("output/feature_1.pdf", width = 4, height = 3)
boxplot(feature_1 ~ group, data = cohort,
        col = "steelblue", ylab = "Feature 1", xlab = "")
dev.off()

# ---- feature 2 ----
summary_2 <- aggregate(
  feature_2 ~ group,
  data = cohort,
  FUN = mean
)
summary_2$feature <- "feature_2"

pdf("output/feature_2.pdf", width = 4, height = 3)
boxplot(feature_2 ~ group, data = cohort,
        col = "grey70", ylab = "feature_2", xlab = "")
dev.off()

write.csv(rbind(summary_1, summary_2), "output/summary.csv", row.names = FALSE)
```

It works. The two blocks are not identical, and that is the warning sign.

## The drift

| Aspect | `feature_1` block | `feature_2` block | Intentional? |
|---|---|---|---|
| Missing values | `na.rm = TRUE` | default (`FALSE`) | No — accidental |
| Y label | `"Feature 1"` | `"feature_2"` | No — inconsistent |
| Fill | `"steelblue"` | `"grey70"` | Maybe — a palette decision |
| Output name | `feature_1.pdf` | `feature_2.pdf` | Yes — instance identity |

Two of the four differences are accidents. This is the cost of copy-paste: the blocks diverge without anyone deciding to diverge.

## The fold

The variation axis is stable: **the feature**. The analysis is the same; only the column, label, and fill change. That is a spec table, not two functions.

```r
FEATURES <- data.frame(
  id    = c("feature_1", "feature_2"),
  label = c("Feature 1", "Feature 2"),
  fill  = c("steelblue", "grey70"),
  stringsAsFactors = FALSE
)

summarise_feature <- function(d, feature) {
  stopifnot(feature %in% names(d))
  out <- aggregate(
    d[[feature]] ~ d$group,
    data = d,
    FUN = function(x) mean(x, na.rm = TRUE)
  )
  names(out) <- c("group", "mean")
  out$feature <- feature
  out
}

plot_feature <- function(d, feature, label, fill) {
  stopifnot(feature %in% names(d))
  ggplot2::ggplot(d, ggplot2::aes(x = group, y = .data[[feature]])) +
    ggplot2::geom_boxplot(fill = fill) +
    ggplot2::labs(x = NULL, y = label) +
    ggplot2::theme_classic(base_size = 9)
}

summaries <- lapply(FEATURES$id, function(f) summarise_feature(cohort, f))
summary_df <- do.call(rbind, summaries)
stopifnot(nrow(summary_df) == nrow(FEATURES) * length(unique(cohort$group)))

for (i in seq_len(nrow(FEATURES))) {
  p <- plot_feature(
    cohort,
    FEATURES$id[i],
    FEATURES$label[i],
    FEATURES$fill[i]
  )
  ggplot2::ggsave(
    file.path("output", paste0(FEATURES$id[i], ".pdf")),
    p, width = 4, height = 3
  )
}

write.csv(summary_df, "output/summary.csv", row.names = FALSE)
```

Three things changed beyond the obvious extraction:

1. `na.rm = TRUE` is now uniform. The accidental difference is gone.
2. The label comes from the table, so it cannot drift from the column name.
3. The assertion checks the output shape **per feature and per group**, not just that the file exists.

## Why this fold is safe

The rule is not "three copies means extract." The rule is:

> Extract when the axis of variation is stable and named.

Here the axis is one column: the feature. The table enumerates every instance, so a new feature is a new row. The function does not need a special case, and no instance loses its identity.

What would have been premature:

- Extracting before the second feature existed, then discovering that feature 2 needs a different aggregation.
- Hiding the fill difference inside the function as `if (feature == "feature_2")`.
- Returning `NULL` for a group with missing data, then relying on `rbind()` to drop it.

## Rubric score

| Test | Before | After | Why |
|---|---|---|---|
| **Locate** | 1 | 2 | Two copied blocks → one function per concern |
| **Isolate** | 1 | 2 | `summarise_feature(cohort, "feature_1")` runs alone |
| **Inspect** | 0 | 2 | `summary_df` is a named object; cacheable |
| **Change** | 0 | 2 | Change the table row, not two blocks |
| **Verify** | 0 | 2 | Assertions plus a frozen-output diff |
| **Total** | **2/10** | **10/10** | |

## What the fold did not fix

The functions still write files at the call site, and the script still has no stage cache. In a real promotion, those would be the next two moves:

```r
saveRDS(cohort, "cache/01_data.rds")
saveRDS(summary_df, "cache/02_summary.rds")
```

Then a change to the plotting function costs one stage, not the whole run.

That is the point of the promotion gate: folding is one step, and it happens only after the axis of variation is understood.
