# wezterm-config

Modular WezTerm configuration for Windows/WSL development workflows.

## Structure

```text
~/.config/wezterm/
  wezterm.lua          # Entry point
  constants.lua        # Shared colors, fonts, layout, and tuning values
  utils.lua            # Width helpers, pane accessors, and label normalization
  appearance.lua       # Window, font, and tab bar styling
  graphics.lua         # Per-machine rendering profile selection
  status.lua           # Tab title formatting and right status bar
  run_once_wezterm_stub.sh
```

## Features

- Auto-detects the higher-performance Windows GPU path and prefers WebGPU at 165fps there, while keeping a conservative OpenGL 120fps fallback for the integrated-GPU machine
- Tab titles prefer foreground process name, then pane title, then a domain-aware fallback label
- Tab titles are width-aware, so wide Unicode glyphs do not get truncated early
- Right status bar shows domain, current directory, and time with spacing tuned for integrated window buttons
- Modular structure — each concern lives in its own file
- Config lives in WSL and is loaded by a Windows-side stub via UNC path

## Setup

### Prerequisites

- [WezTerm](https://wezfurlong.org/wezterm/)
- WSL2 with Ubuntu 24.04
- `inotify-tools` for auto-reload

```bash
sudo apt install inotify-tools
```

### Installation

Clone into `~/.config/wezterm`:

```bash
git clone https://github.com/nothankyouzzz/wezterm-config ~/.config/wezterm
```

Generate the Windows-side stub (run from WSL):

```bash
bash ~/.config/wezterm/run_once_wezterm_stub.sh
```

This writes `%USERPROFILE%\.wezterm.lua` on Windows and generates the config watcher with the correct paths baked in.

Enable the auto-reload watcher:

```bash
systemctl --user enable --now wezterm-watch.service
```

### chezmoi

If you manage dotfiles with chezmoi, add to `.chezmoiexternal.toml`:

```toml
[".config/wezterm"]
    type = "git-repo"
    url = "https://github.com/nothankyouzzz/wezterm-config"
    refreshPeriod = "168h"
```

And add `run_once_wezterm_stub.sh` to your chezmoi source directory so the stub is regenerated on each new machine.

## How it works

WezTerm runs on Windows and looks for `%USERPROFILE%\.wezterm.lua`. This stub hooks into Lua's `require` to redirect module resolution over the UNC path to WSL, then loads `wezterm.lua` as the real entry point. Any changes to files under `~/.config/wezterm/` are detected by `inotifywait`, which touches the stub to trigger WezTerm's built-in config reload.

Tab titles are resolved from the active pane in this order:

1. foreground process name
2. pane title
3. domain-aware fallback label

WSL domains are normalized from `WSL:<distro>` to `<distro>`, and the local Windows domain uses `WEZTERM_PROG` when shell integration provides it.
