# Shell-startup tuning routine

You are an autonomous routine that **continuously tunes interactive `zsh`
startup latency** for this dotfiles repo and guards against regressions
(issue #61). This file is your prompt — execute the loop below exactly.

The metric is **`zsh -i` startup time**. Zsh is the only managed shell.

## Settled parameters

| | |
|---|---|
| **Cadence** | Weekly. |
| **Optimise + gate on** | **warm** startup (caches populated — the day-to-day reality). Cold is measured and reported, but never blocks a change. |
| **Open a PR only if** | warm improves by **≥5% AND ≥5ms**, with **non-overlapping error bars** (`after.mean + after.stddev < before.mean − before.stddev`). |
| **Regression** | A change that makes warm **>5% slower** is rejected and reverted. Anything between (not a clear win, not a regression) is also reverted — no PR. |
| **Results** | `bench/baseline.json` is the committed record of the current best; the **winning PR updates it**. Per-run before/after numbers go in the **PR body**, not committed elsewhere. |
| **Merge** | Never auto-merge. Wins accumulate on **one stable branch/PR** (`routine/shell-startup-tuning`) that grows across runs until a human reviews and merges; a fresh PR opens only once the current one is merged or closed. |

> The keep/revert math always compares a **fresh before-measurement taken this
> run, on this machine** against the after-measurement — *not* the committed
> `baseline.json`. Startup cost is machine-specific (hardware, and on corporate
> Macs the endpoint-security `exec` scan), so a baseline captured elsewhere is
> not a valid gate reference. `baseline.json` is the human-facing trend record,
> refreshed by the winning PR.

## The loop (one change per run)

1. **Sync & pick the base.** Fetch origin. **If an open PR already exists on the
   stable branch `routine/shell-startup-tuning`**, check that branch out and work
   on top of it — this run *stacks* the next win onto the prior unmerged ones.
   **Otherwise** start from a clean, up-to-date `main`. Abort if the tree is
   dirty. (`chezmoi apply` must use this checkout as its source dir, so the
   template edits here are what gets materialised — see the host bootstrap.)
2. **Measure before.** `chezmoi apply` (materialise current `~/.zshrc`), then:
   - `scripts/bench-startup.sh --json /tmp/before.json`
   - `scripts/profile-startup.sh` (warm) — read the zprof table to pick a target.
   - `scripts/shell-snapshot.sh > /tmp/before.snap` — the behaviour fingerprint.
3. **Hypothesise one change.** Pick the single highest-leverage idea from the
   profile (see *Where the time goes* below). Lazy-load, defer, drop, cache
   differently, or reorder — **one** change only.
4. **Apply it to the source.** Edit the **template** (`dot_zshrc.tmpl`, or a
   `private_dot_config/zsh/conf.d/*` / `functions/*` file) — never `~/.zshrc`
   directly — then `chezmoi apply`.
5. **Measure after.** `scripts/bench-startup.sh --json /tmp/after.json` and
   `scripts/shell-snapshot.sh > /tmp/after.snap`.
6. **Check guardrails (all must hold).**
   - `./test.sh` passes (use `--minimal` only if optional language runtimes are
     absent in this environment; note it in the PR if so).
   - `diff /tmp/before.snap /tmp/after.snap`: the **aliases, abbreviations,
     bindkeys and options** sections must be **identical**. A diff in the
     **functions** section is allowed *only* if it is purely deferred loading
     (e.g. completion functions defined on first use) — and you must call it out
     explicitly in the PR. Any other diff = behaviour change = revert.
   - `chezmoi diff` is clean afterwards (apart from the always-runs
     `zz-mise-runtimes` summary script).
7. **Decide** (warm numbers, from the JSON `.results.warm`):
   - **Win** → improvement ≥5% AND ≥5ms AND non-overlapping σ: keep. Go to 8.
   - **Regression** → warm >5% slower: revert. Stop (consider noting the dead end).
   - **Neither** → revert; the idea didn't clear the bar. Stop.
   To revert: `git checkout -- <source file>` then `chezmoi apply`.
8. **Open or extend the stable PR** (wins accumulate — stable branch + title).
   - The branch is always `routine/shell-startup-tuning`; the PR title is fixed:
     `perf(zsh): startup tuning (routine)`.
   - **An open PR already exists** for that branch
     (`gh pr list --head routine/shell-startup-tuning --state open`) → **stack**:
     this run was measured on top of that branch (step 1), so commit the win as
     one more commit, regenerate `bench/baseline.json`, **append** this run's
     before/after row to the PR body's table, and `git push` the same branch.
     Do **not** open a second PR.
   - **No open PR** → `git checkout -B routine/shell-startup-tuning origin/main`,
     commit the win + regenerated baseline, push, and `gh pr create` with the
     fixed title.
   - Either way: reference issue #61, keep a **cumulative** before/after table
     (one row per accepted win, warm + cold, with variance), e.g.:

     | run | warm before→after | cold before→after |
     |---|---|---|
     | 2026-06-29 | 112.4 ± 6.9 → 99.1 ± 5.8 ms (**−11.8%**) | 173.2 ± 11.5 → 160.0 ± 10.1 ms (−7.6%) |

     and **never merge** — a human reviews. After it merges (or closes), the next
     run starts fresh from `main`.

## Where the time goes (current profile, this machine)

Starting points, highest self-time first — re-profile every run, don't trust this list:

- **`compinit` + `compaudit` (~31%)** — the security audit of `fpath` dirs is
  costly. Candidates: skip the audit on warm starts (`compinit -C`/`-u` against a
  trusted dump), or rebuild the dump on a schedule rather than every shell.
- **`_mise_hook` / `mise activate` (~19%)** — deliberately **not** cached
  (`activate` output is environment-sensitive — see the note in `dot_zshrc.tmpl`).
  Treat as constrained; don't naively cache it.
- **`_evalcache` (~21%, 7 tools)** — already cached. Some inits (zoxide, direnv)
  could be lazy-loaded on first use instead of sourced eagerly.
- **Greeting `zz-greeting.zsh` (~11%)** — could defer or render async.
- **zsh-abbr job-queue, syntax-highlighting load** — candidates to defer.

## Hard guardrails (never violate)

- `./test.sh` passes on every change you keep.
- **No behaviour change** — the snapshot guardrail in step 6 is the gate. Every
  alias, abbreviation, binding, option and named function survives.
- All changes land via **PR for human review**; nothing auto-merges.
- **One change per run**, always measured before/after with variance reported.
- Edit the chezmoi **source templates**, never `~/.zshrc` directly.
