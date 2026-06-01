function crpr --description "Open a GitHub PR in a worktree and run /code-review"
    if test (count $argv) -eq 0
        echo "Usage: crpr <number|pr:number|github-pr-url>" >&2
        return 1
    end

    set -l input $argv[1]
    set -l pr
    set -l url_repo

    if string match -rq '^https?://' -- $input
        # Full GitHub PR URL — capture owner/repo and the PR number
        set -l parts (string match -r 'github\.com/([^/]+/[^/]+)/pull/(\d+)' -- $input)
        if test (count $parts) -lt 3
            echo "crpr: could not parse a PR number from URL: $input" >&2
            return 1
        end
        set url_repo $parts[2]
        set pr $parts[3]
    else
        # Bare number or a pr: / mr: / # prefix
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

    # wt's shell integration cd's us into the (newly created) worktree. The
    # pre-start mise-trust hook in ~/.config/worktrunk/config.toml runs
    # (blocking) during the switch, so Claude starts against a trusted config.
    if not wt switch "pr:$pr"
        return 1
    end

    # Passed as a single argument (fish does not word-split a string variable),
    # so no nested quoting. /code-review is a skill triggered from the prompt.
    set -l prompt 'Compare this PR against origin/main and complete a /code-review. Once the results are back, draft some comment replies. Be approachable and friendly (but not overly friendly), and do not sugar-coat. Keep concise, pitched principal -> mid-level. Let me review before doing anything.'
    claude $prompt

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
    end
end
