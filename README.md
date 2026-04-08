# wezterm-config

Modular WezTerm configuration for a Windows + WSL workflow.

This repo keeps the real config in WSL, loads it from Windows through a generated stub, and adds a few deliberate behaviors on top of stock WezTerm: explicit SSH domain wiring, a custom `Ctrl-a` leader flow with immediate status refresh, width-aware tab titles, and a watched reload loop for Lua config changes.

For WSL panes, this repo can also consume optional shell integration signals so
app-specific behaviors such as the Claude clipboard bridge work more reliably.

## Environment

This config assumes:

- WezTerm runs on Windows
- the config source lives in WSL at `~/.config/wezterm`
- WSL2 is available
- `inotify-tools` is installed for auto-reload

Install the watcher dependency in WSL:

```bash
sudo apt install inotify-tools
```

## Quick Start

Clone into the expected location:

```bash
git clone https://github.com/nothankyouzzz/wezterm-config ~/.config/wezterm
```

Generate the Windows-side stub and local watcher script:

```bash
bash ~/.config/wezterm/run_once_wezterm_stub.sh
```

Validate that WezTerm can parse the config without opening the GUI:

```bash
wezterm --config-file ~/.config/wezterm/wezterm.lua show-keys --lua --key-table leader_mode
```

If your machine is set up for it, enable the watcher service:

```bash
systemctl --user enable --now wezterm-watch.service
```

## Repository Layout

```text
~/.config/wezterm/
  wezterm.lua              # Entry point; wires modules together
  constants.lua            # Declarative shared config
  appearance.lua           # Window, fonts, colors, tab bar styling
  graphics.lua             # GPU/backend selection
  domains.lua              # WSL default domain and explicit SSH domains
  keys.lua                 # Custom leader state machine and key bindings
  status.lua               # Tab titles and right status rendering
  utils.lua                # Shared string, width, and pane helpers
  run_once_wezterm_stub.sh # Generates the Windows stub and watcher script
```

`wezterm.lua` should stay thin. If a value is user-facing configuration, it belongs in `constants.lua`. If it is only an implementation detail of one module, keep it in that module.

## WSL Shell Integration

If you use `fish` inside WSL, this repo includes
`shell/wezterm-user-vars.fish`. Source it from your fish startup so WezTerm
gets better command context for WSL-specific behaviors:

```fish
source ~/.config/wezterm/shell/wezterm-user-vars.fish
```

The simplest place to add that is `~/.config/fish/config.fish`.

If you prefer `fish` auto-loading from `conf.d`, you can instead symlink it
into `~/.config/fish/conf.d/`.

## User-Tunable Settings

The main file you should edit is `constants.lua`.

If you are changing behavior rather than tuning values, start from the owning module instead:

- `domains.lua` for WSL/SSH domain resolution
- `keys.lua` for leader bindings and key tables
- `status.lua` for tab titles and right status rendering

### Appearance

Adjust fonts, sizes, theme, window padding, and tab bar presentation in:

- `C.FONTS`
- `C.THEME`
- `C.WINDOW`
- `C.TAB_BAR`
- `C.TITLE_BAR`
- `C.TAB`

### Leader Key

The leader key and timeout live in:

- `C.LEADER.key`
- `C.LEADER.mods`
- `C.LEADER.timeout_milliseconds`

### WSL Default Domain

WSL domain preference is explicit rather than hardcoded in logic. Change:

- `C.WSL.preferred_distributions`

Entries are checked in order. The first match wins.

### SSH Hosts

Managed SSH hosts are declared explicitly in:

- `C.SSH.custom_domains`

For each host, set values such as:

- `name`
- `remote_address`
- `username`
- `assume_shell`
- `multiplexing`
- `remote_wezterm_path`

If a host should use remote WezTerm multiplexing, set `multiplexing = "WezTerm"`. Otherwise it stays on plain SSH and may optionally declare `assume_shell = "Posix"`.

### Graphics Profile

GPU/backend preferences live in:

