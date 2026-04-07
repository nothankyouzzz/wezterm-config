# Repository Guidelines

## Project Structure & Module Organization
This repository is a modular WezTerm config rooted at `~/.config/wezterm`. `wezterm.lua` is the entry point and should stay thin: it wires modules together and returns the final config. Put declarative shared config in `constants.lua`, helpers in `utils.lua`, and feature-specific logic in focused modules such as `appearance.lua`, `keys.lua`, `domains.lua`, and `status.lua`. Keep implementation-only constants local to the module that owns them. Shell automation lives in `run_once_wezterm_stub.sh`; the generated `config_watcher.sh` is ignored and should not be committed.

## Build, Test, and Development Commands
There is no build step. Use these commands during local development:

- `bash ~/.config/wezterm/run_once_wezterm_stub.sh`: regenerate the Windows `%USERPROFILE%\.wezterm.lua` stub and local watcher script after path or bootstrap changes.
- `bash ~/.config/wezterm/config_watcher.sh`: watch `.lua` files and touch the Windows stub to trigger WezTerm reloads.
- `wezterm --config-file ~/.config/wezterm/wezterm.lua show-keys --lua --key-table leader_mode`: validate that WezTerm can parse the config and materialize the custom leader key table.
- `systemctl --user enable --now wezterm-watch.service`: enable the watcher as a user service if your machine is configured for it.

Validate changes by running the CLI parse check above, then reloading WezTerm on Windows and confirming the config loads without runtime errors.

## Coding Style & Naming Conventions
Use Lua with tabs for indentation, matching the existing files. Prefer small modules that expose `apply(config)` for config mutation or `register()` for event hooks. Use `local` for module-scoped values, keep comments brief, and name files by responsibility (`status.lua`, `graphics.lua`). Preserve the current lowercase snake_case style for locals and helper functions.

## Testing Guidelines
This repo currently relies on manual verification rather than an automated test suite. After edits, run the `wezterm --config-file ... show-keys` parse check, then reload WezTerm and exercise the affected behavior: custom leader bindings, tab titles, domain selection, status text, or stub generation. If you change the bootstrap script, rerun it and confirm that `.wezterm.lua` and `config_watcher.sh` are regenerated correctly.

## Commit & Pull Request Guidelines
Recent history uses Conventional Commit-style prefixes such as `feat:`, `fix:`, and `refactor:`. Keep commit subjects short and imperative, for example `fix: handle empty pane title`. PRs should explain the user-visible behavior change, call out Windows/WSL assumptions, and include screenshots or short terminal notes when the change affects tab bar, status line, or rendering behavior.

## Configuration Notes
Keep machine-specific SSH hosts, usernames, and WSL domain preferences in `constants.lua`; do not scatter them across feature modules. Absolute Windows paths should still stay confined to the stub generator. Keep generated artifacts out of Git, and document any new external dependency or validation step in `README.md`.
