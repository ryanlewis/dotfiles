# Startup benchmarks

Reference numbers for interactive **zsh** startup latency, the metric the
shell-startup tuning routine (issue #61) optimises and guards against
regressions.

## Files

- `baseline.json` — committed reference point, produced by
  `scripts/bench-startup.sh --json bench/baseline.json`.

## Capturing / refreshing

```bash
scripts/bench-startup.sh                       # print summary only
scripts/bench-startup.sh --json bench/baseline.json   # also (re)write the baseline
scripts/profile-startup.sh         # warm zprof segment breakdown
scripts/profile-startup.sh --cold  # cold (caches busted) breakdown
```

`hyperfine` is bootstrapped on demand (PATH, else a transient `mise x`); it is
deliberately **not** a managed dotfiles tool.

## What the numbers mean

- **warm** — `_evalcache` init dir + compinit's `zcompdump` already populated.
  The day-to-day reality, and the headline number to drive down.
- **cold** — both caches busted before every run, so each `tool init` re-forks
  and compinit re-dumps. Exercises the rebuild path that runs after a tool
  version bump or a fresh machine.

`results.{warm,cold}` hold the raw hyperfine result objects (mean, stddev,
median, min, max, and all per-run times, in **seconds**).

## Caveats

Baselines are **machine-specific** — startup cost depends on hardware and, on
corporate Macs, on endpoint-security scanning of every `exec`. `baseline.json`
records `host`/`os`/`arch` so a number is never compared across unlike
machines. Regenerate the baseline on the machine you're tuning.
