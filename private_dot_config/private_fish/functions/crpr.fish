function crpr --description "Open a GitHub PR in a cmux workspace and run /code-review"
    # --- Worker mode ----------------------------------------------------------
    # `crpr --here <N> [--ephemeral]` runs the review in the *current* shell and
    # worktree. The launcher invokes this inside a freshly spawned cmux
    # workspace; it is also the path taken when crpr is used outside cmux.
    if test "$argv[1]" = --here
        set -e argv[1]
        _crpr_review $argv
        return $status
    end

    if test (count $argv) -eq 0
        echo "Usage: crpr <number|pr:number|github-pr-url> [more PRs...]" >&2
        return 1
    end

    # Outside cmux, fall back to a blocking in-place review (original behaviour).
    if not set -q CMUX_WORKSPACE_ID; or not command -q cmux
        if test (count $argv) -gt 1
            echo "crpr: parallel reviews need cmux; reviewing $argv[1] only" >&2
        end
        set -l pr (_crpr_pr_number $argv[1]); or return 1
        _crpr_review $pr
        return $status
    end

    # --- Launcher mode --------------------------------------------------------
    # One cmux workspace per PR. The current terminal returns immediately, so
    # several PRs can be reviewed in parallel as separate sidebar tabs.
    set -l repo_root (git rev-parse --show-toplevel 2>/dev/null); or set repo_root $PWD
    set -l launched

    for input in $argv
        set -l pr (_crpr_pr_number $input); or continue

        # wt's pre-start mise-trust hook runs (blocking) during the switch the
        # worker performs, so Claude starts against a trusted config. The
        # worker cds into the worktree itself; we only seed the repo root.
        set -l ws_line (CMUX_QUIET=1 cmux new-workspace --name "pr:$pr" --cwd "$repo_root" --command "crpr --here $pr --ephemeral")
        set -l ws (string match -r 'workspace:\d+' -- $ws_line)
        if test -z "$ws"
            echo "crpr: failed to create a cmux workspace for pr:$pr" >&2
            continue
        end

        # Sidebar status chip so the tab reflects what is running.
        CMUX_QUIET=1 cmux set-status review "pr:$pr" --workspace "$ws" --icon eye --color "#a78bfa" 2>/dev/null

        # Browser pane with the PR page, to the right, without stealing focus.
        set -l pr_url (gh pr view "$pr" --json url -q .url 2>/dev/null)
        if test -n "$pr_url"
            CMUX_QUIET=1 cmux new-pane --workspace "$ws" --type browser --direction right --url "$pr_url" --focus false 2>/dev/null
        end

        set -a launched $ws
        echo "crpr: launched review for pr:$pr in $ws"
    end

    # A lone review: hop into it (set CRPR_NO_SWITCH to stay put). Several:
    # leave them running in parallel and let the user pick from the sidebar.
    if test (count $launched) -eq 1; and not set -q CRPR_NO_SWITCH
        CMUX_QUIET=1 cmux select-workspace --workspace "$launched[1]" 2>/dev/null
    end
end

