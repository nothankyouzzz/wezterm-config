local C = require("constants")

local M = {}

function M.apply(cfg)
	cfg.window_decorations = "INTEGRATED_BUTTONS | RESIZE"
	cfg.adjust_window_size_when_changing_font_size = false
	cfg.initial_cols = 120
	cfg.initial_rows = 28
	cfg.window_padding = {
		left = 10,
		right = 10,
		top = 8,
		bottom = 4,
	}

	cfg.font = C.BODY_FONT
	cfg.font_size = 13
	cfg.color_scheme = "Tokyo Night Moon"
	cfg.use_fancy_tab_bar = true
	cfg.tab_max_width = 24
	cfg.show_tab_index_in_tab_bar = false
	cfg.show_new_tab_button_in_tab_bar = false
	cfg.status_update_interval = 1000
	cfg.inactive_pane_hsb = {
		saturation = 0.95,
		brightness = 0.8,
	}

	cfg.colors = {
		split = C.TITLE_BAR.accent,
		tab_bar = {
			background = C.TITLE_BAR.bg,
			inactive_tab_edge = C.TITLE_BAR.bg,
			active_tab = {
				bg_color = C.TAB.active_bg,
				fg_color = C.TAB.active_fg,
			},
			inactive_tab = {
				bg_color = C.TAB.inactive_bg,
				fg_color = C.TAB.inactive_fg,
			},
			inactive_tab_hover = {
				bg_color = C.TAB.hover_bg,
				fg_color = C.TAB.hover_fg,
			},
			new_tab = {
				bg_color = C.TITLE_BAR.bg,
				fg_color = C.TITLE_BAR.muted,
			},
			new_tab_hover = {
				bg_color = C.TAB.hover_bg,
				fg_color = C.TAB.hover_fg,
			},
		},
	}

	cfg.window_frame = {
		font = C.TITLE_BAR_FONT,
		font_size = 11.5,
		active_titlebar_bg = C.TITLE_BAR.bg,
		inactive_titlebar_bg = C.TITLE_BAR.bg,
		active_titlebar_fg = C.TITLE_BAR.fg,
		inactive_titlebar_fg = C.TITLE_BAR.muted,
		active_titlebar_border_bottom = C.TITLE_BAR.accent,
		inactive_titlebar_border_bottom = C.TITLE_BAR.bg,
		button_fg = C.TITLE_BAR.muted,
		button_bg = C.TITLE_BAR.bg,
		button_hover_fg = C.TITLE_BAR.fg,
		button_hover_bg = C.TAB.inactive_bg,
	}
end

return M
