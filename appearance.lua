local wezterm = require("wezterm")
local C = require("constants")

local M = {}

function M.apply(cfg)
	cfg.window_decorations = C.WINDOW.decorations
	cfg.adjust_window_size_when_changing_font_size = C.WINDOW.adjust_size_when_changing_font_size
	cfg.initial_cols = C.WINDOW.initial_cols
	cfg.initial_rows = C.WINDOW.initial_rows
	cfg.window_padding = C.WINDOW.padding

	cfg.font = wezterm.font_with_fallback(C.FONTS.body.fallback)
	cfg.font_size = C.FONTS.body.size
	cfg.color_scheme = C.THEME.color_scheme
	cfg.use_fancy_tab_bar = C.TAB_BAR.use_fancy
	cfg.tab_max_width = C.TAB_BAR.max_width
	cfg.show_tab_index_in_tab_bar = C.TAB_BAR.show_index
	cfg.show_new_tab_button_in_tab_bar = C.TAB_BAR.show_new_tab_button
	cfg.status_update_interval = C.TAB_BAR.status_update_interval_ms
	cfg.inactive_pane_hsb = C.THEME.inactive_pane_hsb

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
		font = wezterm.font(C.FONTS.title_bar.family),
		font_size = C.FONTS.title_bar.size,
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
