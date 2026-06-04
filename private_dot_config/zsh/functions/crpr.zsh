# Open a GitHub PR in a cmux workspace and run /code-review
crpr() {
    # --- Worker mode ----------------------------------------------------------
    # `crpr --here <N> [--ephemeral]` runs the review in the *current* shell and
    # worktree. The launcher invokes this inside a freshly spawned cmux
    # workspace; it is also the path taken when crpr is used outside cmux.
    if [[ $1 == "--here" ]]; then
        shift
        _crpr_review "$@"
        return $?
    fi

    if (( $# == 0 )); then
        echo "Usage: crpr <number|pr:number|github-pr-url> [more PRs...]" >&2
        return 1
    fi

    # Outside cmux, fall back to a blocking in-place review (original behaviour).
    if [[ -z $CMUX_WORKSPACE_ID ]] || ! command -v cmux >/dev/null; then
        if (( $# > 1 )); then
            echo "crpr: parallel reviews need cmux; reviewing $1 only" >&2
        fi
        local pr
        pr=$(_crpr_pr_number "$1") || return 1
        _crpr_review "$pr"
        return $?
    fi

    # --- Launcher mode --------------------------------------------------------
    # One cmux workspace per PR. The current terminal returns immediately, so
    # several PRs can be reviewed in parallel as separate sidebar tabs.
    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || repo_root=$PWD
    local -a launched
    local input pr ws_line ws pr_url

    for input in "$@"; do
        pr=$(_crpr_pr_number "$input") || continue

        # wt's pre-start mise-trust hook runs (blocking) during the switch the
        # worker performs, so Claude starts against a trusted config. The
        # worker cds into the worktree itself; we only seed the repo root.
        ws_line=$(CMUX_QUIET=1 cmux new-workspace --name "pr:$pr" --cwd "$repo_root" --command "crpr --here $pr --ephemeral")
        ws=$(print -r -- "$ws_line" | grep -oE 'workspace:[0-9]+' | head -1)
        if [[ -z $ws ]]; then
            echo "crpr: failed to create a cmux workspace for pr:$pr" >&2
            continue
        fi

        # Sidebar status chip so the tab reflects what is running.
        CMUX_QUIET=1 cmux set-status review "pr:$pr" --workspace "$ws" --icon eye --color "#a78bfa" 2>/dev/null

        # Browser pane with the PR page, to the right, without stealing focus.
        pr_url=$(gh pr view "$pr" --json url -q .url 2>/dev/null)
        if [[ -n $pr_url ]]; then
            CMUX_QUIET=1 cmux new-pane --workspace "$ws" --type browser --direction right --url "$pr_url" --focus false 2>/dev/null
        fi

        launched+=("$ws")
        echo "crpr: launched review for pr:$pr in $ws"
    done

    # A lone review: hop into it (set CRPR_NO_SWITCH to stay put). Several:
    # leave them running in parallel and let the user pick from the sidebar.
    if (( ${#launched} == 1 )) && [[ -z $CRPR_NO_SWITCH ]]; then
        CMUX_QUIET=1 cmux select-workspace --workspace "${launched[1]}" 2>/dev/null
    fi
}

# Parse and validate a PR ref, echoing the bare number.
_crpr_pr_number() {
    local input=$1 pr="" url_repo="" current

    if [[ $input =~ '^https?://' ]]; then
        # Full GitHub PR URL — capture owner/repo and the PR number.
        if [[ $input =~ 'github\.com/([^/]+/[^/]+)/pull/([0-9]+)' ]]; then
            url_repo=${match[1]}
            pr=${match[2]}
        else
            echo "crpr: could not parse a PR number from URL: $input" >&2
            return 1
        fi
    else
        # Bare number or a pr: / mr: / # prefix.
        pr=${input#(pr:|mr:|\#)}
    fi

    if [[ ! $pr =~ '^[0-9]+$' ]]; then
        echo "crpr: not a valid PR number: $input" >&2
        return 1
    fi

    # When given a URL, make sure it matches the repo we're standing in — wt
    # switch pr:N resolves against the current repo, so a mismatched URL would
    # silently review the wrong PR.
    if [[ -n $url_repo ]]; then
        current=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
        if [[ -n $current && ${(L)url_repo} != ${(L)current} ]]; then
            echo "crpr: URL is for '$url_repo' but you're in '$current' — cd into the right repo first" >&2
            return 1
        fi
    fi

    echo "$pr"
}

# Run /code-review for a PR in the current worktree.
_crpr_review() {
    local pr=$1 ephemeral=""
    [[ " $* " == *" --ephemeral "* ]] && ephemeral=yes

    # wt's shell integration cd's us into the (newly created) worktree.
    if ! wt switch "pr:$pr"; then
        _crpr_clear_status
        return 1
    fi

    # wt only fetches when it first creates the worktree; on reuse it just cd's
    # in, so a repeat review would see stale code. Pull the latest PR head in.
    _crpr_sync "$pr"

    # Passed as a single argument, so no nested quoting. /code-review is a skill
    # triggered from the prompt.
    local prompt='Compare this PR against origin/main and complete a /code-review. Once the results are back, draft some comment replies. Be approachable and friendly (but not overly friendly), and do not sugar-coat. Keep concise, pitched principal -> mid-level. Let me review before doing anything. After presenting the drafts, confirm the next steps with me (change anything, or publish the comments).'
    claude "$prompt"

    # Review is done — drop the sidebar status chip.
    _crpr_clear_status

    # On a clean exit from Claude, offer to prune the worktree. `wt remove`
    # drops the current worktree, cd's back to the primary repo, and keeps the
    # (unmerged) PR branch. Defaults to No so an accidental Enter is harmless.
    local prune="" reply
    if command -v gum >/dev/null; then
        gum confirm --default=false "Prune the pr:$pr worktree?" && prune=yes
    else
        read "reply?Prune the pr:$pr worktree? [y/N] "
        [[ ${(L)reply} == y* ]] && prune=yes
    fi
    if [[ -n $prune ]]; then
        wt remove
        # The launcher's workspaces are disposable: once the worktree is gone
        # there is nothing left to look at, so close the tab too.
        if [[ -n $ephemeral && -n $CMUX_WORKSPACE_ID ]] && command -v cmux >/dev/null; then
            CMUX_QUIET=1 cmux close-workspace --workspace "$CMUX_WORKSPACE_ID" 2>/dev/null
        fi
    fi
}

# Refresh the PR worktree to the latest PR head.
_crpr_sync() {
    local pr=$1 target stashed=""

    # GitHub maintains refs/pull/N/head on the base repo, so this resolves the
    # latest head even for fork PRs. Capture the commit before the next fetch
    # clobbers FETCH_HEAD.
    if ! git fetch --quiet origin "refs/pull/$pr/head" 2>/dev/null; then
        echo "crpr: could not fetch latest for pr:$pr — reviewing the worktree as-is" >&2
        return 0
    fi
    target=$(git rev-parse FETCH_HEAD)

    # Refresh remote-tracking branches too, so the origin/main base the review
    # diffs against is current (best effort).
    git fetch --quiet origin 2>/dev/null

    # Nothing to do if we already match the PR head.
    [[ $(git rev-parse HEAD) == "$target" ]] && return 0

    # Stash any local edits so a dirty worktree can still be refreshed; they get
    # reapplied on top of the new head below. Untracked files are left in place
    # (reset --hard keeps them), so a plain stash of tracked changes suffices.
    if ! git diff --quiet || ! git diff --cached --quiet; then
        if git stash push --quiet --message "crpr: pr:$pr sync"; then
            stashed=yes
        else
            echo "crpr: could not stash local changes — leaving pr:$pr as-is (may be stale)" >&2
            return 0
        fi
    fi

    # Snap exactly to the PR head (covers new commits, rebases and force-pushes).
    git reset --hard --quiet "$target"
    echo "crpr: synced pr:$pr worktree to $(git rev-parse --short HEAD)"

    # Reapply the stashed edits on top of the refreshed head.
    if [[ -n $stashed ]]; then
        if git stash pop --quiet; then
            echo "crpr: reapplied your local changes"
        else
            echo "crpr: your changes conflict with the new pr:$pr head — resolve them; the stash is kept" >&2
        fi
    fi
}

# Clear crpr's cmux review status chip, if any.
_crpr_clear_status() {
    if [[ -n $CMUX_WORKSPACE_ID ]] && command -v cmux >/dev/null; then
        CMUX_QUIET=1 cmux clear-status review --workspace "$CMUX_WORKSPACE_ID" 2>/dev/null
    fi
}
