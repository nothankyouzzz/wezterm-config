local C = require("constants")

local M = {}

function M.trim(text)
	if not text or text == "" then
		return ""
	end
	return text:match("^%s*(.-)%s*$")
end

function M.truncate_right(text, max_width)
	if not text or text == "" then
		return ""
	end
	if #text <= max_width then
		return text
	end
	if max_width <= 3 then
		return text:sub(1, max_width)
	end
	return text:sub(1, max_width - 3) .. "..."
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

function M.dir_label(target)
	return M.basename(M.pane_cwd(target))
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
	local name = M.pane_domain_name(target):gsub("^WSL:", "")
	if name == C.WSL_DISTRO then
		return "ubuntu"
	end
	return name
end

return M
