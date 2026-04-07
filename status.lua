local wezterm = require("wezterm")
local C = require("constants")
local U = require("utils")

local M = {}
M.CUSTOM_LEADER_KEY_TABLE = "leader_mode"
local LEADER_STATE_POLL_INTERVAL_SECONDS = 0.05
local leader_states = {}

local function window_state_id(window)
	local ok, mux_window = pcall(function()
		return window:mux_window()
	end)
	if ok and mux_window then
		local ok_id, mux_window_id = pcall(function()
			return mux_window:window_id()
		end)
		if ok_id and mux_window_id ~= nil then
			return mux_window_id
		end
	end

	local ok_id, window_id = pcall(function()
		return window:window_id()
	end)
	if ok_id then
		return window_id
	end

	return nil
end

local function state_for_window(window)
	local window_id = window_state_id(window)
	if not window_id then
		return nil
	end

	local state = leader_states[window_id]
	if not state then
		state = {
			active = false,
			generation = 0,
		}
		leader_states[window_id] = state
	end

	return state, window_id
end

local function resolve_window(window_id)
	if not wezterm.gui or not wezterm.gui.gui_window_for_mux_window then
		return nil
	end
	return wezterm.gui.gui_window_for_mux_window(window_id)
end

local function current_pane(window, fallback_pane)
	local ok, pane = pcall(function()
		return window:active_pane()
	end)
	if ok and pane then
		return pane
	end

	return fallback_pane
end

local function leader_is_active(window)
	local state = state_for_window(window)
	return state and state.active or false
end

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

local function current_mode_label(window)
	if leader_is_active(window) then
		return C.TAB_BAR.leader_label
	end

	return nil
end

local function format_tab_title(tab, _, _, _, _, max_width)
	local available_width = math.max(math.floor(max_width or 0), 1)
	local title = U.truncate_right(tab_label(tab), available_width)
	local min_width = math.min(C.TAB_BAR.min_title_width, available_width)
	return U.center_text(title, min_width)
end

local function render_status(window, pane)
	pane = current_pane(window, pane)
	local formatted = {}

	table.insert(formatted, { Foreground = { Color = C.TITLE_BAR.accent } })
	table.insert(formatted, { Text = C.TAB_BAR.status_leading_text })

	local mode_label = current_mode_label(window)
	if mode_label then
		table.insert(formatted, { Foreground = { Color = C.TITLE_BAR.accent } })
		table.insert(formatted, { Text = mode_label })
	end
	push_status_part(formatted, U.domain_label(pane), C.TITLE_BAR.muted)
	push_status_part(formatted, U.dir_label(pane), C.TITLE_BAR.fg)
	push_status_part(formatted, wezterm.strftime("%a %H:%M"), C.TITLE_BAR.accent)
	table.insert(formatted, { Text = C.TAB_BAR.status_right_padding })

	window:set_right_status(wezterm.format(formatted))
end

local function watch_leader_state(window_id, generation)
	if not wezterm.time or not wezterm.time.call_after then
		return
	end

	wezterm.time.call_after(LEADER_STATE_POLL_INTERVAL_SECONDS, function()
		local state = leader_states[window_id]
		if not state or not state.active or state.generation ~= generation then
			return
		end

		local window = resolve_window(window_id)
		if not window then
			leader_states[window_id] = nil
			return
		end

		local ok, active_key_table = pcall(function()
			return window:active_key_table()
		end)
		if ok and active_key_table == M.CUSTOM_LEADER_KEY_TABLE then
			watch_leader_state(window_id, generation)
			return
		end

		state.active = false
		state.generation = state.generation + 1
		render_status(window, current_pane(window))
	end)
end

function M.activate_custom_leader(window, pane)
	local state, window_id = state_for_window(window)
	if not state or not window_id then
		render_status(window, pane)
		return
	end

	state.active = true
	state.generation = state.generation + 1
	render_status(window, pane)
	watch_leader_state(window_id, state.generation)
end

function M.deactivate_custom_leader(window, pane)
	local state = state_for_window(window)
	if not state or not state.active then
		render_status(window, pane)
		return
	end

	state.active = false
	state.generation = state.generation + 1
	render_status(window, pane)
end

function M.register()
	wezterm.on("format-tab-title", format_tab_title)
	wezterm.on("update-status", render_status)
end

return M
