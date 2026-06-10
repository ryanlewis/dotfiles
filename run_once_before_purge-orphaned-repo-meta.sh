#!/bin/sh
# Purge repo-meta files orphaned in $HOME by an early apply (June 2026),
# before they were added to .chezmoiignore. They cannot go in .chezmoiremove
# because chezmoi never removes ignored targets, so remove them here instead.
set -eu

cd "$HOME"
rm -f \
    Dockerfile \
    SCRIPTS.md \
    docker-test.sh \
    install.sh \
    renovate.json \
    setup-aliases.sh \
    test-chezmoi-data.yaml \
    test.sh
