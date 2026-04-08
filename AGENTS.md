# Repository Guidelines

## Overview

- This repository is a modular WezTerm config rooted at `~/.config/wezterm`.
- Keep `wezterm.lua` thin: it should only assemble modules and return the final config.
- Favor small, focused modules over broad utility layers or shared abstractions.

## Repository Layout

### Core modules

- `wezterm.lua`: entry point
- `constants.lua`: declarative shared config and machine-specific preferences
- `utils.lua`: shared helpers
- `appearance.lua`, `keys.lua`, `domains.lua`, `status.lua`, `graphics.lua`: feature modules

### Scripts and generated files

- `run_once_wezterm_stub.sh`: generates the Windows `%USERPROFILE%\\.wezterm.lua` stub and local watcher script
- `config_watcher.sh`: generated artifact; do not commit it

### Ownership rules

- Keep implementation-only constants inside the module that owns the behavior.
- Keep machine-specific SSH hosts, usernames, and WSL preferences in `constants.lua`.
- Keep absolute Windows paths confined to the stub generator.

## Editing Rules

### Style

- Use Lua with tabs for indentation, matching the existing files.
- Prefer modules that expose `apply(config)` for config mutation or `register()` for event hooks.
- Use `local` for module-scoped values.
- Preserve the current lowercase `snake_case` style for locals and helper functions.
- Keep comments brief and high-signal.

### Naming and structure

- Name files by responsibility, for example `status.lua` or `graphics.lua`.
- Prefer the smallest change that fixes the problem over introducing new abstractions.

## Development Commands

- `bash ~/.config/wezterm/run_once_wezterm_stub.sh`
  Regenerate the Windows stub and local watcher script after bootstrap or path changes.
- `bash ~/.config/wezterm/config_watcher.sh`
  Watch `.lua` files and touch the Windows stub to trigger WezTerm reloads.
- `wezterm --config-file ~/.config/wezterm/wezterm.lua show-keys --lua --key-table leader_mode`
  Validate that WezTerm can parse the config and materialize the custom leader key table.
- `systemctl --user enable --now wezterm-watch.service`
  Enable the watcher as a user service if this machine is configured for it.

## Validation

- There is no automated test suite; rely on lightweight CLI checks plus manual verification.
- After edits, run the `wezterm --config-file ... show-keys --lua --key-table leader_mode` parse check.
- Then reload WezTerm on Windows and confirm the affected behavior works without runtime errors.
- Exercise the changed behavior directly, such as:
  - custom leader bindings
  - tab titles
  - domain selection
  - status text
  - stub generation
- If you change the bootstrap script, rerun it and confirm that `.wezterm.lua` and `config_watcher.sh` are regenerated correctly.

## Commit Guidelines

- Use Conventional Commit-style prefixes such as `feat:`, `fix:`, and `refactor:`.
- Keep commit subjects short and imperative, for example `fix: handle empty pane title`.
- Keep simple commits lean: a short subject is enough unless extra context is needed to avoid ambiguity.
- Add a detailed commit message body only for changes complex enough that behavior, rationale, or operational boundaries would be unclear from the diff and subject alone.
- Keep generated artifacts out of Git.

## PR Guidelines

- Explain the user-visible behavior change.
- Call out any Windows or WSL assumptions.
- Include screenshots or short terminal notes when the change affects the tab bar, status line, or rendering behavior.

## Documentation Rules

- Document new external dependencies in `README.md`.
- Document any new validation step in `README.md`.
- Keep `README.md` aligned with actual config behavior; do not document aspirational behavior.
- Keep `README.md` user-facing: describe behavior and usage, not internal code paths, helper names, or implementation-specific control flow unless that detail is required to operate or debug the config.

## Session Learnings

<project_constraints>
- For WSL command-aware behaviors, treat shell-emitted `WEZTERM_PROG` as the authoritative signal and consult the raw pane title only when that user var is missing. This avoids hijacking panes whose titles happen to mention the target app.
- Display raw pane titles as-is in `status.lua`; only fall back when the title is empty or is an ignored internal placeholder such as `wslhost.exe`.
</project_constraints>

<known_pitfalls>
- When intercepting a common key such as `Ctrl-v`, non-target panes must receive the raw `SendKey` fallback rather than `PasteFrom("Clipboard")`, or unrelated terminal apps lose their original key behavior.
- In `clipboard_bridge.lua`, only the explicit `NO_IMAGE` result may degrade to normal clipboard paste. Export failures, invalid bridge output, and Windows-to-WSL path mapping failures must stay observable through warnings instead of silently pasting unrelated text.
</known_pitfalls>
