local wezterm = require("wezterm")
local config = wezterm.config_builder()
config:set_strict_mode(true)

require("domains").apply(config)
require("appearance").apply(config)
require("graphics").apply(config)
require("keys").apply(config)
require("status").register()

return config
