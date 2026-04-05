local wezterm = require("wezterm")
local C = require("constants")
local U = require("utils")

local M = {}

local function tab_label(tab)
	local process = U.normalized_label_text(U.pane_process_name(tab.active_pane))
	if process then
		return process
	end

	local title = U.normalized_label_text(U.pane_title(tab.active_pane))
	if title then
		return title
	end

	return U.tab_fallback_label(tab.active_pane)
end

local function push_status_part(formatted, text, color)
	if not text or text == "" then
		return
	end
	if #formatted > 0 then
		table.insert(formatted, { Foreground = { Color = C.TITLE_BAR.muted } })
		table.insert(formatted, { Text = C.TAB_BAR.status_separator })
	end
	table.insert(formatted, { Foreground = { Color = color or C.TITLE_BAR.fg } })
	table.insert(formatted, { Text = text })
end

local function format_tab_title(tab, _, _, _, _, max_width)
	local available_width = math.max(math.floor(max_width or 0), 1)
	local title = U.truncate_right(tab_label(tab), available_width)
	local min_width = math.min(C.TAB_BAR.min_title_width, available_width)
	return U.center_text(title, min_width)
end

local function update_right_status(window, pane)
	local formatted = {}

	table.insert(formatted, { Foreground = { Color = C.TITLE_BAR.accent } })
	table.insert(formatted, { Text = C.TAB_BAR.status_leading_text })

	push_status_part(formatted, U.domain_label(pane), C.TITLE_BAR.muted)
	push_status_part(formatted, U.dir_label(pane), C.TITLE_BAR.fg)
	push_status_part(formatted, wezterm.strftime("%a %H:%M"), C.TITLE_BAR.accent)
	table.insert(formatted, { Text = C.TAB_BAR.status_right_padding })

	window:set_right_status(wezterm.format(formatted))
end

function M.register()
	wezterm.on("format-tab-title", format_tab_title)
	wezterm.on("update-right-status", update_right_status)
end

return M
