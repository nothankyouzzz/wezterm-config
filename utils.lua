local wezterm = require("wezterm")
local C = require("constants")

local M = {}

-- Basic string and path helpers
function M.trim(text)
	if not text or text == "" then
		return ""
	end
	return text:match("^%s*(.-)%s*$")
end

local function basename(path)
	if not path or path == "" then
		return ""
	end
	return path:gsub("[/\\]+$", ""):match("([^/\\]+)$") or path
end

local function cwd_from_uri(cwd_uri)
	if not cwd_uri then
		return ""
	end

	local cwd = cwd_uri.file_path or cwd_uri.path or tostring(cwd_uri)
	if type(cwd) ~= "string" then
		return ""
	end

	cwd = cwd:gsub("^file://", "")
	cwd = cwd:gsub("^//wsl%.localhost/[^/]+", "")
	return cwd
end

-- Pane accessors
local function pane_value(target, method_name, field_name, default)
	if not target then
		return default
	end

	-- We use these helpers from both runtime Pane objects and the
	-- PaneInformation snapshots passed to format-tab-title.
	-- Keep the method + field fallback so tab title rendering doesn't error and
	-- silently fall back to WezTerm's default tab label.
	local ok, getter = pcall(function()
		return target[method_name]
	end)
	if ok and type(getter) == "function" then
		local ok_value, value = pcall(getter, target)
		if ok_value and value ~= nil then
			return value
		end
	end

	local ok, value = pcall(function()
		return target[field_name]
	end)
	if ok and value ~= nil then
		return value
	end

	return default
end

local function pane_cwd(target)
	return cwd_from_uri(pane_value(target, "get_current_working_dir", "current_working_dir", ""))
end

local function pane_user_vars(target)
	local vars = pane_value(target, "get_user_vars", "user_vars", {})
	if type(vars) ~= "table" then
		return {}
	end
	return vars
end

-- Label normalization
local function normalized_domain_label(text)
	local name = M.trim(text)
	if name == "" then
		return nil
	end

	-- WezTerm reports WSL domains as "WSL:<distro>"; strip the transport prefix
	-- so UI labels show the distro users actually recognize.
	name = name:match("^WSL:(.+)$") or name
	return name
end

function M.display_width(text)
	if not text or text == "" then
		return 0
	end

	-- Tab titles can contain wide glyphs, so use WezTerm's cell width rather
	-- than Lua's byte length when deciding whether to truncate.
	local ok, width = pcall(wezterm.column_width, text)
	if ok and type(width) == "number" then
		return width
	end

	local ok_len, length = pcall(utf8.len, text)
	if ok_len and type(length) == "number" then
		return length
	end

	return #text
end

function M.executable_name(text)
	text = M.trim(text)
	if text == "" then
		return ""
	end

	text = text:gsub('^["\']+', ""):gsub('["\']+$', "")
	return basename(text):gsub("%.exe$", "")
end

function M.center_text(text, width)
	width = math.max(math.floor(width or 0), 0)
	if width == 0 then
		return ""
	end

	local text_width = M.display_width(text)
	if text_width >= width then
		return text
	end

	local total_pad = width - text_width
	local left_pad = math.floor(total_pad / 2)
	local right_pad = total_pad - left_pad
	return string.rep(" ", left_pad) .. text .. string.rep(" ", right_pad)
end

function M.truncate_right(text, max_width)
	if not text or text == "" then
		return ""
	end
	max_width = math.max(math.floor(max_width or 0), 0)
	if max_width == 0 then
		return ""
	end
	if M.display_width(text) <= max_width then
		return text
	end

	local ok, truncated = pcall(wezterm.truncate_right, text, max_width)
	if ok and type(truncated) == "string" then
		return truncated
	end

	if max_width <= 3 then
		local stop = utf8.offset(text, max_width + 1)
		return stop and text:sub(1, stop - 1) or text
	end

	local stop = utf8.offset(text, max_width - 2)
	local prefix = stop and text:sub(1, stop - 1) or text
	return prefix .. "..."
end

function M.pane_title(target)
	return pane_value(target, "get_title", "title", "")
end

function M.pane_user_var(target, name)
	if not name or name == "" then
		return ""
	end

	local value = pane_user_vars(target)[name]
	if type(value) ~= "string" then
		return ""
	end

	return M.trim(value)
end

function M.pane_process_name(target)
	return pane_value(target, "get_foreground_process_name", "foreground_process_name", "")
end

function M.pane_domain_name(target)
	return pane_value(target, "get_domain_name", "domain_name", "")
end

function M.is_wsl_domain(target)
	local domain = M.pane_domain_name(target)
	return type(domain) == "string" and domain:match("^WSL:") ~= nil
end

function M.dir_label(target)
	return basename(pane_cwd(target))
end

local function command_label(text)
	text = M.trim(text)
	if text == "" then
		return nil
	end

	local executable = text:match('^"([^"]+)"')
		or text:match("^'([^']+)'")
		or text:match("^(%S+)")
		or text

	return M.normalized_label_text(M.executable_name(executable))
end

function M.is_ignored_tab_label(text)
	local label = M.executable_name(text):lower()
	if label == "" then
		return false
	end

	return C.IGNORED_TAB_LABELS[label] == true
end

function M.normalized_label_text(text)
	text = M.trim(text)
	if text == "" then
		return nil
	end

	-- Keep the right-most label when titles include pipe-delimited context, then
	-- reduce paths and executables to a short display name.
	text = M.executable_name(M.trim(text:match("[^|]+$") or text))
	if text == "" or M.is_ignored_tab_label(text) then
		return nil
	end
	return text
end

function M.pane_command_label(target)
	-- CONSTRAINT: WSL panes need shell-emitted WEZTERM_PROG because the
	-- Windows-side foreground-process probe is only a best-effort heuristic.
	local prog = command_label(M.pane_user_var(target, "WEZTERM_PROG"))
	if prog then
		return prog
	end

	local process = M.normalized_label_text(M.pane_process_name(target))
	if process then
		return process
	end

	local title = M.normalized_label_text(M.pane_title(target))
	if title then
		return title
	end

	return nil
end

function M.domain_label(target)
	return normalized_domain_label(M.pane_domain_name(target)) or ""
end

function M.windows_path_to_wsl(path)
	if type(path) ~= "string" then
		return nil
	end

	local drive = path:match("^([A-Za-z]):")
	if not drive then
		return nil
	end

	local suffix = path:sub(3):gsub("^[/\\]+", "")
	suffix = suffix:gsub("\\", "/")
	return string.format("/mnt/%s/%s", drive:lower(), suffix)
end

function M.shell_single_quote(text)
	text = tostring(text or "")
	return "'" .. text:gsub("'", [['"'"']]) .. "'"
end

function M.tab_fallback_label(target)
	local domain = normalized_domain_label(M.pane_domain_name(target))
	if not domain then
		return "local"
	end

	if domain == "local" then
		-- The local Windows domain has no distro context, so prefer shell
		-- integration's WEZTERM_PROG over a generic fallback label.
		return command_label(M.pane_user_var(target, "WEZTERM_PROG")) or domain
	end

	return domain
end

return M
