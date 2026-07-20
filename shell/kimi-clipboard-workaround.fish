# TODO: temporary workaround for https://github.com/MoonshotAI/kimi-code/issues/1961
# (fix in PR #1962). WSLg bridges Windows clipboard images as image/bmp only,
# which Kimi cannot decode; its PowerShell fallback gets short-circuited and
# also loses its temp-path env var at the WSL boundary. Once the fix ships,
# delete this file, shell/kimi-clipboard-shim/, and the source line in
# shell/wezterm-user-vars.fish.

# Kimi hands its PowerShell fallback the temp path via
# KIMI_WSL_CLIPBOARD_IMAGE_PATH, which only crosses the WSL -> Windows
# boundary when listed in WSLENV (/w = WSL to Win32 direction).
if test -z "$WSLENV"
	set -x WSLENV "KIMI_WSL_CLIPBOARD_IMAGE_PATH/w"
else if not string match -q "*KIMI_WSL_CLIPBOARD_IMAGE_PATH*" -- "$WSLENV"
	set -x WSLENV "$WSLENV:KIMI_WSL_CLIPBOARD_IMAGE_PATH/w"
end

# Route kimi's wl-paste image reads through the shim so its WSL PowerShell
# fallback (PNG export from the Windows clipboard) can take over; see
# shell/kimi-clipboard-shim/wl-paste.
function kimi --description 'wrap kimi with the WSL clipboard-image shim'
	env PATH="$HOME/.config/wezterm/shell/kimi-clipboard-shim:$PATH" kimi $argv
end
