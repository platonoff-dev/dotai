---
name: autoresearch
description: Run an autonomous keep-or-revert loop that improves a measurable metric (latency, bundle size, coverage, error count, benchmark score) by trying one change per iteration, measuring it, and keeping only wins. Use when the user says "autoresearch", "Karpathy loop", "iterate until X improves", "optimize this overnight", or gives a goal plus a command that measures it.
---

# Autoresearch

Karpathy's autoresearch loop applied to engineering work. You agree on a contract with the user once. After that you run alone: one change, measure, keep or reset, log, repeat.

## 1. Agree on the contract

Settle all of these with the user before starting. Ask once, in one batch, for anything missing:

- **Goal**: what to improve.
- **Scope**: the files you may edit. Everything else is read-only.
- **Verify**: a command that prints the metric as one number, plus its direction (higher or lower is better). Example: `hyperfine -N --export-json /tmp/h.json './bench' >/dev/null && jq '.results[0].median' /tmp/h.json`.
- **Guard** (optional): a command that must keep passing, such as the test suite or a type check.
- **Budget**: a number of iterations or a wall-clock limit. The default is 25 iterations.

**Freeze the measurement.** The Verify command, its scripts, fixtures, benchmark inputs and the Guard's tests are off limits. Do not edit them, special-case their inputs, or skip work only when they are running. If a gain is suspiciously large, check whether you gamed the metric before you keep it.

## 2. Set up

1. Start from a clean tree and create the branch `autoresearch/<date>-<slug>`.
2. Create `results.tsv` with the header `commit	metric	delta	status	description`. Keep it untracked: add it to `.git/info/exclude`.
3. **Measure noise.** Run Verify 3 times on the unchanged code. If the results vary, use the median of 3 runs as the metric from now on. Set the keep threshold at about twice the observed spread. Without this step, the loop keeps noise and discards real wins.
4. Note how long Verify takes. A later run that takes more than 2× that is a crash.
5. Log the baseline as row 0 and confirm the setup with the user. **This is the last question you ask.**

## 3. Loop

1. **Review.** Read the last rows of `results.tsv` and `git log --oneline -15`. Don't retry discarded ideas unless you have a real twist on them.
2. **Change.** Make one focused change inside Scope, then commit it.
3. **Measure.** Redirect Verify output to a log file and extract only the number, so long output never enters your context. If no number comes out, read the log tail.
4. **Guard.** Run it if one is configured.
5. **Decide.**
   - **keep**: the guard passes and the metric improved by more than the threshold.
   - **keep**: the metric is within noise and the code got simpler, for example net deleted lines or a dependency removed.
   - **discard**: anything else. Also discard a gain within noise that adds real complexity. Undo with `git reset --hard HEAD~1`. The SHA stays in the log, so `git show <sha>` can still recover it.
   - **crash**: if the cause is trivial, such as a typo or missing import, fix it and re-measure the same idea. Otherwise log it and reset.
6. **Log.** Append a row: short SHA, metric, delta from the current best, status, and a one-line description.

**Don't stop to ask whether to continue.** The user may be away. If you run out of ideas, re-read the code in scope, profile it, combine near-misses, or try a bolder structural change.

Stop when the budget is spent or the goal is met. Also stop when 10 iterations in a row are discarded right after you already tried a bold change.

## 4. Finish

1. Run the Guard once more, plus any broader check that exists but was too slow for the loop, such as the full test suite or other inputs. This catches overfitting to the Verify inputs.
2. Report the baseline and final metric, the kept/discarded/crashed counts, and the 3 biggest wins with their SHAs.
3. Leave the branch for review. Never push, merge or open a PR without approval.
