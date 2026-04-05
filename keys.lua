local wezterm = require("wezterm")

local act = wezterm.action
local M = {}

local LEADER = {
	key = "a",
	mods = "CTRL",
	timeout_milliseconds = 1000,
}

local RESIZE_STEP = 3

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
	cfg.leader = LEADER

	local keys = {
		-- Send CTRL-A through to the terminal with a double tap.
		{
			key = "a",
			mods = "LEADER|CTRL",
			action = act.SendKey({ key = "a", mods = "CTRL" }),
		},

		-- Panes
		{
			key = "v",
			mods = "LEADER",
			action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
		},
		{
			key = "s",
			mods = "LEADER",
			action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
		},
		{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
		{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
		{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
		{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
		{
			key = "r",
			mods = "LEADER",
			action = act.ActivateKeyTable({
				name = "resize_pane",
				one_shot = false,
				until_unknown = true,
			}),
		},
		{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
		{
			key = "x",
			mods = "LEADER",
			action = act.CloseCurrentPane({ confirm = true }),
		},

		-- Tabs
		{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
		{ key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
		{ key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
		{ key = ",", mods = "LEADER", action = act.MoveTabRelative(-1) },
		{ key = ".", mods = "LEADER", action = act.MoveTabRelative(1) },
		{
			key = "q",
			mods = "LEADER",
			action = act.CloseCurrentTab({ confirm = true }),
		},

		-- Workspaces and launcher
		{
			key = "w",
			mods = "LEADER",
			action = act.ShowLauncherArgs({
				flags = "FUZZY|WORKSPACES",
				title = "Workspaces",
			}),
		},
		{ key = "W", mods = "LEADER|SHIFT", action = new_workspace_prompt() },
		{
			key = "Space",
			mods = "LEADER",
			action = act.ShowLauncherArgs({
				flags = "FUZZY|TABS|WORKSPACES|DOMAINS|COMMANDS|LAUNCH_MENU_ITEMS",
				title = "Launcher",
			}),
		},
	}

	for i = 1, 9 do
		table.insert(keys, {
			key = tostring(i),
			mods = "LEADER",
			action = act.ActivateTab(i - 1),
		})
	end

	cfg.keys = keys
	cfg.key_tables = {
		resize_pane = {
			{ key = "h", action = act.AdjustPaneSize({ "Left", RESIZE_STEP }) },
			{ key = "j", action = act.AdjustPaneSize({ "Down", RESIZE_STEP }) },
			{ key = "k", action = act.AdjustPaneSize({ "Up", RESIZE_STEP }) },
			{ key = "l", action = act.AdjustPaneSize({ "Right", RESIZE_STEP }) },
			{ key = "LeftArrow", action = act.AdjustPaneSize({ "Left", RESIZE_STEP }) },
			{ key = "DownArrow", action = act.AdjustPaneSize({ "Down", RESIZE_STEP }) },
			{ key = "UpArrow", action = act.AdjustPaneSize({ "Up", RESIZE_STEP }) },
			{ key = "RightArrow", action = act.AdjustPaneSize({ "Right", RESIZE_STEP }) },
			{ key = "Escape", action = "PopKeyTable" },
			{ key = "Enter", action = "PopKeyTable" },
			{ key = "q", action = "PopKeyTable" },
		},
	}
end

return M
