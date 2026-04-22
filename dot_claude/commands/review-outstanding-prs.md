---
description: "Find outstanding PRs awaiting my review and review them all in parallel"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Agent", "Write"]
---

# Review Outstanding PRs

Find all open PRs in the current GitHub repo that are awaiting my review, then review each one in parallel using specialised subagents. Produce a summary of critical findings.

## Workflow

### Step 1: Detect Repository

Run:
```bash
gh repo view --json nameWithOwner --jq '.nameWithOwner'
```

If this fails, tell the user they need to be in a GitHub repository and stop.

Store the repo identifier (e.g. `owner/repo`).

### Step 2: Get Current User

Run:
```bash
gh api user --jq '.login'
```

Store the GitHub username for filtering.

### Step 3: Find Outstanding PRs

Find all open PRs in the current repo that I haven't reviewed yet, excluding renovate bot.

`gh pr list` automatically infers the repo from the current git remote:

```bash
gh pr list --search "-author:app/renovate -author:@me -reviewed-by:@me" --json number,title,author,url,headRefName,baseRefName,additions,deletions,changedFiles --limit 50
```

This filters:
- Scoped to the current repo (inferred from git remote)
- Open PRs only (default for `gh pr list`)
- Not authored by renovate[bot]
- Not authored by me
- Not already reviewed by me

If no PRs are found, tell the user there are no outstanding PRs to review and stop.

Display the list of PRs found to the user before proceeding:
```
Found X PRs awaiting review:
- #123: Title (author) +adds/-dels, N files
- #456: Title (author) +adds/-dels, N files
```

### Step 4: Create a Team and Review PRs in Parallel

Create an agent team so each PR gets its own teammate. Teammates are full agents that can spawn their own subagents, which means each one can invoke `/pr-review-toolkit:review-pr` (which itself spawns parallel review subagents).

1. Create the team using TeamCreate with `team_name: "pr-reviews"`.

2. For each PR, spawn a teammate using the Agent tool with:
   - `team_name: "pr-reviews"`
   - `name: "pr-<number>"` (e.g. `pr-123`)
   - `isolation: "worktree"` — each teammate gets its own git worktree so they don't conflict on checkout
   - Launch ALL teammates in parallel in a single message

   Each teammate's prompt should be:
   ```
   You are reviewing PR #<number> in <repo>.

   PR details:
   - Title: <title>
   - Author: <author>
   - Branch: <head> -> <base>
   - URL: <url>

   Steps:
   1. Check out the PR branch: `gh pr checkout <number>`
   2. Run the review by invoking the Skill tool with `skill: "pr-review-toolkit:review-pr"` and `args: "all parallel"`.
      This will spawn specialised subagents (code-reviewer, silent-failure-hunter, etc.) to review the PR thoroughly.
   3. Once the review completes, send the full aggregated findings back to the team lead via SendMessage.
      Include all severity-rated findings with file references, and the overall summary.
   ```

3. Wait for all teammates to report back with their findings.

### Step 5: Compile Summary Report

Once ALL agents have completed, compile their findings into a single temporary markdown file.

Write the file to `/tmp/pr-review-summary.md` with this structure:

```markdown
# Outstanding PR Review Summary

**Repository:** <repo>
**Date:** <today's date>
**PRs Reviewed:** <count>

---

## Critical & High Priority Findings

> These issues should be addressed before merging.

For each PR that has CRITICAL or HIGH findings, list them here grouped by PR:

### PR #<number>: <title> (<author>)
<url>

- [SEVERITY] `file`: Description

---

## Per-PR Summaries

For each PR, include:

### PR #<number>: <title>
**Author:** <author> | **URL:** <url>
**Verdict:** <one-line summary — e.g. "Looks good", "Has 2 critical issues", "Minor suggestions only">

<full summary from agent>

---

## Overview

| PR | Author | Critical | High | Medium | Low | Verdict |
|----|--------|----------|------|--------|-----|---------|
| #N | name   | 0        | 1    | 2      | 0   | Needs fixes |

## Recommended Actions

Numbered list of suggested next steps, prioritised by severity.
```

### Step 6: Report to User

Tell the user:
1. How many PRs were reviewed
2. Highlight any CRITICAL or HIGH findings (brief summary)
3. The path to the full report: `/tmp/pr-review-summary.md`

If there are no critical or high findings across all PRs, tell the user all PRs look good.
