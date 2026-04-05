# wezterm-config

Modular WezTerm configuration for Windows/WSL development workflows.

## Structure

```
~/.config/wezterm/
  wezterm.lua          # Entry point
  constants.lua        # Colors, fonts, and WSL constants
  utils.lua            # Pane helpers and string utilities
  appearance.lua       # Font, color scheme, tab bar styling
  graphics.lua         # GPU detection and frame rate
  status.lua           # Tab titles and right status bar
  config_watcher.sh    # Watches for config changes and triggers reload
```

## Features

- Auto-detects discrete GPU (NVIDIA/DirectX 12) and switches to WebGPU at 165fps, falls back to OpenGL at 120fps for integrated graphics
- Custom tab bar with centered titles and minimum width padding
- Right status bar showing domain, current directory, and time
- Modular structure — each concern lives in its own file
- Config lives in WSL, loaded by a Windows-side stub via UNC path

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
git clone https://github.com/nothankyou/wezterm-config ~/.config/wezterm
```

Generate the Windows-side stub (run from WSL):

```bash
bash ~/.config/wezterm/run_once_wezterm_stub.sh
```

This writes `%USERPROFILE%\.wezterm.lua` on Windows and generates `config_watcher.sh` with the correct paths baked in.

Enable the auto-reload watcher:

```bash
systemctl --user enable --now wezterm-watch.service
```

### chezmoi

If you manage dotfiles with chezmoi, add to `.chezmoiexternal.toml`:

```toml
[".config/wezterm"]
    type = "git-repo"
    url = "https://github.com/nothankyou/wezterm-config"
    refreshPeriod = "168h"
```

And add `run_once_wezterm_stub.sh` to your chezmoi source directory so the stub is regenerated on each new machine.

## How it works

WezTerm runs on Windows and looks for `%USERPROFILE%\.wezterm.lua`. This stub hooks into Lua's `require` to redirect module resolution over the UNC path to WSL, then loads `wezterm.lua` as the real entry point. Any changes to files under `~/.config/wezterm/` are detected by `inotifywait`, which touches the stub to trigger WezTerm's built-in config reload.
