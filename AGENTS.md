# Repository Guidelines

## What this repo is

Modular WezTerm configuration for a Windows + WSL2 workflow. WezTerm runs on
Windows, but the config lives in WSL at `~/.config/wezterm`. A generated stub
(`%USERPROFILE%\.wezterm.lua`) rewrites Lua `require()` paths to the WSL UNC
path and executes `wezterm.lua`, so the whole config is managed from WSL
while the native Windows GUI picks it up.

## Layout

- `wezterm.lua`: thin entry point; only assembles modules and returns the
  config. Do not add logic here.
- `lua/constants.lua`: declarative shared config and machine-specific
  preferences (fonts, colors, leader key, WSL distros, SSH hosts, graphics).
- `lua/appearance.lua`, `keys.lua`, `domains.lua`, `status.lua`,
  `graphics.lua`, `clipboard_bridge.lua`: feature modules, each exposing
  `apply(config)` for config mutation or `register()` for event hooks.
- `lua/utils.lua`: shared helpers. `pane_value()` tries a method call, then a
  field lookup, so helpers work on both live `Pane` objects and the
  `PaneInformation` snapshots passed to `format-tab-title`.
- `shell/wezterm-user-vars.fish`: fish integration; emits the `WEZTERM_PROG`
  user var on pre/post-execute and prompt events.
- `shell/kimi-clipboard-workaround.fish` + `shell/kimi-clipboard-shim/`:
  temporary Kimi clipboard workaround; delete once
  https://github.com/MoonshotAI/kimi-code/pull/1962 ships.
- `scripts/run_once_wezterm_stub.sh`: generates the Windows stub, the local
  watcher script, and the user service unit.
- `config_watcher.sh`: generated artifact; do not commit it.

## Style

- Lua is formatted with `stylua` (2-space indent, 120 columns; see
  `stylua.toml`). Fish and shell files keep their existing style.
- `snake_case` for locals and helpers; `M` as the module table; `local` for
  module-scoped values; brief, high-signal comments.
- Implementation-only constants stay inside the module that owns the
  behavior. Machine-specific values (SSH hosts, usernames, WSL distro
  preferences) go in `constants.lua`. Absolute Windows paths stay in
  `scripts/run_once_wezterm_stub.sh`.
- Prefer the smallest change that fixes the problem over new abstractions.

## Commands

- `wezterm --config-file ~/.config/wezterm/wezterm.lua show-keys --lua --key-table leader_mode`
  Parse check; run after every Lua edit.
- `bash ~/.config/wezterm/scripts/run_once_wezterm_stub.sh`
  Regenerate the Windows stub, watcher script, and service unit after
  bootstrap or path changes.
- `systemctl --user enable --now wezterm-watch.service`
  Enable the generated watcher as a user service.

## Validation

There is no automated test suite. Run the parse check above, then reload
WezTerm on Windows and exercise the changed behavior directly (leader
bindings, tab titles, domain selection, status text, clipboard bridge, stub
generation). If the bootstrap script changed, rerun it and confirm the stub,
`config_watcher.sh`, and `wezterm-watch.service` regenerate correctly.

## Behavioral constraints

- Custom leader: `ActivateKeyTable` with `one_shot` plus
  `Status.activate_custom_leader` paints the `LEADER` label immediately; a
  50 ms poll clears it when the key table exits. WezTerm's built-in leader
  does not refresh the status bar on its own.
- Clipboard bridge: only WSL panes running Claude Code (detected via
  `WEZTERM_PROG`, pane title as last-resort fallback) get the image export.
  Non-target panes must receive a raw `SendKey` Ctrl-v, never
  `PasteFrom("Clipboard")`. Only an explicit `NO_IMAGE` may degrade to a
  normal paste; every other failure surfaces as a warning, never a silent
  paste of unrelated text.
- `WEZTERM_PROG` is the authoritative signal for what runs in a WSL pane;
  never gate behavior on a raw pane title that could match unrelated apps.
- Tab titles show the raw pane title as-is; fall back only when it is empty
  or an ignored placeholder such as `wslhost.exe`.

## Commits and PRs

- Conventional Commit prefixes (`feat:`, `fix:`, `refactor:`, `docs:`); short
  imperative subjects; add a body only when behavior or rationale is unclear
  from the diff alone.
- PRs: explain the user-visible change, call out Windows/WSL assumptions, and
  include screenshots or terminal notes for tab bar, status, or rendering
  changes.
- Keep `README.md` aligned with actual behavior and user-facing; document new
  dependencies and validation steps there. Keep generated artifacts out of
  Git.
