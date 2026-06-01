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

    # mise config in a freshly created worktree is trusted by the pre-start hook
    # in ~/.config/worktrunk/config.toml, which blocks until done before the -x
    # command launches Claude.
    wt switch "pr:$pr" -x "claude /code-review"
end
