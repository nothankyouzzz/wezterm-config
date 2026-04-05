local wezterm = require("wezterm")

local M = {}

-- WSL
M.WSL_DISTRO = "Ubuntu-24.04"

M.IGNORED_TAB_LABELS = {
	wslhost = true,
	conhost = true,
	OpenConsole = true,
}

-- Typography
M.DOT = utf8.char(0x2022)
M.STATUS_DOT = utf8.char(0x25CF)

M.BODY_FONT = wezterm.font_with_fallback({
	"CaskaydiaCove Nerd Font Mono",
})
M.TITLE_BAR_FONT = wezterm.font("CaskaydiaCove Nerd Font Mono")

-- Colors
M.TITLE_BAR = {
	bg = "#1e2030",
	fg = "#c8d3f5",
	muted = "#7a88cf",
	accent = "#82aaff",
}

M.TAB = {
	active_bg = "#2f334d",
	active_fg = "#c8d3f5",
	inactive_bg = "#222436",
	inactive_fg = "#7a88cf",
	hover_bg = "#3b4261",
	hover_fg = "#d5dcff",
}

return M
