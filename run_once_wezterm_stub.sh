#!/bin/bash

WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
WSL_USER=$USER
WSL_DISTRO=$WSL_DISTRO_NAME
STUB_PATH="/mnt/c/Users/$WIN_USER/.wezterm.lua"
WATCHER_PATH="$HOME/.config/wezterm/config_watcher.sh"

cat >"$STUB_PATH" <<EOF
local wsl_config_dir = "\\\\\\\\wsl.localhost\\\\$WSL_DISTRO\\\\home\\\\$WSL_USER\\\\.config\\\\wezterm"

package.path = wsl_config_dir .. "\\\\?.lua;" .. package.path

local _require = require
require = function(modname)
    if package.loaded[modname] then
        return package.loaded[modname]
    end

    local path = wsl_config_dir .. "\\\\" .. modname:gsub("%.", "\\\\") .. ".lua"
    local ok, result = pcall(dofile, path)
    if ok then
        package.loaded[modname] = result
        return result
    end

    return _require(modname)
end

return dofile(wsl_config_dir .. "\\\\wezterm.lua")
EOF

echo "WezTerm stub written to $STUB_PATH"

cat >"$WATCHER_PATH" <<EOF
#!/bin/bash

STUB="/mnt/c/Users/$WIN_USER/.wezterm.lua"
CONFIG_DIR="\$HOME/.config/wezterm"

inotifywait -m -r -e close_write --include '\\.lua\$' "\$CONFIG_DIR" |
while read -r _ _ _; do
    touch "\$STUB"
done
EOF

chmod +x "$WATCHER_PATH"
echo "config_watcher.sh written to $WATCHER_PATH"
