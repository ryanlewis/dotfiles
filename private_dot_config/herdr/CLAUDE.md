# herdr config — managed by chezmoi

`config.toml` lives in the chezmoi source (`private_dot_config/herdr/config.toml`) and is
rendered to `~/.config/herdr/config.toml`. Edit the source, then apply + reload — a source
edit does nothing on its own until both run:

```bash
chezmoi apply ~/.config/herdr/config.toml   # render source → live file
herdr server reload-config                  # hot-reload the running server (no restart)
```

Don't hand-edit the live `~/.config/herdr/config.toml` — it's generated and a local change
is overwritten on the next `chezmoi apply`. (`chezmoi edit ~/.config/herdr/config.toml` opens
the source from anywhere.)

## Notes
- Reloading without applying re-reads the stale live file, so the change appears to no-op.
- `reload-config` returns JSON: `"status":"applied"` + empty `diagnostics` = it took.
  Check the server is up with `herdr status server`.
- Keybind action names are fixed (`next_tab`, `previous_tab`, `rename_tab`,
  `switch_workspace`, `previous_workspace`, …) — a typo'd key is dropped silently.