- `C.GRAPHICS.preferred`
- `C.GRAPHICS.fallback`

## Non-Default Behaviors

### Custom Leader Handling

This repo uses a custom leader flow so the status bar can show `LEADER`
immediately when `Ctrl-a` is pressed, rather than waiting for the next status
refresh.

`Ctrl-a Ctrl-a` still sends a literal `Ctrl-a` through to the running program.

### WSL Clipboard Image Bridge

In WSL Claude Code panes, `Ctrl-v` first tries to export a Windows clipboard
image to a temporary PNG and paste the resulting WSL path as bracketed text.

This is aimed at terminal apps such as Claude Code that can turn a pasted image
filepath into an attachment but cannot reliably read the Windows clipboard from
inside WSL.

If there is no image in the Windows clipboard, the binding falls back to
WezTerm's normal clipboard paste behavior. Bridge failures are surfaced as a
warning instead of silently pasting unrelated text. Non-Claude panes receive
the raw `Ctrl-v` keypress unchanged.

### Tab Title Resolution

Tab titles use the raw pane title when it is meaningful.

If the title is empty or looks like an internal placeholder, the config falls
back to a domain-aware label.

Labels are width-aware, so wide glyphs do not get truncated based on byte length.

### Status Bar

The right status bar shows:

- current leader mode, when active
- current domain
- current directory
- day and time

Leader state is refreshed immediately so the `LEADER` indicator appears and
clears without waiting for the normal status update cadence.

### Auto-Reload Watcher

The generated watcher script touches the Windows stub when `.lua` files change. It listens for:

- `close_write`
- `create`
- `move`
- `delete`

## Windows/WSL Loading Model

WezTerm on Windows loads `%USERPROFILE%\.wezterm.lua`.

That file is generated by `run_once_wezterm_stub.sh` and does two things:

1. rewrites Lua module loading so `require()` resolves over the WSL UNC path
2. executes the real `wezterm.lua` inside `~/.config/wezterm`

This lets the config live entirely in WSL while still using the native Windows WezTerm GUI.

## Validate Changes

Use this as the basic parse check after edits:

```bash
wezterm --config-file ~/.config/wezterm/wezterm.lua show-keys --lua --key-table leader_mode
```

Then manually verify the affected behavior inside WezTerm:

- a WSL `fish` pane updates its tab title when you run different commands
- leader activation and `Ctrl-a Ctrl-a`
- `Ctrl-v` in a WSL Claude Code pane with an image in the Windows clipboard
- pane and tab bindings
- tab title rendering
- SSH domain selection
- right status contents
- watcher-triggered reloads, if you changed the stub script

## Troubleshooting

If WezTerm does not pick up changes:

- rerun `bash ~/.config/wezterm/run_once_wezterm_stub.sh`
- confirm `%USERPROFILE%\.wezterm.lua` was regenerated
- confirm `config_watcher.sh` exists and is executable
- run the CLI parse check above before reopening the GUI

If a new SSH host does not behave as expected:

- confirm it is declared in `C.SSH.custom_domains`
- confirm `multiplexing` is set intentionally
- confirm `remote_wezterm_path` is set when using remote WezTerm mux
- confirm `assume_shell = "Posix"` is only used when you want plain SSH tabs/panes to inherit the remote cwd

## Maintenance Notes

- `config_watcher.sh` is generated and should not be committed.
- Keep machine-specific SSH hosts, usernames, and WSL preferences in `constants.lua`.
- Keep absolute Windows paths confined to `run_once_wezterm_stub.sh`.
- Keep `wezterm.lua` thin and push logic into focused modules.

### chezmoi

If you manage dotfiles with chezmoi, add:

```toml
[".config/wezterm"]
    type = "git-repo"
    url = "https://github.com/nothankyouzzz/wezterm-config"
    refreshPeriod = "168h"
```

And keep `run_once_wezterm_stub.sh` in your chezmoi source so the stub can be regenerated on a new machine.
