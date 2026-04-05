local wezterm = require("wezterm")
local C = require("constants")
local U = require("utils")

local M = {}

local function format_tab_title(tab, _, _, _, _, max_width)
	local function tab_label(t)
		local manual = U.normalized_label_text(t.tab_title)
		if manual then
			return manual
		end
		local process = U.normalized_label_text(U.pane_process_name(t.active_pane))
		if process then
			return process
		end
		local title = U.normalized_label_text(U.pane_title(t.active_pane))
		if title then
			return title
		end
		return "shell"
	end

	local title = U.truncate_right(tab_label(tab), math.max(max_width - 2, 10))
	local min_width = 16
	if #title < min_width then
		local total_pad = min_width - #title
		local left_pad = math.floor(total_pad / 2)
		local right_pad = total_pad - left_pad
		title = string.rep(" ", left_pad) .. title .. string.rep(" ", right_pad)
	end
	return title
end

local function update_right_status(window, pane)
	local formatted = {}

	local function push_part(text, color)
		if not text or text == "" then
			return
		end
		if #formatted > 0 then
			table.insert(formatted, { Foreground = { Color = C.TITLE_BAR.muted } })
			table.insert(formatted, { Text = "  " .. C.DOT .. "  " })
		end
		table.insert(formatted, { Foreground = { Color = color or C.TITLE_BAR.fg } })
		table.insert(formatted, { Text = text })
	end

	table.insert(formatted, { Foreground = { Color = C.TITLE_BAR.accent } })
	table.insert(formatted, { Text = C.STATUS_DOT .. "  " })

	push_part(U.domain_label(pane), C.TITLE_BAR.muted)
	push_part(U.dir_label(pane), C.TITLE_BAR.fg)
	push_part(wezterm.strftime("%a %H:%M"), C.TITLE_BAR.accent)

	window:set_right_status(wezterm.format(formatted))
end

function M.register()
	wezterm.on("format-tab-title", format_tab_title)
	wezterm.on("update-right-status", update_right_status)
end

return M
