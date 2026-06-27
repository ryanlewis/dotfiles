# Ghostty Dotfiles

## Environment
- Dotfiles managed with **chezmoi** — edit the source (`private_dot_config/ghostty/config`), then `chezmoi apply`; don't hand-edit the live `~/.config/ghostty/config` (it's generated and gets overwritten)
- Ghostty config: `~/.config/ghostty/config`
- Ghostty docs: https://ghostty.org/docs/config/reference

## Gotchas
- Always verify Ghostty config option names against docs before adding — option names are not always intuitive (e.g. `split-divider-color` not `split-color`)
