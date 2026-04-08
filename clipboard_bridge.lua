local wezterm = require("wezterm")
local U = require("utils")

local act = wezterm.action
local M = {}
local image_cache = {
	hash = "",
	windows_path = "",
	wsl_path = "",
}

local function command_mentions_claude(commandline)
	commandline = U.trim(commandline):lower()
	if commandline == "" then
		return false
	end

	if commandline:match("@anthropic%-ai/claude%-code") or commandline:match("claude%-code") then
		return true
	end

	for token in commandline:gmatch("%S+") do
		local executable = U.executable_name(token):lower()
		if executable == "claude" or executable == "claude-code" then
			return true
		end
	end

	return false
end

local function is_claude_pane(pane)
	local prog = U.pane_user_var(pane, "WEZTERM_PROG")
	if prog ~= "" then
		return command_mentions_claude(prog)
	end

	return command_mentions_claude(U.pane_title(pane))
end

local function forward_ctrl_v(window, pane)
	window:perform_action(
		act.SendKey({
			key = "v",
			mods = "CTRL",
		}),
		pane
	)
end

local function notify_bridge_failure(window, message, detail)
	local log_message = message
	if detail and detail ~= "" then
		log_message = log_message .. ": " .. detail
	end
	wezterm.log_warn(log_message)

	pcall(function()
		window:toast_notification("wezterm clipboard bridge", message, nil, 4000)
	end)
end

local function paste_quoted_path(pane, path)
	-- NOTE: Claude in WSL can turn a pasted image filepath into an
	-- attachment, but it only sees text input here, so paste a shell-safe single-
	-- quoted POSIX path that won't re-expand metacharacters in fish or POSIX
	-- shells.
	pane:send_paste(U.shell_single_quote(path))
end

local function parse_export_output(stdout)
	local status = ""
	local hash = ""
	local path = ""

	for line in stdout:gmatch("[^\r\n]+") do
		if line:match("^STATUS:") then
			status = U.trim(line:sub(8))
		elseif line:match("^HASH:") then
			hash = U.trim(line:sub(6))
		elseif line:match("^PATH:") then
			path = U.trim(line:sub(6))
		end
	end

	if status == "NO_IMAGE" then
		return "no_image", nil, nil
	end

	if status == "IMAGE" and hash ~= "" and path ~= "" then
		return "image", path, hash
	end

	if hash ~= "" and path ~= "" then
		return "image", path, hash
	end

	return "error", nil, nil
end

local function dump_windows_clipboard_image(cached_hash, cached_path)
	local script = table.concat({
		"param([string]$ExpectedHash, [string]$ExistingPath)",
		"[Console]::OutputEncoding = [System.Text.Encoding]::UTF8",
		"$ErrorActionPreference = 'Stop'",
		"$img = $null",
		"$stream = $null",
		"$sha = $null",
		"try {",
		"  $img = Get-Clipboard -Format Image",
		"  if ($img -eq $null) {",
		"    Write-Output 'STATUS:NO_IMAGE'",
		"  } else {",
		"    $stream = [System.IO.MemoryStream]::new()",
		"    $sha = [System.Security.Cryptography.SHA256]::Create()",
		"    $img.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)",
		"    $bytes = $stream.ToArray()",
		"    $hash = ([System.BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()",
		"    if ($ExpectedHash -and $hash -eq $ExpectedHash -and $ExistingPath -and (Test-Path -LiteralPath $ExistingPath)) {",
		"      $path = $ExistingPath",
		"    } else {",
		"      $path = Join-Path ([System.IO.Path]::GetTempPath()) ('wezterm-clipboard-' + [System.Guid]::NewGuid().ToString() + '.png')",
		"      [System.IO.File]::WriteAllBytes($path, $bytes)",
		"    }",
		"    Write-Output 'STATUS:IMAGE'",
		"    Write-Output ('HASH:' + $hash)",
		"    Write-Output ('PATH:' + $path)",
		"  }",
		"} catch {",
		"  Write-Error $_",
		"  exit 1",
		"} finally {",
		"  if ($sha) { $sha.Dispose() }",
		"  if ($stream) { $stream.Dispose() }",
		"  if ($img -is [System.IDisposable]) { $img.Dispose() }",
		"}",
	}, "; ")

	local ok, stdout, stderr = wezterm.run_child_process({
		"powershell.exe",
		"-NoProfile",
		"-Command",
		script,
		cached_hash or "",
		cached_path or "",
	})

	if ok then
		local status, path, hash = parse_export_output(stdout)
		if status == "image" then
			return status, path, hash
		end
		if status == "no_image" then
			return status, nil, nil
		end
		return "error", nil, nil, "clipboard bridge returned incomplete output"
	end

	local detail = U.trim(stderr)
	if detail == "" then
		detail = "clipboard export command failed"
	end
	return "error", nil, nil, detail
end

function M.paste_from_bridge(window, pane)
	if not U.is_wsl_domain(pane) or not is_claude_pane(pane) then
		forward_ctrl_v(window, pane)
		return
	end

	local status, windows_path, hash, err = dump_windows_clipboard_image(image_cache.hash, image_cache.windows_path)
	if status == "no_image" then
		window:perform_action(act.PasteFrom("Clipboard"), pane)
		return
	end
	if status ~= "image" or not windows_path then
		notify_bridge_failure(window, "failed to read clipboard image", err)
		return
	end

	local wsl_path = image_cache.wsl_path
	if hash ~= image_cache.hash or windows_path ~= image_cache.windows_path or wsl_path == "" then
		wsl_path = U.windows_path_to_wsl(windows_path)
	end
	if not wsl_path then
		notify_bridge_failure(window, "failed to map Windows temp image into WSL", windows_path)
		return
	end

	image_cache.hash = hash
	image_cache.windows_path = windows_path
	image_cache.wsl_path = wsl_path
	paste_quoted_path(pane, wsl_path)
end

function M.key_binding(key, mods)
	return {
		key = key,
		mods = mods,
		action = wezterm.action_callback(function(window, pane)
			M.paste_from_bridge(window, pane)
		end),
	}
end

return M
