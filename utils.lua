local wezterm = require("wezterm")
local C = require("constants")

local M = {}

function M.trim(text)
	if not text or text == "" then
		return ""
	end
	return text:match("^%s*(.-)%s*$")
end

function M.display_width(text)
	if not text or text == "" then
		return 0
	end

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

function M.basename(path)
	if not path or path == "" then
		return ""
	end
	return path:gsub("[/\\]+$", ""):match("([^/\\]+)$") or path
end

function M.cwd_from_uri(cwd_uri)
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

function M.pane_value(target, method_name, field_name, default)
	if not target then
		return default
	end

	local ok, getter = pcall(function()
		return target[method_name]
	end)
	if ok and type(getter) == "function" then
		local ok2, value = pcall(getter, target)
		if ok2 and value ~= nil then
			return value
		end
	end

	local ok3, value = pcall(function()
		return target[field_name]
	end)
	if ok3 and value ~= nil then
		return value
	end

	return default
end

function M.pane_cwd(target)
	return M.cwd_from_uri(M.pane_value(target, "get_current_working_dir", "current_working_dir", ""))
end

function M.pane_title(target)
	return M.pane_value(target, "get_title", "title", "")
end

function M.pane_process_name(target)
	return M.pane_value(target, "get_foreground_process_name", "foreground_process_name", "")
end

function M.pane_domain_name(target)
	return M.pane_value(target, "get_domain_name", "domain_name", "")
end

function M.pane_user_vars(target)
	local vars = M.pane_value(target, "get_user_vars", "user_vars", {})
	if type(vars) ~= "table" then
		return {}
	end
	return vars
end

function M.dir_label(target)
	return M.basename(M.pane_cwd(target))
end

function M.command_label(text)
	text = M.trim(text)
	if text == "" then
		return nil
	end

	local executable = text:match('^"([^"]+)"')
		or text:match("^'([^']+)'")
		or text:match("^(%S+)")
		or text

	return M.normalized_label_text(executable)
end

function M.normalized_label_text(text)
	text = M.trim(text)
	if text == "" then
		return nil
	end
	text = M.trim(text:match("[^|]+$") or text)
	text = M.basename(text):gsub("%.exe$", "")
	if text == "" or C.IGNORED_TAB_LABELS[text] then
		return nil
	end
	return text
end

function M.domain_label(target)
	local name = M.trim(M.pane_domain_name(target))
	if name == "" then
		return ""
	end
	name = name:match("^WSL:(.+)$") or name
	return name
end

function M.tab_fallback_label(target)
	local domain = M.trim(M.pane_domain_name(target))
	if domain == "" then
		return "local"
	end

	if domain == "local" then
		local user_vars = M.pane_user_vars(target)
		return M.command_label(user_vars.WEZTERM_PROG) or "local"
	end

	return M.domain_label(target)
end

return M
