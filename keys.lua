local wezterm = require("wezterm")
local C = require("constants")
local ClipboardBridge = require("clipboard_bridge")
local Status = require("status")

local act = wezterm.action
local M = {}

local RESIZE_STEP = 3
local TAB_SELECT_BINDINGS = {
	{ key = "1", index = 0 },
	{ key = "2", index = 1 },
	{ key = "3", index = 2 },
	{ key = "4", index = 3 },
	{ key = "5", index = 4 },
	{ key = "6", index = 5 },
	{ key = "7", index = 6 },
	{ key = "8", index = 7 },
	{ key = "9", index = 8 },
}

local function perform_action_and_refresh(window, pane, action)
	window:perform_action(action, pane)
	Status.deactivate_custom_leader(window, pane)
end

local function leader_binding(key, action, mods)
	return {
		key = key,
		mods = mods,
		action = wezterm.action_callback(function(window, pane)
			perform_action_and_refresh(window, pane, action)
		end),
	}
end

local function leader_activation()
	return wezterm.action_callback(function(window, pane)
		Status.activate_custom_leader(window, pane)
		window:perform_action(act.ActivateKeyTable({
			name = Status.CUSTOM_LEADER_KEY_TABLE,
			one_shot = true,
			timeout_milliseconds = C.LEADER.timeout_milliseconds,
			until_unknown = true,
			prevent_fallback = true,
		}), pane)
	end)
end

local function append_tab_select_bindings(bindings)
	for _, binding in ipairs(TAB_SELECT_BINDINGS) do
		table.insert(bindings, leader_binding(binding.key, act.ActivateTab(binding.index)))
	end
end

local function trim(text)
	if not text or text == "" then
		return ""
	end
	return text:match("^%s*(.-)%s*$")
end

local function new_workspace_prompt()
	return act.PromptInputLine({
		description = "Enter name for new workspace",
		action = wezterm.action_callback(function(window, pane, line)
			line = trim(line)
			if line ~= "" then
				window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
			end
		end),
	})
end

function M.apply(cfg)
	local keys = {
		{
			key = C.LEADER.key,
			mods = C.LEADER.mods,
			action = leader_activation(),
		},
		{ key = "h", mods = "ALT", action = act.ActivatePaneDirection("Left") },
		{ key = "j", mods = "ALT", action = act.ActivatePaneDirection("Down") },
		{ key = "k", mods = "ALT", action = act.ActivatePaneDirection("Up") },
		{ key = "l", mods = "ALT", action = act.ActivatePaneDirection("Right") },
		{ key = "LeftArrow", mods = "ALT", action = act.AdjustPaneSize({ "Left", RESIZE_STEP }) },
		{ key = "DownArrow", mods = "ALT", action = act.AdjustPaneSize({ "Down", RESIZE_STEP }) },
		{ key = "UpArrow", mods = "ALT", action = act.AdjustPaneSize({ "Up", RESIZE_STEP }) },
		{ key = "RightArrow", mods = "ALT", action = act.AdjustPaneSize({ "Right", RESIZE_STEP }) },
		ClipboardBridge.key_binding(C.CLIPBOARD_BRIDGE.key, C.CLIPBOARD_BRIDGE.mods),
	}

	cfg.keys = keys
	cfg.key_tables = {
		[Status.CUSTOM_LEADER_KEY_TABLE] = {
			-- Send CTRL-A through to the terminal with a double tap.
			leader_binding(C.LEADER.key, act.SendKey({ key = C.LEADER.key, mods = C.LEADER.mods }), C.LEADER.mods),

			-- Panes
			leader_binding("v", act.SplitHorizontal({ domain = "CurrentPaneDomain" })),
			leader_binding("s", act.SplitVertical({ domain = "CurrentPaneDomain" })),
			leader_binding("z", act.TogglePaneZoomState),
			leader_binding("x", act.CloseCurrentPane({ confirm = true })),

			-- Tabs
			leader_binding("c", act.SpawnTab("CurrentPaneDomain")),
			leader_binding("n", act.ActivateTabRelative(1)),
			leader_binding("p", act.ActivateTabRelative(-1)),
			leader_binding(",", act.MoveTabRelative(-1)),
			leader_binding(".", act.MoveTabRelative(1)),
			leader_binding("q", act.CloseCurrentTab({ confirm = true })),

			-- Workspaces and launcher
			leader_binding("w", act.ShowLauncherArgs({
				flags = "FUZZY|WORKSPACES",
				title = "Workspaces",
			})),
			leader_binding("W", new_workspace_prompt(), "SHIFT"),
			leader_binding("Space", act.ShowLauncherArgs({
				flags = "FUZZY|TABS|WORKSPACES|DOMAINS|COMMANDS|LAUNCH_MENU_ITEMS",
				title = "Launcher",
			})),
		},
	}

	append_tab_select_bindings(cfg.key_tables[Status.CUSTOM_LEADER_KEY_TABLE])
end

return M
