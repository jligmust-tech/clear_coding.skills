# The editability rubric

Five tests. Score each 0, 1, or 2. Maximum 10.

Use it when code is about to be handed to someone else — a collaborator, a reviewer, or future you. Do **not** use it to score scratch work; scratch has its own contract (see `explore-r`).

> The question behind the rubric: **can I change one behaviour by editing one place, under ten lines, without running the whole script or holding 200 lines in my head?**

---

## 1. Locate

Can you find the responsible line in under 30 seconds?

| Score | Evidence |
|---|---|
| 0 | You must read the whole file, or grep several names to find it. |
| 1 | There is a section banner, but the logic is nested three levels down. |
| 2 | One function name, one call site, one obvious place. |

## 2. Isolate

Can you run just that piece on one case?

| Score | Evidence |
|---|---|
| 0 | It only runs as part of the full pipeline, with global state and side effects. |
| 1 | You can run it after loading a cached stage, but only by hand-editing the script. |
| 2 | `f(fixture_row)` works, or `Rscript run.R --stage 2 --limit 1`. |

## 3. Inspect

Can you see the intermediate it consumes and produces?

| Score | Evidence |
|---|---|
| 0 | Only the final figure or file is visible. |
| 1 | A cache file exists, but what is in it and when it was written are undocumented. |
| 2 | Named stage objects, written to `cache/`, with a `DEBUG` switch that returns intermediates. |

## 4. Change

Is the fix ten lines or fewer, in one place?

| Score | Evidence |
|---|---|
| 0 | The same edit is needed in N copied blocks. |
| 1 | One function, but it owns several unrelated concerns, so the edit risks side effects. |
| 2 | One function, or one row in a spec table. |

## 5. Verify

Can you prove the other instances did not break?

| Score | Evidence |
|---|---|
| 0 | You look at the final figure and hope. |
| 1 | You can diff the output against a frozen copy. |
| 2 | Assertions at stage boundaries, a frozen output diff, and a one-row fixture test. |

---

## Interpreting the score

| Total | Meaning |
|---|---|
| 9–10 | Deliverable. Hand it over. |
| 8 | Acceptable. Note the missing point. |
| 5–7 | Prototype. Promote before it becomes load-bearing. |
| 0–4 | Scratch. Keep it in `explore-r`; do not build on it. |

An 8 is a pass, not a target. The two easiest points to lose are **Isolate** and **Verify**, because they cost effort up front and pay back only when something changes.

## Using it in review

Do not rewrite the code. Produce a table:

| Location | Failed test | Why it hurts editing | Minimal fix |
|---|---|---|---|
| `plot_overview()` | Change | Six concerns in one body | Split at the blank-line boundaries into stages |
| `cfg$platform` | Inspect | A placeholder is overwritten later | Compute once, pass as an argument |
| `norm_*` family | Change | Six copies of one skeleton | Spec table + one interpreter |

One row per finding. The minimal fix is the smallest change that moves the score up one point — not a rewrite.