function _crpr_pr_number --description "Parse and validate a PR ref, echoing the bare number"
    set -l input $argv[1]
    set -l pr
    set -l url_repo

    if string match -rq '^https?://' -- $input
        # Full GitHub PR URL — capture owner/repo and the PR number.
        set -l parts (string match -r 'github\.com/([^/]+/[^/]+)/pull/(\d+)' -- $input)
        if test (count $parts) -lt 3
            echo "crpr: could not parse a PR number from URL: $input" >&2
            return 1
        end
        set url_repo $parts[2]
        set pr $parts[3]
    else
        # Bare number or a pr: / mr: / # prefix.
        set pr (string replace -r '^(pr:|mr:|#)' '' -- $input)
    end

    if not string match -rq '^\d+$' -- $pr
        echo "crpr: not a valid PR number: $input" >&2
        return 1
    end

    # When given a URL, make sure it matches the repo we're standing in —
    # wt switch pr:N resolves against the current repo, so a mismatched URL
    # would silently review the wrong PR.
    if set -q url_repo[1]
        set -l current (gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
        if test -n "$current"; and test (string lower -- $url_repo) != (string lower -- $current)
            echo "crpr: URL is for '$url_repo' but you're in '$current' — cd into the right repo first" >&2
            return 1
        end
    end

    echo $pr
end

function _crpr_review --description "Run /code-review for a PR in the current worktree"
    set -l pr $argv[1]
    set -l ephemeral
    contains -- --ephemeral $argv; and set ephemeral yes

    # wt's shell integration cd's us into the (newly created) worktree.
    if not wt switch "pr:$pr"
        _crpr_clear_status
        return 1
    end

    # wt only fetches when it first creates the worktree; on reuse it just cd's
    # in, so a repeat review would see stale code. Pull the latest PR head in.
    _crpr_sync $pr

    # Passed as a single argument (fish does not word-split a string variable),
    # so no nested quoting. /code-review is a skill triggered from the prompt.
    set -l prompt 'Compare this PR against origin/main and complete a /code-review. Once the results are back, draft some comment replies. Be approachable and friendly (but not overly friendly), and do not sugar-coat. Keep concise, pitched principal -> mid-level. Let me review before doing anything. After presenting the drafts, confirm the next steps with me (change anything, or publish the comments).'
    claude $prompt

    # Review is done — drop the sidebar status chip.
    _crpr_clear_status

    # On a clean exit from Claude, offer to prune the worktree. `wt remove`
    # drops the current worktree, cd's back to the primary repo, and keeps the
    # (unmerged) PR branch. Defaults to No so an accidental Enter is harmless.
    set -l prune
    if command -q gum
        gum confirm --default=false "Prune the pr:$pr worktree?"; and set prune yes
    else
        read -l -P "Prune the pr:$pr worktree? [y/N] " reply
        string match -qi 'y*' -- $reply; and set prune yes
    end
    if test -n "$prune"
        wt remove
        # The launcher's workspaces are disposable: once the worktree is gone
        # there is nothing left to look at, so close the tab too.
        if test -n "$ephemeral"; and set -q CMUX_WORKSPACE_ID; and command -q cmux
            CMUX_QUIET=1 cmux close-workspace --workspace "$CMUX_WORKSPACE_ID" 2>/dev/null
        end
    end
end

function _crpr_sync --description "Refresh the PR worktree to the latest PR head"
    set -l pr $argv[1]

    # GitHub maintains refs/pull/N/head on the base repo, so this resolves the
    # latest head even for fork PRs. Capture the commit before the next fetch
    # clobbers FETCH_HEAD.
    if not git fetch --quiet origin "refs/pull/$pr/head" 2>/dev/null
        echo "crpr: could not fetch latest for pr:$pr — reviewing the worktree as-is" >&2
        return 0
    end
    set -l target (git rev-parse FETCH_HEAD)

    # Refresh remote-tracking branches too, so the origin/main base the review
    # diffs against is current (best effort).
    git fetch --quiet origin 2>/dev/null

    # Nothing to do if we already match the PR head.
    test (git rev-parse HEAD) = "$target"; and return 0

    # Stash any local edits so a dirty worktree can still be refreshed; they get
    # reapplied on top of the new head below. Untracked files are left in place
    # (reset --hard keeps them), so a plain stash of tracked changes suffices.
    set -l stashed
    if not git diff --quiet; or not git diff --cached --quiet
        if git stash push --quiet --message "crpr: pr:$pr sync"
            set stashed yes
        else
            echo "crpr: could not stash local changes — leaving pr:$pr as-is (may be stale)" >&2
            return 0
        end
    end

    # Snap exactly to the PR head (covers new commits, rebases and force-pushes
    # alike).
    git reset --hard --quiet "$target"
    echo "crpr: synced pr:$pr worktree to "(git rev-parse --short HEAD)

    # Reapply the stashed edits on top of the refreshed head.
    if test -n "$stashed"
        if git stash pop --quiet
            echo "crpr: reapplied your local changes"
        else
            echo "crpr: your changes conflict with the new pr:$pr head — resolve them; the stash is kept" >&2
        end
    end
end

function _crpr_clear_status --description "Clear crpr's cmux review status chip, if any"
    if set -q CMUX_WORKSPACE_ID; and command -q cmux
        CMUX_QUIET=1 cmux clear-status review --workspace "$CMUX_WORKSPACE_ID" 2>/dev/null
    end
end
