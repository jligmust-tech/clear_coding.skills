#!/usr/bin/env Rscript
# Runnable version of the case study, base R only.
# Run from the repository root:
#   Rscript examples/run_all.R

args <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", args[grepl("^--file=", args)])
base_dir <- if (length(file_arg) > 0) dirname(normalizePath(file_arg)) else "examples"

cohort <- read.csv(file.path(base_dir, "synthetic_cohort.csv"),
                   stringsAsFactors = FALSE)

stopifnot(nrow(cohort) == 6)
stopifnot(all(c("id", "group", "marker_1", "feature_1", "feature_2") %in% names(cohort)))

# ---- spec table ------------------------------------------------------------

FEATURES <- data.frame(
  id    = c("feature_1", "feature_2"),
  label = c("Feature 1", "Feature 2"),
  fill  = c("steelblue", "grey70"),
  stringsAsFactors = FALSE
)

# ---- pure functions --------------------------------------------------------

summarise_feature <- function(d, feature) {
  stopifnot(feature %in% names(d))
  out <- aggregate(
    x = d[[feature]],
    by = list(group = d$group),
    FUN = function(x) mean(x, na.rm = TRUE)
  )
  names(out)[names(out) == "x"] <- "mean"
  out$feature <- feature
  out
}

plot_feature <- function(d, feature, label, fill) {
  stopifnot(feature %in% names(d))
  boxplot(d[[feature]] ~ d$group,
          col = fill, ylab = label, xlab = "")
}

# ---- run -------------------------------------------------------------------

summaries <- lapply(FEATURES$id, function(f) summarise_feature(cohort, f))
summary_df <- do.call(rbind, summaries)

stopifnot(nrow(summary_df) == nrow(FEATURES) * length(unique(cohort$group)))
stopifnot(!anyNA(summary_df$mean))

print(summary_df)

# Write the plots to a temporary device so the example leaves no files behind.
pdf(tempfile(fileext = ".pdf"))
for (i in seq_len(nrow(FEATURES))) {
  plot_feature(cohort, FEATURES$id[i], FEATURES$label[i], FEATURES$fill[i])
}
dev.off()

# ---- regression demo -------------------------------------------------------
# A small group must produce a row with NA, not disappear.

cut_stats <- function(d, min_n = 3) {
  data.frame(
    n    = nrow(d),
    mean = if (nrow(d) < min_n) NA_real_ else mean(d$feature_1, na.rm = TRUE)
  )
}

by_group <- split(cohort, cohort$group)
res <- do.call(rbind, lapply(by_group, cut_stats))

stopifnot(nrow(res) == length(unique(cohort$group)))
stopifnot(anyNA(res$mean))

cat("\nRegression demo (cohort_b has n = 2, so its mean is NA but the row remains):\n")
print(res)

cat("\nAll checks passed.\n")
