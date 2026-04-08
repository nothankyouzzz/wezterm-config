local M = {}
local DOT = utf8.char(0x2022)
local STATUS_DOT = utf8.char(0x25CF)

-- Label filtering
M.IGNORED_TAB_LABELS = {
	wslhost = true,
	conhost = true,
	openconsole = true,
}

-- Typography
M.FONTS = {
	body = {
		fallback = {
			"CaskaydiaCove Nerd Font Mono",
		},
		size = 13,
	},
	title_bar = {
		family = "CaskaydiaCove Nerd Font Mono",
		size = 11.5,
	},
}

-- Layout and sizing
M.WINDOW = {
	decorations = "INTEGRATED_BUTTONS | RESIZE",
	adjust_size_when_changing_font_size = false,
	initial_cols = 120,
	initial_rows = 28,
	padding = {
		left = 10,
		right = 10,
		top = 8,
		bottom = 4,
	},
}

M.THEME = {
	color_scheme = "Tokyo Night Moon",
	inactive_pane_hsb = {
		saturation = 0.95,
		brightness = 0.8,
	},
}

M.TAB_BAR = {
	use_fancy = true,
	max_width = 24,
	min_title_width = 16,
	show_index = false,
	show_new_tab_button = false,
	status_update_interval_ms = 1000,
	status_leading_text = STATUS_DOT .. "  ",
	status_separator = "  " .. DOT .. "  ",
	status_right_padding = " ",
	leader_label = "LEADER",
}

M.LEADER = {
	key = "a",
	mods = "CTRL",
	timeout_milliseconds = 1000,
}

M.CLIPBOARD_BRIDGE = {
	key = "v",
	mods = "CTRL",
}

M.WSL = {
	preferred_distributions = {
		{ type = "exact", value = "Ubuntu-24.04" },
		{ type = "pattern", value = "^Ubuntu" },
	},
}

M.SSH = {
	custom_domains = {
		{
			name = "syncthing",
			remote_address = "syncthing",
			username = "azureuser",
			assume_shell = "Posix",
			multiplexing = "None",
		},
	},
}

M.GRAPHICS = {
	preferred = {
		device_type = "DiscreteGpu",
		backend = "Dx12",
		front_end = "WebGpu",
		max_fps = 165,
		power_preference = "HighPerformance",
	},
	fallback = {
		front_end = "OpenGL",
		max_fps = 120,
	},
}

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
