# Publishing checklist

Run this before the first public push and before every release.

The goal is simple: **no real data, no personal paths, no identity, no private repository names.**

## 1. Keep the denylist outside the repo

Create `../denylist.txt` next to the checkout, never inside it. Put every term that must not appear in public:

```text
<your-username>
<your-email-domain>
<your-institution>
<your-data-root>
<your-private-repo-name>
<your-cohort-name>
<your-drive-name>
```

Then:

```bash
git grep -nF -f ../denylist.txt
```

An empty result is the only pass.

## 2. Scan for paths and identifiers

```bash
# absolute paths
git grep -nE '/User[s]/|/Volume[s]/|/hom[e]/|[A-Za-z]:\\'

# email addresses (do not scan for a bare "@": R S4 slots use it)
git grep -nE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'

# common sensitive tokens
git grep -nE 'TCG[A]-|PAT[0-9]{3}|MRN|token|secret|password|api[_-]?key'
```

Review every hit. Some are legitimate (the word "token" in prose); most are leaks. `PAT001`–`PAT006` in `examples/` are intentional synthetic placeholders, not leaks.

## 3. Clean-room run

Copy the repository somewhere with no data and run every example:

```bash
tmp="$(mktemp -d)"
cp -R . "$tmp/repo"
cd "$tmp/repo"
Rscript examples/run_all.R
```

If an example needs a file that is not in the repository, the example is wrong.

## 4. Check history, not just the working tree

A clean working tree can still have a dirty history.

```bash
git log -p | grep -nF -f ../denylist.txt
```

For a new repository, start with a fresh `git init`; never copy `.git` from a private project. If history must be reused:

```bash
git filter-repo --replace-text ../replacements.txt
```

## 5. Set the public identity deliberately

```bash
git config user.name  "<public name>"
git config user.email "<id>@users.noreply.github.com"
```

Decide before the first commit. Changing it later means rewriting history.

## 6. Confirm the ignore rules

`.gitignore` must exclude at least:

```text
data/
cache/
output/
debug/
*.rds
*.pdf
*.png
*.xlsx
.Rhistory
.RData
.Rproj.user
.env
```

Data goes in the repository only if it is synthetic and small enough to review by eye.

## 7. Check the examples themselves

- [ ] Every path is relative (`data/...`, `output/...`).
- [ ] Every row is synthetic (`PAT001`, `cohort_a`, `feature_1`).
- [ ] No real cohort, disease, marker, gene, or institution names.
- [ ] No figure copied from a real analysis.
- [ ] No `sessionInfo()` output, hostname, or package library path in the docs.
- [ ] The examples run with the packages declared in the README.
- [ ] Line counts and file names in prose are rounded or generic.

## 8. License and attribution

- [ ] A `LICENSE` file exists and matches the README.
- [ ] If text is adapted from another project, its license is compatible and credited.
- [ ] The README states that all examples are synthetic.

## 9. Final read

Open the repository in a browser as a stranger.

- Does the README explain the loop in under a minute?
- Can you find the install command without scrolling?
- Does any example look like it came from a real study?
- Would a search for your name, institution, or dataset find this page?

If the last answer is yes, go back to step 1.
