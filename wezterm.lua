local wezterm = require("wezterm")
local config = wezterm.config_builder()
config:set_strict_mode(true)

local function preferred_default_domain()
	local wsl_domains = wezterm.default_wsl_domains()

	for _, domain in ipairs(wsl_domains) do
		if domain.distribution == "Ubuntu-24.04" then
			return domain.name
		end
	end

	for _, domain in ipairs(wsl_domains) do
		if domain.distribution:match("^Ubuntu") then
			return domain.name
		end
	end

	return nil
end

local default_domain = preferred_default_domain()
if default_domain then
	config.default_domain = default_domain
end

require("appearance").apply(config)
require("graphics").apply(config)
require("status").register()

return config
